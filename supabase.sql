-- TiSpetta – tabelle nel progetto Supabase "hairagione" (prefisso ts_ per non toccare HaiRagione)
-- Il sito può solo INSERIRE righe (con limiti di lunghezza); nessuno dal sito può leggerle.
-- Le leggi tu dal pannello Supabase (Table Editor).

create table if not exists public.ts_contatti (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  email text not null unique check (char_length(email) between 5 and 254 and email like '%@%'),
  consenso_avvisi boolean not null check (consenso_avvisi),
  profilo jsonb check (profilo is null or pg_column_size(profilo) < 4000),
  fonte text check (fonte is null or char_length(fonte) <= 30)
);

create table if not exists public.ts_richieste (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  nome text not null check (char_length(nome) between 2 and 100),
  telefono text not null check (char_length(telefono) between 6 and 30),
  email text check (email is null or char_length(email) <= 254),
  messaggio text check (messaggio is null or char_length(messaggio) <= 1000),
  bando_id text check (bando_id is null or char_length(bando_id) <= 60),
  bando_nome text check (bando_nome is null or char_length(bando_nome) <= 120),
  profilo jsonb check (profilo is null or pg_column_size(profilo) < 4000),
  consenso boolean not null check (consenso),
  fonte text check (fonte is null or char_length(fonte) <= 30),
  stato text not null default 'nuova' check (stato in ('nuova', 'contattato', 'inviata_consulente', 'cliente', 'persa'))
);

create table if not exists public.ts_segnalazioni (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  messaggio text not null check (char_length(messaggio) between 3 and 2000),
  email text check (email is null or char_length(email) <= 254),
  pagina text check (pagina is null or char_length(pagina) <= 200)
);

create table if not exists public.ts_eventi (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  tipo text not null check (char_length(tipo) <= 40),
  dettaglio text check (dettaglio is null or char_length(dettaglio) <= 200),
  fonte text check (fonte is null or char_length(fonte) <= 30),
  dispositivo text check (dispositivo is null or char_length(dispositivo) <= 10)
);

alter table public.ts_contatti enable row level security;
alter table public.ts_richieste enable row level security;
alter table public.ts_segnalazioni enable row level security;
alter table public.ts_eventi enable row level security;

-- Il sito (ruolo anon) può solo inserire. Non esistono policy di lettura, modifica o cancellazione.
revoke all on public.ts_contatti, public.ts_richieste, public.ts_segnalazioni, public.ts_eventi from anon, authenticated;
grant insert on public.ts_contatti, public.ts_richieste, public.ts_segnalazioni, public.ts_eventi to anon;

drop policy if exists "ts_contatti_insert" on public.ts_contatti;
create policy "ts_contatti_insert" on public.ts_contatti for insert to anon with check (true);
drop policy if exists "ts_richieste_insert" on public.ts_richieste;
create policy "ts_richieste_insert" on public.ts_richieste for insert to anon with check (true);
drop policy if exists "ts_segnalazioni_insert" on public.ts_segnalazioni;
create policy "ts_segnalazioni_insert" on public.ts_segnalazioni for insert to anon with check (true);
drop policy if exists "ts_eventi_insert" on public.ts_eventi;
create policy "ts_eventi_insert" on public.ts_eventi for insert to anon with check (true);

-- Vista comoda per te: le richieste di aiuto più recenti (le vede solo chi entra nel pannello)
create or replace view public.ts_richieste_da_gestire with (security_invoker = true) as
  select created_at, stato, nome, telefono, email, bando_nome, messaggio, profilo->>'regione' as regione
  from public.ts_richieste where stato in ('nuova', 'contattato') order by created_at desc;
revoke all on public.ts_richieste_da_gestire from anon, authenticated;
