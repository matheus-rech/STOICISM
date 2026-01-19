'use client'

/**
 * BringToLife Client Component
 *
 * Features:
 * - Text prompt input
 * - Image upload (sketch/photo)
 * - Live preview of generated app
 * - Download generated HTML
 */
import { useState, useRef } from 'react'
import { generateApp, generateFromSketch } from '../actions/bring-to-life'

export default function BringToLifeUI() {
  const [prompt, setPrompt] = useState('')
  const [generatedHtml, setGeneratedHtml] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const iframeRef = useRef<HTMLIFrameElement>(null)

  // Handle image upload
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (event) => {
      const dataUrl = event.target?.result as string
      setImagePreview(dataUrl)
    }
    reader.readAsDataURL(file)
  }

  // Generate app from prompt or image
  const handleGenerate = async () => {
    setIsLoading(true)
    setError('')

    try {
      let result

      if (imagePreview) {
        // Extract base64 data and mime type from data URL
        const [header, base64] = imagePreview.split(',')
        const mimeType = header.match(/:(.*?);/)?.[1] || 'image/png'
        result = await generateFromSketch(base64, mimeType)
      } else {
        result = await generateApp(prompt)
      }

      if (result.success) {
        setGeneratedHtml(result.html)
      } else {
        setError(result.error || 'Generation failed')
      }
    } catch (err: any) {
      setError(err.message)
    } finally {
      setIsLoading(false)
    }
  }

  // Download generated HTML
  const handleDownload = () => {
    const blob = new Blob([generatedHtml], { type: 'text/html' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'generated-app.html'
    a.click()
    URL.revokeObjectURL(url)
  }

  // Clear image
  const clearImage = () => {
    setImagePreview(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-12">
          <h1 className="text-4xl font-bold text-white mb-2">
            🎨 Bring to Life
          </h1>
          <p className="text-purple-200">
            Transform sketches, photos, or ideas into interactive web apps
          </p>
        </header>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* Input Panel */}
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20">
            <h2 className="text-xl font-semibold text-white mb-4">Input</h2>

            {/* Image Upload */}
            <div className="mb-6">
              <label className="block text-sm text-purple-200 mb-2">
                Upload Sketch or Photo (optional)
              </label>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleImageUpload}
                className="hidden"
              />
              {imagePreview ? (
                <div className="relative">
                  <img
                    src={imagePreview}
                    alt="Upload preview"
                    className="w-full h-48 object-contain rounded-lg bg-black/30"
                  />
                  <button
                    onClick={clearImage}
                    className="absolute top-2 right-2 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center hover:bg-red-600"
                  >
                    ×
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full h-32 border-2 border-dashed border-purple-400/50 rounded-lg flex flex-col items-center justify-center text-purple-300 hover:border-purple-400 hover:bg-purple-500/10 transition"
                >
                  <span className="text-3xl mb-2">📷</span>
                  <span>Click to upload image</span>
                </button>
              )}
            </div>

            {/* Text Prompt */}
            <div className="mb-6">
              <label className="block text-sm text-purple-200 mb-2">
                Describe what you want to build
              </label>
              <textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="e.g., Create a meditation timer with breathing exercises..."
                className="w-full h-32 px-4 py-3 rounded-lg bg-black/30 border border-white/20 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-400"
              />
            </div>

            {/* Generate Button */}
            <button
              onClick={handleGenerate}
              disabled={isLoading || (!prompt && !imagePreview)}
              className="w-full py-3 px-6 rounded-lg bg-gradient-to-r from-purple-500 to-pink-500 text-white font-semibold disabled:opacity-50 disabled:cursor-not-allowed hover:from-purple-600 hover:to-pink-600 transition flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <div className="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full" />
                  Generating...
                </>
              ) : (
                <>✨ Bring to Life</>
              )}
            </button>

            {error && (
              <div className="mt-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-200">
                {error}
              </div>
            )}
          </div>

          {/* Preview Panel */}
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold text-white">Preview</h2>
              {generatedHtml && (
                <button
                  onClick={handleDownload}
                  className="px-4 py-2 rounded-lg bg-green-500/20 text-green-300 hover:bg-green-500/30 transition text-sm"
                >
                  ⬇️ Download HTML
                </button>
              )}
            </div>

            <div className="bg-white rounded-lg overflow-hidden" style={{ height: '500px' }}>
              {generatedHtml ? (
                <iframe
                  ref={iframeRef}
                  srcDoc={generatedHtml}
                  className="w-full h-full border-0"
                  sandbox="allow-scripts allow-forms"
                  title="Generated App Preview"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-gray-400 bg-gray-100">
                  <div className="text-center">
                    <span className="text-6xl mb-4 block">🖼️</span>
                    <p>Your generated app will appear here</p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Quick Presets */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold text-white mb-4">Quick Start Templates</h3>
          <div className="flex flex-wrap gap-3">
            {[
              { label: '🔢 Counter', prompt: 'Create a modern counter app with increment, decrement buttons' },
              { label: '✅ Todo List', prompt: 'Create a todo app with add, complete, delete, local storage' },
              { label: '⏱️ Pomodoro', prompt: 'Create a Pomodoro timer with start, pause, reset' },
              { label: '🏛️ Stoic Quote', prompt: 'Create a stoic philosophy quote display with elegant typography' },
              { label: '🎮 Memory Game', prompt: 'Create a memory card matching game with emoji cards' },
              { label: '📊 Dashboard', prompt: 'Create a modern analytics dashboard with charts and metrics' },
            ].map((preset) => (
              <button
                key={preset.label}
                onClick={() => setPrompt(preset.prompt)}
                className="px-4 py-2 rounded-full bg-white/10 text-purple-200 hover:bg-white/20 transition text-sm"
              >
                {preset.label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
