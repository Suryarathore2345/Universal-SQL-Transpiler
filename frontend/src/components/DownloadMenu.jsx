/**
 * Download dropdown for the target (output) pane.
 *
 * Always offers "Download All". When the last transpile result included
 * per-object breakdown (objects: [{object_type, name, sql}, ...]), also
 * offers one entry per object type present (Tables, Views, Materialized
 * Views, Procedures, Functions) — each downloads only the statements of
 * that type, concatenated.
 */
import { useEffect, useRef, useState } from 'react'
import { downloadText, slug } from '../utils/download.js'

const TYPE_LABELS = {
  table: 'Tables',
  view: 'Views',
  materialized_view: 'Materialized Views',
  procedure: 'Procedures',
  function: 'Functions',
}

export default function DownloadMenu({ allSql, objects = [], sourceDialect, targetDialect }) {
  const [open, setOpen] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    if (!open) return
    function onClickOutside(e) {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', onClickOutside)
    return () => document.removeEventListener('mousedown', onClickOutside)
  }, [open])

  if (!allSql) return null

  const baseName = `${slug(sourceDialect)}_to_${slug(targetDialect)}`

  // Group objects by type, preserving first-seen order
  const byType = []
  for (const obj of objects) {
    let bucket = byType.find(b => b.type === obj.object_type)
    if (!bucket) {
      bucket = { type: obj.object_type, items: [] }
      byType.push(bucket)
    }
    bucket.items.push(obj)
  }

  function handleDownloadAll() {
    downloadText(`${baseName}.sql`, allSql)
    setOpen(false)
  }

  function handleDownloadType(type, items) {
    const sql = items.map(o => o.sql).join('\n\n')
    const typeSlug = slug(TYPE_LABELS[type] ?? type)
    downloadText(`${baseName}__${typeSlug}.sql`, sql)
    setOpen(false)
  }

  return (
    <div className="download-menu" ref={ref}>
      <button className="btn-download" onClick={() => setOpen(o => !o)} title="Download converted SQL">
        ⭳ Download
      </button>
      {open && (
        <div className="download-dropdown">
          <button className="download-item" onClick={handleDownloadAll}>
            <span>All statements</span>
            <span className="download-item-count">{objects.length || ''}</span>
          </button>
          {byType.length > 0 && <div className="download-divider" />}
          {byType.map(({ type, items }) => (
            <button
              key={type}
              className="download-item"
              onClick={() => handleDownloadType(type, items)}
            >
              <span>{TYPE_LABELS[type] ?? type}</span>
              <span className="download-item-count">{items.length}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
