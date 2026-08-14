/**
 * SqlEditor — Monaco Editor wrapper for SQL input/output.
 * Uses the official @monaco-editor/react package.
 * Docs: https://github.com/suren-atoyan/monaco-react
 */
import Editor from '@monaco-editor/react'

// Monaco's bundled 'sql' language (from monaco-editor's basic-languages set)
// only ships a tokenizer for syntax highlighting — it has no completion
// provider of its own, which is why the editor previously fell back to
// word-based suggestions (arbitrary words pulled from the document text,
// e.g. column names) instead of real SQL keywords. This registers an actual
// keyword/function completion provider so typing "c" suggests CASE, CAST,
// COUNT, CREATE, etc.
const SQL_KEYWORDS = [
  'SELECT', 'FROM', 'WHERE', 'GROUP', 'BY', 'ORDER', 'HAVING', 'LIMIT', 'OFFSET',
  'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'MERGE',
  'CREATE', 'ALTER', 'DROP', 'TABLE', 'VIEW', 'MATERIALIZED', 'PROCEDURE', 'FUNCTION',
  'REPLACE', 'IF', 'EXISTS', 'SCHEMA', 'DATABASE', 'INDEX', 'SEQUENCE', 'TRIGGER',
  'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'UNIQUE', 'CHECK', 'CONSTRAINT', 'DEFAULT',
  'NOT', 'NULL', 'AS', 'DISTINCT', 'ALL', 'UNION', 'INTERSECT', 'EXCEPT',
  'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 'CROSS', 'NATURAL', 'ON', 'USING',
  'AND', 'OR', 'IN', 'BETWEEN', 'LIKE', 'IS', 'ASC', 'DESC',
  'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
  'WITH', 'RECURSIVE', 'PARTITION', 'OVER', 'ROWS', 'RANGE', 'UNBOUNDED', 'PRECEDING', 'FOLLOWING',
  'GRANT', 'REVOKE', 'TRUNCATE', 'COMMIT', 'ROLLBACK', 'BEGIN', 'TRANSACTION',
  'VARCHAR', 'INTEGER', 'BIGINT', 'SMALLINT', 'DECIMAL', 'NUMERIC', 'FLOAT', 'DOUBLE',
  'TIMESTAMP', 'DATE', 'TIME', 'BOOLEAN', 'IDENTITY', 'AUTOINCREMENT',
]

const SQL_FUNCTIONS = [
  'CAST', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX',
  'ROW_NUMBER', 'RANK', 'DENSE_RANK', 'LAG', 'LEAD',
  'COALESCE', 'NVL', 'NULLIF', 'ISNULL',
  'SUBSTRING', 'TRIM', 'UPPER', 'LOWER', 'LENGTH', 'CONCAT', 'REPLACE',
  'ROUND', 'FLOOR', 'CEIL', 'CEILING', 'ABS',
  'EXTRACT', 'DATE_TRUNC', 'DATEADD', 'DATEDIFF', 'CURRENT_DATE', 'CURRENT_TIMESTAMP',
]

let completionProviderRegistered = false

function registerSqlCompletionProvider(monaco) {
  if (completionProviderRegistered) return
  completionProviderRegistered = true

  monaco.languages.registerCompletionItemProvider('sql', {
    triggerCharacters: [' ', '.'],
    provideCompletionItems(model, position) {
      const word = model.getWordUntilPosition(position)
      const range = {
        startLineNumber: position.lineNumber,
        endLineNumber: position.lineNumber,
        startColumn: word.startColumn,
        endColumn: word.endColumn,
      }
      const keywordItems = SQL_KEYWORDS.map((kw) => ({
        label: kw,
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: kw,
        range,
      }))
      const functionItems = SQL_FUNCTIONS.map((fn) => ({
        label: fn,
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: `${fn}(`,
        range,
      }))
      return { suggestions: [...keywordItems, ...functionItems] }
    },
  })
}

export default function SqlEditor({
  value,
  onChange,
  readOnly = false,
  loading = false,
  placeholder = '',
}) {
  function handleMount(editor, monaco) {
    // Register UST custom theme
    monaco.editor.defineTheme('ust-dark', {
      base: 'vs-dark',
      inherit: true,
      rules: [
        { token: 'keyword.sql', foreground: 'a78bfa', fontStyle: 'bold' },
        { token: 'string.sql',  foreground: '86efac' },
        { token: 'comment',     foreground: '6b7280', fontStyle: 'italic' },
        { token: 'number',      foreground: 'fbbf24' },
      ],
      colors: {
        'editor.background':           '#0d1117',
        'editor.foreground':           '#e6edf3',
        'editor.lineHighlightBackground': '#161b22',
        'editor.selectionBackground':  '#2d333b',
        'editorLineNumber.foreground': '#484f58',
        'editorLineNumber.activeForeground': '#a78bfa',
        'editorCursor.foreground':     '#a78bfa',
        'scrollbar.shadow':            '#00000000',
        'editor.inactiveSelectionBackground': '#161b22',
      },
    })
    monaco.editor.setTheme('ust-dark')

    registerSqlCompletionProvider(monaco)

    // Show placeholder when empty
    if (placeholder && !value) {
      editor.updateOptions({ renderValidationDecorations: 'off' })
    }
  }

  return (
    <div className={`editor-wrap ${loading ? 'editor-loading' : ''}`}>
      {loading && (
        <div className="editor-overlay">
          <span className="spinner" />
        </div>
      )}
      {!loading && placeholder && !value && (
        <div className="editor-placeholder" aria-hidden="true">{placeholder}</div>
      )}
      <Editor
        height="100%"
        defaultLanguage="sql"
        value={value}
        onChange={readOnly ? undefined : onChange}
        options={{
          readOnly,
          fontSize: 13,
          fontFamily: "'JetBrains Mono', 'Fira Code', 'Cascadia Code', 'Consolas', monospace",
          fontLigatures: true,
          minimap: { enabled: false },
          scrollBeyondLastLine: false,
          wordWrap: 'on',
          lineNumbers: 'on',
          renderLineHighlight: 'all',
          smoothScrolling: true,
          cursorBlinking: 'smooth',
          padding: { top: 12, bottom: 12 },
          suggest: { showKeywords: true },
          // Monaco's word-based suggestions scan the document text itself and
          // surface any word that's appeared in it (e.g. column names from a
          // pasted DDL) alongside real SQL keywords. Off, so the completion
          // list only ever contains actual SQL language suggestions.
          wordBasedSuggestions: 'off',
        }}
        onMount={handleMount}
      />
    </div>
  )
}
