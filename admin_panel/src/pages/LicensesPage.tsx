import { useState, type FormEvent } from 'react'
import { useLicenses, useResetLicense, useRevokeLicense } from '../hooks/useLicenses'
import { GenerateLicenseForm } from '../components/GenerateLicenseForm'
import { LicenseTable } from '../components/LicenseTable'
import { ErrorMessage } from '../components/ErrorMessage'

export function LicensesPage() {
  const [input, setInput] = useState('')
  const [buyer, setBuyer] = useState('')

  const { data, error, isPending } = useLicenses(buyer)
  const reset = useResetLicense()
  const revoke = useRevokeLicense()

  // licenca com reset ou revoke em curso (desactiva os botoes dessa linha)
  const pendingId = reset.isPending ? reset.variables : revoke.isPending ? revoke.variables : null

  function handleSearch(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setBuyer(input.trim())
  }

  return (
    <div>
      <h1>Licencas</h1>
      <GenerateLicenseForm />

      <section>
        <h2>Lista</h2>
        <form onSubmit={handleSearch}>
          <label htmlFor="buyerSearch">Comprador</label>{' '}
          <input id="buyerSearch" value={input} onChange={(e) => setInput(e.target.value)} />{' '}
          <button type="submit">Procurar</button>
        </form>

        <ErrorMessage error={reset.error ?? revoke.error} />
        {isPending && <p>A carregar...</p>}
        <ErrorMessage error={error} />
        {data && (
          <LicenseTable
            licenses={data}
            pendingId={pendingId}
            onReset={(id) => reset.mutate(id)}
            onRevoke={(id) => revoke.mutate(id)}
          />
        )}
      </section>
    </div>
  )
}