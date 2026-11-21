# iOS-Release einrichten: Apple, Environment und Secrets

> Für den Workflow `.github/workflows/ios-release.yml` (ADR 0005, security.md G6/A3).
> Alles hier machst **du selbst** im Browser bzw. in Git Bash. Schlüssel, Passwörter und den Inhalt
> der Secrets gibst du nie an Claude weiter. Mir reicht die Rückmeldung „erledigt“ und die **Team-ID** (die ist nicht geheim).
> Stand: 2026-11-21

## 0. Vorbereitung
- [ ] Arbeitsordner **außerhalb** des Repos anlegen, z. B. `C:\Users\<du>\divedown-signing\`. In `.gitignore` steht zwar `*.p12`, `*.p8` und `*.mobileprovision`, aber **nicht** `*.key`, `*.csr`, `*.cer` und `*.b64`. Deshalb gar nicht erst im Repo arbeiten.
- [ ] Passwortmanager offen: Dort landen das p12-Passwort, die Key-ID, die Issuer-ID und als Anhang `divedown_dist.p12`, `divedown_dist.key` und die `.p8`-Datei.

## 1. Apple Developer (developer.apple.com → Account)
- [ ] **Team-ID** notieren: *Membership details* → *Team ID* (10 Zeichen). → an Claude melden.
- [ ] **App-ID anlegen:** *Certificates, Identifiers & Profiles* → *Identifiers* → **+** → *App IDs* → *App*
  - Description: `DiveDown`
  - Bundle ID: **Explicit** `io.github.wessleph.divedown`
  - Capabilities: nur **HealthKit** anhaken (E3, für T6). Sonst nichts, auch kein „Clinical Health Records“, kein Push, kein iCloud.
- [ ] **Distribution-Zertifikat** (in Git Bash, im Arbeitsordner):
  ```bash
  openssl genrsa -out divedown_dist.key 2048
  openssl req -new -key divedown_dist.key -out divedown_dist.csr -subj "/CN=DiveDown Distribution"
  ```
  Im Portal: *Certificates* → **+** → **Apple Distribution** → `divedown_dist.csr` hochladen → `distribution.cer` herunterladen. Dann:
  ```bash
  openssl x509 -inform DER -in distribution.cer -out distribution.pem
  openssl pkcs12 -export -inkey divedown_dist.key -in distribution.pem -out divedown_dist.p12 \
    -name "DiveDown Distribution" \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
  ```
  Das Passwort für die p12 fragt `openssl` ab: lang und zufällig, direkt in den Passwortmanager.
  Die drei `-…pbe`/`-macalg`-Optionen sind nötig, weil der Schlüsselbund von macOS die neueren OpenSSL-3-Verfahren beim Import oft ablehnt.
- [ ] **Profil anlegen:** *Profiles* → **+** → *Distribution* → **App Store Connect** → App-ID `io.github.wessleph.divedown` → das eben erstellte Zertifikat → Name `DiveDown App Store` → herunterladen (`DiveDown_App_Store.mobileprovision`).

## 2. App Store Connect (appstoreconnect.apple.com)
- [ ] **App anlegen:** *Apps* → **+** → *Neue App*
  - Plattform iOS, Name `DiveDown` (falls vergeben z. B. `DiveDown Logbuch`), Primärsprache **Deutsch**, Bundle-ID aus der Liste, SKU `divedown`, Zugriff „Vollständig“.
- [ ] **API-Schlüssel nur für den Upload:** *Benutzer und Zugriff* → *Integrationen* → *App Store Connect API* → *Teamschlüssel* → **+**
  - Name `DiveDown CI`, Zugriff **Developer** (nicht Admin, nicht App Manager; security.md A3).
  - `.p8` herunterladen (**geht nur einmal**), **Key-ID** und oben die **Issuer-ID** notieren.
  - Falls der erste Upload mit einem Rechtefehler scheitert: nicht selbst hochstufen, sondern mir den Fehlertext zeigen. Dann entscheiden wir gemeinsam.

## 3. GitHub: Environment `release` (Repo → *Settings* → *Environments*)
- [ ] **New environment** → Name `release`
- [ ] **Required reviewers:** `wessleph`. **„Prevent self-review“ ausgeschaltet lassen**, sonst kannst du deine eigenen Läufe nicht freigeben.
- [ ] **Deployment branches and tags:** *Selected branches and tags* → Regel Branch `main` und Regel Tag `v*`.
- [ ] **Environment secrets** (genau diese sechs, **keine** Repository-Secrets):

  | Name | Inhalt |
  |---|---|
  | `IOS_DIST_P12_BASE64` | `divedown_dist.p12` als Base64 |
  | `IOS_DIST_P12_PASSWORD` | Passwort der p12 |
  | `IOS_PROFILE_BASE64` | `DiveDown_App_Store.mobileprovision` als Base64 |
  | `ASC_KEY_ID` | Key-ID des API-Schlüssels |
  | `ASC_ISSUER_ID` | Issuer-ID |
  | `ASC_KEY_P8_BASE64` | `AuthKey_<KeyID>.p8` als Base64 |

  Am einfachsten ohne Zwischenablage, in Git Bash im Arbeitsordner (`gh` ist angemeldet). Die Werte stehen danach nicht im Terminal-Verlauf:
  ```bash
  R=wessleph/DiveDown
  base64 -w0 divedown_dist.p12                   | gh secret set IOS_DIST_P12_BASE64 --env release -R $R
  base64 -w0 DiveDown_App_Store.mobileprovision  | gh secret set IOS_PROFILE_BASE64  --env release -R $R
  base64 -w0 AuthKey_*.p8                        | gh secret set ASC_KEY_P8_BASE64   --env release -R $R
  gh secret set IOS_DIST_P12_PASSWORD --env release -R $R   # fragt den Wert verdeckt ab
  gh secret set ASC_KEY_ID            --env release -R $R
  gh secret set ASC_ISSUER_ID         --env release -R $R
  gh secret list --env release -R $R                        # zeigt nur die Namen
  ```

## 4. GitHub: Actions-Einstellungen (*Settings* → *Actions* → *General*)
- [ ] **Actions permissions:** „Allow wessleph, and select non-wessleph, actions and reusable workflows“ → nur **„Allow actions created by GitHub“** anhaken, sonst nichts erlauben.
- [ ] Falls angeboten: **„Require actions to be pinned to a full-length commit SHA“** einschalten (deckt sich mit W1).
- [ ] **Fork pull request workflows from outside collaborators:** „Require approval for **all** external contributors“.
- [ ] **Workflow permissions:** „Read repository contents and packages permissions“. **„Allow GitHub Actions to create and approve pull requests“ aus.**

## 5. GitHub: Tag-Schutz (*Settings* → *Rules* → *Rulesets*)
- [ ] **New tag ruleset** → Name `Release-Tags`, Enforcement **Active**
- [ ] Target: *Include by pattern* `v*`
- [ ] Rules: **Restrict creations**, **Restrict updates**, **Restrict deletions**
- [ ] Bypass list: nur **Repository admin** (du). Damit darf außer dir niemand einen Tag `v…` anlegen, der den Release-Workflow auslöst.

## 6. Aufräumen und Merken
- [ ] Im Arbeitsordner löschen: `divedown_dist.csr`, `distribution.cer`, `distribution.pem`. **Aufbewahren** (Passwortmanager bzw. verschlüsselt an zwei Orten): `divedown_dist.key`, `divedown_dist.p12`, `.p8`, `.mobileprovision`.
- [ ] Kalender-Erinnerung **Oktober 2027**: Distribution-Zertifikat und Profil laufen nach einem Jahr ab, kurz vor der Verlängerung des Apple-Kontos (ADR 0005, Roadmap 13a). Dann Secrets erneuern.

## 7. Rückmeldung an Claude
- Team-ID: `__________`
- Name der App in App Store Connect: `__________`
- Abschnitte 1–5 erledigt: ja / nein (was fehlt?)

Danach: Pipeline-Branch nach `main` mergen (nach Rückfrage), dann *Actions* → **iOS release** → *Run workflow* auf `main` → im Lauf **Review deployments** → `release` freigeben. Der Build erscheint nach der Verarbeitung durch Apple (ca. 15–30 min) in TestFlight.
