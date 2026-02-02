# Repository Guidelines

## Project Structure & Module Organization
- `MomentumBar/`: macOS app source (SwiftUI). Key areas: `App/`, `Core/`, `Features/`, `Models/`, `Services/`, `Assets.xcassets`.
- `MomentumBarWidget/`: widget extension sources.
- `MomentumBarTests/` and `MomentumBarUITests/`: test targets.
- `backend/`: Node/Express license server (`src/`, `email-templates/`).
- `website/`: Next.js marketing site (`src/`, Tailwind config).
- `Shortcuts/`: prebuilt macOS Shortcuts assets.

## Build, Test, and Development Commands
- macOS app: open `MomentumBar.xcodeproj` in Xcode and run the `MomentumBar` scheme.
- CLI build/test (macOS): `xcodebuild -scheme MomentumBar -destination 'platform=macOS' test`.
- Backend dev server: `cd backend && npm run dev` (nodemon).
- Backend prod run: `cd backend && npm start`.
- Backend DB bootstrap: `cd backend && npm run db:init`.
- Website dev: `cd website && npm run dev`.
- Website build/start: `cd website && npm run build` then `npm run start`.
- Website lint: `cd website && npm run lint`.

## Coding Style & Naming Conventions
- Swift: 4-space indentation, no trailing whitespace; follow existing SwiftUI patterns in `MomentumBar/`.
- TypeScript/React (website): 2-space indentation, no semicolons (match `website/src/app/*`).
- JavaScript (backend): 4-space indentation; prefer `const`/`let`, module-level `require` at top.
- Naming: Swift types in `UpperCamelCase`, functions/vars in `lowerCamelCase`; React components in `UpperCamelCase`.

## Testing Guidelines
- Swift tests use the Swift Testing framework (`import Testing`, `#expect`). Place new tests in `MomentumBarTests/` and name test types by feature (e.g., `TimeZoneServiceTests`).
- UI tests live in `MomentumBarUITests/`.
- Website: use `npm run lint` as the default quality gate (no dedicated test runner present).
- Backend: no automated tests currently; add tests alongside `backend/src/` if you introduce a framework.

## Commit & Pull Request Guidelines
- Commit history mixes conventional commits (`feat:`, `fix:`) and plain messages; prefer conventional commit prefixes with concise, imperative subjects.
- Keep commits scoped (app vs backend vs website) and avoid “commit”/“fixes” as standalone messages.
- PRs should include a brief summary, linked issue (if any), and screenshots or screen recordings for UI changes (SwiftUI or website).

## Security & Configuration Tips
- Backend requires environment variables (Dodo Payments keys, DB URL, email settings). Use a local `.env` in `backend/` and keep secrets out of git.
