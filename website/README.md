# Alathar website (Firebase Hosting)

Static pages for the stores:
- `/` — about + support (Apple "Support URL", Google "Website")
- `/privacy` — privacy policy (Google Play and App Store "Privacy policy URL")

Hosted on Firebase project **alathar-14555** → https://alathar-14555.web.app

Deploys automatically from GitHub (`.github/workflows/firebase-hosting.yml`) on every
push to `main` that changes `website/`. Manual deploy from this folder:
`firebase deploy --only hosting`.
