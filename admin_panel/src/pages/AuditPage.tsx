import { useState } from 'react'
import { useAudit } from '../hooks/useAdmin'
import { AuditTable } from '../components/AuditTable'
import { Pagination } from '../components/Pagination'
import { ErrorMessage } from '../components/ErrorMessage'

const PAGE_SIZE = 20

export function AuditPage() {
  const [page, setPage] = useState(0)
  const { data, error, isPending } = useAudit({ page, size: PAGE_SIZE })

  return (
    <div>
      <h1>Auditoria</h1>
      {isPending && <p>A carregar...</p>}
      <ErrorMessage error={error} />
      {data && (
        <>
          <AuditTable entries={data.content} />
          <Pagination page={page} totalPages={data.page.totalPages} onChange={setPage} />
        </>
      )}
    </div>
  )
}