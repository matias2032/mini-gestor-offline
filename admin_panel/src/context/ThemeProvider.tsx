import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { ThemeContext, type ThemeContextValue, type ThemeMode } from './ThemeContext'

// Tem de ser igual ao script do index.html (que evita o "flash" do tema errado)
const STORAGE_KEY = 'admin-theme'

function initialMode(): ThemeMode {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'light' || saved === 'dark') return saved
  } catch {
    // localStorage indisponivel: segue o tema do sistema
  }
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [mode, setMode] = useState<ThemeMode>(initialMode)

  useEffect(() => {
    document.documentElement.dataset.theme = mode
  }, [mode])

  const toggle = useCallback(() => {
    const next: ThemeMode = mode === 'dark' ? 'light' : 'dark'
    setMode(next)
    try {
      localStorage.setItem(STORAGE_KEY, next)
    } catch {
      // sem persistencia: o tema vale so para esta sessao do browser
    }
  }, [mode])

  const value = useMemo<ThemeContextValue>(() => ({ mode, toggle }), [mode, toggle])

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}