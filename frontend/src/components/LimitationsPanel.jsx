/**
 * LimitationsPanel — shows known transpilation limitations for the selected
 * target dialect, filtered to only what's relevant to the current source SQL.
 *
 * Two-level filtering:
 *  1. Backend already removed entries irrelevant to the source *dialect*
 *     (e.g. DISTKEY_REMOVED is gone when source ≠ Redshift).
 *  2. Here we additionally hide entries whose sql_keywords are present in the
 *     registry but NOT in the user's actual source SQL
 *     (e.g. PROCEDURE_BODY_MANUAL only shows when SQL contains "PROCEDURE").
 */
import { useState, useMemo } from 'react'

const LEVEL_COLOR = {
  error: 'var(--accent-red)',
  warn:  'var(--accent-yellow)',
  info:  'var(--accent-blue)',
}

const LEVEL_LABEL = {
  error: 'ERROR',
  warn:  'WARN',
  info:  'INFO',
}

/**
 * Given a limitation entry and the uppercased source SQL, decide whether to show it.
 * Rule: if sql_keywords is non-empty, at least one keyword must appear in the SQL.
 *       If sql_keywords is empty / absent, always show (backend already filtered by source dialect).
 */
function isRelevant(lim, sqlUpper) {
  if (!lim.sql_keywords || lim.sql_keywords.length === 0) return true
  return lim.sql_keywords.some(kw => sqlUpper.includes(kw.toUpperCase()))
}

export default function LimitationsPanel({ limitations = [], dialectName = '', sourceSql = '' }) {
  const [open, setOpen] = useState(false)

  // Compute once per SQL change — uppercased for case-insensitive keyword matching
  const sqlUpper = useMemo(() => sourceSql.toUpperCase(), [sourceSql])

  // Filter to only relevant limitations
  const visible = useMemo(
    () => limitations.filter(lim => isRelevant(lim, sqlUpper)),
    [limitations, sqlUpper],
  )

  if (visible.length === 0) return null

  const errorCount = visible.filter(l => l.level === 'error').length
  const warnCount  = visible.filter(l => l.level === 'warn').length

  const badge = errorCount > 0
    ? { color: LEVEL_COLOR.error, text: `${errorCount} error${errorCount > 1 ? 's' : ''}` }
    : warnCount > 0
      ? { color: LEVEL_COLOR.warn,  text: `${warnCount} warn${warnCount > 1 ? 's' : ''}` }
      : { color: LEVEL_COLOR.info,  text: `${visible.length} notes` }

  return (
    <div className="lim-panel">
      <button
        className="panel-toggle"
        onClick={() => setOpen(o => !o)}
        aria-expanded={open}
      >
        <span className="panel-dot" style={{ background: badge.color }} />
        <span className="panel-title">
          {dialectName ? `${dialectName} limitations` : 'Target limitations'}
        </span>
        <span className="panel-count" style={{ color: badge.color }}>
          {badge.text}
        </span>
        <span className="panel-chevron">{open ? '▲' : '▼'}</span>
      </button>

      {open && (
        <ul className="lim-list">
          {visible.map(lim => (
            <li key={lim.feature} className="lim-item">
              <span
                className="lim-badge"
                style={{ background: `${LEVEL_COLOR[lim.level]}22`, color: LEVEL_COLOR[lim.level] }}
              >
                {LEVEL_LABEL[lim.level] ?? lim.level.toUpperCase()}
              </span>
              <span className="lim-feature">{lim.feature}</span>
              <p className="lim-desc">{lim.description}</p>
              {lim.doc_url && (
                <a
                  className="lim-doc"
                  href={lim.doc_url}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Official docs ↗
                </a>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
