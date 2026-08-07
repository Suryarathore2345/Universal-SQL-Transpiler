/**
 * "Upload .sql/.txt" button for the source pane — reads the chosen file
 * client-side (FileReader) and hands its text content to onUpload.
 */
import { useRef, useState } from 'react'
import { readFileAsText } from '../utils/download.js'

// Picker `accept` is only a hint (a user can still choose "All files"), so
// both size and content are validated after selection too — otherwise a
// large or binary file gets dumped straight into the Monaco editor with no
// feedback beyond a wall of mojibake.
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024 // 5 MB

export default function UploadButton({ onUpload, disabled }) {
  const inputRef = useRef(null)
  const [error, setError] = useState(null)

  async function handleChange(e) {
    const file = e.target.files?.[0]
    e.target.value = '' // allow re-selecting the same file later
    if (!file) return
    setError(null)

    if (file.size > MAX_UPLOAD_BYTES) {
      setError(`File is too large (${(file.size / 1024 / 1024).toFixed(1)} MB) — max ${MAX_UPLOAD_BYTES / 1024 / 1024} MB`)
      return
    }

    try {
      const text = await readFileAsText(file)
      // Cheap binary-content heuristic: SQL/text files shouldn't contain
      // NUL bytes or other non-printable control characters. This won't
      // catch every binary format, but it catches the common case of
      // someone accidentally picking an image/archive/etc. via "All files".
      if (/[\x00-\x08\x0E-\x1F]/.test(text.slice(0, 8192))) {
        setError('This file does not look like text — please choose a .sql or .txt file')
        return
      }
      onUpload(text)
    } catch (err) {
      setError('Could not read file')
    }
  }

  return (
    <>
      <button
        className="btn-upload"
        onClick={() => inputRef.current?.click()}
        disabled={disabled}
        title="Upload a .sql or .txt file"
      >
        ⭱ Upload
      </button>
      <input
        ref={inputRef}
        type="file"
        accept=".sql,.txt,text/plain"
        onChange={handleChange}
        style={{ display: 'none' }}
      />
      {error && <span className="upload-error">{error}</span>}
    </>
  )
}
