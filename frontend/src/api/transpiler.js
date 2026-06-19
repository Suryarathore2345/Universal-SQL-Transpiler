/**
 * API client for the Universal SQL Transpiler backend.
 * All calls go through the Vite proxy → FastAPI on :8000.
 */

const BASE = '/api'

/**
 * Fetch all supported dialects with their metadata.
 * @returns {Promise<Array>} Array of DialectCapabilities objects
 */
export async function fetchDialects() {
  const res = await fetch(`${BASE}/dialects`)
  if (!res.ok) throw new Error(`Failed to load dialects: ${res.status}`)
  const data = await res.json()
  return data.dialects
}

/**
 * Fetch known limitations for a target dialect (or all dialects if omitted).
 * Pass `source` to filter out limitations irrelevant to the current source dialect.
 * @param {string} [dialect]  target dialect key
 * @param {string} [source]   source dialect key (optional filter)
 * @returns {Promise<Array>} Array of DialectLimitations objects
 */
export async function fetchLimitations(dialect, source) {
  const params = new URLSearchParams()
  if (dialect) params.set('dialect', dialect)
  if (source)  params.set('source',  source)
  const qs  = params.toString()
  const url = qs ? `${BASE}/limitations?${qs}` : `${BASE}/limitations`
  const res = await fetch(url)
  if (!res.ok) throw new Error(`Failed to load limitations: ${res.status}`)
  const data = await res.json()
  return data.dialects
}

/**
 * Transpile SQL from one dialect to another.
 * @param {Object} params
 * @param {string} params.sql
 * @param {string} params.sourceDialect
 * @param {string} params.targetDialect
 * @param {boolean} [params.includeIr]
 * @param {string|null} [params.targetSchema]  Dynamic schema override (null = hardcoded)
 * @returns {Promise<Object>} TranspileResponse
 */
export async function transpile({ sql, sourceDialect, targetDialect, includeIr = false, targetSchema = null }) {
  const body = {
    sql,
    source_dialect: sourceDialect,
    target_dialect: targetDialect,
    include_ir: includeIr,
  }
  if (targetSchema) body.target_schema = targetSchema

  const res = await fetch(`${BASE}/transpile`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })

  const data = await res.json()

  if (!res.ok) {
    throw new Error(data.detail || data.error || `HTTP ${res.status}`)
  }

  return data
}
