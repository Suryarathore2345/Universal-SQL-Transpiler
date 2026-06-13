/**
 * ConfidenceBadge — displays a colour-coded score pill next to the
 * Transpile button after a successful conversion.
 *
 * Levels:
 *   HIGH          (score ≥ 0.85) — green
 *   PARTIAL       (score ≥ 0.65) — yellow
 *   MANUAL_REVIEW (score < 0.65) — red
 */

const LEVEL_META = {
  HIGH: {
    label: 'HIGH',
    icon: '✓',
    cls: 'badge--high',
    tip: 'Clean conversion — no warnings or unsupported features detected.',
  },
  PARTIAL: {
    label: 'PARTIAL',
    icon: '⚠',
    cls: 'badge--partial',
    tip: 'Conversion succeeded with warnings. Review the Warnings panel.',
  },
  MANUAL_REVIEW: {
    label: 'REVIEW',
    icon: '✕',
    cls: 'badge--review',
    tip: 'Unsupported features detected. Manual review required before deploying.',
  },
}

export default function ConfidenceBadge({ score, level, onClick }) {
  if (score === null || score === undefined) return null

  const meta = LEVEL_META[level] ?? LEVEL_META.PARTIAL
  const pct = Math.round(score * 100)

  return (
    <button
      className={`confidence-badge ${meta.cls}`}
      title={meta.tip}
      onClick={onClick}
      aria-label={`Confidence: ${pct}% — ${meta.label}. Click for full report.`}
    >
      <span className="badge-icon">{meta.icon}</span>
      <span className="badge-pct">{pct}%</span>
      <span className="badge-label">{meta.label}</span>
      <span className="badge-report-hint">↗ Report</span>
    </button>
  )
}
