from __future__ import annotations
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from models import Offer, OffersResponse
from utils import generate_offers

app = FastAPI(title="OptiRide API Simulator", version="0.1.0")

# CORS: autoriser l'app mobile/web locale
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # à restreindre en prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/offers", response_model=OffersResponse)
async def get_offers(
    departure: str = Query(..., description="Adresse ou coordonnées GPS du départ"),
    destination: str = Query(..., description="Adresse ou coordonnées GPS de la destination"),
):
    offers = generate_offers(departure, destination)
    return OffersResponse(offers=offers)

# Docs Swagger accessibles sur /docs par défaut

# Démarrer: uvicorn main:app --reload --port 8081
