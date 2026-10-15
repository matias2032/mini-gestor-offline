import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { licenseApi } from '../api/licenseApi'
import type { ApiError } from '../api/http'
import type { GenerateLicenseRequest, GeneratedLicense } from '../types/license'
import { useAuth } from './useAuth'

export const licenseKeys = {
  all: ['licenses'] as const,
  list: (buyer?: string) => ['licenses', 'list', buyer ?? ''] as const,
}

export function useLicenses(buyer?: string) {
  const { isAuthenticated } = useAuth()
  return useQuery({
    queryKey: licenseKeys.list(buyer),
    queryFn: () => licenseApi.list(buyer),
    enabled: isAuthenticated,
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