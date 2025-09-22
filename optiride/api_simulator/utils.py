from __future__ import annotations
import random
from typing import List
from models import Offer

PLATFORMS = ["Uber", "Bolt", "Heetch"]


def generate_offers(departure: str, destination: str) -> List[Offer]:
    # Seed semi-déterministe pour que les retours restent cohérents pour une même requête
    seed = hash((departure.strip().lower(), destination.strip().lower())) & 0xFFFFFFFF
    r = random.Random(seed)

    offers: list[Offer] = []
    for platform in PLATFORMS:
        price = round(r.uniform(10.0, 30.0), 2)
        waiting = r.randint(1, 10)
        duration = r.randint(10, 30)
        offers.append(Offer(platform=platform, price=price, waiting_time=waiting, duration=duration))
    # Optionnel: trier par prix croissant pour un rendu stable
    offers.sort(key=lambda o: (o.price, o.waiting_time))
    return offers
