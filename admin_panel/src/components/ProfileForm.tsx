import { useState, type FormEvent } from 'react'
import { useProfile, useUpdateProfile } from '../hooks/useAdmin'
import type { AdminProfile } from '../types/admin'
import { formatDate } from '../utils/format'
import { ErrorMessage } from './ErrorMessage'

function ProfileEditor({ profile }: { profile: AdminProfile }) {
  const update = useUpdateProfile()
  const [username, setUsername] = useState(profile.username)

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    update.mutate({ username: username.trim() })
  }

  return (
    <form onSubmit={handleSubmit}>
      <p>Ultimo login: {formatDate(profile.lastLoginAt)}</p>
      <p>Conta criada em: {formatDate(profile.createdAt)}</p>
      <div>
        <label htmlFor="profileUsername">Utilizador</label>
        <input
          id="profileUsername"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          minLength={3}
          maxLength={50}
          required
        />
      </div>
      <ErrorMessage error={update.error} />
      {update.isSuccess && <p role="status">Guardado.</p>}
      <button type="submit" disabled={update.isPending}>
        {update.isPending ? 'A guardar...' : 'Guardar'}
      </button>
    </form>
  )
}

export function ProfileForm() {
  const { data, error, isPending } = useProfile()
  if (isPending) return <p>A carregar...</p>
  if (error) return <ErrorMessage error={error} />
  return <ProfileEditor profile={data} />
}