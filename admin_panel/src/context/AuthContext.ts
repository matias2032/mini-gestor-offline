import { createContext } from 'react'
import type { LoginRequest } from '../types/admin'

export interface AuthContextValue {
  isAuthenticated: boolean
  // true quando a sessao terminou por 401 ou por expiracao do TTL (para o ecra de login avisar)
  sessionExpired: boolean
  login: (data: LoginRequest) => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthContextValue | null>(null)