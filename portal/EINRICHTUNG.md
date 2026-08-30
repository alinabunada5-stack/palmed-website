# Mitgliederportal einrichten (einmalig, ca. 15 Minuten)

Das Portal besteht aus `mitglieder.html` (für Mitglieder) und `verwaltung.html`
(nur Vorstand). Beide brauchen eine Datenbank bei **Supabase** (kostenloser
Tarif reicht für den Start).

## 1. Supabase-Konto und Projekt anlegen (machst du selbst)

1. https://supabase.com öffnen → **Start your project** → mit E-Mail registrieren
2. **New project** anlegen:
   - Name: `palmed-portal`
   - Datenbank-Passwort: sicher wählen und **im Passwortmanager speichern**
   - Region: **Frankfurt (eu-central-1)** – wichtig für DSGVO
3. Warten bis das Projekt bereit ist (ca. 2 Minuten)

## 2. Datenbank einrichten

1. Links im Menü: **SQL Editor** → **New query**
2. Den kompletten Inhalt der Datei `portal/supabase-setup.sql` einfügen → **Run**
3. Es sollte „Success" erscheinen

## 3. Anmeldung konfigurieren

1. Links: **Authentication → URL Configuration**
2. **Site URL** eintragen: `https://alinabunada5-stack.github.io/palmed-website/mitglieder.html`
3. Unter **Redirect URLs** zusätzlich eintragen:
   `https://alinabunada5-stack.github.io/palmed-website/*`

## 4. Schlüssel eintragen

1. Links: **Project Settings → API**
2. Dort stehen **Project URL** und der **anon public**-Schlüssel
3. Beide in die Datei `portal-config.js` eintragen (oder Claude geben –
   der anon-Schlüssel ist für die Öffentlichkeit gedacht, die Sicherheit
   liegt in den Zugriffsregeln der Datenbank)
4. Änderung hochladen (Claude Bescheid sagen oder `git push`)

## 5. Dich selbst zum Admin machen

1. Auf `mitglieder.html` mit deiner E-Mail anmelden (Link kommt per Mail)
2. In Supabase: **SQL Editor** → ausführen (E-Mail anpassen):

```sql
insert into admins (id)
select id from auth.users where email = 'DEINE@EMAIL.DE';
```

3. Fertig – auf `verwaltung.html` siehst du jetzt alle Anträge

## Wer darf sich anmelden?

Standardmäßig kann sich jede E-Mail-Adresse registrieren. Für einen
geschlossenen Mitgliederkreis in Supabase unter
**Authentication → Sign In / Up** die Option „Allow new users to sign up"
ausschalten und Mitglieder unter **Authentication → Users → Invite user**
per E-Mail einladen.

## Was noch aussteht (nächste Ausbaustufe)

- Automatischer E-Mail-Versand der Bescheinigung als PDF (aktuell: der
  „Bescheinigung senden"-Knopf öffnet eine vorbereitete E-Mail)
- E-Mail-Benachrichtigung an das Mitglied bei Entscheidung
- Interne, nur für Mitglieder sichtbare Formulare und Dokumente
