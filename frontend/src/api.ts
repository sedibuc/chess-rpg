const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export async function validateLoadout(payload: any) {
  const r = await fetch(`${API_URL}/match/validate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  })
  if (!r.ok) throw new Error('Error validando loadout')
  return r.json()
}

export async function duel(payload: any) {
  const r = await fetch(`${API_URL}/match/duel`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  })
  if (!r.ok) throw new Error('Error en duelo')
  return r.json()
}
