/**
 * DialectSelector — visual card-based dialect picker.
 *
 * Shows the selected dialect as a prominent card (logo + full name).
 * Click to open a smooth dropdown grid of all available dialects.
 * No native <select> — fully custom so we control every pixel.
 */
import { useState, useRef, useEffect, useCallback } from 'react'
import DialectLogo from './DialectLogo.jsx'
import { DIALECT_COLORS } from '../data/dialectMeta.js'

export default function DialectSelector({ label, value, dialects, onChange, disabled }) {
  const [open, setOpen] = useState(false)
  const wrapRef = useRef(null)

  const selected = dialects.find(d => d.key === value) ?? dialects[0]

  // Close on outside click
  useEffect(() => {
    if (!open) return
    function handle(e) {
      if (wrapRef.current && !wrapRef.current.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', handle)
    return () => document.removeEventListener('mousedown', handle)
  }, [open])

  // Close on Escape
  useEffect(() => {
    if (!open) return
    function handle(e) { if (e.key === 'Escape') setOpen(false) }
    window.addEventListener('keydown', handle)
    return () => window.removeEventListener('keydown', handle)
  }, [open])

  const handleSelect = useCallback((key) => {
    onChange(key)
    setOpen(false)
  }, [onChange])

  const brandColor = selected ? (DIALECT_COLORS[selected.key]?.primary ?? '#7c3aed') : '#7c3aed'

  return (
    <div className="ds-wrap" ref={wrapRef}>
      <p className="ds-label">{label}</p>

      {/* ── Trigger button — shows selected dialect ── */}
      <button
        className={`ds-trigger ${open ? 'ds-trigger--open' : ''}`}
        onClick={() => !disabled && setOpen(o => !o)}
        disabled={disabled}
        style={{ '--brand': brandColor }}
        aria-haspopup="listbox"
        aria-expanded={open}
      >
        <span className="ds-trigger-logo">
          {selected && <DialectLogo dialectKey={selected.key} size={28} />}
        </span>
        <span className="ds-trigger-text">
          <span className="ds-trigger-name">{selected?.short_name ?? 'Select…'}</span>
          <span className="ds-trigger-vendor">{selected?.vendor ?? ''}</span>
        </span>
        <span className={`ds-chevron ${open ? 'ds-chevron--up' : ''}`}>
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M2 4.5L6 8.5L10 4.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </span>
      </button>

      {/* ── Dropdown grid ── */}
      {open && (
        <div className="ds-dropdown" role="listbox" aria-label={label}>
          <div className="ds-grid">
            {dialects.map(d => {
              const isActive = d.key === value
              const color = DIALECT_COLORS[d.key]?.primary ?? '#7c3aed'
              return (
                <button
                  key={d.key}
                  className={`ds-card ${isActive ? 'ds-card--active' : ''}`}
                  onClick={() => handleSelect(d.key)}
                  style={{ '--card-brand': color }}
                  role="option"
                  aria-selected={isActive}
                  title={d.display_name}
                >
                  <span className="ds-card-logo">
                    <DialectLogo dialectKey={d.key} size={32} />
                  </span>
                  <span className="ds-card-name">{d.short_name}</span>
                  {isActive && (
                    <span className="ds-card-check">
                      <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                        <path d="M1.5 5L4 7.5L8.5 2.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    </span>
                  )}
                </button>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
