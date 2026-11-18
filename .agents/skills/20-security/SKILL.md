---
name: 20-security
description: Bedrohungsmodell, Datenschutz- und Lizenzprüfung für ein DiveDown-Feature. Greift nach abgenommener Architektur, vor dem Testschreiben.
---

## Wann diese Skill greift
- `design.md` eines Features ist abgenommen.
- Besonders bei: Login, Teilen, Sync, NAS-Erreichbarkeit, Standortdaten, neue Abhängigkeiten.

## Voraussetzungen (Gate rein)
- `specs/<feature>/design.md` existiert und ist abgenommen.
- Wenn nicht: STOP. Nicht weiterarbeiten.

## Vorgehen
1. STRIDE-Bedrohungsmodell **pro Komponentengrenze** aus `design.md`
   (App ↔ SQLite, App ↔ Tauchcomputer via BLE/USB, App ↔ NAS-Backend, NAS ↔ Internet).
2. OWASP-Top-10 (und OWASP Mobile Top 10) gegen das Design halten.
3. Explizit beantworten:
   - Wo kommen Daten von außen rein? (Tauchcomputer-Rohdaten, Imports, Sync, geteilte Tauchgänge)
   - Wo wird **autorisiert**, nicht nur authentifiziert? Wer darf welchen Tauchgang sehen?
   - Was wird geloggt — und was nie (Tokens, Passwörter, genaue Standorte, Gesundheitsdaten)?
   - Wie ist der NAS von außen erreichbar (VPN/Tailscale, Tunnel, Reverse-Proxy + TLS)?
     Kein offener Port ohne TLS und Auth.
   - Backups des NAS-Backends: wo, wie oft, wiederherstellbar?
4. Abhängigkeiten prüfen: Lizenzliste (besonders LGPL `libdivecomputer`),
   bekannte Schwachstellen (`dart pub outdated`, OSV-Scanner).
5. Secrets-Scan im Repo (z. B. `gitleaks`); keine Keys im Code, `.env` in `.gitignore`.
6. Frischen Subagenten als Angreifer einsetzen: „Du hast ein Familienkonto in DiveDown.
   Beschreibe drei realistische Angriffspfade auf fremde Daten oder den NAS."

## Ergebnis (Artefakt)
- Datei: `specs/<feature>/security.md`
- Muss enthalten: Bedrohungen je Grenze, Gegenmaßnahmen, akzeptierte Restrisiken (bewusst benannt).

## Red Flags — Abbruch und Neustart
- Bedrohungsmodell nur für die „offensichtliche" Komponente statt für alle Grenzen.
- Restrisiken stillschweigend akzeptiert, ohne sie aufzuschreiben.
- NAS-Dienst soll direkt ins Internet, ohne TLS/Auth/Update-Plan.
- Lizenz einer Abhängigkeit ungeklärt.

## Gate raus
- Sicherheitsfragen beantwortet und vom Menschen gegengelesen? Sonst keine Tests schreiben.
