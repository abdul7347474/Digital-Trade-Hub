# MVP test plan

1. Register Buyer A and Provider B using separate test emails.
2. Promote a dedicated test admin account to `admin` using the SQL in README.
3. Provider B creates an approved-eligible service/referral listing; verify it appears as pending and is not public.
4. Admin signs into `admin/index.html`, approves the listing.
5. Buyer A creates a referral request for the same platform/type.
6. Admin approves the request; verify a match row is created automatically for matching approved listings.
7. Verify a user cannot read another user's payment submissions or private data.
8. Verify a normal user cannot approve their own listing/request or change their role.
9. Test rejected and suspended listings.
10. Do not test real payments until merchant sandbox credentials and server-side callback verification exist.
