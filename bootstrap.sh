#!/usr/bin/env bash
set -euo pipefail

mkdir -p .github/workflows .vscode backend/app/{routers,services} frontend/src

# .gitignore
cat > .gitignore <<'EOF'
__pycache__/
+.pytest_cache/
+.venv/
+env/
+dist/
+node_modules/
+.DS_Store
+.vscode/.history
+.idea/
+.coverage
+coverage.xml
+*.log
+*.env
+.env*
+frontend/.vite
+frontend/dist
EOF

# README
cat > README.md <<'EOF'
# Juego de Ajedrez RPG — Monorepo (Frontend + Backend)

Arquitectura:
- **frontend/**: Vite + React + TypeScript
- **backend/**: FastAPI (Python 3.11)
- **docker-compose.yml**: levanta ambos servicios
- **CI**: GitHub Actions (tests backend + build frontend)
- **Apply Patch Bot**: workflow para aplicar parches desde comentarios

## Conceptos del juego (v0)
- **Puntos pre-partida**: cada jugador recibe _N_ puntos para distribuir entre sus piezas (el **rey** siempre con 0).
- **Vida y desgaste**: las piezas tienen `hp`. Al ser atacadas, pierden `hp`. A 0 se retiran.
- **Azar** controlado: `rng_seed` opcional para reproducibilidad.
- **Persistencia** (futuro): tienda con objetos persistentes; experiencia por victorias (no comprable).
- **Equipos**: muchas piezas disponibles; eliges equipo antes de jugar.

## Desarrollo local (Docker)
```bash
docker compose up --build
# Backend: http://localhost:8000/docs
# Frontend: http://localhost:5173

Backend (sin Docker)
bash
Copy code
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -U pip
pip install -e .
uvicorn app.main:app --reload --port 8000
Frontend (sin Docker)
bash
Copy code
cd frontend
npm install
npm run dev
Apply-Patch desde comentarios
En un Issue/PR comenta:

csharp
Copy code
[apply-patch]
```patch
<diff unificado>
bash
Copy code
El bot creará PR automáticamente.
EOF

# docker-compose
cat > docker-compose.yml <<'EOF'
version: "3.9"
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - APP_ENV=dev
      - UVICORN_HOST=0.0.0.0
      - UVICORN_PORT=8000
    volumes:
      - ./backend:/app
    command: >
      bash -lc "uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

  frontend:
    build: ./frontend
    ports:
      - "5173:5173"
    environment:
      - VITE_API_URL=http://localhost:8000
    volumes:
      - ./frontend:/usr/src/app
      - /usr/src/app/node_modules
    command: >
      bash -lc "npm run dev -- --host"
EOF

# GitHub Actions: apply-patch
cat > .github/workflows/apply-patch.yml <<'EOF'
name: Apply Patch from Comment
on:
  issue_comment:
    types: [created]
permissions:
  contents: write
  pull-requests: write

jobs:
  apply-patch:
    if: contains(github.event.comment.body, '[apply-patch]')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout default branch
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Extract patch from comment
        id: extract
        uses: actions/github-script@v7
        with:
          script: |
            const body = context.payload.comment.body;
            const match = body.match(/```patch([\\s\\S]*?)```/);
            if (!match) core.setFailed('No se encontró bloque ```patch``` en el comentario.');
            core.setOutput('patch', match[1].trim());
      - name: Write patch file
        run: echo "${{ steps.extract.outputs.patch }}" > changes.patch
      - name: Create branch
        run: |
          BRANCH="chatgpt/patch-${{ github.run_id }}"
          echo "BRANCH=$BRANCH" >> $GITHUB_ENV
          git switch -c "$BRANCH"
      - name: Apply patch (3-way)
        run: |
          git apply --whitespace=fix --3way changes.patch || (echo "::error::Falló git apply" && exit 1)
          git add -A
          git commit -m "Apply patch from comment by ${{ github.actor }}"
          git push -u origin "$BRANCH"
      - name: Open PR
        uses: actions/github-script@v7
        with:
          script: |
            const branch = process.env.BRANCH;
            const { data: repo } = await github.repos.get(context.repo);
            const base = repo.default_branch;
            const pr = await github.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Apply patch ${branch}`,
              head: branch,
              base,
              body: `Parche aplicado automáticamente desde comentario por @${context.actor}.`
            });
            core.notice(`PR creado: #${pr.data.number}`);
EOF

# GitHub Actions: CI
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on:
  push:
    branches: [ "main", "develop", "feature/**", "feat/**" ]
  pull_request:
    branches: [ "main", "develop" ]
jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - name: Install backend
        working-directory: backend
        run: |
          python -m pip install -U pip
          pip install -e .[dev]
      - name: Test
        working-directory: backend
        run: pytest -q --disable-warnings
  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - name: Install & build
        working-directory: frontend
        run: |
          npm ci || npm install
          npm run build
EOF

# VS Code task (para futuros parches locales)
cat > .vscode/tasks.json <<'EOF'
{
  "version": "2.0.0",
  "inputs": [
    { "id": "patchPath", "type": "promptString", "description": "Ruta del archivo .patch", "default": "changes.patch" }
  ],
  "tasks": [
    {
      "label": "Aplicar parche (3-way)",
      "type": "shell",
      "command": "git switch -c feat/chatgpt-$(date +%s) && git apply --whitespace=fix --3way '${input:patchPath}' && git add -A && git commit -m \"Aplicar parche ChatGPT\"",
      "problemMatcher": []
    }
  ]
}
EOF

# Backend: pyproject
mkdir -p backend
cat > backend/pyproject.toml <<'EOF'
[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"

[project]
name = "chess-rpg-backend"
version = "0.1.0"
description = "Backend FastAPI para juego de ajedrez con atributos."
requires-python = ">=3.11"
dependencies = [
  "fastapi>=0.115.0",
  "uvicorn[standard]>=0.30.0",
  "pydantic>=2.5.0",
]

[project.optional-dependencies]
dev = [
  "pytest>=8.0.0",
  "pytest-cov>=5.0.0",
  "httpx>=0.27.0",
]

[tool.pytest.ini_options]
addopts = "-q"
pythonpath = ["."]
EOF

# Backend: Dockerfile
cat > backend/Dockerfile <<'EOF'
FROM python:3.11-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY pyproject.toml /app/pyproject.toml
RUN pip install -U pip && pip install -e .
COPY app /app/app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Backend: app files
touch backend/app/__init__.py
cat > backend/app/config.py <<'EOF'
from pydantic import BaseModel
import os

class Settings(BaseModel):
    app_env: str = os.getenv("APP_ENV", "dev")
    rng_seed: int | None = None  # Semilla global opcional

settings = Settings()
EOF

cat > backend/app/models.py <<'EOF'
from __future__ import annotations
from dataclasses import dataclass
from typing import Literal

PieceType = Literal["king", "queen", "rook", "bishop", "knight", "pawn"]

@dataclass
class Piece:
    id: str
    type: PieceType
    hp: int = 100
    atk: int = 0
    defn: int = 0
    spd: int = 0

    def is_king(self) -> bool:
        return self.type == "king"

@dataclass
class Loadout:
    points_pool: int
    pieces: list[Piece]

    def validate(self) -> None:
        spent = 0
        king_count = 0
        for p in self.pieces:
            if p.is_king():
                king_count += 1
                if any([p.atk, p.defn, p.spd]):
                    raise ValueError("El rey debe tener 0 puntos asignados en todos los atributos.")
            for v in (p.atk, p.defn, p.spd):
                if v < 0:
                    raise ValueError("Atributos no pueden ser negativos.")
            spent += p.atk + p.defn + p.spd
        if king_count != 1:
            raise ValueError("El equipo debe tener exactamente 1 rey.")
        if spent > self.points_pool:
            raise ValueError(f"Excediste el pool de puntos ({spent} > {self.points_pool}).")
EOF

cat > backend/app/schemas.py <<'EOF'
from pydantic import BaseModel, Field
from typing import Literal, List, Optional

PieceType = Literal["king", "queen", "rook", "bishop", "knight", "pawn"]

class PieceIn(BaseModel):
    id: str
    type: PieceType
    hp: int = Field(default=100, ge=1, le=500)
    atk: int = Field(default=0, ge=0, le=200)
    defn: int = Field(default=0, ge=0, le=200)
    spd: int = Field(default=0, ge=0, le=200)

class LoadoutIn(BaseModel):
    points_pool: int = Field(ge=0, le=500)
    pieces: List[PieceIn]
    rng_seed: Optional[int] = None

class ValidationResult(BaseModel):
    ok: bool
    message: str = ""

class DuelRequest(BaseModel):
    a: PieceIn
    b: PieceIn
    rng_seed: Optional[int] = None

class DuelResult(BaseModel):
    winner_id: str
    details: str
EOF

cat > backend/app/services/match_engine.py <<'EOF'
from __future__ import annotations
import random
from app.models import Piece

class MatchEngine:
    """Motor mínimo: calcula iniciativa y daño con azar controlado."""
    def __init__(self, rng_seed: int | None = None):
        self._rng = random.Random(rng_seed)

    def _roll(self, base: int) -> int:
        jitter = base * 0.1
        value = base + self._rng.uniform(-jitter, jitter)
        return max(0, int(round(value)))

    def duel(self, a: Piece, b: Piece) -> str:
        a_spd = self._roll(a.spd)
        b_spd = self._roll(b.spd)
        first, second = (a, b) if a_spd >= b_spd else (b, a)

        def hit(attacker: Piece, defender: Piece) -> int:
            atk = self._roll(attacker.atk)
            dfs = self._roll(defender.defn)
            dmg = max(1, atk - int(dfs * 0.5))
            return dmg

        a_hp, b_hp = a.hp, b.hp
        for _ in range(3):
            if first is a:
                b_hp -= hit(a, b)
                if b_hp <= 0:
                    return a.id
                a_hp -= hit(b, a)
                if a_hp <= 0:
                    return b.id
            else:
                a_hp -= hit(b, a)
                if a_hp <= 0:
                    return b.id
                b_hp -= hit(a, b)
                if b_hp <= 0:
                    return a.id
        score_a = self._roll(a.atk + a.defn + a.spd)
        score_b = self._roll(b.atk + b.defn + b.spd)
        return a.id if score_a >= score_b else b.id
EOF

cat > backend/app/routers/__init__.py <<'EOF'
EOF

cat > backend/app/routers/match.py <<'EOF'
from fastapi import APIRouter, HTTPException
from app.schemas import LoadoutIn, ValidationResult, DuelRequest, DuelResult
from app.models import Loadout, Piece
from app.services.match_engine import MatchEngine

router = APIRouter(prefix="/match", tags=["match"])

@router.post("/validate", response_model=ValidationResult)
def validate_loadout(payload: LoadoutIn) -> ValidationResult:
    pieces = [
        Piece(id=p.id, type=p.type, hp=p.hp, atk=p.atk, defn=p.defn, spd=p.spd)
        for p in payload.pieces
    ]
    loadout = Loadout(points_pool=payload.points_pool, pieces=pieces)
    try:
        loadout.validate()
    except ValueError as e:
        return ValidationResult(ok=False, message=str(e))
    return ValidationResult(ok=True, message="Distribución válida.")

@router.post("/duel", response_model=DuelResult)
def duel(req: DuelRequest) -> DuelResult:
    if req.a.type == "king" or req.b.type == "king":
        raise HTTPException(status_code=400, detail="El rey no participa en duelos directos.")
    eng = MatchEngine(rng_seed=req.rng_seed)
    a = Piece(id=req.a.id, type=req.a.type, hp=req.a.hp, atk=req.a.atk, defn=req.a.defn, spd=req.a.spd)
    b = Piece(id=req.b.id, type=req.b.type, hp=req.b.hp, atk=req.b.atk, defn=req.b.defn, spd=req.b.spd)
    winner = eng.duel(a, b)
    return DuelResult(winner_id=winner, details="Duelos prototipo a 3 rondas + desempate.")
EOF

cat > backend/app/main.py <<'EOF'
from fastapi import FastAPI
from app.routers import match
from app.config import settings

app = FastAPI(title="Chess RPG API", version="0.1.0")

@app.get("/health")
def health():
    return {"status": "ok", "env": settings.app_env}

app.include_router(match.router)
EOF

mkdir -p backend/tests
cat > backend/tests/test_health.py <<'EOF'
from fastapi.testclient import TestClient
from app.main import app

def test_health_ok():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
EOF

# Frontend
cat > frontend/Dockerfile <<'EOF'
FROM node:20-slim
WORKDIR /usr/src/app
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
RUN npm install || true
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]
EOF

cat > frontend/package.json <<'EOF'
{
  "name": "chess-rpg-frontend",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173 --strictPort"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.22",
    "typescript": "^5.4.0",
    "vite": "^5.2.0"
  }
}
EOF

cat > frontend/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true
  }
}
EOF

cat > frontend/vite.config.ts <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true
  }
})
EOF

cat > frontend/index.html <<'EOF'
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Ajedrez RPG</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

cat > frontend/src/main.tsx <<'EOF'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
EOF

cat > frontend/src/api.ts <<'EOF'
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
EOF

cat > frontend/src/App.tsx <<'EOF'
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
EOF

echo "✅ Estructura creada."
