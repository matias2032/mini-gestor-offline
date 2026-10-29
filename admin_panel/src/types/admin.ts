export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  token: string
  tokenType: string
  expiresIn: number // segundos
}

export interface AdminProfile {
  id: number
  username: string
  lastLoginAt: string | null
  createdAt: string
}

export interface UpdateProfileRequest {
  username: string
}

export interface ChangePasswordRequest {
  currentPassword: string
  newPassword: string
}

export interface AuditEntry {
  id: number
  adminId: number | null
  username: string | null
  action: string
  licenseId: number | null
  ip: string | null
  createdAt: string
}