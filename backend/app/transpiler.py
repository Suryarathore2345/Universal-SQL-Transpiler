"""
Core transpiler — orchestrates parser → IR → generator pipeline.

Usage:
    from app.transpiler import Transpiler
    result = Transpiler.convert(source_sql, "redshift", "snowflake")
"""
from __future__ import annotations

from typing import Dict, List, Optional, Type

from app.dialects.base import DialectGenerator, DialectParser
from app.ir.models import (
    Dialect, IRDDLObject, IRDocReference, IRFunction, IRMaterializedView,
    IRProcedure, IRTable, IRView, IRWarning, ObjectType, TranspileResult,
    Warningseverity,
)


# ---------------------------------------------------------------------------
# Dialect registry — add new dialects here as they are implemented
# ---------------------------------------------------------------------------

def _load_parsers() -> Dict[Dialect, DialectParser]:
    from app.dialects.redshift.parser import RedshiftParser
    from app.dialects.snowflake.parser import SnowflakeParser
    from app.dialects.sqlserver.parser import SQLServerParser
    from app.dialects.synapse.parser import SynapseParser
    from app.dialects.fabric_dw.parser import FabricDWParser
    from app.dialects.databricks.parser import DatabricksParser
    from app.dialects.oracle.parser import OracleParser
    from app.dialects.bigquery.parser import BigQueryParser

    return {
        Dialect.REDSHIFT: RedshiftParser(),
        Dialect.SNOWFLAKE: SnowflakeParser(),
        Dialect.SQLSERVER: SQLServerParser(),
        Dialect.SYNAPSE: SynapseParser(),
        Dialect.FABRIC_DW: FabricDWParser(),
        Dialect.DATABRICKS: DatabricksParser(),
        Dialect.ORACLE: OracleParser(),
        Dialect.BIGQUERY: BigQueryParser(),
    }


def _load_generators() -> Dict[Dialect, DialectGenerator]:
    from app.dialects.redshift.generator import RedshiftGenerator
    from app.dialects.snowflake.generator import SnowflakeGenerator
    from app.dialects.sqlserver.generator import SQLServerGenerator
    from app.dialects.synapse.generator import SynapseGenerator
    from app.dialects.fabric_dw.generator import FabricDWGenerator
    from app.dialects.databricks.generator import DatabricksGenerator
    from app.dialects.oracle.generator import OracleGenerator
    from app.dialects.bigquery.generator import BigQueryGenerator

    return {
        Dialect.REDSHIFT: RedshiftGenerator(),
        Dialect.SNOWFLAKE: SnowflakeGenerator(),
        Dialect.SQLSERVER: SQLServerGenerator(),
        Dialect.SYNAPSE: SynapseGenerator(),
        Dialect.FABRIC_DW: FabricDWGenerator(),
        Dialect.DATABRICKS: DatabricksGenerator(),
        Dialect.ORACLE: OracleGenerator(),
        Dialect.BIGQUERY: BigQueryGenerator(),
    }


class Transpiler:
    """
    Main transpiler class. Converts SQL DDL between supported dialect pairs.

    Architecture:
      source SQL → [DialectParser] → IR → [DialectGenerator] → target SQL

    Each parser and generator pair is independent, so adding a new dialect
    requires only a new Parser + Generator (no changes to existing code).
    """

    _parsers: Optional[Dict[Dialect, DialectParser]] = None
    _generators: Optional[Dict[Dialect, DialectGenerator]] = None

    @classmethod
    def _get_parsers(cls) -> Dict[Dialect, DialectParser]:
        if cls._parsers is None:
            cls._parsers = _load_parsers()
        return cls._parsers

    @classmethod
    def _get_generators(cls) -> Dict[Dialect, DialectGenerator]:
        if cls._generators is None:
            cls._generators = _load_generators()
        return cls._generators

    @classmethod
    def supported_dialects(cls) -> List[str]:
        return [d.value for d in cls._get_parsers().keys()]

    @classmethod
    def convert(
        cls,
        sql: str,
        source_dialect: str,
        target_dialect: str,
        object_type: Optional[str] = None,
    ) -> TranspileResult:
        """
        Convert SQL DDL from source_dialect to target_dialect.

        Args:
            sql:             Input SQL text (single statement or multi-statement script)
            source_dialect:  Source dialect key (e.g. "redshift", "snowflake")
            target_dialect:  Target dialect key
            object_type:     Optional hint: "table"|"view"|"materialized_view"|etc.

        Returns:
            TranspileResult with converted_sql, warnings, unsupported_features, doc_references.
        """
        try:
            src = Dialect(source_dialect)
            tgt = Dialect(target_dialect)
        except ValueError as e:
            return TranspileResult(
                converted_sql="",
                source_dialect=Dialect.REDSHIFT,
                target_dialect=Dialect.SNOWFLAKE,
                object_type=ObjectType.TABLE,
                warnings=[IRWarning(
                    feature="INVALID_DIALECT",
                    message=str(e),
                    severity=Warningseverity.ERROR,
                )],
            )

        parsers = cls._get_parsers()
        generators = cls._get_generators()

        if src not in parsers:
            return cls._unsupported_dialect_result(src, tgt, f"Source dialect '{src.value}' is not yet implemented. Coming in Phase 2.")

        if tgt not in generators:
            return cls._unsupported_dialect_result(src, tgt, f"Target dialect '{tgt.value}' is not yet implemented. Coming in Phase 2.")

        parser = parsers[src]
        generator = generators[tgt]

        all_warnings: List[IRWarning] = []
        all_unsupported: List[IRWarning] = []
        all_doc_refs: List[IRDocReference] = []
        output_parts: List[str] = []
        detected_object_type = ObjectType.TABLE

        parse_results = parser.parse(sql)

        for ir_obj, parse_warnings, parse_refs in parse_results:
            all_warnings.extend(parse_warnings)
            all_doc_refs.extend(parse_refs)

            if ir_obj is None:
                continue

            # Determine object type for the result metadata
            if isinstance(ir_obj, IRTable):
                detected_object_type = ObjectType.TABLE
                gen_sql, gen_warnings, gen_refs = generator.generate_table(ir_obj)
            elif isinstance(ir_obj, IRMaterializedView):
                detected_object_type = ObjectType.MATERIALIZED_VIEW
                gen_sql, gen_warnings, gen_refs = generator.generate_materialized_view(ir_obj)
            elif isinstance(ir_obj, IRView):
                detected_object_type = ObjectType.VIEW
                gen_sql, gen_warnings, gen_refs = generator.generate_view(ir_obj)
            elif isinstance(ir_obj, IRProcedure):
                detected_object_type = ObjectType.PROCEDURE
                gen_sql, gen_warnings, gen_refs = generator.generate_procedure(ir_obj)
            elif isinstance(ir_obj, IRFunction):
                detected_object_type = ObjectType.FUNCTION
                gen_sql, gen_warnings, gen_refs = generator.generate_function(ir_obj)
            else:
                all_warnings.append(IRWarning(
                    feature="UNSUPPORTED_OBJECT_TYPE",
                    message=f"Object type {type(ir_obj).__name__} is not supported.",
                    severity=Warningseverity.WARNING,
                ))
                continue

            output_parts.append(gen_sql)
            all_warnings.extend(gen_warnings)
            all_doc_refs.extend(gen_refs)

        # Separate warnings from unsupported features
        unsupported = [w for w in all_warnings if w.unsupported]
        clean_warnings = [w for w in all_warnings if not w.unsupported]

        # Deduplicate doc refs by URL
        seen_urls = set()
        deduped_refs = []
        for ref in all_doc_refs:
            if ref.url not in seen_urls:
                seen_urls.add(ref.url)
                deduped_refs.append(ref)

        return TranspileResult(
            converted_sql="\n\n".join(output_parts),
            source_dialect=src,
            target_dialect=tgt,
            object_type=ObjectType(object_type) if object_type else detected_object_type,
            warnings=clean_warnings,
            unsupported_features=unsupported,
            doc_references=deduped_refs,
        )

    @classmethod
    def _unsupported_dialect_result(cls, src: Dialect, tgt: Dialect, message: str) -> TranspileResult:
        return TranspileResult(
            converted_sql="",
            source_dialect=src,
            target_dialect=tgt,
            object_type=ObjectType.TABLE,
            warnings=[IRWarning(
                feature="UNSUPPORTED_DIALECT",
                message=message,
                severity=Warningseverity.ERROR,
                unsupported=True,
            )],
        )
