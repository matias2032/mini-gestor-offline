import { request } from './http'
import type { GenerateLicenseRequest, GeneratedLicense, License } from '../types/license'

export const licenseApi = {
  generate: (data: GenerateLicenseRequest) =>
    request<GeneratedLicense>('/api/v1/admin/licenses', { method: 'POST', body: data }),

  // Hoje o servidor devolve uma lista simples. Quando fizermos o passo 3
  // (paginacao e filtros), este ficheiro e o tipo mudam para PagedModel<License>.
  list: (buyer?: string) =>
    request<License[]>('/api/v1/admin/licenses', { query: { buyer } }),

  reset: (id: number) =>
    request<void>(`/api/v1/admin/licenses/${id}/reset`, { method: 'POST' }),

  revoke: (id: number) =>
    request<void>(`/api/v1/admin/licenses/${id}/revoke`, { method: 'POST' }),
}