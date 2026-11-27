# Android über den internen Test von Google Play

> Für T42 (ADR 0005, Nachtrag 2026-11-27; security.md G6). Stand: 2026-11-27.
> Alles hier machst **du selbst** in der Play Console bzw. in PowerShell. Passwörter und Schlüsseldateien gibst du nie an Claude weiter.
> Die Menünamen der Play Console ändern sich öfter. Steht dort etwas anderes als hier, nimm das, was die Console anzeigt, und melde die Abweichung, damit wir die Anleitung anpassen.
> Quellen, abgerufen am 2026-11-27: [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756), [Tests einrichten](https://support.google.com/googleplay/android-developer/answer/9845334), [Testanforderungen für neue private Konten](https://support.google.com/googleplay/android-developer/answer/14151465).

## Überblick: zwei Schlüssel
| Datei in `divedown-signing` | Alias | Wofür | Eingetragen in |
|---|---|---|---|
| `divedown-upload.p12` | `divedown` | **App-Signaturschlüssel**: signiert die APK. Google bekommt eine verschlüsselte Kopie und signiert damit die Installationen aus dem Play Store. Fingerabdruck `83:4A:…:27:E5` (README). | `android/key.properties` |
| `divedown-play-upload.p12` (neu, Schritt 3) | `upload` | **Upload-Schlüssel**: signiert nur das App-Bundle, das du zu Google hochlädst. | `android/upload-key.properties` (neu, Schritt 4) |

Der Name `divedown-upload.p12` stammt aus T33 und bleibt, weil `key.properties` darauf zeigt. Gemeint ist der App-Signaturschlüssel.
Welcher Schlüssel benutzt wird, entscheidet der Build selbst: `flutter build appbundle` nimmt den Upload-Schlüssel, `flutter build apk` den App-Signaturschlüssel.

Lege dir für die Dateien von Google einen Unterordner an, z. B. `C:\Users\<du>\divedown-signing\play\`.

## 1. App in der Play Console anlegen
**Alle Apps → App erstellen:**
- App-Name: `DiveDown`
- Standardsprache: **Deutsch – de-DE**
- App oder Spiel: **App**
- Kostenlos oder kostenpflichtig: **Kostenlos** (lässt sich später nicht mehr ändern)
- Die Erklärungen (Richtlinien für Entwickler, US-Exportgesetze) bestätigen.

- **Paketname: `io.github.wessleph.divedown`** (genau so, steht in `android/app/build.gradle.kts`). Seit der Android-Entwicklerverifizierung fragt die Console ihn schon beim Anlegen ab (Stand 2026-11-27; früher kam er erst mit dem ersten Bundle). Damit ist er bei Google registriert und lässt sich nicht mehr ändern.

**Automatischen Schutz ausschalten:** App-Integrität → „Automatischer Schutz“ → Verwalten → Schalter „Installationsprüfung“ aus. Sonst baut Google Laufzeitprüfungen in den ausgelieferten Code ein, die eine App aus einer anderen Quelle zum Play Store schicken. Das passt nicht zu einer GPL-App, die auch als APK verteilt wird, und die Store-App wäre nicht mehr das, was aus dem Quellcode gebaut wird. Bei neuen Apps ist er voreingestellt (2026-11-27). Er wirkt ab dem nächsten Release.

## 2. Eigenen Schlüssel als App-Signaturschlüssel hinterlegen (vor dem ersten Hochladen)
Google erzeugt sonst beim ersten Hochladen selbst einen Schlüssel. Deshalb **zuerst** diesen Schritt.

1. In der App: **Testen und veröffentlichen → App-Integrität** (früher „Einrichtung → App-Signatur“; Google nennt auch „Protected with Play → Manage Play app signing“) → **Schlüssel ändern** bzw. **Anderen Schlüssel verwenden**.
2. Wähle **„Schlüssel aus Java-Schlüsselspeicher exportieren und hochladen“** (englisch: „Export and upload a key from Java keystore“).
3. Lade dort das Werkzeug **PEPK** (`pepk.jar`) und den **Verschlüsselungsschlüssel** (`encryption_public_key.pem`) herunter, nur von dieser Seite in der Play Console, in den Ordner `play\`.
4. Die Console zeigt einen Befehl. Führe **diesen** Befehl aus und ersetze nur die Pfade. Mit dem Java von Android Studio sieht er etwa so aus:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\java.exe" -jar "$env:USERPROFILE\divedown-signing\play\pepk.jar" --keystore="$env:USERPROFILE\divedown-signing\divedown-upload.p12" --alias=divedown --output="$env:USERPROFILE\divedown-signing\play\divedown-app-signing.zip" --include-cert --rsa-aes-encryption --encryption-key-path="$env:USERPROFILE\divedown-signing\play\encryption_public_key.pem"
```

   PEPK fragt nach dem Passwort des Schlüsselspeichers und des Schlüssels: beide Male das Passwort „DiveDown Android-Schlüssel“ aus Chrome.
5. Die erzeugte Datei `divedown-app-signing.zip` in der Console hochladen. Sie ist verschlüsselt, nur Google kann sie öffnen.
6. Die Console verlangt dabei meist auch das **Upload-Zertifikat** → zuerst Schritt 3, dann hier weiter.

Meldet PEPK, dass es den Schlüsselspeicher nicht lesen kann (Google nennt nur `.jks`/`.keystore`), schick mir die Meldung ohne Passwort; ein PKCS12-Speicher lässt sich mit `keytool -importkeystore` umwandeln.

## 3. Upload-Schlüssel erzeugen
Neues, langes Zufallspasswort in Chrome anlegen, z. B. Eintrag „DiveDown Play-Upload-Schlüssel“ (wie beim ersten Schlüssel: Website `https://play.google.com/console`). Ein Passwort erzeugt dieser Befehl direkt in die Zwischenablage:

```powershell
$b = New-Object byte[] 24; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b) | Set-Clipboard
```

Dann den Schlüssel erzeugen (Fragen wie beim ersten Mal: Passwort zweimal einfügen, Name, Rest mit Enter, zum Schluss `ja`):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$env:USERPROFILE\divedown-signing\divedown-play-upload.p12" -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```

Zertifikat für Google exportieren (fragt das neue Passwort ab):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -export -rfc -keystore "$env:USERPROFILE\divedown-signing\divedown-play-upload.p12" -alias upload -file "$env:USERPROFILE\divedown-signing\play\upload_certificate.pem"
```

`upload_certificate.pem` in Schritt 2.6 hochladen und speichern.

**Prüfen (T42.5):** Unter „App-Integrität“ stehen jetzt zwei Zertifikate. Beim **App-Signaturschlüssel** muss der SHA-256-Fingerabdruck `83:4A:81:53:5B:41:26:4E:70:C3:2D:33:9C:D1:A5:B7:ED:F4:85:05:EB:34:05:F6:84:73:88:EE:A6:8D:27:E5` sein, beim Upload-Schlüssel („Schlüssel hochladen“) ein anderer, seit 2026-11-27 `99:15:1C:63:B4:5E:68:83:1B:CB:DB:FE:1D:4D:D1:CD:DB:24:92:0D:09:3B:EA:16:1F:BE:1E:D8:E8:A4:F9:0B`. Google erzeugt beim Anlegen der App schon einen eigenen Schlüssel; solange die Installationsbasis 0 % ist, ersetzt „Schlüssel ändern“ ihn.

## 4. `android/upload-key.properties` anlegen
Wie `key.properties` (android-release-einrichtung.md §3), nur mit dem Upload-Schlüssel:

```powershell
notepad C:\dev\DiveDown\android\upload-key.properties
```

```properties
storeFile=C:/Users/<du>/divedown-signing/divedown-play-upload.p12
storePassword=<Passwort Play-Upload-Schlüssel>
keyAlias=upload
keyPassword=<dasselbe Passwort>
```

Speichern (Strg+S), dann prüfen: Die Größe muss über 0 liegen, und Git muss die Datei ignorieren.

```powershell
(Get-Item C:\dev\DiveDown\android\upload-key.properties).Length
```

```powershell
git -C C:\dev\DiveDown check-ignore -v android/upload-key.properties
```

## 5. App-Bundle bauen
Google nimmt jede Build-Nummer nur einmal und verlangt, dass sie steigt. Wie bei iOS ist sie die **Anzahl der Commits** (security.md G6, R). Deshalb immer von einem committeten Stand bauen:

```powershell
cd C:\dev\DiveDown; flutter build appbundle --release --build-number=$(git rev-list --count HEAD)
```

Ergebnis: `build\app\outputs\bundle\release\app-release.aab`. Fehlt `upload-key.properties`, bricht der Build mit einem Verweis auf diese Anleitung ab.

**Prüfen (T42.4):** Das Bundle trägt das Upload-Zertifikat, **nicht** `83:4A:…`:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -printcert -jarfile C:\dev\DiveDown\build\app\outputs\bundle\release\app-release.aab
```

## 6. Internen Test einrichten und veröffentlichen
1. **Testen und veröffentlichen → Testen → Interner Test → Tester:** E-Mail-Liste erstellen, z. B. „Familie und Freunde“, nur Adressen von Leuten, die zugestimmt haben (Google-Konto des Android-Handys). Speichern.
2. **Interner Test → Releases → Neuen Release erstellen:** `app-release.aab` hochladen. Release-Name z. B. `1.0.0 (Build N)`, Versionshinweise auf Deutsch.
3. **Weiter → Speichern → Release veröffentlichen** (bzw. „Einführung als internen Test starten“).
4. Verlangt die Console vorher Angaben unter **App-Inhalte**, so beantworten:
   - Datenschutzerklärung: `https://wessleph.github.io/DiveDown/datenschutz/`
   - App-Zugriff: alle Funktionen ohne Anmeldung nutzbar
   - Werbung: enthält keine Werbung
   - Einstufung des Inhalts: Fragebogen ehrlich ausfüllen (keine Gewalt, kein Glücksspiel, keine Nutzerkommunikation)
   - Zielgruppe: keine Altersgruppe unter 13 wählen, sonst gelten die zusätzlichen Regeln für Kinder-Apps
   - Datensicherheit: Apps nur im internen Test sind laut Google ausgenommen; falls doch gefragt: **keine Daten erfasst, keine Daten geteilt**
   - Gesundheit: Unter Android liest DiveDown keine Gesundheitsdaten (Apple Health gibt es nur unter iOS)
   Unklare Fragen nicht raten, sondern mir die Frage schicken.
5. **Tester → Link kopieren** und an die Tester schicken. Sie öffnen den Link auf dem Android-Handy, nehmen die Einladung an und installieren DiveDown über den Play Store.

Ein interner Test braucht laut Google keine Prüfung durch Google und ist meist nach wenigen Minuten bei den Testern.

## 7. Updates
1. Änderungen committen (die Build-Nummer kommt aus der Anzahl der Commits).
2. Schritt 5: Bundle bauen und prüfen.
3. Interner Test → Neuen Release erstellen → hochladen → veröffentlichen.

Die Tester bekommen das Update wie jedes andere über den Play Store. Eine APK für Leute ohne Google-Konto baust du mit derselben Build-Nummer: `flutter build apk --release --build-number=$(git rev-list --count HEAD)`.

## 8. Sichern
- Beide Schlüssel liegen an **zwei** Orten: in `divedown-signing` auf dem PC und als Kopie auf `P:\IT Projekte\Sicherung-Signaturschluessel` (seit 2026-11-27). Die `.p12`-Dateien sind mit ihrem eigenen Passwort verschlüsselt, ein zusätzliches Sicherungs-Passwort wie bei iOS braucht es nicht. Die Passwörter stehen im Chrome-Passwortmanager („DiveDown Android-Schlüssel“, „DiveDown Play-Upload-Schlüssel“). Kopieren:

  ```powershell
  Copy-Item "$env:USERPROFILE\divedown-signing\divedown-upload.p12", "$env:USERPROFILE\divedown-signing\divedown-play-upload.p12" "P:\IT Projekte\Sicherung-Signaturschluessel\"
  ```
- Geht der **Upload-Schlüssel** verloren, kann man in der Play Console unter „App-Integrität“ ein Zurücksetzen beantragen. Den **App-Signaturschlüssel** kann niemand ersetzen, deshalb bleibt seine Sicherung das Wichtigste.
- Die Dateien von Google im Ordner `play\` (`pepk.jar`, `encryption_public_key.pem`, `divedown-app-signing.zip`, `upload_certificate.pem`) braucht man nach dem Einrichten nicht mehr. Die ZIP-Datei enthält den verschlüsselten Schlüssel: nach dem Hochladen löschen.

## 9. Eigenes Handy umstellen (T42.6)
Auf dem S25 läuft die Debug-App mit einem anderen Schlüssel. Einmalig:
1. DiveDown → **Einstellungen → Logbuch sichern**, Datei sicher ablegen.
2. DiveDown deinstallieren.
3. Testlink öffnen, Einladung annehmen, DiveDown aus dem Play Store installieren.
4. **Einstellungen → Logbuch wiederherstellen.**

Prüfen, dass die installierte App das Zertifikat `83:4A:…` trägt (Handy per USB, `adb` aus dem Android-SDK):

```powershell
adb shell pm path io.github.wessleph.divedown
```

Den Pfad hinter `package:` zur Datei `base.apk` nehmen:

```powershell
adb pull <Pfad>/base.apk "$env:TEMP\divedown-base.apk"
```

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs "$env:TEMP\divedown-base.apk"
```

`Signer #1 certificate SHA-256 digest` muss `834a81535b41264e70c32d339cd1a5b7edf48505eb3405f6847388eea68d27e5` sein.
