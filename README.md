# hkgalden_flutter

A mobile client for [hkGalden](https://hkgalden.com), a Hong Kong online forum, built with Flutter. The UI is Traditional Chinese (zh-Hant, HK).

## Features

- Browse and paginate forum threads and channels via a slide-out drawer
- Read threads and replies, with rich HTML-rendered content
- Last-read / reading-position restore, keep-alive and load-more footers
- Pull to load the previous page of a thread
- Reply directly in a thread; compose posts with a rich text editor (Flutter Quill)
- A toggleable smiley keyboard in the compose editor
- User profiles, user thread lists, and a blocked-users list
- Link previews for X (Twitter) and YouTube under comment URLs
- Full-screen photo viewer and image upload
- Dark/gray app theme

## Tech Stack

- **State management:** `bloc` / `flutter_bloc` with `equatable`
- **Networking:** GraphQL (`graphql` client) plus `dio` / `http`; OAuth login via `flutter_web_auth_2`
- **Persistence:** Hive (auth token, thread reading positions, image aspect ratios)
- **Editor:** Flutter Quill rich text editor
- **Platforms:** Android and iOS

## Architecture

The code lives under `lib/` and is organized by responsibility:

- `networking/` — GraphQL queries/mutations and image upload (`hkgalden_api.dart`, `image_upload_api.dart`)
- `parser/` — parses forum HTML into rich content for rendering
- `models/` — domain models (Thread, Reply, Channel, User, Tag, Smiley, etc.) and UI-state models
- `repository/` — per-domain data access (channel, thread, thread list, session user, blocked users, ...)
- `bloc/` — one bloc/cubit per domain
- `ui/` — feature screens (`home`, `thread`, `user_detail`) plus shared widgets (`common`)

## Getting Started

Requires Flutter 3.47 (Dart 3.13; managed through [FVM](https://fvm.app) via `.fvmrc`).

1. Install dependencies:

   ```sh
   flutter pub get
   ```

2. Create a `.env` file from the template (`flutter_dotenv`) with any required API configuration.

3. Run the app:

   ```sh
   flutter run
   ```

## Testing

```sh
flutter test
```

## Building / Release

- `android-release.yml` and `ios-release.yml` GitHub Actions workflows handle Android and iOS App Store Connect release builds.
- iOS release uses local Apple signing (certificate/key tracked locally; CSR and key files are git-ignored).

## Repository Structure

- `android/`, `ios/` — platform projects
- `assets/`, `fonts/` — bundled resources
- `lib/` — application source
- `test/` — tests
