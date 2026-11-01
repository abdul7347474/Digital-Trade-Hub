# Digital Trade Hub — Starter MVP

A starter project for an Android-first digital services and referral marketplace.

## Included
- Flutter app source (email/password sign-up and sign-in, browse listings, create referral requests/listings, submit manual payment reference)
- Supabase PostgreSQL schema with Row Level Security (RLS)
- Admin web panel (approve listings/requests, view matches and payment submissions)
- Setup guide, environment checklist, and security notes

## Important scope and safety
This project is a **working MVP foundation**, not a finished audited production system.
- It is designed for legitimate digital services and official exchange referral links/offers.
- It does **not** support buying/selling/transferring Facebook, Instagram, LinkedIn, NayaPay, SadaPay, or exchange login accounts.
- Do not collect passwords, OTPs, recovery codes, API secrets, or identity documents in marketplace listings.
- Exchange referral participation must follow the exchange's current eligibility, age, regional, and promotion rules.
- Payment is **manual-record mode** in this starter. A payment reference is recorded for admin review; no money is collected or verified automatically.
- Live JazzCash/Easypaisa payments require merchant onboarding, provider-issued credentials, server-side integration, and testing. Never put secret keys in the app.
- Have the app, privacy policy, payment flow, and marketplace terms reviewed before public launch.

## Quick start

### 1) Install tools
Install Flutter SDK, Android Studio, Android SDK, Git, and create a Supabase project.

### 2) Create Flutter platform scaffolding
From this folder:
```bash
flutter create --org com.digitaltradehub --project-name digital_trade_hub .
```
If prompted about overwriting files, keep this project's `lib/` and `pubspec.yaml`. The command creates the Android/iOS/web platform folders.

### 3) Install dependencies
```bash
flutter pub get
```

### 4) Configure Supabase
In Supabase Dashboard:
- Create a project.
- Open SQL Editor and run `supabase/schema.sql`.
- In Authentication settings, enable Email provider.
- Create a Storage bucket named `payment-proofs` (private).
- Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `lib/main.dart` or pass them at build time.

Recommended build command:
```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

The anon/publishable key is intended for client apps when RLS is correctly configured. **Never use the service-role key in Flutter or browser code.**

### 5) Create an admin user
- Register a normal user through the app.
- In Supabase SQL Editor, run:
```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'YOUR_ADMIN_EMAIL');
```
Replace the email. Only trusted owners should be admins.

### 6) Open admin panel
Open `admin/index.html` through a local static server (not by double-clicking if the browser blocks modules):
```bash
cd admin
python -m http.server 8080
```
Visit `http://localhost:8080`. Enter the Supabase URL and anon key, then sign in with the admin account.

### 7) Build APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```
APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Suggested launch sequence
1. Run locally and test with two test accounts.
2. Test listing/request moderation and matching.
3. Test manual payment reference workflow with no real funds.
4. Obtain merchant approval and official JazzCash/Easypaisa API documentation.
5. Implement payment initiation and server-side callback verification in a Supabase Edge Function or trusted backend.
6. Add privacy policy, terms, refund/dispute rules, support contact, and security review.
7. Only then consider public release.

## Folder map
- `lib/` Flutter app
- `supabase/schema.sql` database schema, RLS, matching trigger, storage policies
- `admin/` minimal admin web panel
- `docs/` setup, security, API checklist
