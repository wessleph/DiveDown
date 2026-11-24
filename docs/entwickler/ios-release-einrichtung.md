# iOS-Release einrichten: Apple, Environment und Secrets

> Für den Workflow `.github/workflows/ios-release.yml` (ADR 0005, security.md G6/A3).
> Alles hier machst **du selbst** im Browser bzw. in Git Bash. Schlüssel, Passwörter und den Inhalt
> der Secrets gibst du nie an Claude weiter. Mir reicht die Rückmeldung „erledigt“ und die **Team-ID** (die ist nicht geheim).
> Stand: 2026-11-24 (nach der ersten Einrichtung ergänzt: Stolpersteine unter Git Bash, Passwortmanager, externe Gruppe)

## 0. Vorbereitung
- [ ] **Git Bash** öffnen (Windows-Taste, „Git Bash“). Einfügen mit Rechtsklick → Paste oder Shift+Einfg, Strg+V geht dort oft nicht. Bei Passwortabfragen erscheint beim Tippen nichts.
- [ ] Arbeitsordner **außerhalb** des Repos anlegen: `mkdir -p ~/divedown-signing && cd ~/divedown-signing`. In `.gitignore` steht zwar `*.p12`, `*.p8` und `*.mobileprovision`, aber **nicht** `*.key`, `*.csr`, `*.cer` und `*.b64`. Deshalb gar nicht erst im Repo arbeiten.
- [ ] Passwortmanager offen: Dort landen das p12-Passwort, die Key-ID und die Issuer-ID. Kann er keine Anhänge speichern (z. B. der Google-Passwortmanager in Chrome), sichern wir die Dateien in Abschnitt 6 als verschlüsselte Datei.
- [ ] **Nie** die Ausgabe von `openssl rand` oder ein Passwort in einen Chat oder ein Ticket kopieren. Passiert es doch, Passwort neu erzeugen.

## 1. Apple Developer (developer.apple.com → Account)
- [ ] **Team-ID** notieren: *Membership details* → *Team ID* (10 Zeichen). → an Claude melden.
- [ ] **App-ID anlegen:** *Certificates, Identifiers & Profiles* → *Identifiers* → **+** → *App IDs* → *App*
  - Description: `DiveDown`
  - Bundle ID: **Explicit** `io.github.wessleph.divedown`
  - Capabilities: nur **HealthKit** anhaken (E3, für T6). Sonst nichts, auch kein „Clinical Health Records“, kein Push, kein iCloud.
- [ ] **Distribution-Zertifikat** (in Git Bash, im Arbeitsordner):
  ```bash
  openssl genrsa -out divedown_dist.key 2048
  MSYS_NO_PATHCONV=1 openssl req -new -key divedown_dist.key -out divedown_dist.csr -subj "/CN=DiveDown Distribution"
  ```
  `MSYS_NO_PATHCONV=1` ist nötig, weil Git Bash `/CN=…` sonst für einen Pfad hält und zu `C:/Program Files/Git/CN=…` macht.
  Im Portal: *Certificates* → **+** → **Apple Distribution** → `divedown_dist.csr` hochladen (nur diese Datei auswählen) → `distribution.cer` herunterladen und mit `mv ~/Downloads/distribution.cer .` in den Ordner holen. Dann:
  ```bash
  openssl x509 -inform DER -in distribution.cer -out distribution.pem
  openssl rand -base64 24          # p12-Passwort erzeugen, direkt in den Passwortmanager
  read -s -p "p12-Passwort: " P12PASS; echo; export P12PASS
  echo ${#P12PASS}                 # zeigt nur die Länge, etwa 32
  openssl pkcs12 -export -inkey divedown_dist.key -in distribution.pem -out divedown_dist.p12 \
    -name "DiveDown Distribution" \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 -passout env:P12PASS
  openssl pkcs12 -in divedown_dist.p12 -noout -passin env:P12PASS && echo "p12 ok"
  ```
  Das Passwort kommt über eine Variable statt über die Abfrage von `openssl`: Unter Git Bash hängt die Abfrage, und mit `winpty` kommt eingefügter Text nicht zuverlässig an („Verify failure“). Das Fenster offen lassen, `P12PASS` wird in Abschnitt 3 noch gebraucht.
  Die drei `-…pbe`/`-macalg`-Optionen sind nötig, weil der Schlüsselbund von macOS die neueren OpenSSL-3-Verfahren beim Import oft ablehnt.
- [ ] **Profil anlegen:** *Profiles* → **+** → *Distribution* → **App Store Connect** → App-ID `io.github.wessleph.divedown` → das eben erstellte Zertifikat → Name `DiveDown App Store` → herunterladen (`DiveDown_App_Store.mobileprovision`).

## 2. App Store Connect (appstoreconnect.apple.com)
- [ ] Offene Vereinbarungen annehmen (Banner oben bzw. *Business*). Für eine kostenlose App reicht die Free-Apps-Vereinbarung, Bank- und Steuerdaten sind nicht nötig.
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

  Am einfachsten ohne Zwischenablage, in Git Bash im Arbeitsordner (`gh auth status` muss angemeldet zeigen). Die Werte stehen danach nicht im Terminal-Verlauf:
  ```bash
  R=wessleph/DiveDown
  base64 -w0 divedown_dist.p12                   | gh secret set IOS_DIST_P12_BASE64 --env release -R $R
  base64 -w0 DiveDown_App_Store.mobileprovision  | gh secret set IOS_PROFILE_BASE64  --env release -R $R
  base64 -w0 AuthKey_*.p8                        | gh secret set ASC_KEY_P8_BASE64   --env release -R $R
  printf %s "$P12PASS" | gh secret set IOS_DIST_P12_PASSWORD --env release -R $R
  gh secret set ASC_KEY_ID --env release -R $R --body <Key-ID>   # nicht geheim, steht im Dateinamen der .p8
  read -s -p "Issuer-ID: " ISSUER; echo; printf %s "$ISSUER" | gh secret set ASC_ISSUER_ID --env release -R $R
  gh secret list --env release -R $R                        # zeigt nur die sechs Namen
  unset P12PASS ISSUER
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
- [ ] Im Arbeitsordner löschen: `rm divedown_dist.csr distribution.cer distribution.pem`.
- [ ] **Aufbewahren**, verschlüsselt an zwei Orten (z. B. NAS-Ordner außerhalb des Repo-Spiegels und USB-Stick): `divedown_dist.key`, `divedown_dist.p12`, `.p8`, `.mobileprovision`. Ohne Passwortmanager mit Anhängen so:
  ```bash
  openssl rand -base64 24          # Sicherungs-Passwort, in den Passwortmanager
  read -s -p "Sicherungs-Passwort: " BAK; echo; export BAK
  tar -cf - divedown_dist.key divedown_dist.p12 AuthKey_*.p8 DiveDown_App_Store.mobileprovision \
    | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -out divedown-ios-signing.tar.enc -pass env:BAK
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in divedown-ios-signing.tar.enc -pass env:BAK | tar -tf -
  unset BAK
  ```
  Entpacken später mit `openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in divedown-ios-signing.tar.enc | tar -xf -` (fragt das Passwort ab). Diesen Befehl zum Passwort notieren.
- [ ] Kalender-Erinnerung **Oktober 2027**: Distribution-Zertifikat und Profil laufen nach einem Jahr ab, kurz vor der Verlängerung des Apple-Kontos (ADR 0005, Roadmap 13a). Dann Secrets erneuern.

## 7. Rückmeldung an Claude
- Team-ID: `__________`
- Name der App in App Store Connect: `__________`
- Abschnitte 1–5 erledigt: ja / nein (was fehlt?)

Danach: *Actions* → **iOS release** → *Run workflow* auf `main` → im Lauf **Review deployments** → `release` anhaken → **Approve and deploy**. Der Build erscheint nach der Verarbeitung durch Apple (ca. 15–30 min) in TestFlight mit dem Status „Ready to Submit“.

## 8. TestFlight-Gruppen (erste Einrichtung am 2026-11-24)
- [ ] *TestFlight* → *Test Information* ausfüllen: Beta-Beschreibung und „What to Test“ auf Deutsch (für die Tester), *Review Notes* auf Englisch (für Apple), Datenschutz-URL, Kontakt, *Sign-in required* aus, *License Agreement* leer.
- [ ] Interne Gruppe anlegen (**+** neben *Internal Testing*, Name `Intern`, automatische Verteilung an). **Erst danach** zeigt App Store Connect die Möglichkeit für externe Gruppen: auf die interne Gruppe klicken, dort erscheint die Option für eine externe Gruppe (Oberfläche seit 2026).
- [ ] Externe Gruppe `Familie und Freunde` → Build hinzufügen → *Submit for Review*. Die erste Beta-Prüfung dauert meist 1–2 Tage. Danach in der Gruppe den **Public Link** einschalten und verschicken.
- Neue Builds aus der CI müssen der externen Gruppe jeweils von Hand hinzugefügt werden; die interne Gruppe bekommt sie automatisch.
