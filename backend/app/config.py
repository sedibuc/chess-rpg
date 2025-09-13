from pydantic import BaseModel
import os

class Settings(BaseModel):
    app_env: str = os.getenv("APP_ENV", "dev")
    rng_seed: int | None = None  # Semilla global opcional

settings = Settings()
