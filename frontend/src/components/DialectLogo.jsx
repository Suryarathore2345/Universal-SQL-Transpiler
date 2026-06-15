/**
 * DialectLogo — SVG brand logos for all 8 supported SQL platforms.
 * Each logo is drawn to brand spec colours at 40×40 viewBox.
 */

// ── Individual logo SVGs ──────────────────────────────────────────────────

function RedshiftLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="rs-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#FF9900"/>
          <stop offset="100%" stopColor="#FF6B35"/>
        </linearGradient>
      </defs>
      {/* AWS Redshift — stylised database cylinder */}
      <ellipse cx="20" cy="9" rx="14" ry="4.5" fill="url(#rs-grad)" opacity="0.9"/>
      <rect x="6" y="9" width="28" height="20" fill="url(#rs-grad)" opacity="0.75"/>
      <ellipse cx="20" cy="29" rx="14" ry="4.5" fill="#FF9900"/>
      {/* Horizontal band highlight */}
      <rect x="6" y="16" width="28" height="3.5" fill="#FFB84D" opacity="0.5"/>
      {/* RS mark */}
      <text x="20" y="24" textAnchor="middle" fontSize="9" fontWeight="700" fill="white" fontFamily="system-ui">RS</text>
    </svg>
  )
}

function SnowflakeLogo({ size = 36 }) {
  // Six-spoke snowflake — Snowflake Inc. brand blue
  const spoke = (angle) => {
    const rad = (angle * Math.PI) / 180
    const x1 = 20 + 6 * Math.cos(rad)
    const y1 = 20 + 6 * Math.sin(rad)
    const x2 = 20 + 15 * Math.cos(rad)
    const y2 = 20 + 15 * Math.sin(rad)
    // Small cross bars
    const bx1 = 20 + 11 * Math.cos(rad) - 3.5 * Math.sin(rad)
    const by1 = 20 + 11 * Math.sin(rad) + 3.5 * Math.cos(rad)
    const bx2 = 20 + 11 * Math.cos(rad) + 3.5 * Math.sin(rad)
    const by2 = 20 + 11 * Math.sin(rad) - 3.5 * Math.cos(rad)
    return { x1, y1, x2, y2, bx1, by1, bx2, by2 }
  }
  const spokes = [0, 60, 120, 180, 240, 300].map(spoke)
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="sf-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#29B5E8"/>
          <stop offset="100%" stopColor="#0099CC"/>
        </linearGradient>
      </defs>
      <circle cx="20" cy="20" r="19" fill="#0D1117" opacity="0"/>
      {spokes.map((s, i) => (
        <g key={i}>
          <line x1={s.x1} y1={s.y1} x2={s.x2} y2={s.y2} stroke="url(#sf-grad)" strokeWidth="2.5" strokeLinecap="round"/>
          <line x1={s.bx1} y1={s.by1} x2={s.bx2} y2={s.by2} stroke="url(#sf-grad)" strokeWidth="2" strokeLinecap="round"/>
        </g>
      ))}
      <circle cx="20" cy="20" r="3.5" fill="url(#sf-grad)"/>
    </svg>
  )
}

function SQLServerLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="sql-grad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#E8423F"/>
          <stop offset="100%" stopColor="#CC2927"/>
        </linearGradient>
      </defs>
      {/* Cylinder body */}
      <ellipse cx="20" cy="10" rx="14" ry="5" fill="url(#sql-grad)"/>
      <rect x="6" y="10" width="28" height="20" fill="url(#sql-grad)" opacity="0.8"/>
      <ellipse cx="20" cy="30" rx="14" ry="5" fill="#CC2927"/>
      {/* Highlight stripe */}
      <ellipse cx="20" cy="10" rx="14" ry="5" fill="none" stroke="#FF6B6B" strokeWidth="1" opacity="0.6"/>
      {/* SQL text */}
      <text x="20" y="24" textAnchor="middle" fontSize="8" fontWeight="800" fill="white" fontFamily="system-ui">SQL</text>
    </svg>
  )
}

function SynapseLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="syn-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#8764B8"/>
          <stop offset="100%" stopColor="#0078D4"/>
        </linearGradient>
        <linearGradient id="syn-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#1a1033"/>
          <stop offset="100%" stopColor="#001a3d"/>
        </linearGradient>
      </defs>
      <rect x="2" y="2" width="36" height="36" rx="8" fill="url(#syn-bg)"/>
      {/* Azure Synapse — lightning bolt */}
      <path
        d="M22 4 L10 22 L19 22 L18 36 L30 18 L21 18 Z"
        fill="url(#syn-grad)"
        opacity="0.95"
      />
    </svg>
  )
}

function FabricDWLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="fab-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#00D4A8"/>
          <stop offset="50%" stopColor="#00B294"/>
          <stop offset="100%" stopColor="#007A65"/>
        </linearGradient>
        <linearGradient id="fab-ribbon" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#33E8C8"/>
          <stop offset="100%" stopColor="#00B294"/>
        </linearGradient>
      </defs>
      {/* Microsoft Fabric — F ribbon shape (inspired by the official Fabric logo) */}
      {/* Outer ribbon fold — left side */}
      <path
        d="M8 4 C8 4 14 4 18 8 C22 12 20 20 16 24 C12 28 8 28 8 28 L8 20 C8 20 12 20 14 16 C16 12 14 8 8 8 Z"
        fill="url(#fab-grad)"
      />
      {/* Inner ribbon fold — right side */}
      <path
        d="M18 8 C22 4 30 4 32 8 C34 12 30 18 24 20 C20 21 16 24 16 24 C20 20 22 14 18 8 Z"
        fill="url(#fab-ribbon)"
        opacity="0.9"
      />
      {/* Bottom tail */}
      <path
        d="M8 28 C8 28 10 28 12 32 C14 36 12 38 10 36 C8 34 8 28 8 28 Z"
        fill="url(#fab-grad)"
        opacity="0.8"
      />
    </svg>
  )
}

function DatabricksLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="db-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#FF6B47"/>
          <stop offset="100%" stopColor="#FF3621"/>
        </linearGradient>
      </defs>
      {/* Databricks — stylised spark/delta shape */}
      {/* Lower left brick */}
      <path d="M4 28 L20 20 L20 28 L4 36 Z" fill="url(#db-grad)" opacity="0.7"/>
      {/* Upper middle */}
      <path d="M4 12 L20 4 L36 12 L20 20 Z" fill="url(#db-grad)"/>
      {/* Lower right brick */}
      <path d="M36 28 L20 20 L20 28 L36 36 Z" fill="url(#db-grad)" opacity="0.85"/>
      {/* Top spark highlight */}
      <path d="M20 4 L36 12 L20 20 L4 12 Z" fill="#FF8A6E" opacity="0.4"/>
    </svg>
  )
}

function OracleLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="ora-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#F80000"/>
          <stop offset="100%" stopColor="#CC0000"/>
        </linearGradient>
      </defs>
      {/* Oracle — "O" pill shape (their iconic ellipse logo) */}
      <rect x="4" y="12" width="32" height="16" rx="8" fill="url(#ora-grad)"/>
      {/* Inner cutout */}
      <rect x="11" y="15" width="18" height="10" rx="5" fill="#0d1117"/>
      {/* Subtle highlight */}
      <rect x="4" y="12" width="32" height="6" rx="8" fill="#FF4444" opacity="0.3"/>
    </svg>
  )
}

function BigQueryLogo({ size = 36 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      <defs>
        <linearGradient id="bq-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#4285F4"/>
          <stop offset="100%" stopColor="#1A73E8"/>
        </linearGradient>
      </defs>
      {/* BigQuery — magnifier over colorful data bars */}
      {/* Data bars (Google colors) */}
      <rect x="5"  y="22" width="5" height="13" rx="1.5" fill="#EA4335" opacity="0.9"/>
      <rect x="12" y="16" width="5" height="19" rx="1.5" fill="#FBBC04" opacity="0.9"/>
      <rect x="19" y="18" width="5" height="17" rx="1.5" fill="#34A853" opacity="0.9"/>
      {/* Magnifier circle */}
      <circle cx="28" cy="14" r="8" fill="none" stroke="url(#bq-grad)" strokeWidth="3"/>
      <circle cx="28" cy="14" r="4" fill="url(#bq-grad)" opacity="0.25"/>
      {/* Handle */}
      <line x1="33.5" y1="19.5" x2="38" y2="24" stroke="url(#bq-grad)" strokeWidth="3" strokeLinecap="round"/>
    </svg>
  )
}

// ── Public API ─────────────────────────────────────────────────────────────

const LOGO_MAP = {
  redshift:   RedshiftLogo,
  snowflake:  SnowflakeLogo,
  sqlserver:  SQLServerLogo,
  synapse:    SynapseLogo,
  fabric_dw:  FabricDWLogo,
  databricks: DatabricksLogo,
  oracle:     OracleLogo,
  bigquery:   BigQueryLogo,
}

export default function DialectLogo({ dialectKey, size = 36 }) {
  const Logo = LOGO_MAP[dialectKey]
  if (!Logo) {
    return (
      <svg width={size} height={size} viewBox="0 0 40 40">
        <rect x="4" y="4" width="32" height="32" rx="6" fill="#30363d"/>
        <text x="20" y="26" textAnchor="middle" fontSize="14" fill="#8b949e" fontFamily="system-ui">DB</text>
      </svg>
    )
  }
  return <Logo size={size} />
}
