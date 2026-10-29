import { useTheme } from '../hooks/useTheme'
import { MoonIcon, SunIcon } from './icons'

export function ThemeToggle() {
  const { mode, toggle } = useTheme()
  const dark = mode === 'dark'
  return (
    <button type="button" role="switch" aria-checked={dark} className="theme-toggle" onClick={toggle}>
      <span className="theme-toggle__label">
        {dark ? <MoonIcon /> : <SunIcon />}
        <span>Modo escuro</span>
      </span>
      <span className="switch" aria-hidden="true">
        <span className="switch__thumb" />
      </span>
    </button>
  )
}