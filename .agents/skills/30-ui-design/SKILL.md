---
name: 30-ui-design
description: Nutzerflüsse, alle UI-Zustände und Zugänglichkeit einer DiveDown-Oberfläche spezifizieren. Greift vor dem Implementieren jeder Oberfläche.
---

## Wann diese Skill greift
- Ein Feature hat sichtbare Oberfläche (neuer Screen, neuer Ablauf, geänderte Bedienung).

## Voraussetzungen (Gate rein)
- `specs/<feature>/design.md` existiert und ist abgenommen.
- `specs/<feature>/security.md` ist abgenommen.
- Wenn nicht: STOP. Nicht weiterarbeiten.

## Vorgehen
1. Nutzerflüsse durchgehen (z. B. Tauchcomputer verbinden → auslesen → neue Tauchgänge prüfen → speichern).
2. **Zustände explizit auflisten** — für jeden Screen:
   leer, ladend, Fehler, Erfolg, zu viele Daten, **offline**, **Sync ausstehend/Konflikt**,
   Bluetooth aus / Berechtigung verweigert, Tauchcomputer nicht unterstützt, Übertragung abgebrochen.
3. Eigener visueller Stil — DiveMate nur als Ablauf-Vorbild, keine Übernahme von Layouts 1:1,
   Icons, Farben oder Texten.
4. Alle Texte auf Deutsch, Einheiten (m/ft, bar/psi, °C/°F) umschaltbar mitdenken.
5. Zugänglichkeit: Kontrast (WCAG AA), Touch-Ziele ≥ 48 dp, Schriftgrößen skalierbar,
   Screenreader-Labels; Bedienbarkeit mit nassen Händen/Handschuhen am Tauchplatz bedenken.
6. Layouts für Smartphone hoch/quer und Tablet festlegen.

## Ergebnis (Artefakt)
- Datei: `specs/<feature>/ui-spec.md`
- Muss enthalten: Flows, alle Zustände je Screen, Texte, Accessibility-Anforderungen, Layouts.

## Red Flags — Abbruch und Neustart
- Nur der „glückliche Pfad" ist spezifiziert; Fehler-, Leer- oder Offline-Zustände fehlen.
- Gestaltung ist erkennbar von DiveMate kopiert.
- Englische Texte in der Oberfläche.

## Gate raus
- Alle Zustände spezifiziert und vom Menschen abgenommen? Sonst nicht implementieren.
