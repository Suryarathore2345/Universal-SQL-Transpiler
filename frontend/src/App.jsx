/**
 * Universal SQL Transpiler — main application component.
 *
 * Layout:
 *   Header (gradient logo + subtitle)
 *   ┌─────────────────────────────────────────────┐
 *   │  DialectSelector  [↔ Swap]  DialectSelector  │
 *   ├──────────────┬──────────────────────────────┤
 *   │  Source SQL  │      Target SQL (read-only)  │
 *   │  (Monaco)    │      (Monaco)                │
 *   └──────────────┴──────────────────────────────┘
 *   [Transpile] button
 *   WarningsPanel
 *   DocRefsPanel
 */
import { useEffect, useState, useCallback } from 'react'
import SqlEditor from './components/SqlEditor.jsx'
import DialectSelector from './components/DialectSelector.jsx'
import WarningsPanel from './components/WarningsPanel.jsx'
import DocRefsPanel from './components/DocRefsPanel.jsx'
import LimitationsPanel from './components/LimitationsPanel.jsx'
import { fetchDialects, fetchLimitations, transpile } from './api/transpiler.js'

const DEFAULT_SQL = `-- Paste your SQL DDL here
CREATE TABLE public.orders (
    order_id    BIGINT          NOT NULL,
    customer_id INTEGER         NOT NULL,
    amount      DECIMAL(18, 2)  NOT NULL,
    status      VARCHAR(32)     DEFAULT 'pending',
    created_at  TIMESTAMP       NOT NULL,
    PRIMARY KEY (order_id)
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (created_at);
`

export default function App() {
  const [dialects, setDialects]       = useState([])
  const [sourceDialect, setSrc]       = useState('redshift')
  const [targetDialect, setTgt]       = useState('snowflake')
  const [sourceSql, setSourceSql]     = useState(DEFAULT_SQL)
  const [targetSql, setTargetSql]     = useState('')
  const [warnings, setWarnings]       = useState([])
  const [unsupported, setUnsupported] = useState([])
  const [docRefs, setDocRefs]         = useState([])
  const [loading, setLoading]         = useState(false)
  const [error, setError]             = useState(null)
  const [copied, setCopied]           = useState(false)
  const [limitations, setLimitations] = useState([])

  // Load dialect list on mount
  useEffect(() => {
    fetchDialects()
      .then(setDialects)
      .catch(err => setError(`Could not load dialects: ${err.message}`))
  }, [])

  // Reload limitations whenever target dialect changes
  useEffect(() => {
    if (!targetDialect) return
    fetchLimitations(targetDialect)
      .then(dl => setLimitations(dl[0]?.limitations ?? []))
      .catch(() => setLimitations([]))
  }, [targetDialect])

  const handleSwap = useCallback(() => {
    setSrc(targetDialect)
    setTgt(sourceDialect)
    setSourceSql(targetSql || sourceSql)
    setTargetSql('')
    setWarnings([])
    setUnsupported([])
    setDocRefs([])
    setError(null)
  }, [sourceDialect, targetDialect, sourceSql, targetSql])

  const handleTranspile = useCallback(async () => {
    if (!sourceSql.trim()) return
    setLoading(true)
    setError(null)
    setTargetSql('')
    setWarnings([])
    setUnsupported([])
    setDocRefs([])

    try {
      const result = await transpile({
        sql: sourceSql,
        sourceDialect,
        targetDialect,
      })
      setTargetSql(result.converted_sql)
      setWarnings(result.warnings ?? [])
      setUnsupported(result.unsupported_features ?? [])
      setDocRefs(result.doc_references ?? [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [sourceSql, sourceDialect, targetDialect])

  // Keyboard shortcut: Ctrl+Enter / Cmd+Enter
  useEffect(() => {
    function onKey(e) {
      if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        e.preventDefault()
        handleTranspile()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [handleTranspile])

  async function handleCopy() {
    if (!targetSql) return
    await navigator.clipboard.writeText(targetSql)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const srcDialect = dialects.find(d => d.key === sourceDialect)
  const tgtDialect = dialects.find(d => d.key === targetDialect)

  return (
    <div className="app">
      {/* ── Header ── */}
      <header className="app-header">
        <div className="header-inner">
          <div className="logo-wrap">
            <span className="logo-icon">⟨⟩</span>
            <div>
              <h1 className="logo-title">Universal SQL Transpiler</h1>
              <p className="logo-sub">
                Convert DDL between Redshift · Snowflake · SQL Server · Synapse ·
                Fabric DW · Databricks · Oracle · BigQuery
              </p>
            </div>
          </div>
          <a
            className="header-badge"
            href="/api/docs"
            target="_blank"
            rel="noopener noreferrer"
          >
            API docs ↗
          </a>
        </div>
      </header>

      <main className="app-main">
        {/* ── Dialect row ── */}
        <div className="dialect-row">
          {dialects.length > 0 ? (
            <>
              <DialectSelector
                label="Source dialect"
                value={sourceDialect}
                dialects={dialects}
                onChange={v => { setSrc(v); setTargetSql(''); setError(null) }}
                disabled={loading}
              />

              <div className="swap-col">
                <button
                  className="btn-swap"
                  onClick={handleSwap}
                  disabled={loading}
                  title="Swap source and target"
                >
                  ⇄
                </button>
              </div>

              <DialectSelector
                label="Target dialect"
                value={targetDialect}
                dialects={dialects}
                onChange={v => { setTgt(v); setTargetSql(''); setError(null) }}
                disabled={loading}
              />
            </>
          ) : (
            <div className="loading-dialects">Loading dialects…</div>
          )}
        </div>

        {/* ── Editors ── */}
        <div className="editors-row">
          {/* Source */}
          <div className="editor-pane">
            <div className="pane-header">
              <span className="pane-label">
                {srcDialect?.display_name ?? sourceDialect}
              </span>
              <span className="pane-hint">source</span>
            </div>
            <SqlEditor
              value={sourceSql}
              onChange={setSourceSql}
              readOnly={false}
            />
          </div>

          {/* Divider + Transpile button */}
          <div className="center-col">
            <button
              className={`btn-transpile ${loading ? 'btn-transpile--loading' : ''}`}
              onClick={handleTranspile}
              disabled={loading || !sourceSql.trim() || dialects.length === 0}
              title="Transpile (Ctrl+Enter)"
            >
              {loading ? (
                <span className="spinner-sm" />
              ) : (
                <>
                  <span className="btn-arrow">→</span>
                  <span className="btn-label">Transpile</span>
                </>
              )}
            </button>
          </div>

          {/* Target */}
          <div className="editor-pane">
            <div className="pane-header">
              <span className="pane-label">
                {tgtDialect?.display_name ?? targetDialect}
              </span>
              <span className="pane-hint">output</span>
              {targetSql && (
                <button className="btn-copy" onClick={handleCopy}>
                  {copied ? '✓ Copied' : 'Copy'}
                </button>
              )}
            </div>
            <SqlEditor
              value={targetSql}
              readOnly
              loading={loading}
              placeholder="Output will appear here…"
            />
          </div>
        </div>

        {/* ── Error banner ── */}
        {error && (
          <div className="error-banner" role="alert">
            <span className="error-icon">⚠</span>
            <span>{error}</span>
            <button className="error-dismiss" onClick={() => setError(null)}>✕</button>
          </div>
        )}

        {/* ── Notices ── */}
        <div className="panels-row">
          <WarningsPanel warnings={warnings} unsupported={unsupported} />
          <DocRefsPanel refs={docRefs} />
          <LimitationsPanel
            limitations={limitations}
            dialectName={tgtDialect?.short_name ?? targetDialect}
          />
        </div>
      </main>

      <footer className="app-footer">
        <span>Universal SQL Transpiler · v1.0</span>
        <span className="footer-sep">·</span>
        <a href="/api/health" target="_blank" rel="noopener noreferrer">API health</a>
        <span className="footer-sep">·</span>
        <a href="/api/docs" target="_blank" rel="noopener noreferrer">OpenAPI</a>
      </footer>
    </div>
  )
}
