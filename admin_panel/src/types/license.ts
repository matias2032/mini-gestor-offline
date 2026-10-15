export type LicenseStatus = 'UNUSED' | 'ACTIVE' | 'REVOKED'

export interface License {
  id: number
  codeHint: string
  channel: string
  buyerLabel: string | null
  status: LicenseStatus
  deviceId: string | null
  activatedAt: string | null
  activationCount: number
  createdAt: string
}

export interface GenerateLicenseRequest {
  channel: string
  buyerLabel?: string
}

// O codigo em claro so existe nesta resposta
export interface GeneratedLicense {
  id: number
  code: string
  channel: string
  buyerLabel: string | null
}