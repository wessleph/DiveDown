# Test des Apple-Health-Imports mit der Apple Watch Ultra (T6.14)

> Für den Freund mit der Watch Ultra. Dauer: etwa 15 Minuten, sobald ein Tauchgang aufgezeichnet ist.
> Was hier fehlt oder anders aussieht, bitte über **Einstellungen → Hilfe → Fehler melden** in DiveDown schicken (mit Diagnose-Protokoll; es enthält keine Tiefen, Temperaturen oder Pulswerte).

## Voraussetzungen
- iPhone mit **iOS 17 oder neuer**, DiveDown aus TestFlight in der neuesten Version.
- Mindestens ein Tauchgang, den die Watch Ultra mit der App **„Tiefe“** oder einer Tauch-App (z. B. Oceanic+) aufgezeichnet hat. In der Health-App unter *Trainings* muss er als **Tauchen** erscheinen.
- Hat die Watch die Daten noch nicht ans iPhone übertragen: Watch in die Nähe des iPhones legen, ein paar Minuten warten.

## Ablauf
1. DiveDown → **Importieren** → **Apple Health**.
2. Die Seite erklärt, was gelesen wird. Zeitraum **„Letzte 12 Monate“** lassen, **„Tauchgänge suchen“** tippen.
3. iOS fragt einmal nach dem Zugriff. **Alle Kategorien einschalten** (Trainings, Wassertiefe, Wassertemperatur, Herzfrequenz) → *Erlauben*. Schreiben fragt DiveDown nicht an.
4. Die Vorschau zeigt die gefundenen Tauchgänge. Auswählen → **„… importieren“**.

## Bitte prüfen und zurückmelden
| Was | Erwartet |
|---|---|
| Anzahl | so viele Tauchgänge wie in der Health-App unter *Trainings → Tauchen* im Zeitraum |
| Datum und Uhrzeit | wie auf der Watch bzw. in der Health-App (auch bei Tauchgängen im Ausland) |
| max. Tiefe und Dauer | wie in der Health-App bzw. Oceanic+ (Tiefen über ca. 40 m erfasst die Watch nicht) |
| Profil im Detail | Tiefenkurve über den ganzen Tauchgang, Chip **„Puls“** an, Temperaturkurve |
| zweiter Import | derselbe Tauchgang erscheint als **„Bereits im Logbuch“** |
| ohne Zugriff | Health-App → Profil → Apps → DiveDown → alles aus → erneut suchen: „Keine Tauchgänge im gewählten Zeitraum gefunden.“ mit Hinweis auf den Zugriff |

Am hilfreichsten ist ein Screenshot vom Tauchgang in DiveDown neben dem in der Health-App oder in Oceanic+.
