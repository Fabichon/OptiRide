from __future__ import annotations
from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse, StreamingResponse
from models import ProvidersResponse, OffersResponse, SearchParams, VehicleClass
from offer_generator import OfferGenerator, PROVIDERS
from datetime import datetime, timezone
import asyncio
import json

app = FastAPI(title="OptiRide Mock API", version="0.1.0")
generator = OfferGenerator()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/providers", response_model=ProvidersResponse)
async def providers():
    return ProvidersResponse(providers=PROVIDERS)

@app.get("/offers")
async def offers(origin: str = Query(...), destination: str = Query(...), vehicle_class: list[VehicleClass] | None = Query(default=None, alias="vehicleClass")):
    offers = generator.generate_offers(origin, destination, vehicle_class)
    resp = OffersResponse(offers=offers, count=len(offers), generatedAt=datetime.now(timezone.utc))
    return JSONResponse(resp.to_public_dict())

@app.get("/offers/stream")
async def offers_stream(origin: str, destination: str, interval_sec: int = 15, vehicle_class: list[VehicleClass] | None = Query(default=None, alias="vehicleClass")):
    async def event_gen():
        while True:
            offers = generator.generate_offers(origin, destination, vehicle_class)
            payload = OffersResponse(offers=offers, count=len(offers), generatedAt=datetime.now(timezone.utc)).to_public_dict()
            yield f"data: {json.dumps(payload)}\n\n"
            await asyncio.sleep(interval_sec)
    return StreamingResponse(event_gen(), media_type="text/event-stream")

@app.post("/offers")
async def offers_post(params: SearchParams):
    offers = generator.generate_offers(params.origin, params.destination, params.vehicle_classes)
    resp = OffersResponse(offers=offers, count=len(offers), generatedAt=datetime.now(timezone.utc))
    return JSONResponse(resp.to_public_dict())

# Run: uvicorn main:app --reload --port 8081
