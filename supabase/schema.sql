-- Digital Trade Hub MVP schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.app_role as enum ('user', 'admin');
create type public.listing_status as enum ('pending', 'approved', 'rejected', 'suspended');
create type public.listing_kind as enum ('service', 'referral');
create type public.request_kind as enum ('service', 'referral');
create type public.request_status as enum ('pending', 'approved', 'matched', 'rejected', 'closed');
create type public.payment_method as enum ('jazzcash', 'easypaisa');
create type public.payment_status as enum ('submitted', 'under_review', 'verified', 'rejected', 'refunded');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role public.app_role not null default 'user',
  created_at timestamptz not null default now()
);

create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 4 and 100),
  description text not null check (char_length(description) between 10 and 3000),
  listing_type public.listing_kind not null,
  platform text not null,
  price_amount numeric(12,2) check (price_amount is null or price_amount >= 0),
  price_currency text not null default 'PKR',
  official_url text,
  status public.listing_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint no_account_transfer_words check (
    lower(title || ' ' || description) not like '%sell account%'
    and lower(title || ' ' || description) not like '%buy account%'
    and lower(title || ' ' || description) not like '%password%'
    and lower(title || ' ' || description) not like '%otp%'
  )
);

create table public.referral_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  request_type public.request_kind not null default 'referral',
  notes text not null default '',
  status public.request_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.referral_requests(id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  provider_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'suggested' check (status in ('suggested','accepted','declined','completed','cancelled')),
  created_at timestamptz not null default now(),
  unique(request_id, listing_id)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete set null,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount >= 0),
  currency text not null default 'PKR',
  status text not null default 'created' check (status in ('created','awaiting_payment','paid_pending_review','in_progress','completed','cancelled','disputed')),
  created_at timestamptz not null default now()
);

create table public.payment_submissions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  payer_id uuid not null references public.profiles(id) on delete cascade,
  method public.payment_method not null,
  amount numeric(12,2) not null check (amount > 0),
  transaction_reference text not null,
  status public.payment_status not null default 'submitted',
  admin_note text,
  created_at timestamptz not null default now()
);

create table public.commissions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  beneficiary_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount >= 0),
  currency text not null default 'PKR',
  status text not null default 'pending' check (status in ('pending','approved','paid','cancelled')),
  created_at timestamptz not null default now()
);

create index listings_status_type_platform_idx on public.listings(status, listing_type, platform);
create index referral_requests_status_platform_idx on public.referral_requests(status, platform);
create index matches_requester_idx on public.matches(requester_id);
create index matches_provider_idx on public.matches(provider_id);
create index payments_status_idx on public.payment_submissions(status);

-- Auto-match only after an admin approves a request.
create function public.match_approved_request()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.status = 'approved' and old.status is distinct from new.status then
    insert into public.matches(request_id, listing_id, requester_id, provider_id)
    select new.id, l.id, new.requester_id, l.seller_id
    from public.listings l
    where l.status = 'approved'
      and l.listing_type::text = new.request_type::text
      and lower(l.platform) = lower(new.platform)
      and l.seller_id <> new.requester_id
    on conflict (request_id, listing_id) do nothing;

    if exists(select 1 from public.matches where request_id = new.id) then
      update public.referral_requests set status = 'matched' where id = new.id;
    end if;
  end if;
  return new;
end;
$$;

create trigger on_request_approved
after update of status on public.referral_requests
for each row execute procedure public.match_approved_request();

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.referral_requests enable row level security;
alter table public.matches enable row level security;
alter table public.orders enable row level security;
alter table public.payment_submissions enable row level security;
alter table public.commissions enable row level security;

create policy "profiles readable by signed in users" on public.profiles for select to authenticated using (true);
create policy "users update own basic profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = (select role from public.profiles p where p.id = auth.uid()));

create policy "approved listings public to signed in" on public.listings for select to authenticated using (status = 'approved' or seller_id = auth.uid() or public.is_admin());
create policy "users create own pending listings" on public.listings for insert to authenticated with check (seller_id = auth.uid() and status = 'pending');
create policy "seller edits own pending listing" on public.listings for update to authenticated using (seller_id = auth.uid() and status = 'pending') with check (seller_id = auth.uid() and status = 'pending');
create policy "admin manages listings" on public.listings for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "requester sees own requests or admin" on public.referral_requests for select to authenticated using (requester_id = auth.uid() or public.is_admin());
create policy "user creates own pending request" on public.referral_requests for insert to authenticated with check (requester_id = auth.uid() and status = 'pending');
create policy "admin manages requests" on public.referral_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "match parties or admin see matches" on public.matches for select to authenticated using (requester_id = auth.uid() or provider_id = auth.uid() or public.is_admin());
create policy "admin manages matches" on public.matches for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "order parties or admin see orders" on public.orders for select to authenticated using (buyer_id = auth.uid() or seller_id = auth.uid() or public.is_admin());
create policy "buyer creates order" on public.orders for insert to authenticated with check (buyer_id = auth.uid());
create policy "admin manages orders" on public.orders for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "payer sees own payment or admin" on public.payment_submissions for select to authenticated using (payer_id = auth.uid() or public.is_admin());
create policy "payer submits own payment reference" on public.payment_submissions for insert to authenticated with check (payer_id = auth.uid() and status = 'submitted');
create policy "admin manages payment submissions" on public.payment_submissions for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "beneficiary or admin sees commissions" on public.commissions for select to authenticated using (beneficiary_id = auth.uid() or public.is_admin());
create policy "admin manages commissions" on public.commissions for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Private payment proof storage bucket. Optional proof uploads; avoid uploading sensitive documents.
insert into storage.buckets (id, name, public) values ('payment-proofs', 'payment-proofs', false)
on conflict (id) do nothing;
create policy "users upload own payment proof folder" on storage.objects
for insert to authenticated with check (bucket_id = 'payment-proofs' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users read own payment proof folder or admin" on storage.objects
for select to authenticated using (bucket_id = 'payment-proofs' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
