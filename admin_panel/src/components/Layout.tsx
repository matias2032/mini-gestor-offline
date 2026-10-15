import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

export function Layout() {
  const { logout } = useAuth()
  return (
    <div>
      <header>
        <nav>
          <NavLink to="/licencas">Licencas</NavLink>{' '}
          <NavLink to="/auditoria">Auditoria</NavLink>{' '}
          <NavLink to="/perfil">Perfil</NavLink>{' '}
          <button type="button" onClick={logout}>
            Sair
          </button>
        </nav>
      </header>
      <main>
        <Outlet />
      </main>
    </div>
  )
}