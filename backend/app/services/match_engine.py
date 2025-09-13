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
