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
import ConfidenceBadge from './components/ConfidenceBadge.jsx'
import ReportDashboard from './components/ReportDashboard.jsx'
import { fetchDialects, fetchLimitations, transpile } from './api/transpiler.js'
import { DIALECT_COLORS, DIALECT_SAMPLES } from './data/dialectMeta.js'

export default function App() {
  const [dialects, setDialects]       = useState([])
  const [sourceDialect, setSrc]       = useState('redshift')
  const [targetDialect, setTgt]       = useState('snowflake')
  const [sourceSql, setSourceSql]     = useState(DIALECT_SAMPLES['redshift'] ?? '')
  const [targetSql, setTargetSql]     = useState('')
  const [warnings, setWarnings]       = useState([])
  const [unsupported, setUnsupported] = useState([])
  const [docRefs, setDocRefs]         = useState([])
  const [loading, setLoading]         = useState(false)
  const [error, setError]             = useState(null)
  const [copied, setCopied]           = useState(false)
  const [limitations, setLimitations] = useState([])

  // Phase 8 — confidence + report
  const [confidenceScore, setConfidenceScore] = useState(null)
  const [confidenceLevel, setConfidenceLevel] = useState(null)
  const [lastResult, setLastResult]           = useState(null)
  const [showReport, setShowReport]           = useState(false)

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

  // When source dialect changes, update sample SQL to match that dialect's syntax
  const handleSourceChange = useCallback((newKey) => {
    setSrc(newKey)
    setTargetSql('')
    setError(null)
    setConfidenceScore(null)
    setConfidenceLevel(null)
    setLastResult(null)
    // Only replace if user hasn't modified the default (check against all samples)
    const allSamples = Object.values(DIALECT_SAMPLES)
    const isUsingDefault = allSamples.some(s => sourceSql.trim() === s.trim())
    if (isUsingDefault) {
      setSourceSql(DIALECT_SAMPLES[newKey] ?? '')
    }
  }, [sourceSql])

  const handleSwap = useCallback(() => {
    setSrc(targetDialect)
    setTgt(sourceDialect)
    const swappedSql = targetSql || DIALECT_SAMPLES[targetDialect] || sourceSql
    setSourceSql(swappedSql)
    setTargetSql('')
    setWarnings([])
    setUnsupported([])
    setDocRefs([])
    setError(null)
    setConfidenceScore(null)
    setConfidenceLevel(null)
    setLastResult(null)
  }, [sourceDialect, targetDialect, sourceSql, targetSql])

  const handleTranspile = useCallback(async () => {
    if (!sourceSql.trim()) return
    setLoading(true)
    setError(null)
    setTargetSql('')
    setWarnings([])
    setUnsupported([])
    setDocRefs([])
    setConfidenceScore(null)
    setConfidenceLevel(null)
    setLastResult(null)

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
      setConfidenceScore(result.confidence_score ?? null)
      setConfidenceLevel(result.confidence_level ?? null)
      setLastResult(result)
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

  // Dynamic background: ambient glow from source (left) and target (right) brand colors
  const srcColor = DIALECT_COLORS[sourceDialect]?.primary ?? '#7c3aed'
  const tgtColor = DIALECT_COLORS[targetDialect]?.primary ?? '#2563eb'
  const appStyle = {
    '--src-color': srcColor,
    '--tgt-color': tgtColor,
    '--src-glow':  DIALECT_COLORS[sourceDialect]?.glow ?? 'rgba(124,58,237,0.1)',
    '--tgt-glow':  DIALECT_COLORS[targetDialect]?.glow ?? 'rgba(37,99,235,0.1)',
  }

  return (
    <div className="app" style={appStyle}>
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
                onChange={handleSourceChange}
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
                onChange={v => { setTgt(v); setTargetSql(''); setError(null); setConfidenceScore(null); setLastResult(null) }}
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

        {/* ── Confidence bar (appears after first transpile) ── */}
        {confidenceScore !== null && !loading && (
          <div className="confidence-bar">
            <span className="confidence-bar-label">Conversion quality</span>
            <ConfidenceBadge
              score={confidenceScore}
              level={confidenceLevel}
              onClick={() => setShowReport(true)}
            />
            <span className="confidence-bar-hint">Click the badge to open the full report</span>
          </div>
        )}

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
        {lastResult && (
          <>
            <span className="footer-sep">·</span>
            <button className="footer-report-btn" onClick={() => setShowReport(true)}>
              View Report
            </button>
          </>
        )}
      </footer>

      {/* ── Report Dashboard modal ── */}
      {showReport && lastResult && (
        <ReportDashboard
          result={lastResult}
          sourceDialect={dialects.find(d => d.key === sourceDialect)}
          targetDialect={dialects.find(d => d.key === targetDialect)}
          onClose={() => setShowReport(false)}
        />
      )}
    </div>
  )
}
