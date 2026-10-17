import { Navigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { LoginForm } from '../components/LoginForm'

export function LoginPage() {
  const { isAuthenticated } = useAuth()
  if (isAuthenticated) return <Navigate to="/licencas" replace />
  return (
    <main className="auth-page">
      <div className="card">
        <h1 className="auth-title">Painel de licencas</h1>
        <LoginForm />
      </div>
    </main>
  )
}