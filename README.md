# Schedule App

A lightweight Flutter client for viewing and exporting school schedules. This repository contains the UI client only — intended for private use. The app connects directly to a Supabase project from the client using a `.env` file. Do not use this repository to host secrets publicly.

## Quick start

Prerequisites:

- Flutter SDK (stable)
- Python 3 (for the local static server used by PWA helpers)
- Supabase project (see [schema](./schema.sql))

Run locally (development):

```bash
flutter pub get
flutter run -d chrome
```

Build a release web bundle:

```bash
flutter build web --release
```

Serve the built web folder locally (quick check / PWA test):

```bash
# from repo root
python3 -m http.server 8000 --directory build/web
```

## Installation

This repo includes convenience scripts to run the static `build/web` on macOS and Linux at user login.

- Dispatcher: `scripts/install.sh` detects your OS and target and calls the appropriate installer. Use `--target web|native` and `--uninstall` flags.

Examples:

```bash
# Install web PWA auto-start for current OS
./scripts/install.sh --target web

# Uninstall
./scripts/install.sh --target web --uninstall
```

## Security & secrets (important)

This app reads Supabase credentials from a `.env` file at runtime (client-side). That means the anon/service keys are present in client code if you bundle `.env` into assets. This repository is intended as a private client-only tool. Important recommendations:

- Never publish `.env` with real credentials to a public repo.
- If keys are exposed, rotate them immediately in the Supabase dashboard.
- Prefer storing secrets in a trusted server-side backend or use environment injection in build/CI (do not embed service keys into public builds).

## Troubleshooting

- If `flutter run` or `flutter build web` fails: ensure your Flutter SDK is up to date and run `flutter doctor`.
- If the PWA auto-start service doesn't launch:
  - macOS: check `~/Library/Logs/com.schedule_app.pwa-server.log` and `.err`; ensure `python3` is in your PATH for launchd or update the helper to use an absolute path.
  - Linux: check `journalctl --user -u schedule_app_pwa_server.service` for logs.
- If PDF download doesn't start on web, open DevTools Console for errors and make sure `build/web/flutter_service_worker.js` and `manifest.json` exist in the web bundle.

## Contributing

Open an issue or submit a PR :)
