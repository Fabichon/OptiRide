from __future__ import annotations
from enum import StrEnum
from pydantic import BaseModel, Field, ConfigDict
from typing import Literal, Optional
from datetime import datetime, timezone

class ProviderId(StrEnum):
    uber = "uber"
    bolt = "bolt"
    freenow = "freenow"
    heetch = "heetch"

class VehicleClass(StrEnum):
    economy = "economy"
    comfort = "comfort"
    premium = "premium"
    van = "van"

class SearchParams(BaseModel):
    origin: str = Field(..., description="Adresse de départ brute")
    destination: str = Field(..., description="Adresse d'arrivée brute")
    vehicle_classes: Optional[list[VehicleClass]] = Field(default=None, description="Filtre classes de véhicule")

class RideOffer(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    provider: ProviderId
    vehicle_class: VehicleClass = Field(alias="vehicleClass")
    estimated_price: float = Field(alias="estimatedPrice", ge=0)
    currency: Literal["EUR"] = "EUR"
    eta_driver_sec: int = Field(alias="etaDriverSec", ge=0)
    generated_at: datetime = Field(alias="generatedAt")

    def to_public_dict(self) -> dict:
        d = self.model_dump(by_alias=True)
        d["generatedAt"] = self.generated_at.astimezone(timezone.utc).isoformat()
        return d

class ProvidersResponse(BaseModel):
    providers: list[ProviderId]

class OffersResponse(BaseModel):
    offers: list[RideOffer]
    count: int
    generated_at: datetime = Field(alias="generatedAt")

    def to_public_dict(self) -> dict:
        return {
            "offers": [o.to_public_dict() for o in self.offers],
            "count": self.count,
            "generatedAt": self.generated_at.astimezone(timezone.utc).isoformat(),
        }
