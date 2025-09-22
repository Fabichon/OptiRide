from __future__ import annotations
from pydantic import BaseModel, Field

class Offer(BaseModel):
    platform: str
    price: float = Field(ge=0)
    waiting_time: int = Field(ge=0, description="Minutes d'attente")
    duration: int = Field(ge=0, description="Durée du trajet en minutes")

class OffersResponse(BaseModel):
    offers: list[Offer]
