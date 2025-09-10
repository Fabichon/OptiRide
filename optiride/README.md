# OptiRide

Comparateur VTC (inspiré fonctionnellement d'applis françaises de type OBI) affichant des offres simulées (mock) multi-fournisseurs.

## Objectif
Saisir une adresse de départ et de destination, afficher une liste d'offres (prix estimé, ETA chauffeur, classe véhicule) puis ouvrir l'app fournisseur via deeplink (mock pour l'instant).

## Statut
MVP local hors production. Données 100% simulées via `MockQuoteProvider`. Aucun prix réel, aucune API partenaire.

## Stack
- Flutter 3.35+
- Dart 3.9+
- Navigation: GoRouter
- State: Riverpod
- Material 3 (thème clair/sombre)
- Services prévus: geolocator, google_maps_flutter (carte plus tard), url_launcher (deeplinks)

## Domain
Modèles principaux:
- `SearchQuery`
- `RideOffer`
- `ProviderId`
- `VehicleClass`

## Données & Rafraîchissement
`QuoteProvider` (interface) → `MockQuoteProvider` émet un flux rafraîchi toutes les 30s. Génération pseudo-aléatoire triée par prix.

## Lancement
```
flutter pub get
flutter run -d windows   # test logique rapide desktop
flutter run -d android   # test mobile + plugins (géoloc, deeplinks, carte)
```

## Sécurité / Secrets
Pas de clés API dans le repo. Ajouter ultérieurement un fichier `.env` (non versionné) si intégrations réelles.

## Roadmap (extraits)
- Intégrer vrai moteur de géocodage (Places / Photon / etc.)
- Affichage carte + positions estimées.
- Implémenter deeplinks spécifiques par fournisseur avec paramètres.
- Gestion favoris / historiques.

## Avertissements
Projet expérimental. N'utilise aucune donnée propriétaire. Toute similarité visuelle avec des services existants doit être évitée.

## Licence
Non spécifiée (par défaut tous droits réservés tant que la licence n'est pas ajoutée).

## API Simulateur externe

Un simulateur FastAPI facultatif est fourni dans `api_simulator/`.

Lancer (port 8081 par défaut) :
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r api_simulator/requirements.txt
uvicorn api_simulator.main:app --reload --port 8081
```

L'application Flutter tente un health-check `GET /health` :
- Succès → utilisation `ApiQuoteProvider` (SSE tenté d'abord `/offers/stream`, fallback polling 20s)
- Échec → fallback `MockQuoteProvider`

Pour désactiver SSE temporairement : passer `enableSse: false` lors de la création d'`ApiQuoteProvider` (adapter dans `quoteProviderImpl`).

Android Emulator: remplacer `localhost` par `10.0.2.2` (adapter `apiBaseUrlProvider`).

Paramètres SSE / retry (côté `ApiQuoteProvider`) :
- `enableSse` (bool, défaut true)
- `maxSseRetries` (défaut 5)
- `baseBackoff` (défaut 2s, exponentiel avec jitter jusqu'à ~2s * 2^(n-1) + 400ms)

Si toutes les tentatives échouent → bascule silencieuse sur polling.

### Cartographie & Autocomplete

La clé Google Maps/Places n'est **pas** committée. Fournir à l'exécution :

```powershell
flutter run -d android --dart-define=MAPS_API_KEY=VOTRE_CLE
```

Providers ajoutés :
- `mapsApiKeyProvider` lit `String.fromEnvironment('MAPS_API_KEY')`
- `currentPositionProvider` (géoloc)
- `placeSuggestionsProvider` (autocomplete + debounce 350ms)

Widgets :
- `SearchMap` (tap pour définir le départ -> remplit champ "Départ")
- `DestinationAutocompleteField` (overlay suggestions Places)

Aucune persistance encore des coordonnées; le champ départ reçoit lat,lng formatés.

---
