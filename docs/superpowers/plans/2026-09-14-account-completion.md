# MAREA account completion — Implementation Plan

> For agentic workers: use executing-plans to implement this plan task by task in the current session. Preserve the existing UI polish and unrelated README changes.

**Goal:** Complete welcome, account access, optional onboarding and profile customization without presenting an unconfigured service as ready for public registration.

**Architecture:** Keep Flutter, ChangeNotifier, go_router and Supabase. Add a public, versioned legal catalogue with server-enforced registration acceptance; private profile preferences and private Storage images. Auth emails support manually entered codes so Android and Web do not depend on mobile deep links.

**Spec:** The user's approved scope in this conversation: welcome, terms/privacy, verification/resend, recovery, security settings, optional interests/goals, editable social identity, avatar/cover and full account deletion.

## Constraints and launch boundary

- Preserve navy/aqua identity and the current responsive UI. No feed, recommendations engine, AR, social login or tracking.
- Mexico and 18+ were confirmed by the user. Controller identity/contact and approved legal texts remain pending user decisions. Do not invent them. Migration defaults registration to disabled; published policy is required at the server and in the form.
- Add only image_picker and url_launcher to existing runtime dependencies. Use existing native hosts and Supabase Edge Functions.
- No remote migrations, external publication or production data changes in this implementation session. Deliver remote validation instructions and state which checks ran locally.
- Existing accounts retain their data; new columns default safely. Consent is never backdated or inferred for existing accounts.

## Tasks

### 1. Domain contracts and regression coverage
- [x] Add tests for profile optional-field removal, normalized safe portfolio URLs, catalogue-limited interests/goals, and unknown onboarding status defaults.
- [x] Run `flutter test test/features/profile`; observe failures before implementing models.
- [x] Extend `Profile` / `ProfileUpdateInput` with interests, goals, onboarding status, website, avatar/cover paths and cover preset. Keep immutable server fields out of updates.
- [x] Add legal policy/consent contracts with a disabled default and tests that missing or unpublished documents cannot enable signup.

### 2. Supabase persistence, legal enforcement and media lifecycle
- [x] Add migration `002_account_completion.sql`; do not rewrite migration 001.
- [x] Store published legal documents and acceptance versions with server timestamps. Enforce registration policy in the auth user trigger and provide an authenticated acceptance RPC for existing accounts.
- [x] Add constraints and grants for profile additions, private Storage bucket, ownership validation and a durable deletion marker.
- [x] Add authenticated media Edge Function: decode validated PNG, size/pixel limits, server-generated owner path; delete only caller-owned files.
- [x] Extend delete-account to mark deletion, reject new media writes, remove caller-owned objects in batches, then delete Auth; retries resume. Document that Storage and Auth are not one transaction.

### 3. Account state and access UI
- [x] Test welcome/public legal routing, onboarding redirects, recovery precedence and duplicate-submit suppression.
- [x] Add welcome, legal documents/acceptance, confirmation codes with resend cooldown, password recovery and account-security screens.
- [x] Validate username availability inside the serialized submit operation; distinguish lookup failures from occupied names. Preserve form data after failures.
- [x] Extend session state without allowing late profile requests to restore a logged-out account. Password recovery must not be redirected to the profile before completion.

### 4. Optional onboarding and profile editing
- [x] Test skip persistence, optional-field removal and exit-with-unsaved-changes behavior; manually exercise interest selection in the isolated browser preview.
- [x] Add a short interests/goals onboarding with skip, back and resume from settings. Save only explicit selections, no sensitive categories.
- [x] Add avatar/cover selection, preview, remove/reset, portfolio and interests/goals editing. Discard staged media on cancellation; preserve old media until profile save succeeds.
- [x] Display saved images and portfolio links safely; keep email/security separate from the social profile.

### 5. Verification and handoff
- [x] Update isolated visual preview fixtures, legal/setup documentation and email templates. Mark sample documents as nonproduction.
- [x] Run `dart format`, `flutter analyze`, `flutter test`, Edge Function tests/checks, `flutter build web` and Android debug build when local SDK permits.
- [x] Inspect welcome/register/onboarding/profile in the browser; run all new account screens through six responsive sizes and fix layout failures.
- [x] Deliver exact configuration/deployment steps and unresolved legal/remote verification gates. Do not claim remote checks passed without running them.

## Verified outcome — 2026-09-14

- Local implementation complete; no hosted migrations, functions or legal documents were published.
- Flutter analyzer clean; 62 Flutter tests, 33 isolated PostgreSQL assertions and 3 image-function tests passed. Deno checks passed. Web and Android debug builds succeeded.
- Browser preview exercised login, optional onboarding, profile editing and save. Responsive tests cover 360, 390, 600, 1024, 1366 and 1440 px widths. Fixed the profile type dropdown overflow on small screens.
- Remaining release gates are documented in `docs/account-completion.md`: approved legal texts and controller contact, Supabase migration/functions, SMTP/templates, two-account remote checks and interactive Android testing. Self-declared age is not identity verification.
