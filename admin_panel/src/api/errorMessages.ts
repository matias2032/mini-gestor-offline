import { ApiError } from './http'

const MESSAGES: Record<string, string> = {
  NETWORK_ERROR: 'Nao foi possivel contactar o servidor.',
  INVALID_CREDENTIALS: 'Utilizador ou password incorrectos.',
  LOGIN_LOCKED: 'Conta bloqueada por 15 minutos apos demasiadas tentativas.',
  WRONG_CURRENT_PASSWORD: 'A password actual esta incorrecta.',
  WEAK_PASSWORD: 'A nova password deve ter pelo menos 12 caracteres.',
  USERNAME_TAKEN: 'Esse nome de utilizador ja esta em uso.',
  ADMIN_NOT_FOUND: 'Conta de administrador nao encontrada.',
  INVALID_CODE: 'Licenca nao encontrada.',
  REVOKED: 'A licenca esta revogada.',
  ALREADY_USED: 'A licenca ja esta activa noutro aparelho.',
  VALIDATION_ERROR: 'Dados invalidos.',
  MALFORMED_REQUEST: 'Pedido mal formado.',
  UNAUTHORIZED: 'Sessao invalida ou expirada.',
  FORBIDDEN: 'Sem permissao para esta accao.',
  NOT_FOUND: 'Recurso nao encontrado.',
  SERVER_ERROR: 'Erro interno do servidor.',
}

export function errorText(error: unknown): string {
  if (error instanceof ApiError) {
    return MESSAGES[error.code] ?? `Erro inesperado (${error.status} ${error.code}).`
  }
  return 'Erro inesperado.'
}