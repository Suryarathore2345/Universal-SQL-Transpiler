/**
 * ColumnLengthsPanel — shown only when the "customize string lengths" toggle
 * is on AND the last transpile response returned length_decisions (i.e. the
 * source had one or more unbounded-string columns, like Databricks STRING,
 * going to a target that needs a bounded VARCHAR-family length).
 *
 * Renders one row per decision with an editable length input, plus a bulk
 * "apply to all" convenience field. Edits are held in `overrides` (owned by
 * App.jsx) and sent back as column_overrides on the next Transpile click.
 */
import { useState } from 'react'

export default function ColumnLengthsPanel({ decisions = [], overrides, onChange }) {
  const [bulkValue, setBulkValue] = useState('')

  if (decisions.length === 0) return null

  const keyFor = (d) => `${d.table}::${d.column}`

  function setOne(d, value) {
    const n = value === '' ? null : Number(value)
    onChange({ ...overrides, [keyFor(d)]: n })
  }

  function applyToAll() {
    const n = Number(bulkValue)
    if (!bulkValue || Number.isNaN(n)) return
    const next = { ...overrides }
    for (const d of decisions) next[keyFor(d)] = n
    onChange(next)
  }

  return (
    <section className="length-decisions-panel">
      <div className="panel-title-row">
        <span className="panel-title">
          Column lengths need review
          <span className="count-badge">{decisions.length}</span>
        </span>
        <div className="length-bulk-row">
          <input
            type="number"
            min={1}
            className="length-input length-input-bulk"
            placeholder="Set all to…"
            value={bulkValue}
            onChange={e => setBulkValue(e.target.value)}
          />
          <button className="btn-length-apply-all" onClick={applyToAll} disabled={!bulkValue}>
            Apply to all
          </button>
        </div>
      </div>

      <div className="panel-body">
        {decisions.map((d) => {
          const key = keyFor(d)
          const current = overrides[key] ?? ''
          return (
            <div className="length-decision-row" key={key}>
              <div className="length-decision-label">
                <code>{d.table}.{d.column}</code>
                <span className="length-decision-source">{d.source_type} → VARCHAR</span>
              </div>
              <input
                type="number"
                min={d.min_length}
                max={d.max_length}
                className="length-input"
                placeholder={String(d.applied_default)}
                value={current}
                onChange={e => setOne(d, e.target.value)}
              />
              <span className="length-decision-range">max {d.max_length}</span>
            </div>
          )
        })}
      </div>
    </section>
  )
}
