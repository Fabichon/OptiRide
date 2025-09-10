# OptiRide API Simulator

Mock REST & SSE API (FastAPI) pour alimenter l'app Flutter en données de test.

## Endpoints

- `GET /health` -> `{ "status": "ok" }`
- `GET /providers` -> `{ "providers": ["uber", "bolt", ...] }`
- `GET /offers?origin=PARIS&destination=LYON&vehicleClass=economy&vehicleClass=van`
- `GET /offers/stream?origin=PARIS&destination=LYON&interval_sec=15` (Server Sent Events)
- `POST /offers` (body JSON SearchParams)

### Format `RideOffer`
```json
{
  "provider": "uber",
  "vehicleClass": "economy",
  "estimatedPrice": 23.40,
  "currency": "EUR",
  "etaDriverSec": 240,
  "generatedAt": "2025-09-08T11:22:33.123Z"
}
```

### SearchParams (POST /offers)
```json
{
  "origin": "Paris Gare de Lyon",
  "destination": "La Défense",
  "vehicle_classes": ["economy", "van"]
}
```

## Installation locale

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r api_simulator/requirements.txt
uvicorn api_simulator.main:app --reload --port 8081
```

## Exemples curl
```powershell
curl http://localhost:8081/health
curl "http://localhost:8081/offers?origin=PARIS&destination=LYON"
```

## Notes
- Génération pseudo-déterministe basée sur la requête.
- Tri par prix puis ETA.
- SSE: chaque payload complet envoyé toutes les `interval_sec` secondes.
