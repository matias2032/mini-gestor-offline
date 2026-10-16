import { useEffect, useState, type ComponentType, type SVGProps } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { useMediaQuery } from '../hooks/useMediaQuery'
import { HistoryIcon, KeyIcon, MenuIcon } from './icons'
import { ThemeToggle } from './ThemeToggle'
import { UserMenu } from './UserMenu'

interface NavItem {
  to: string
  label: string // hoje texto fixo; com i18n passa a ser uma chave (t('nav.licenses'))
  icon: ComponentType<SVGProps<SVGSVGElement>>
}

// O Perfil nao esta aqui: vive no menu do utilizador, no fundo da sidebar
const NAV_ITEMS: NavItem[] = [
  { to: '/licencas', label: 'Licencas', icon: KeyIcon },
  { to: '/auditoria', label: 'Auditoria', icon: HistoryIcon },
]

const DESKTOP_QUERY = '(min-width: 900px)'

export function Layout() {
  const isDesktop = useMediaQuery(DESKTOP_QUERY)

  // null = ainda nao mexeste: a sidebar abre em desktop e fica fechada em mobile.
  // Depois de carregares no hamburger, a tua escolha manda.
  const [userOpen, setUserOpen] = useState<boolean | null>(null)
  const open = userOpen ?? isDesktop

  function closeOnMobile() {
    if (!isDesktop) setUserOpen(false)
  }

  // Escape fecha a gaveta em mobile
  useEffect(() => {
    if (!open || isDesktop) return
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') setUserOpen(false)
    }
    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [open, isDesktop])

  return (
    <div className="shell" data-open={open}>
      <aside id="sidebar" className="sidebar" aria-label="Navegacao principal">
        <div className="sidebar__brand">Painel de licencas</div>

        <nav className="sidebar__nav">
          {NAV_ITEMS.map(({ to, label, icon: Icon }) => (
            <NavLink key={to} to={to} className="nav-link" onClick={closeOnMobile}>
              <Icon />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar__theme">
          <ThemeToggle />
        </div>

        <div className="sidebar__footer">
          <UserMenu onNavigate={closeOnMobile} />
        </div>
      </aside>

      <div className="backdrop" aria-hidden="true" onClick={() => setUserOpen(false)} />

      <div className="main">
        <header className="topbar">
          <button
            type="button"
            className="icon-button"
            aria-label={open ? 'Fechar menu' : 'Abrir menu'}
            aria-expanded={open}
            aria-controls="sidebar"
            onClick={() => setUserOpen(!open)}
          >
            <MenuIcon />
          </button>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}