import { ProfileForm } from '../components/ProfileForm'
import { ChangePasswordForm } from '../components/ChangePasswordForm'

export function ProfilePage() {
  return (
    <div>
      <h1>Perfil</h1>
      <section>
        <h2>Dados da conta</h2>
        <ProfileForm />
      </section>
      <section>
        <h2>Alterar password</h2>
        <ChangePasswordForm />
      </section>
    </div>
  )
}