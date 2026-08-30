-- ============================================================
-- PalMed Deutschland – Mitgliederportal
-- Einmalig im Supabase SQL-Editor ausführen (Projekt > SQL Editor)
-- ============================================================

-- ---------- Profile (wird bei Registrierung automatisch angelegt) ----------
create table if not exists profile (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  vorname text default '',
  nachname text default '',
  ort text default '',
  telefon text default '',
  berufsgruppe text default '',
  fachrichtung text default '',
  benachrichtigungen boolean default true,
  erstellt timestamptz default now()
);

-- ---------- Administratoren ----------
create table if not exists admins (
  id uuid primary key references auth.users (id) on delete cascade
);

-- Hilfsfunktion: ist der angemeldete Nutzer Admin?
create or replace function ist_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (select 1 from admins where id = auth.uid());
$$;

-- ---------- Bescheinigungs-Anträge ----------
create table if not exists antraege (
  id bigint generated always as identity primary key,
  mitglied uuid not null references auth.users (id) on delete cascade,
  art text not null check (art in ('Spendenbescheinigung', 'Beitragsbescheinigung')),
  jahr int not null,
  betrag text default '',
  anschrift text not null,
  anmerkung text default '',
  status text not null default 'offen' check (status in ('offen', 'genehmigt', 'abgelehnt')),
  kommentar text default '',
  erstellt timestamptz default now(),
  entschieden timestamptz
);

-- ---------- Projekt-Beteiligungen ----------
create table if not exists beteiligungen (
  id bigint generated always as identity primary key,
  mitglied uuid not null references auth.users (id) on delete cascade,
  projekt text not null,
  nachricht text default '',
  erstellt timestamptz default now()
);

-- ---------- Stellenbörse ----------
create table if not exists stellen (
  id bigint generated always as identity primary key,
  mitglied uuid not null references auth.users (id) on delete cascade,
  typ text not null check (typ in ('Stellenangebot', 'Stellengesuch')),
  titel text not null,
  ort text default '',
  beschreibung text not null,
  kontakt text not null,
  erstellt timestamptz default now()
);

-- ---------- Profil automatisch anlegen ----------
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into profile (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------- Zugriffsregeln (Row Level Security) ----------
alter table profile enable row level security;
alter table admins enable row level security;
alter table antraege enable row level security;
alter table beteiligungen enable row level security;
alter table stellen enable row level security;

-- Profile: jeder sieht/ändert nur sich selbst, Admins sehen alle
create policy "profil_lesen" on profile for select
  using (auth.uid() = id or ist_admin());
create policy "profil_aendern" on profile for update
  using (auth.uid() = id) with check (auth.uid() = id);

-- Admins-Tabelle: nur lesbar (jeder darf prüfen, ob er selbst Admin ist)
create policy "admin_selbst_pruefen" on admins for select
  using (auth.uid() = id);

-- Anträge: Mitglied stellt & sieht eigene, Admin sieht & entscheidet alle
create policy "antrag_stellen" on antraege for insert
  with check (auth.uid() = mitglied);
create policy "antrag_lesen" on antraege for select
  using (auth.uid() = mitglied or ist_admin());
create policy "antrag_entscheiden" on antraege for update
  using (ist_admin());

-- Beteiligungen: Mitglied meldet & sieht eigene, Admin sieht alle
create policy "beteiligung_anlegen" on beteiligungen for insert
  with check (auth.uid() = mitglied);
create policy "beteiligung_lesen" on beteiligungen for select
  using (auth.uid() = mitglied or ist_admin());

-- Stellenbörse: alle angemeldeten Mitglieder sehen alles,
-- jeder verwaltet nur eigene Einträge (Admin darf löschen)
create policy "stellen_lesen" on stellen for select
  using (auth.role() = 'authenticated');
create policy "stellen_anlegen" on stellen for insert
  with check (auth.uid() = mitglied);
create policy "stellen_loeschen" on stellen for delete
  using (auth.uid() = mitglied or ist_admin());

-- ============================================================
-- NACH dem Ausführen: sich selbst zum Admin machen.
-- 1. Einmal im Portal anmelden (mitglieder.html)
-- 2. Dann hier ausführen (E-Mail anpassen):
--
-- insert into admins (id)
-- select id from auth.users where email = 'info@palmeddeutschland.de';
-- ============================================================
