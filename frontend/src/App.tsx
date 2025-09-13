import { useState } from 'react'
import { validateLoadout, duel } from './api'

const sampleLoadout = {
  points_pool: 30,
  rng_seed: 123,
  pieces: [
    { id: 'K', type: 'king', hp: 100, atk: 0, defn: 0, spd: 0 },
    { id: 'Q', type: 'queen', hp: 110, atk: 10, defn: 10, spd: 10 },
    { id: 'N1', type: 'knight', hp: 90, atk: 6, defn: 5, spd: 4 },
    { id: 'B1', type: 'bishop', hp: 90, atk: 4, defn: 4, spd: 6 }
  ]
}

export default function App() {
  const [msg, setMsg] = useState<string>('Listo para validar distribución.')
  const [result, setResult] = useState<string>('')

  const onValidate = async () => {
    const r = await validateLoadout(sampleLoadout)
    setMsg(r.ok ? `OK: ${r.message}` : `Error: ${r.message}`)
  }

  const onDuel = async () => {
    const r = await duel({
      a: { id: 'N1', type: 'knight', hp: 90, atk: 6, defn: 5, spd: 4 },
      b: { id: 'B1', type: 'bishop', hp: 90, atk: 4, defn: 4, spd: 6 },
      rng_seed: 123
    })
    setResult(`Ganador: ${r.winner_id} (${r.details})`)
  }

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', padding: 24, maxWidth: 880, margin: '0 auto' }}>
      <h1>Ajedrez RPG — Prototipo</h1>
      <p>{msg}</p>
      <div style={{ display: 'flex', gap: 12 }}>
        <button onClick={onValidate}>Validar distribución</button>
        <button onClick={onDuel}>Simular duelo</button>
      </div>
      {result && <pre style={{ marginTop: 16 }}>{result}</pre>}
      <hr />
      <small>
        Backend en <code>/backend</code> (FastAPI) · Frontend en <code>/frontend</code> (Vite + React)
      </small>
    </div>
  )
}
