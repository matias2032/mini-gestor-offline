import { request } from './http'
import type { PagedModel } from '../types/common'
import type {
  AdminProfile,
  AuditEntry,
  ChangePasswordRequest,
  LoginRequest,
  LoginResponse,
  UpdateProfileRequest,
} from '../types/admin'

export const adminApi = {
  login: (data: LoginRequest) =>
    request<LoginResponse>('/api/v1/auth/login', { method: 'POST', body: data }),

  getMe: () => request<AdminProfile>('/api/v1/admin/me'),

  updateMe: (data: UpdateProfileRequest) =>
    request<AdminProfile>('/api/v1/admin/me', { method: 'PUT', body: data }),

  changePassword: (data: ChangePasswordRequest) =>
    request<void>('/api/v1/admin/me/password', { method: 'PUT', body: data }),

  listAudit: (params: { licenseId?: number; page?: number; size?: number } = {}) =>
    request<PagedModel<AuditEntry>>('/api/v1/admin/audit', { query: params }),
}