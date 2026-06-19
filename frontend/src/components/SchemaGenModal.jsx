/**
 * Dynamic Schema Generation modal.
 *
 * Accepts CSV or JSON sample data, a table name, an optional schema, and
 * calls POST /api/schema/infer to generate a CREATE TABLE DDL in the
 * currently-selected source dialect.  The result is inserted into the
 * source editor and the modal closes.
 */
import { useRef, useState } from 'react'
import { inferSchema } from '../api/transpiler.js'

const SAMPLE_CSV = `id,name,amount,is_active,created_at
1,Alice,1500.50,true,2024-01-01
2,Bob,2000.00,false,2024-02-15
3,Charlie,3500.75,true,2024-03-20`

const SAMPLE_JSON = `[
  {"id": 1, "email": "alice@example.com", "score": 9.5, "active": true, "joined": "2024-01-01"},
  {"id": 2, "email": "bob@example.com",   "score": 7.2, "active": false, "joined": "2024-03-10"}
]`

export default function SchemaGenModal({ sourceDialect, onInsert, onClose }) {
  const [fmt, setFmt]           = useState('csv')
  const [data, setData]         = useState(SAMPLE_CSV)
  const [tableName, setTable]   = useState('my_table')
  const [schemaName, setSchema] = useState('')
  const [loading, setLoading]   = useState(false)
  const [error, setError]       = useState(null)
  const textareaRef             = useRef(null)

  function handleFormatChange(newFmt) {
    setFmt(newFmt)
    setData(newFmt === 'json' ? SAMPLE_JSON : SAMPLE_CSV)
    setError(null)
  }

  async function handleGenerate() {
    if (!data.trim()) { setError('Please paste some sample data first.'); return }
    if (!tableName.trim()) { setError('Table name is required.'); return }
    setLoading(true)
    setError(null)
    try {
      const result = await inferSchema({
        data,
        format: fmt,
        tableName: tableName.trim(),
        schemaName: schemaName.trim(),
        targetDialect: sourceDialect,
      })
      onInsert(result.ddl)
      onClose()
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  function handleBackdrop(e) {
    if (e.target === e.currentTarget) onClose()
  }

  return (
    <div className="sg-backdrop" onClick={handleBackdrop}>
      <div className="sg-modal" role="dialog" aria-modal="true" aria-label="Generate Schema">
        {/* Header */}
        <div className="sg-header">
          <div className="sg-title-group">
            <span className="sg-icon">⊕</span>
            <div>
              <h2 className="sg-title">Generate Schema from Data</h2>
              <p className="sg-subtitle">
                Paste CSV or JSON — types are inferred automatically and a{' '}
                <code>CREATE TABLE</code> is generated in <strong>{sourceDialect}</strong> dialect.
              </p>
            </div>
          </div>
          <button className="sg-close" onClick={onClose} aria-label="Close">✕</button>
        </div>

        {/* Body */}
        <div className="sg-body">
          {/* Format toggle */}
          <div className="sg-row">
            <label className="sg-label">Input format</label>
            <div className="sg-fmt-toggle">
              {['csv', 'json'].map(f => (
                <button
                  key={f}
                  className={`sg-fmt-btn ${fmt === f ? 'sg-fmt-btn--active' : ''}`}
                  onClick={() => handleFormatChange(f)}
                >
                  {f.toUpperCase()}
                </button>
              ))}
            </div>
          </div>

          {/* Table / Schema name */}
          <div className="sg-row sg-row--inline">
            <div className="sg-field">
              <label className="sg-label" htmlFor="sg-table">Table name <span className="sg-required">*</span></label>
              <input
                id="sg-table"
                className="sg-input"
                value={tableName}
                onChange={e => setTable(e.target.value)}
                placeholder="my_table"
                spellCheck={false}
              />
            </div>
            <div className="sg-field">
              <label className="sg-label" htmlFor="sg-schema">Schema / dataset <span className="sg-optional">(optional)</span></label>
              <input
                id="sg-schema"
                className="sg-input"
                value={schemaName}
                onChange={e => setSchema(e.target.value)}
                placeholder="e.g. public, dbo, analytics"
                spellCheck={false}
              />
            </div>
          </div>

          {/* Data textarea */}
          <div className="sg-row sg-row--grow">
            <label className="sg-label">
              Sample data
              <span className="sg-label-hint">
                (first row = headers for CSV · object keys become columns for JSON ·
                up to 200 rows sampled)
              </span>
            </label>
            <textarea
              ref={textareaRef}
              className="sg-textarea"
              value={data}
              onChange={e => { setData(e.target.value); setError(null) }}
              spellCheck={false}
              placeholder={fmt === 'csv' ? SAMPLE_CSV : SAMPLE_JSON}
            />
          </div>

          {/* Type inference legend */}
          <div className="sg-legend">
            <span className="sg-legend-title">Auto-detected types:</span>
            {[
              ['INT64', 'whole numbers'],
              ['FLOAT64', 'decimals'],
              ['BOOLEAN', 'true/false · yes/no · 0/1'],
              ['DATE', 'YYYY-MM-DD'],
              ['TIMESTAMP', 'YYYY-MM-DD HH:MM:SS'],
              ['VARCHAR(n)', 'everything else'],
            ].map(([t, desc]) => (
              <span key={t} className="sg-legend-item">
                <code>{t}</code> {desc}
              </span>
            ))}
          </div>

          {/* Error */}
          {error && (
            <div className="sg-error">
              <span>⚠</span> {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="sg-footer">
          <button className="sg-btn-cancel" onClick={onClose} disabled={loading}>
            Cancel
          </button>
          <button
            className={`sg-btn-generate ${loading ? 'sg-btn-generate--loading' : ''}`}
            onClick={handleGenerate}
            disabled={loading || !data.trim() || !tableName.trim()}
          >
            {loading ? <span className="spinner-sm" /> : '⊕ Generate DDL'}
          </button>
        </div>
      </div>
    </div>
  )
}
