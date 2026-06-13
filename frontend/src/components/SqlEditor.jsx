/**
 * SqlEditor — Monaco Editor wrapper for SQL input/output.
 * Uses the official @monaco-editor/react package.
 * Docs: https://github.com/suren-atoyan/monaco-react
 */
import Editor from '@monaco-editor/react'

export default function SqlEditor({
  value,
  onChange,
  readOnly = false,
  loading = false,
  placeholder = '',
}) {
  function handleMount(editor, monaco) {
    // Register UST custom theme
    monaco.editor.defineTheme('ust-dark', {
      base: 'vs-dark',
      inherit: true,
      rules: [
        { token: 'keyword.sql', foreground: 'a78bfa', fontStyle: 'bold' },
        { token: 'string.sql',  foreground: '86efac' },
        { token: 'comment',     foreground: '6b7280', fontStyle: 'italic' },
        { token: 'number',      foreground: 'fbbf24' },
      ],
      colors: {
        'editor.background':           '#0d1117',
        'editor.foreground':           '#e6edf3',
        'editor.lineHighlightBackground': '#161b22',
        'editor.selectionBackground':  '#2d333b',
        'editorLineNumber.foreground': '#484f58',
        'editorLineNumber.activeForeground': '#a78bfa',
        'editorCursor.foreground':     '#a78bfa',
        'scrollbar.shadow':            '#00000000',
        'editor.inactiveSelectionBackground': '#161b22',
      },
    })
    monaco.editor.setTheme('ust-dark')

    // Show placeholder when empty
    if (placeholder && !value) {
      editor.updateOptions({ renderValidationDecorations: 'off' })
    }
  }

  return (
    <div className={`editor-wrap ${loading ? 'editor-loading' : ''}`}>
      {loading && (
        <div className="editor-overlay">
          <span className="spinner" />
        </div>
      )}
      <Editor
        height="100%"
        defaultLanguage="sql"
        value={value}
        onChange={readOnly ? undefined : onChange}
        options={{
          readOnly,
          fontSize: 13,
          fontFamily: "'JetBrains Mono', 'Fira Code', 'Cascadia Code', 'Consolas', monospace",
          fontLigatures: true,
          minimap: { enabled: false },
          scrollBeyondLastLine: false,
          wordWrap: 'on',
          lineNumbers: 'on',
          renderLineHighlight: 'all',
          smoothScrolling: true,
          cursorBlinking: 'smooth',
          padding: { top: 12, bottom: 12 },
          suggest: { showKeywords: true },
        }}
        onMount={handleMount}
      />
    </div>
  )
}
