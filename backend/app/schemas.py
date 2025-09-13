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
