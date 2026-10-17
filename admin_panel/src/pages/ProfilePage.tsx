import { ProfileForm } from '../components/ProfileForm'
import { ChangePasswordForm } from '../components/ChangePasswordForm'

export function ProfilePage() {
  return (
    <div className="page-narrow">
      <h1>Perfil</h1>
      <section className="card">
        <h2>Dados da conta</h2>
        <ProfileForm />
      </section>
      <section className="card">
        <h2>Alterar password</h2>
        <ChangePasswordForm />
      </section>
    </div>
  )
}