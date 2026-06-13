/**
 * LimitationsPanel — shows known transpilation limitations for the selected
 * target dialect.  Collapsible, same visual style as WarningsPanel.
 */
import { useState } from 'react'

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

export default function LimitationsPanel({ limitations = [], dialectName = '' }) {
  const [open, setOpen] = useState(false)

  if (limitations.length === 0) return null

  const errorCount = limitations.filter(l => l.level === 'error').length
  const warnCount  = limitations.filter(l => l.level === 'warn').length

  const badge = errorCount > 0
    ? { color: LEVEL_COLOR.error, text: `${errorCount} error${errorCount > 1 ? 's' : ''}` }
    : warnCount > 0
      ? { color: LEVEL_COLOR.warn,  text: `${warnCount} warn${warnCount > 1 ? 's' : ''}` }
      : { color: LEVEL_COLOR.info,  text: `${limitations.length} notes` }

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
          {limitations.map(lim => (
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
