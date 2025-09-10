from __future__ import annotations
import random
from datetime import datetime, timezone
from typing import Iterable
from models import RideOffer, ProviderId, VehicleClass

PROVIDERS = [p for p in ProviderId]

class OfferGenerator:
    def __init__(self, seed: int | None = None):
        self._base_random = random.Random(seed)

    def _price_base(self, vehicle_class: VehicleClass) -> float:
        base = {
            VehicleClass.economy: 8.0,
            VehicleClass.comfort: 11.0,
            VehicleClass.premium: 17.0,
            VehicleClass.van: 14.0,
        }[vehicle_class]
        return base

    def generate_offers(self, origin: str, destination: str, vehicle_classes: list[VehicleClass] | None = None) -> list[RideOffer]:
        distance_km = max(1.0, min(30.0, len(origin + destination) / 5.0))  # fake heuristic
        offers: list[RideOffer] = []
        classes = vehicle_classes or [c for c in VehicleClass]
        for provider in PROVIDERS:
            for vc in classes:
                r = random.Random(self._base_random.random() + hash((origin, destination, provider, vc)) % 10_000)
                surge = r.uniform(0.9, 1.6)
                price = round((self._price_base(vc) + distance_km * r.uniform(0.8, 1.4)) * surge, 2)
                eta = int(r.uniform(2, 12) * 60)  # seconds
                offers.append(RideOffer(
                    provider=provider,
                    vehicleClass=vc,
                    estimatedPrice=price,
                    etaDriverSec=eta,
                    generatedAt=datetime.now(timezone.utc),
                ))
        offers.sort(key=lambda o: (o.estimated_price, o.eta_driver_sec))
        return offers
