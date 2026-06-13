/**
 * DocRefsPanel — lists the official documentation pages consulted
 * during transpilation, grouped by platform.
 */
import { useState } from 'react'

const PLATFORM_ICONS = {
  redshift:    '🔴',
  snowflake:   '❄️',
  sqlserver:   '🪟',
  synapse:     '⚡',
  fabric_dw:   '🧵',
  databricks:  '🔷',
  oracle:      '🔶',
  bigquery:    '🔵',
}

export default function DocRefsPanel({ refs = [] }) {
  const [open, setOpen] = useState(false)
  if (refs.length === 0) return null

  // Group by platform
  const grouped = {}
  for (const r of refs) {
    if (!grouped[r.platform]) grouped[r.platform] = []
    grouped[r.platform].push(r)
  }

  return (
    <section className="doc-refs-panel">
      <button className="panel-toggle" onClick={() => setOpen(o => !o)}>
        <span className="panel-title">
          <span className="doc-icon">📚</span>
          Official docs consulted
          <span className="count-badge">{refs.length}</span>
        </span>
        <span className="chevron">{open ? '▾' : '▸'}</span>
      </button>

      {open && (
        <div className="panel-body doc-refs-body">
          {Object.entries(grouped).map(([platform, items]) => (
            <div key={platform} className="doc-group">
              <h4 className="doc-group-title">
                {PLATFORM_ICONS[platform] ?? '🗄️'} {platform}
              </h4>
              <ul className="doc-list">
                {items.map((r, i) => (
                  <li key={i} className="doc-item">
                    <a href={r.url} target="_blank" rel="noopener noreferrer" className="doc-link">
                      {r.title}
                    </a>
                    {r.purpose && <span className="doc-purpose"> — {r.purpose}</span>}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}
