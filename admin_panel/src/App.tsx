import { Navigate, Route, Routes } from 'react-router-dom'
import { ProtectedRoute } from './components/ProtectedRoute'
import { Layout } from './components/Layout'
import { LoginPage } from './pages/LoginPage'
import { LicensesPage } from './pages/LicensesPage'
import { AuditPage } from './pages/AuditPage'
import { ProfilePage } from './pages/ProfilePage'

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<Layout />}>
          <Route path="/licencas" element={<LicensesPage />} />
          <Route path="/auditoria" element={<AuditPage />} />
          <Route path="/perfil" element={<ProfilePage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/licencas" replace />} />
    </Routes>
  )
}