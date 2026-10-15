import { useState, type FormEvent } from 'react'
import { useLicenses, useResetLicense, useRevokeLicense } from '../hooks/useLicenses'
import type { LicenseStatus } from '../types/license'
import { GenerateLicenseForm } from '../components/GenerateLicenseForm'
import { LicenseTable } from '../components/LicenseTable'
import { LicenseDetail } from '../components/LicenseDetail'
import { Pagination } from '../components/Pagination'
import { ErrorMessage } from '../components/ErrorMessage'

const PAGE_SIZE = 20

interface Filters {
  buyer: string
  status: LicenseStatus | ''
  channel: string
}

const EMPTY: Filters = { buyer: '', status: '', channel: '' }

export function LicensesPage() {
  const [draft, setDraft] = useState<Filters>(EMPTY) // o que esta nos campos
  const [applied, setApplied] = useState<Filters>(EMPTY) // o que foi enviado ao servidor
  const [page, setPage] = useState(0)
  const [selectedId, setSelectedId] = useState<number | null>(null)

  const { data, error, isPending } = useLicenses({ ...applied, page, size: PAGE_SIZE })
  const reset = useResetLicense()
  const revoke = useRevokeLicense()

  const pendingId = reset.isPending ? reset.variables : revoke.isPending ? revoke.variables : null

  function handleSearch(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setApplied({
      buyer: draft.buyer.trim(),
      status: draft.status,
      channel: draft.channel.trim(),
    })
    setPage(0) // filtro novo volta sempre a primeira pagina
  }

  function handleClear() {
    setDraft(EMPTY)
    setApplied(EMPTY)
    setPage(0)
  }

  return (
    <div>
      <h1>Licencas</h1>
      <GenerateLicenseForm />

      <section>
        <h2>Lista</h2>
        <form onSubmit={handleSearch}>
          <label htmlFor="fBuyer">Comprador</label>{' '}
          <input
            id="fBuyer"
            value={draft.buyer}
            onChange={(e) => setDraft({ ...draft, buyer: e.target.value })}
          />{' '}
          <label htmlFor="fStatus">Estado</label>{' '}
          <select
            id="fStatus"
            value={draft.status}
            onChange={(e) => setDraft({ ...draft, status: e.target.value as LicenseStatus | '' })}
          >
            <option value="">Todos</option>
            <option value="UNUSED">UNUSED</option>
            <option value="ACTIVE">ACTIVE</option>
            <option value="REVOKED">REVOKED</option>
          </select>{' '}
          <label htmlFor="fChannel">Canal</label>{' '}
          <input
            id="fChannel"
            value={draft.channel}
            onChange={(e) => setDraft({ ...draft, channel: e.target.value })}
          />{' '}
          <button type="submit">Procurar</button>{' '}
          <button type="button" onClick={handleClear}>
            Limpar
          </button>
        </form>

        <ErrorMessage error={reset.error ?? revoke.error} />
        {isPending && <p>A carregar...</p>}
        <ErrorMessage error={error} />
        {data && (
          <>
            <p>{data.page.totalElements} licenca(s)</p>
            <LicenseTable
              licenses={data.content}
              pendingId={pendingId}
              onReset={(id) => reset.mutate(id)}
              onRevoke={(id) => revoke.mutate(id)}
              onSelect={setSelectedId}
            />
            <Pagination page={page} totalPages={data.page.totalPages} onChange={setPage} />
          </>
        )}
      </section>

      {selectedId !== null && (
        <LicenseDetail id={selectedId} onClose={() => setSelectedId(null)} />
      )}
    </div>
  )
}