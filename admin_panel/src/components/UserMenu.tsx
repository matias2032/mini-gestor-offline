import { useEffect, useRef, useState } from 'react'
import { NavLink } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { useProfile } from '../hooks/useAdmin'
import { ChevronIcon, LogoutIcon, PersonIcon } from './icons'

interface UserMenuProps {
  onNavigate: () => void // fecha a sidebar em ecras pequenos
}

export function UserMenu({ onNavigate }: UserMenuProps) {
  const { logout } = useAuth()
  const { data } = useProfile()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  // Fecha ao clicar fora e com Escape
  useEffect(() => {
    if (!open) return
    function onPointerDown(e: PointerEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('pointerdown', onPointerDown)
    document.addEventListener('keydown', onKeyDown)
    return () => {
      document.removeEventListener('pointerdown', onPointerDown)
      document.removeEventListener('keydown', onKeyDown)
    }
  }, [open])

  const username = data?.username ?? 'Admin'

  return (
    <div className="user-menu" ref={ref}>
      {open && (
        <div className="user-menu__list" role="menu">
          <NavLink
            to="/perfil"
            role="menuitem"
            className="user-menu__item"
            onClick={() => {
              setOpen(false)
              onNavigate()
            }}
          >
            <PersonIcon />
            <span>Perfil</span>
          </NavLink>
          <button
            type="button"
            role="menuitem"
            className="user-menu__item"
            onClick={() => {
              setOpen(false)
              logout()
            }}
          >
            <LogoutIcon />
            <span>Sair</span>
          </button>
        </div>
      )}
      <button
        type="button"
        className="user-menu__trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen(!open)}
      >
        <span className="avatar" aria-hidden="true">
          {username.charAt(0).toUpperCase()}
        </span>
        <span className="user-menu__name">{username}</span>
        <ChevronIcon className="user-menu__chevron" />
      </button>
    </div>
  )
}