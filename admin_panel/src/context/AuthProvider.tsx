import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { adminApi } from '../api/adminApi'
import { setToken, setUnauthorizedHandler } from '../api/http'
import type { LoginRequest } from '../types/admin'
import { AuthContext, type AuthContextValue } from './AuthContext'

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()

  // O token vive em memoria no modulo api/http. Aqui guardamos apenas
  // quando expira, que e o que a UI precisa para saber se ha sessao.
  const [expiresAt, setExpiresAt] = useState<number | null>(null)
  const [sessionExpired, setSessionExpired] = useState(false)

  const endSession = useCallback(
    (expired: boolean) => {
      setToken(null)
      setExpiresAt(null)
      setSessionExpired(expired)
      queryClient.clear() // nenhum dado do admin fica em cache depois do logout
    },
    [queryClient],
  )

  const login = useCallback(async (data: LoginRequest) => {
    const response = await adminApi.login(data)
    setToken(response.token) // sincrono, antes de qualquer query correr
    setSessionExpired(false)
    setExpiresAt(Date.now() + response.expiresIn * 1000)
  }, [])

  const logout = useCallback(() => endSession(false), [endSession])

  // 401 com token (devolvido pelo http.ts) = sessao expirada no servidor
  useEffect(() => {
    setUnauthorizedHandler(() => endSession(true))
    return () => setUnauthorizedHandler(null)
  }, [endSession])

  // Logout automatico quando o TTL (30 min) acaba, sem esperar por um 401
  useEffect(() => {
    if (expiresAt === null) return
    const timer = setTimeout(() => endSession(true), Math.max(expiresAt - Date.now(), 0))
    return () => clearTimeout(timer)
  }, [expiresAt, endSession])

  const value = useMemo<AuthContextValue>(
    () => ({ isAuthenticated: expiresAt !== null, sessionExpired, login, logout }),
    [expiresAt, sessionExpired, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}