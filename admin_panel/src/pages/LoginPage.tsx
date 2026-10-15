import { Navigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { LoginForm } from '../components/LoginForm'

export function LoginPage() {
  const { isAuthenticated } = useAuth()
  if (isAuthenticated) return <Navigate to="/licencas" replace />
  return (
    <main>
      <h1>Painel de licencas</h1>
      <LoginForm />
    </main>
  )
}