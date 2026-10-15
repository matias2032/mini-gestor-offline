import {
  keepPreviousData,
  skipToken,
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'
import { licenseApi } from '../api/licenseApi'
import type { ApiError } from '../api/http'
import type { GenerateLicenseRequest, GeneratedLicense, LicenseFilters } from '../types/license'
import { useAuth } from './useAuth'

export const licenseKeys = {
  all: ['licenses'] as const,
  list: (filters: LicenseFilters) => ['licenses', 'list', filters] as const,
  detail: (id: number | null) => ['licenses', 'detail', id] as const,
}

export function useLicenses(filters: LicenseFilters) {
  const { isAuthenticated } = useAuth()
  return useQuery({
    queryKey: licenseKeys.list(filters),
    queryFn: () => licenseApi.list(filters),
    enabled: isAuthenticated,
    placeholderData: keepPreviousData, // evita piscar a tabela ao mudar de pagina ou filtro
  })
}

export function useLicense(id: number | null) {
  const { isAuthenticated } = useAuth()
  return useQuery({
    queryKey: licenseKeys.detail(id),
    queryFn: isAuthenticated && id !== null ? () => licenseApi.get(id) : skipToken,
  })
}

export function useGenerateLicense() {
  const queryClient = useQueryClient()
  return useMutation<GeneratedLicense, ApiError, GenerateLicenseRequest>({
    mutationFn: licenseApi.generate,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: licenseKeys.all }),
  })
}

export function useResetLicense() {
  const queryClient = useQueryClient()
  return useMutation<void, ApiError, number>({
    mutationFn: licenseApi.reset,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: licenseKeys.all }),
  })
}

export function useRevokeLicense() {
  const queryClient = useQueryClient()
  return useMutation<void, ApiError, number>({
    mutationFn: licenseApi.revoke,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: licenseKeys.all }),
  })
}