# Datenschutzerklärung für die App DiveDown

> **ENTWURF**, Stand 2026-11-18. Vor der Veröffentlichung: Platzhalter in [eckigen Klammern] ausfüllen und Inhalt gegen die fertige App 1.0 prüfen (Phase 60).
> Ziel: öffentliche URL für App Store Connect bzw. TestFlight (security.md §9.2). Hinweis: GitHub Pages funktioniert bei **privaten** Repos nur mit einem kostenpflichtigen Konto. Alternativen: die Seite in einem kleinen öffentlichen Repo veröffentlichen oder warten, bis DiveDown öffentlich ist.
> Keine Rechtsberatung. Der Text ist für eine private, kostenlose App ohne Server formuliert.

**Stand:** [DATUM DER VERÖFFENTLICHUNG] · **App-Version:** 1.0

## 1. Kurz gesagt
- DiveDown speichert alle Daten **nur auf deinem Gerät**.
- Die App hat **keinen Server**, **kein Konto**, **keine Werbung**, **kein Tracking** und **keine Analyse-Dienste**.
- Die Android-Version hat nicht einmal die Berechtigung, ins Internet zu gehen.
- Daten verlassen dein Gerät nur, wenn **du selbst** eine Sicherung oder ein Diagnose-Protokoll teilst.

## 2. Verantwortlich
[VOR- UND NACHNAME]
[ADRESSE]
E-Mail: [KONTAKT-E-MAIL]

DiveDown ist ein privates, nicht kommerzielles Open-Source-Projekt (Lizenz GPL-3.0).

## 3. Welche Daten die App auf deinem Gerät verarbeitet
| Daten | Woher | Wozu | Wo gespeichert |
|---|---|---|---|
| Taucherprofile (Name bzw. Spitzname, Farbe) | deine Eingabe | Logbücher mehrerer Taucher auf einem Gerät trennen | nur lokal |
| Tauchgänge (Zeit, Dauer, Tiefe, Temperatur, Flaschendruck, Gase, Ereignisse, Tauchplatz, Notizen, Bewertung) | Tauchcomputer, FIT-Datei, Apple Health oder deine Eingabe | Logbuch, Diagramme, Luftverbrauch | nur lokal |
| Daten des Tauchcomputers (Hersteller, Modell, Seriennummer, Firmware, Bluetooth-Kennung, Kopplungscode) | Tauchcomputer per Bluetooth | Gerät wiedererkennen, nur neue Tauchgänge laden | nur lokal; der Kopplungscode im geschützten Schlüsselspeicher des Systems |
| **Gesundheitsdaten aus Apple Health** (Tiefe, Wassertemperatur, Puls von Unterwasser-Workouts) | Apple Health, **nur mit deiner Erlaubnis**, **nur lesend** | Tauchgänge der Apple Watch übernehmen | nur lokal. DiveDown schreibt nichts in Apple Health. |
| Tauchplatz-Katalog | in der App mitgeliefert | Vorschläge beim Eintragen des Tauchplatzes | nur lokal, enthält keine persönlichen Daten |
| Diagnose-Protokoll (technische Ereignisse, Fehlercodes, Gerätemodell, Versionsnummern) | die App selbst | Fehlersuche | nur lokal, höchstens 7 Tage bzw. 5 MB. Ohne Orte, Namen, Notizen oder Gesundheitswerte. |

Die Logbuch-Datenbank wird **nicht** in iCloud- bzw. Google-Backups aufgenommen, weil darin Gesundheitsdaten stehen können. Für Sicherungen gibt es die Funktion „Logbuch sichern“ (Abschnitt 4).

**Berechtigungen:** Bluetooth (Verbindung zum Tauchcomputer) und, nur unter iOS, das Lesen aus Apple Health. Auf Android-Versionen bis 11 verlangt das System für Bluetooth-Suchen zusätzlich die Standort-Berechtigung. DiveDown fragt deinen Standort trotzdem nie ab.

## 4. Wann Daten dein Gerät verlassen, und nur dann
1. **Logbuch sichern:** Du erstellst eine Sicherungsdatei und wählst selbst, wohin sie geht, z. B. in „Dateien“, in einen Cloud-Speicher oder per Mail.
   Die Datei ist **nicht verschlüsselt** und kann Gesundheitsdaten (Puls) enthalten. Für den gewählten Speicherort gilt die Datenschutzerklärung des jeweiligen Anbieters.
2. **Diagnose-Logs teilen:** Du siehst vor dem Senden, was im Protokoll steht, und schickst es selbst, z. B. per Mail.
   Ich (Abschnitt 2) erhalte dann deine Nachricht samt Absender und Protokoll. Ich nutze das ausschließlich zur Fehlersuche und lösche es, sobald der Fehler behoben ist, spätestens nach 6 Monaten.
   Rechtsgrundlage: deine Einwilligung durch das aktive Senden (Art. 6 Abs. 1 lit. a DSGVO).

## 5. Verteilung der App
- **iPhone (TestFlight):** Die App wird über Apples TestFlight verteilt. Apple verarbeitet dabei Daten nach den eigenen Bedingungen ([Apple-Datenschutzrichtlinie](https://www.apple.com/legal/privacy/)).
  Wenn du in TestFlight Feedback oder Absturzberichte sendest, erhalte ich diese über App Store Connect. Je nach Einladungsart sehe ich dabei auch Name bzw. E-Mail-Adresse, die du bei TestFlight angegeben hast.
- **Android (APK über GitHub):** Beim Herunterladen verarbeitet GitHub technische Daten wie deine IP-Adresse ([GitHub Privacy Statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement)). Ich erhalte davon nichts.

## 6. Deine Rechte
Da ich außer freiwillig gesendeten Diagnose-Nachrichten keine Daten über dich habe, betreffen deine Rechte vor allem diese Nachrichten.
Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch. Außerdem kannst du dich bei einer Datenschutz-Aufsichtsbehörde beschweren.
[Falls Wohnsitz in der Schweiz: zusätzlich Verweis auf das Schweizer Datenschutzgesetz (DSG) und den EDÖB, edoeb.admin.ch.]

Alle Daten in der App löschst du selbst: einzelne Tauchgänge, ganze Taucherprofile, oder alles durch Deinstallieren der App.

## 7. Kinder
DiveDown richtet sich an Taucherinnen und Taucher jeden Alters in Familie und Freundeskreis. Die App erhebt von niemandem Daten.

## 8. Änderungen
Ändert sich, wie DiveDown mit Daten umgeht (z. B. durch eine spätere Sync-Funktion über einen eigenen Server), wird diese Erklärung **vor** dem Update angepasst. In der App siehst du dann einen Hinweis.
