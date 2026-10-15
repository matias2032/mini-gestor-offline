import { ApiError } from '../api/http'
import { errorText } from '../api/errorMessages'

export function ErrorMessage({ error }: { error: unknown }) {
  if (!error) return null
  const fields = error instanceof ApiError ? error.fields : undefined
  return (
    <div role="alert">
      <p>{errorText(error)}</p>
      {fields && (
        <ul>
          {Object.entries(fields).map(([field, message]) => (
            <li key={field}>
              {field}: {message}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}