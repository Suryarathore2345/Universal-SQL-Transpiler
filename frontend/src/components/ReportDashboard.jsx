/**
 * ReportDashboard — full-screen animated overlay that shows a
 * "mind-bending" conversion report with:
 *
 *   ① Confidence gauge (arc/dial SVG)
 *   ② Score breakdown bar chart (warnings / residuals / unsupported / docs)
 *   ③ Timeline strip (parse → generate → validate → score)
 *   ④ Dialect conversion path with animated arrow
 *   ⑤ Detailed tables for warnings, residuals, unsupported features, doc refs
 *
 * Props:
 *   result       — the full TranspileResponse object from the API
 *   sourceDialect — { key, display_name, short_name }
 *   targetDialect — { key, display_name, short_name }
 *   onClose      — () => void
 */
import { useEffect, useRef, useState } from 'react'

// ── Confidence gauge ───────────────────────────────────────────────────────

function ConfidenceGauge({ score, level }) {
  // Semicircle arc:  M (cx-r, cy) A r r 0 0 1 (cx+r, cy)
  // sweep=1 → clockwise → arc curves ABOVE cy (through apex at cy-r)
  // Parametric point at fraction t:  angle = π*(1-t) from the positive x-axis
  //   x = cx + r·cos(π(1-t))
  //   y = cy - r·sin(π(1-t))   (subtract because SVG y increases downward)
  const r  = 56
  const cx = 80
  const cy = 78   // pushed up so score text clears the arc bottom
  const strokeW  = 10
  const circumference = Math.PI * r

  const COLOR = {
    HIGH:          '#34d399',
    PARTIAL:       '#fbbf24',
    MANUAL_REVIEW: '#f87171',
  }
  const color = COLOR[level] ?? '#60a5fa'

  const [animScore, setAnimScore] = useState(0)
  useEffect(() => {
    let raf
    const start = performance.now()
    const dur = 900
    function tick(now) {
      const t = Math.min((now - start) / dur, 1)
      const ease = 1 - Math.pow(1 - t, 3)
      setAnimScore(ease * score)
      if (t < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [score])

  const animFilled = circumference * animScore
  const dashArr    = `${animFilled} ${circumference}`
  const pct        = Math.round(animScore * 100)

  // Glow-dot position follows the arc exactly
  const dotAngle = Math.PI * (1 - animScore)   // π at score=0 → 0 at score=1
  const dotX = cx + r * Math.cos(dotAngle)
  const dotY = cy - r * Math.sin(dotAngle)

  // Track goes full 180°; background track uses full circumference
  const trackArr = `${circumference} ${circumference}`

  return (
    <div className="rpt-gauge-wrap">
      <svg viewBox="0 0 160 110" className="rpt-gauge-svg">
        {/* Background track */}
        <path
          d={`M ${cx - r} ${cy} A ${r} ${r} 0 0 1 ${cx + r} ${cy}`}
          fill="none"
          stroke="var(--bg-base)"
          strokeWidth={strokeW}
          strokeLinecap="round"
          strokeDasharray={trackArr}
        />
        {/* Coloured fill */}
        <path
          d={`M ${cx - r} ${cy} A ${r} ${r} 0 0 1 ${cx + r} ${cy}`}
          fill="none"
          stroke={color}
          strokeWidth={strokeW}
          strokeLinecap="round"
          strokeDasharray={dashArr}
          style={{ filter: `drop-shadow(0 0 5px ${color}88)` }}
        />
        {/* Glow dot — follows arc path correctly */}
        {animScore > 0.01 && (
          <circle
            cx={dotX}
            cy={dotY}
            r={strokeW / 2 + 1}
            fill={color}
            style={{ filter: `drop-shadow(0 0 7px ${color})`, opacity: 0.9 }}
          />
        )}
        {/* Score % — centred in the arc */}
        <text x={cx} y={cy + 4} textAnchor="middle" className="gauge-pct-text">
          {pct}%
        </text>
        {/* Level label — below the arc baseline, never overlaps */}
        <text
          x={cx} y={cy + 22}
          textAnchor="middle"
          className="gauge-level-text"
          style={{ fill: color }}
        >
          {level.replace(/_/g, ' ')}
        </text>
      </svg>
    </div>
  )
}

// ── Animated count-up number ───────────────────────────────────────────────

function CountUp({ value, dur = 700 }) {
  const [v, setV] = useState(0)
  useEffect(() => {
    let raf
    const start = performance.now()
    function tick(now) {
      const t = Math.min((now - start) / dur, 1)
      setV(Math.round(t * value))
      if (t < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [value, dur])
  return <>{v}</>
}

// ── Bar item ───────────────────────────────────────────────────────────────

function ScoreBar({ label, value, max, color, icon }) {
  const pct = max > 0 ? (value / max) * 100 : 0
  const [width, setWidth] = useState(0)
  useEffect(() => {
    const t = setTimeout(() => setWidth(pct), 80)
    return () => clearTimeout(t)
  }, [pct])

  return (
    <div className="rpt-bar-row">
      <span className="rpt-bar-icon">{icon}</span>
      <span className="rpt-bar-label">{label}</span>
      <div className="rpt-bar-track">
        <div
          className="rpt-bar-fill"
          style={{ width: `${width}%`, background: color }}
        />
      </div>
      <span className="rpt-bar-val" style={{ color }}><CountUp value={value} /></span>
    </div>
  )
}

// ── Timeline step ──────────────────────────────────────────────────────────

function TimelineStep({ icon, label, done, active, delay }) {
  const [visible, setVisible] = useState(false)
  useEffect(() => {
    const t = setTimeout(() => setVisible(true), delay)
    return () => clearTimeout(t)
  }, [delay])

  return (
    <div className={`tl-step ${visible ? 'tl-step--in' : ''} ${done ? 'tl-step--done' : ''}`}>
      <div className={`tl-dot ${done ? 'tl-dot--done' : active ? 'tl-dot--active' : ''}`}>
        {done ? '✓' : icon}
      </div>
      <span className="tl-label">{label}</span>
    </div>
  )
}

// ── Section header ─────────────────────────────────────────────────────────

function Section({ title, count, color, children, startOpen = false }) {
  const [open, setOpen] = useState(startOpen)
  return (
    <div className="rpt-section">
      <button className="rpt-section-hdr" onClick={() => setOpen(o => !o)}>
        <span className="rpt-section-title">{title}</span>
        {count !== undefined && (
          <span className="rpt-section-count" style={{ color }}>{count}</span>
        )}
        <span className="rpt-section-chevron">{open ? '▲' : '▼'}</span>
      </button>
      {open && <div className="rpt-section-body">{children}</div>}
    </div>
  )
}

// ── Warning/residual row ───────────────────────────────────────────────────

function IssueRow({ item, severity }) {
  const SEV_COLOR = { error: 'var(--accent-red)', warning: 'var(--accent-yellow)', info: 'var(--accent-blue)' }
  const sev = item.severity ?? severity ?? 'warning'
  return (
    <div className="rpt-issue-row">
      <span className="rpt-issue-sev" style={{ color: SEV_COLOR[sev] ?? 'var(--accent-yellow)' }}>
        {sev.toUpperCase()}
      </span>
      <div className="rpt-issue-body">
        <code className="rpt-issue-feature">{item.feature}</code>
        <p className="rpt-issue-msg">{item.message}</p>
        {item.doc_url && (
          <a href={item.doc_url} target="_blank" rel="noopener noreferrer" className="rpt-issue-link">
            Official docs ↗
          </a>
        )}
      </div>
    </div>
  )
}

// ── Main component ─────────────────────────────────────────────────────────

export default function ReportDashboard({ result, sourceDialect, targetDialect, onClose }) {
  const overlayRef = useRef(null)

  // Close on Escape
  useEffect(() => {
    function onKey(e) { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  // Close on backdrop click
  function handleOverlayClick(e) {
    if (e.target === overlayRef.current) onClose()
  }

  const {
    confidence_score = 1,
    confidence_level = 'HIGH',
    warning_count = 0,
    residual_count = 0,
    elapsed_ms = 0,
    warnings = [],
    unsupported_features = [],
    residual_warnings = [],
    doc_references = [],
    source_dialect,
    target_dialect,
    object_type,
    converted_sql = '',
  } = result

  const sqlLines = converted_sql.split('\n').length
  const sqlChars = converted_sql.length
  const totalIssues = warning_count + residual_count + unsupported_features.length
  const maxBar = Math.max(1, warning_count, residual_count, unsupported_features.length, doc_references.length)

  return (
    <div className="rpt-overlay" ref={overlayRef} onClick={handleOverlayClick}>
      <div className="rpt-modal" role="dialog" aria-label="Conversion Report">
        {/* ── Modal header ── */}
        <div className="rpt-header">
          <div className="rpt-header-left">
            <span className="rpt-header-icon">⟨⟩</span>
            <div>
              <h2 className="rpt-title">Conversion Report</h2>
              <p className="rpt-subtitle">
                {sourceDialect?.display_name ?? source_dialect}
                &nbsp;<span className="rpt-arrow">→</span>&nbsp;
                {targetDialect?.display_name ?? target_dialect}
                &nbsp;·&nbsp;<span className="rpt-obj-type">{object_type}</span>
              </p>
            </div>
          </div>
          <button className="rpt-close" onClick={onClose} aria-label="Close report">✕</button>
        </div>

        <div className="rpt-body">
          {/* ── Row 1: Gauge + stat cards + timeline ── */}
          <div className="rpt-row rpt-row--top">

            {/* Gauge */}
            <div className="rpt-card rpt-card--gauge">
              <p className="rpt-card-label">Confidence</p>
              <ConfidenceGauge score={confidence_score} level={confidence_level} />
              <p className="rpt-card-hint">
                {confidence_level === 'HIGH' && 'No issues — production ready'}
                {confidence_level === 'PARTIAL' && 'Review warnings before deploying'}
                {confidence_level === 'MANUAL_REVIEW' && 'Manual intervention required'}
              </p>
            </div>

            {/* Stat cards */}
            <div className="rpt-stats-grid">
              <div className="rpt-stat-card">
                <span className="rpt-stat-val stat-val--green"><CountUp value={Math.round(confidence_score * 100)} />%</span>
                <span className="rpt-stat-lbl">Score</span>
              </div>
              <div className="rpt-stat-card">
                <span className="rpt-stat-val stat-val--blue"><CountUp value={elapsed_ms} />ms</span>
                <span className="rpt-stat-lbl">Latency</span>
              </div>
              <div className="rpt-stat-card">
                <span className={`rpt-stat-val ${totalIssues > 0 ? 'stat-val--yellow' : 'stat-val--green'}`}>
                  <CountUp value={totalIssues} />
                </span>
                <span className="rpt-stat-lbl">Issues</span>
              </div>
              <div className="rpt-stat-card">
                <span className="rpt-stat-val stat-val--purple"><CountUp value={sqlLines} /></span>
                <span className="rpt-stat-lbl">SQL Lines</span>
              </div>
              <div className="rpt-stat-card">
                <span className="rpt-stat-val stat-val--blue"><CountUp value={doc_references.length} /></span>
                <span className="rpt-stat-lbl">Doc Refs</span>
              </div>
              <div className="rpt-stat-card">
                <span className="rpt-stat-val stat-val--muted"><CountUp value={sqlChars} /></span>
                <span className="rpt-stat-lbl">Characters</span>
              </div>
            </div>

            {/* Timeline */}
            <div className="rpt-card rpt-card--timeline">
              <p className="rpt-card-label">Pipeline</p>
              <div className="rpt-timeline">
                <TimelineStep icon="📥" label="Parse"    done delay={0}   />
                <div className="tl-connector" />
                <TimelineStep icon="⚙"  label="Generate" done delay={120} />
                <div className="tl-connector" />
                <TimelineStep icon="🔍" label="Validate" done delay={240} />
                <div className="tl-connector" />
                <TimelineStep icon="🎯" label="Score"    done delay={360} />
              </div>
            </div>
          </div>

          {/* ── Row 2: Score breakdown bars ── */}
          <div className="rpt-card rpt-card--bars">
            <p className="rpt-card-label">Issue Breakdown</p>
            <ScoreBar label="Warnings"   value={warning_count}                  max={maxBar} color="var(--accent-yellow)" icon="⚠" />
            <ScoreBar label="Residuals"  value={residual_count}                 max={maxBar} color="var(--accent-red)"    icon="🔴" />
            <ScoreBar label="Blocked"    value={unsupported_features.length}    max={maxBar} color="#f43f5e"               icon="✕" />
            <ScoreBar label="Doc Refs"   value={doc_references.length}          max={maxBar} color="var(--accent-blue)"   icon="📖" />
          </div>

          {/* ── Row 3: Detail sections ── */}
          <div className="rpt-sections">
            {warnings.length > 0 && (
              <Section title="Warnings" count={warnings.length} color="var(--accent-yellow)" startOpen>
                {warnings.map((w, i) => <IssueRow key={i} item={w} />)}
              </Section>
            )}

            {residual_warnings.length > 0 && (
              <Section title="Residual Patterns" count={residual_warnings.length} color="var(--accent-red)">
                <p className="rpt-section-desc">
                  The residual validator detected leftover source-dialect syntax in
                  the output. These patterns were not converted and require manual correction.
                </p>
                {residual_warnings.map((w, i) => <IssueRow key={i} item={w} />)}
              </Section>
            )}

            {unsupported_features.length > 0 && (
              <Section title="Unsupported Features" count={unsupported_features.length} color="#f43f5e">
                <p className="rpt-section-desc">
                  These features have no equivalent in the target dialect.
                  Manual implementation is required.
                </p>
                {unsupported_features.map((w, i) => <IssueRow key={i} item={w} />)}
              </Section>
            )}

            {doc_references.length > 0 && (
              <Section title="Documentation References" count={doc_references.length} color="var(--accent-blue)">
                <p className="rpt-section-desc">
                  These official documentation pages informed the conversion decisions.
                </p>
                <div className="rpt-doc-grid">
                  {doc_references.map((d, i) => (
                    <a
                      key={i}
                      href={d.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="rpt-doc-card"
                    >
                      <span className="rpt-doc-platform">{d.platform}</span>
                      <span className="rpt-doc-title">{d.title}</span>
                      {d.purpose && <span className="rpt-doc-purpose">{d.purpose}</span>}
                      <span className="rpt-doc-arrow">↗</span>
                    </a>
                  ))}
                </div>
              </Section>
            )}

            {warnings.length === 0 && residual_warnings.length === 0 &&
             unsupported_features.length === 0 && (
              <div className="rpt-clean-banner">
                <span className="rpt-clean-icon">✓</span>
                <div>
                  <p className="rpt-clean-title">Clean conversion</p>
                  <p className="rpt-clean-sub">
                    No warnings, residual patterns, or unsupported features detected.
                    Output SQL is production-ready for {targetDialect?.display_name ?? target_dialect}.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* ── Footer ── */}
        <div className="rpt-footer">
          <span className="rpt-footer-text">
            Universal SQL Transpiler · v1.0 · {source_dialect} → {target_dialect}
          </span>
          <button className="btn-rpt-close" onClick={onClose}>Close Report</button>
        </div>
      </div>
    </div>
  )
}
