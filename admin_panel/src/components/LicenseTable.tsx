import type { License } from '../types/license'
import { formatDate } from '../utils/format'
import { BlockIcon, EyeIcon, RestartIcon } from './icons'

interface LicenseTableProps {
  licenses: License[]
  pendingId: number | null // licenca com reset/revoke em curso
  onReset: (id: number) => void
  onRevoke: (id: number) => void
  onSelect: (id: number) => void
}

export function LicenseTable({ licenses, pendingId, onReset, onRevoke, onSelect }: LicenseTableProps) {
  if (licenses.length === 0) return <p>Sem licencas.</p>

  function confirmReset(l: License) {
    if (window.confirm(`Reset da licenca #${l.id}? O codigo volta a poder ser activado noutro aparelho.`)) {
      onReset(l.id)
    }
  }

  function confirmRevoke(l: License) {
    if (window.confirm(`Revogar a licenca #${l.id}? Esta accao nao se desfaz.`)) {
      onRevoke(l.id)
    }
  }

  return (
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Codigo</th>
          <th>Canal</th>
          <th>Comprador</th>
          <th>Estado</th>
          <th>Aparelho</th>
          <th>Activada em</th>
          <th>Activacoes</th>
          <th>Criada em</th>
          <th>Accoes</th>
        </tr>
      </thead>
      <tbody>
        {licenses.map((l) => {
          const revoked = l.status === 'REVOKED'
          const busy = pendingId === l.id
          return (
            <tr key={l.id}>
              <td>{l.id}</td>
              <td>...{l.codeHint}</td>
              <td>{l.channel}</td>
              <td>{l.buyerLabel ?? '-'}</td>
              <td>{l.status}</td>
              <td>{l.deviceId ?? '-'}</td>
              <td>{formatDate(l.activatedAt)}</td>
              <td>{l.activationCount}</td>
              <td>{formatDate(l.createdAt)}</td>
              <td>
                <div className="actions">
                  <button type="button" className="btn btn--sm btn--info" onClick={() => onSelect(l.id)}>
                    <EyeIcon /> Detalhe
                  </button>
                  <button
                    type="button"
                    className="btn btn--sm btn--warning"
                    disabled={revoked || busy}
                    onClick={() => confirmReset(l)}
                  >
                    <RestartIcon /> Reset
                  </button>
                  <button
                    type="button"
                    className="btn btn--sm btn--danger"
                    disabled={revoked || busy}
                    onClick={() => confirmRevoke(l)}
                  >
                    <BlockIcon /> Revogar
                  </button>
                </div>
              </td>
            </tr>
          )
        })}
      </tbody>
    </table>
  )
}