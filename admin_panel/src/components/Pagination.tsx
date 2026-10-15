interface PaginationProps {
  page: number
  totalPages: number
  onChange: (page: number) => void
}

export function Pagination({ page, totalPages, onChange }: PaginationProps) {
  if (totalPages <= 1) return null
  return (
    <div>
      <button type="button" disabled={page <= 0} onClick={() => onChange(page - 1)}>
        Anterior
      </button>
      <span>
        {' '}
        Pagina {page + 1} de {totalPages}{' '}
      </span>
      <button type="button" disabled={page + 1 >= totalPages} onClick={() => onChange(page + 1)}>
        Seguinte
      </button>
    </div>
  )
}