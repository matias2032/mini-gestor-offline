import { QueryClient } from '@tanstack/react-query'
import { ApiError } from './http'

// Por defeito o React Query repete 3 vezes. Erros 4xx (401, 403, 404, 409, 429)
// sao respostas finais do servidor: repetir so atrasa a mensagem e agrava o bloqueio de login.
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        if (error instanceof ApiError && error.status >= 400 && error.status < 500) return false
        return failureCount < 2
      },
      refetchOnWindowFocus: false,
    },
  },
})