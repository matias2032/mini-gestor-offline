import { useState } from 'react'
import type { GeneratedLicense } from '../types/license'

interface GeneratedCodeProps {
  license: GeneratedLicense
  onClose: () => void
}

export function GeneratedCode({ license, onClose }: GeneratedCodeProps) {
  const [copied, setCopied] = useState(false)

  async function copy() {
    try {
      await navigator.clipboard.writeText(license.code)
      setCopied(true)
    } catch {
      setCopied(false) // o codigo continua visivel para copiar a mao
    }
  }

  return (
    <div role="status">
      <p>
        Licenca #{license.id} criada ({license.channel}
        {license.buyerLabel ? `, ${license.buyerLabel}` : ''}).
      </p>
      <p>
        <strong>{license.code}</strong>
      </p>
      <p>Copia o codigo agora: o servidor guarda so o hash e nao o volta a mostrar.</p>
      <button type="button" onClick={copy}>
        {copied ? 'Copiado' : 'Copiar'}
      </button>{' '}
      <button type="button" onClick={onClose}>
        Fechar
      </button>
    </div>
  )
}