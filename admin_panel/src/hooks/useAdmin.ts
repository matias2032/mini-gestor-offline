import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { adminApi } from '../api/adminApi'
import type { ApiError } from '../api/http'
import type {
  AdminProfile,
  ChangePasswordRequest,
  LoginRequest,
  UpdateProfileRequest,
} from '../types/admin'
import { useAuth } from './useAuth'

export const adminKeys = {
  me: ['admin', 'me'] as const,
  audit: (params: object) => ['admin', 'audit', params] as const,
}

export function useLogin() {
  const { login } = useAuth()
  return useMutation<void, ApiError, LoginRequest>({ mutationFn: login })
}

export function useProfile() {
  const { isAuthenticated } = useAuth()
  return useQuery({
    queryKey: adminKeys.me,
    queryFn: adminApi.getMe,
    enabled: isAuthenticated,
  })
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()
  return useMutation<AdminProfile, ApiError, UpdateProfileRequest>({
    mutationFn: adminApi.updateMe,
    onSuccess: (profile) => queryClient.setQueryData(adminKeys.me, profile),
  })
}

// 403 WRONG_CURRENT_PASSWORD e 400 WEAK_PASSWORD chegam aqui como ApiError e nao fazem logout
export function useChangePassword() {
  return useMutation<void, ApiError, ChangePasswordRequest>({
    mutationFn: adminApi.changePassword,
  })
}

export function useAudit(params: { licenseId?: number; page?: number; size?: number } = {}) {
  const { isAuthenticated } = useAuth()
  return useQuery({
    queryKey: adminKeys.audit(params),
    queryFn: () => adminApi.listAudit(params),
    enabled: isAuthenticated,
    placeholderData: keepPreviousData, // evita piscar a tabela ao mudar de pagina
  })
}