import { useLicense } from '../hooks/useLicenses'
import { formatDate } from '../utils/format'
import { ErrorMessage } from './ErrorMessage'

interface LicenseDetailProps {
  id: number
  onClose: () => void
}

export function LicenseDetail({ id, onClose }: LicenseDetailProps) {
  const { data, error, isPending } = useLicense(id)

  return (
    <section>
      <h2>Licenca #{id}</h2>
      {isPending && <p>A carregar...</p>}
      <ErrorMessage error={error} />
      {data && (
        <dl>
          <dt>Codigo</dt>
          <dd>...{data.codeHint}</dd>
          <dt>Canal</dt>
          <dd>{data.channel}</dd>
          <dt>Comprador</dt>
          <dd>{data.buyerLabel ?? '-'}</dd>
          <dt>Estado</dt>
          <dd>{data.status}</dd>
          <dt>Aparelho</dt>
          <dd>{data.deviceId ?? '-'}</dd>
          <dt>Activada em</dt>
          <dd>{formatDate(data.activatedAt)}</dd>
          <dt>Activacoes</dt>
          <dd>{data.activationCount}</dd>
          <dt>Criada em</dt>
          <dd>{formatDate(data.createdAt)}</dd>
        </dl>
      )}
      <button type="button" onClick={onClose}>
        Fechar
      </button>
    </section>
  )
}