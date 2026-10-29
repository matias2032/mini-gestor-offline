import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

// Quando o logout acontece (manual, 401 ou TTL), isAuthenticated passa a false e isto redirecciona sozinho
export function ProtectedRoute() {
  const { isAuthenticated } = useAuth()
  if (!isAuthenticated) return <Navigate to="/login" replace />
  return <Outlet />
}