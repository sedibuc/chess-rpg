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
