/**
 * Full-screen cinematic intro: dark startup → SQL data streams →
 * transformation core → UST logo emergence → hero moment → supported
 * platforms → shrink-and-dock into the real header logo.
 *
 * The real <App/> is always mounted underneath this overlay (see main.jsx),
 * so its data fetch starts immediately — this component is purely a visual
 * transition, never a loading gate.
 */
import { useEffect, useRef, useState } from 'react'
import { motion, useReducedMotion } from 'framer-motion'
import './LandingAnimation.css'

const SESSION_KEY = 'ust_intro_seen'
const REPLAY_EVENT = 'ust:replay-intro'

const PLATFORMS = [
  'Redshift', 'Snowflake', 'SQL Server', 'Synapse',
  'Fabric', 'Databricks', 'Oracle', 'BigQuery',
]

const STREAM_TOKENS = [
  '010101', 'CREATE TABLE', 'VARCHAR', 'BIGINT',
  'SELECT', 'TIMESTAMP', 'SQL', 'INSERT',
  '101010', 'JOIN', 'WHERE', 'GROUP BY',
]

// Phase durations in ms — full sequence, and a much shorter one for
// prefers-reduced-motion. `null` duration means "wait for skip/click".
const PHASES_FULL = [
  { key: 'dark',       duration: 300 },
  { key: 'streams',    duration: 650 },
  { key: 'core',       duration: 500 },
  { key: 'logo',       duration: 600 },
  { key: 'hero',       duration: 1100 },
  { key: 'platforms',  duration: 650 },
  { key: 'transition', duration: 600 },
]
const PHASES_REDUCED = [
  { key: 'logo',       duration: 350 },
  { key: 'hero',       duration: 300 },
  { key: 'transition', duration: 350 },
]

export default function LandingAnimation() {
  const reduceMotion = useReducedMotion()
  const phases = reduceMotion ? PHASES_REDUCED : PHASES_FULL

  const [visible, setVisible] = useState(() => sessionStorage.getItem(SESSION_KEY) !== '1')
  const [phaseIndex, setPhaseIndex] = useState(0)
  const [dockTransform, setDockTransform] = useState(null)
  const timerRef = useRef(null)
  const logoRef = useRef(null)

  const phase = phases[phaseIndex]?.key ?? 'done'

  const finish = () => {
    sessionStorage.setItem(SESSION_KEY, '1')
    setVisible(false)
  }

  // Advance through phases on a timer.
  useEffect(() => {
    if (!visible) return undefined
    if (phaseIndex >= phases.length) {
      finish()
      return undefined
    }
    if (phase === 'transition') {
      // Compute where the real header logo sits so this overlay's logo can
      // shrink/move to dock exactly on top of it before the crossfade.
      const targetEl = document.querySelector('.logo-icon-img')
      const sourceEl = logoRef.current
      if (targetEl && sourceEl) {
        const t = targetEl.getBoundingClientRect()
        const s = sourceEl.getBoundingClientRect()
        setDockTransform({
          x: (t.left + t.width / 2) - (s.left + s.width / 2),
          y: (t.top + t.height / 2) - (s.top + s.height / 2),
          scale: t.width / s.width,
        })
      } else {
        setDockTransform({ x: -window.innerWidth / 2 + 60, y: -window.innerHeight / 2 + 30, scale: 0.2 })
      }
    }
    const { duration } = phases[phaseIndex]
    timerRef.current = setTimeout(() => setPhaseIndex((i) => i + 1), duration)
    return () => clearTimeout(timerRef.current)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phaseIndex, visible])

  // Click/tap anywhere skips straight to the dock transition.
  const handleSkip = () => {
    const transitionIdx = phases.findIndex((p) => p.key === 'transition')
    if (transitionIdx === -1 || phaseIndex >= transitionIdx) return
    clearTimeout(timerRef.current)
    setPhaseIndex(transitionIdx)
  }

  // Replay support — dispatched from the app footer.
  useEffect(() => {
    const onReplay = () => {
      sessionStorage.removeItem(SESSION_KEY)
      setDockTransform(null)
      setPhaseIndex(0)
      setVisible(true)
    }
    window.addEventListener(REPLAY_EVENT, onReplay)
    return () => window.removeEventListener(REPLAY_EVENT, onReplay)
  }, [])

  if (!visible) return null

  const showStreams = !reduceMotion && (phase === 'streams' || phase === 'core')
  const showCore = !reduceMotion && phase === 'core'
  const showLogo = phase === 'logo' || phase === 'hero' || phase === 'platforms' || phase === 'transition'
  const showHeroText = phase === 'hero' || phase === 'platforms' || phase === 'transition'
  const showPlatforms = phase === 'platforms' || phase === 'transition'
  const isTransitioning = phase === 'transition'

  return (
    <motion.div
      className="landing-overlay"
      onClick={handleSkip}
      initial={{ opacity: 1 }}
      animate={{ opacity: isTransitioning ? 0 : 1 }}
      transition={{ duration: 0.6, delay: isTransitioning ? 0.15 : 0 }}
      onAnimationComplete={() => { if (isTransitioning) finish() }}
    >
        <div className="landing-glow" />
        <div className="landing-lines" />

        {showStreams && (
          <div className="landing-streams">
            {STREAM_TOKENS.map((tok, i) => (
              <motion.span
                key={tok}
                className="landing-token"
                style={{ top: `${8 + (i * 84) % 84}%` }}
                initial={{ x: i % 2 === 0 ? '-40vw' : '40vw', opacity: 0 }}
                animate={{ x: 0, opacity: [0, 1, 1, 0] }}
                transition={{ duration: 0.9, delay: i * 0.04, ease: 'easeInOut' }}
              >
                {tok}
              </motion.span>
            ))}
          </div>
        )}

        {showCore && (
          <div className="landing-core">
            <motion.svg className="landing-arc landing-arc-a" viewBox="0 0 200 200"
              initial={{ rotate: -30, opacity: 0 }} animate={{ rotate: 160, opacity: 1 }}
              transition={{ duration: 0.5, ease: 'easeOut' }}>
              <circle cx="100" cy="100" r="86" />
            </motion.svg>
            <motion.svg className="landing-arc landing-arc-b" viewBox="0 0 200 200"
              initial={{ rotate: 30, opacity: 0 }} animate={{ rotate: -160, opacity: 1 }}
              transition={{ duration: 0.5, ease: 'easeOut' }}>
              <circle cx="100" cy="100" r="70" />
            </motion.svg>
          </div>
        )}

        {showLogo && (
          <motion.div
            ref={logoRef}
            className="landing-logo-block"
            initial={{ scale: 0.3, opacity: 0 }}
            animate={
              isTransitioning && dockTransform
                ? { scale: dockTransform.scale, x: dockTransform.x, y: dockTransform.y, opacity: 1 }
                : { scale: 1, opacity: 1 }
            }
            transition={
              isTransitioning
                ? { duration: 0.6, ease: [0.22, 1, 0.36, 1] }
                : { duration: reduceMotion ? 0.3 : 0.6, ease: [0.16, 1, 0.3, 1] }
            }
          >
            <motion.div
              className="landing-logo-glow"
              animate={!isTransitioning ? { scale: [1, 1.06, 1], opacity: [0.6, 0.85, 0.6] } : { opacity: 0 }}
              transition={{ duration: 2.4, repeat: isTransitioning ? 0 : Infinity, ease: 'easeInOut' }}
            />
            <img src="/logo.png" alt="UST" className="landing-logo-img" />
          </motion.div>
        )}

        {showHeroText && !isTransitioning && (
          <motion.div
            className="landing-hero-text"
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
          >
            <h2>UNIVERSAL SQL TRANSPILER</h2>
            <p>Write Once. Run Anywhere.</p>
          </motion.div>
        )}

        {showPlatforms && !isTransitioning && (
          <motion.div
            className="landing-platforms"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.4 }}
          >
            {PLATFORMS.map((p, i) => (
              <motion.span
                key={p}
                className="landing-platform-node"
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.35, delay: i * 0.05 }}
              >
                {p}
              </motion.span>
            ))}
          </motion.div>
        )}

        {!isTransitioning && (
          <div className="landing-skip-hint">Click to skip</div>
        )}
    </motion.div>
  )
}

/** Call from anywhere (e.g. a Settings/About menu) to replay the intro. */
export function replayIntro() {
  window.dispatchEvent(new Event(REPLAY_EVENT))
}
