// Corpo de erro do GlobalExceptionHandler: {"error": "CODIGO"} (+ "fields" em VALIDATION_ERROR)
export interface ApiErrorBody {
  error: string
  fields?: Record<string, string>
}

// Espelho do PagedModel do Spring Data
export interface PagedModel<T> {
  content: T[]
  page: {
    size: number
    number: number
    totalElements: number
    totalPages: number
  }
}