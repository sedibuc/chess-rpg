from fastapi import FastAPI
from app.routers import match
from app.config import settings

app = FastAPI(title="Chess RPG API", version="0.1.0")

@app.get("/health")
def health():
    return {"status": "ok", "env": settings.app_env}

app.include_router(match.router)
