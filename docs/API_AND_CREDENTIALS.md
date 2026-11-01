# API and credentials checklist

## Supabase
1. Create a project at https://supabase.com/
2. Copy Project URL and anon/publishable key.
3. Run `supabase/schema.sql`.
4. Never expose the service-role key in Flutter, admin browser code, GitHub, or screenshots.

## JazzCash and Easypaisa
This starter does not process live payments. To enable them:
1. Apply for a merchant account directly with the provider.
2. Ask for the current merchant API/integration documentation for your business model.
3. Obtain sandbox credentials first, if offered.
4. Implement payment initiation and callback/webhook verification on a trusted server (e.g. Supabase Edge Function).
5. Verify signatures, amount, currency, merchant ID, transaction status, duplicate callbacks, and order ownership server-side.
6. Only update an order to paid after verified provider callback. Never trust a screenshot or a client-side success message.
7. Ask each provider about fees, settlement times, refunds, chargebacks, and business eligibility.

Do not share merchant secret keys in chat or put them in the mobile app.

## Exchange referral programs
Use only official affiliate/referral dashboards and URLs:
- Binance: https://www.binance.com/
- OKX: https://www.okx.com/
- Bitget: https://www.bitget.com/
- Gate.io: https://www.gate.io/

Availability, reward rules, country eligibility, age requirements, and promotional terms change. Admin should manually verify each link and record the last-checked date. Do not ask users for exchange passwords, OTPs, API keys, or account access.

## Firebase
Use Firebase Console to create a project if push notifications are added later. Configure Android app package name and download `google-services.json`. This MVP does not yet implement push notifications.
