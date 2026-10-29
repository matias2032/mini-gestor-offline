import { useState, type FormEvent } from 'react'
import { useAuth } from '../hooks/useAuth'
import { useLogin } from '../hooks/useAdmin'
import { ErrorMessage } from './ErrorMessage'

export function LoginForm() {
  const { sessionExpired } = useAuth()
  const login = useLogin()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    login.mutate({ username: username.trim(), password })
  }

  return (
    <form onSubmit={handleSubmit}>
      {sessionExpired && <p role="status">A sessao expirou. Entra de novo.</p>}
      <div>
        <label htmlFor="username">Utilizador</label>
        <input
          id="username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          maxLength={50}
          autoComplete="username"
          required
        />
      </div>
      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          maxLength={100}
          autoComplete="current-password"
          required
        />
      </div>
      <ErrorMessage error={login.error} />
      <button type="submit" disabled={login.isPending}>
        {login.isPending ? 'A entrar...' : 'Entrar'}
      </button>
    </form>
  )
}