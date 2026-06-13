/**
 * DialectSelector — dropdown to pick a SQL platform.
 * Shows a vendor emoji + display name for each dialect.
 */

const DIALECT_ICONS = {
  redshift:    '🔴',
  snowflake:   '❄️',
  sqlserver:   '🪟',
  synapse:     '⚡',
  fabric_dw:   '🧵',
  databricks:  '🔷',
  oracle:      '🔶',
  bigquery:    '🔵',
}

export default function DialectSelector({ label, value, dialects, onChange, disabled }) {
  return (
    <div className="dialect-selector">
      <label className="dialect-label">{label}</label>
      <div className="dialect-select-wrap">
        <select
          className="dialect-select"
          value={value}
          onChange={e => onChange(e.target.value)}
          disabled={disabled}
        >
          {dialects.map(d => (
            <option key={d.key} value={d.key}>
              {DIALECT_ICONS[d.key] ?? '🗄️'}  {d.display_name}
            </option>
          ))}
        </select>
      </div>
    </div>
  )
}
