import { request } from './http'
import type { PagedModel } from '../types/common'
import type {
  GenerateLicenseRequest,
  GeneratedLicense,
  License,
  LicenseFilters,
} from '../types/license'

export const licenseApi = {
  generate: (data: GenerateLicenseRequest) =>
    request<GeneratedLicense>('/api/v1/admin/licenses', { method: 'POST', body: data }),

  // Valores vazios sao omitidos pelo request(), por isso status '' = sem filtro
  list: (filters: LicenseFilters = {}) =>
    request<PagedModel<License>>('/api/v1/admin/licenses', { query: filters }),

  get: (id: number) => request<License>(`/api/v1/admin/licenses/${id}`),

  reset: (id: number) =>
    request<void>(`/api/v1/admin/licenses/${id}/reset`, { method: 'POST' }),

  revoke: (id: number) =>
    request<void>(`/api/v1/admin/licenses/${id}/revoke`, { method: 'POST' }),
}