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
