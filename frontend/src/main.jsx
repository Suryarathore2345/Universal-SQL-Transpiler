import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import LandingAnimation from './components/LandingAnimation/LandingAnimation.jsx'
import './styles/index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    {/* App mounts immediately underneath so its data fetch isn't gated on
        the intro — LandingAnimation is a pure visual overlay on top. */}
    <App />
    <LandingAnimation />
  </React.StrictMode>,
)
