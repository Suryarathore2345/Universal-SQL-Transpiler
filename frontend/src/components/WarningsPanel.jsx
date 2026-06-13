/**
 * WarningsPanel — shows transpilation warnings and unsupported-feature alerts.
 */
import { useState } from 'react'

const SEVERITY_META = {
  error:   { label: 'Error',   cls: 'sev-error'   },
  warning: { label: 'Warning', cls: 'sev-warning'  },
  info:    { label: 'Info',    cls: 'sev-info'     },
}

function WarningItem({ w, kind }) {
  const meta = SEVERITY_META[w.severity?.toLowerCase()] ?? SEVERITY_META.warning
  return (
    <div className={`warning-item ${meta.cls} ${kind === 'unsupported' ? 'unsupported' : ''}`}>
      <div className="warning-header">
        <span className={`badge ${meta.cls}`}>{meta.label}</span>
        {kind === 'unsupported' && <span className="badge badge-unsupported">Unsupported</span>}
        <code className="warning-feature">{w.feature}</code>
      </div>
      <p className="warning-message">{w.message}</p>
      {w.doc_url && (
        <a
          className="warning-doc-link"
          href={w.doc_url}
          target="_blank"
          rel="noopener noreferrer"
        >
          Official docs ↗
        </a>
      )}
    </div>
  )
}

export default function WarningsPanel({ warnings = [], unsupported = [] }) {
  const [open, setOpen] = useState(true)
  const total = warnings.length + unsupported.length
  if (total === 0) return null

  return (
    <section className="warnings-panel">
      <button className="panel-toggle" onClick={() => setOpen(o => !o)}>
        <span className="panel-title">
          {unsupported.length > 0 && <span className="dot dot-red" />}
          {warnings.length > 0 && unsupported.length === 0 && <span className="dot dot-yellow" />}
          Notices
          <span className="count-badge">{total}</span>
        </span>
        <span className="chevron">{open ? '▾' : '▸'}</span>
      </button>

      {open && (
        <div className="panel-body">
          {unsupported.map((u, i) => (
            <WarningItem key={`u-${i}`} w={u} kind="unsupported" />
          ))}
          {warnings.map((w, i) => (
            <WarningItem key={`w-${i}`} w={w} kind="warning" />
          ))}
        </div>
      )}
    </section>
  )
}
