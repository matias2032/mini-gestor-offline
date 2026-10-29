import { useState, type FormEvent } from 'react'
import { useGenerateLicense } from '../hooks/useLicenses'
import { ErrorMessage } from './ErrorMessage'
import { GeneratedCode } from './GeneratedCode'

export function GenerateLicenseForm() {
  const generate = useGenerateLicense()
  const [channel, setChannel] = useState('WHATSAPP')
  const [buyerLabel, setBuyerLabel] = useState('')

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    generate.mutate(
      { channel: channel.trim(), buyerLabel: buyerLabel.trim() || undefined },
      { onSuccess: () => setBuyerLabel('') },
    )
  }

  return (
    <section>
      <h2>Gerar licenca</h2>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="channel">Canal</label>
          <input
            id="channel"
            value={channel}
            onChange={(e) => setChannel(e.target.value)}
            maxLength={20}
            required
          />
        </div>
        <div>
          <label htmlFor="buyerLabel">Comprador (opcional)</label>
          <input
            id="buyerLabel"
            value={buyerLabel}
            onChange={(e) => setBuyerLabel(e.target.value)}
            maxLength={120}
          />
        </div>
        <ErrorMessage error={generate.error} />
        <button type="submit" disabled={generate.isPending}>
          {generate.isPending ? 'A gerar...' : 'Gerar'}
        </button>
      </form>
      {generate.data && <GeneratedCode license={generate.data} onClose={generate.reset} />}
    </section>
  )
}