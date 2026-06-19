/**
 * "Upload .sql/.txt" button for the source pane — reads the chosen file
 * client-side (FileReader) and hands its text content to onUpload.
 */
import { useRef, useState } from 'react'
import { readFileAsText } from '../utils/download.js'

export default function UploadButton({ onUpload, disabled }) {
  const inputRef = useRef(null)
  const [error, setError] = useState(null)

  async function handleChange(e) {
    const file = e.target.files?.[0]
    e.target.value = '' // allow re-selecting the same file later
    if (!file) return
    setError(null)
    try {
      const text = await readFileAsText(file)
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
