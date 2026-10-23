# Alathar on the web (Firebase Hosting)

https://alathar-14555.web.app — Firebase project **alathar-14555**

- `/` — the Alathar app itself (Flutter web, built from this repository)
- `/support` — about + support page (Apple "Support URL", Google "Website")
- `/privacy` — privacy policy (both stores' "Privacy policy URL")

`.github/workflows/firebase-hosting.yml` builds `flutter build web`, adds the
pages from `website/public` and deploys, on every push to `main` that changes
the app or the website. It needs the GitHub secret
`FIREBASE_SERVICE_ACCOUNT_ALATHAR_14555`.

Manual deploy from a PC with Flutter and the Firebase CLI:

    flutter build web --release
    rmdir /s /q website\dist & mkdir website\dist
    xcopy /e /i build\web website\dist
    copy website\public\*.html website\dist\ & xcopy /e /i website\public\site website\dist\site
    cd website && firebase deploy --only hosting
