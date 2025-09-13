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
