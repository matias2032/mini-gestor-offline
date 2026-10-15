import type { AuditEntry } from '../types/admin'
import { formatDate } from '../utils/format'

export function AuditTable({ entries }: { entries: AuditEntry[] }) {
  if (entries.length === 0) return <p>Sem registos.</p>
  return (
    <table>
      <thead>
        <tr>
          <th>Data</th>
          <th>Utilizador</th>
          <th>Accao</th>
          <th>Licenca</th>
          <th>IP</th>
        </tr>
      </thead>
      <tbody>
        {entries.map((a) => (
          <tr key={a.id}>
            <td>{formatDate(a.createdAt)}</td>
            <td>{a.username ?? '-'}</td>
            <td>{a.action}</td>
            <td>{a.licenseId ?? '-'}</td>
            <td>{a.ip ?? '-'}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}