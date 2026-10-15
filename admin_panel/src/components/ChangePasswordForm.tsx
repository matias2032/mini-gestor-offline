import { useState, type FormEvent } from 'react'
import { useChangePassword } from '../hooks/useAdmin'
import { ErrorMessage } from './ErrorMessage'

const MIN_LENGTH = 12 // igual ao MIN_PASSWORD_LENGTH do AdminService

export function ChangePasswordForm() {
  const change = useChangePassword()
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [localError, setLocalError] = useState<string | null>(null)

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    if (newPassword.length < MIN_LENGTH) {
      setLocalError(`A nova password deve ter pelo menos ${MIN_LENGTH} caracteres.`)
      return
    }
    if (newPassword !== confirm) {
      setLocalError('A confirmacao nao coincide com a nova password.')
      return
    }
    setLocalError(null)
    change.mutate(
      { currentPassword, newPassword },
      {
        onSuccess: () => {
          setCurrentPassword('')
          setNewPassword('')
          setConfirm('')
        },
      },
    )
  }

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="currentPassword">Password actual</label>
        <input
          id="currentPassword"
          type="password"
          value={currentPassword}
          onChange={(e) => setCurrentPassword(e.target.value)}
          maxLength={100}
          autoComplete="current-password"
          required
        />
      </div>
      <div>
        <label htmlFor="newPassword">Nova password</label>
        <input
          id="newPassword"
          type="password"
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          maxLength={100}
          autoComplete="new-password"
          required
        />
      </div>
      <div>
        <label htmlFor="confirmPassword">Confirmar nova password</label>
        <input
          id="confirmPassword"
          type="password"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          maxLength={100}
          autoComplete="new-password"
          required
        />
      </div>
      {localError && <p role="alert">{localError}</p>}
      <ErrorMessage error={change.error} />
      {change.isSuccess && <p role="status">Password alterada.</p>}
      <button type="submit" disabled={change.isPending}>
        {change.isPending ? 'A guardar...' : 'Alterar password'}
      </button>
    </form>
  )
}