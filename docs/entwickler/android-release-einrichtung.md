# Android-Release einrichten: eigener Signaturschlüssel

> Für signierte Release-APKs (T33, security.md S und A3, ADR 0005).
> Alles hier machst **du selbst** in Git Bash bzw. PowerShell. Die Passwörter und den Keystore gibst du nie an Claude weiter.
> Mir reicht die Rückmeldung „erledigt“ und die Ausgabe des Fingerabdrucks aus Schritt 4 (der ist nicht geheim).
> Stand: 2026-11-23

## Warum
Android installiert ein Update nur, wenn es mit **demselben Schlüssel** signiert ist wie die installierte App.
Geht der Schlüssel verloren, kann niemand mehr Updates installieren. Die Familie müsste die App dann löschen und neu einrichten.
Deshalb: Schlüssel einmal erzeugen, **an zwei Orten verschlüsselt sichern** (z. B. Passwortmanager plus verschlüsselter USB-Stick oder NAS-Ordner), **nie ins Repo** und **nie in die CI**.

## 1. Arbeitsordner außerhalb des Repos
Zum Beispiel `C:\Users\<du>\divedown-signing\`. Der Ordner für die iOS-Signatur kann es auch sein.

## 2. Keystore erzeugen (einmalig)
`keytool` liegt im JDK von Android Studio. In PowerShell:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$env:USERPROFILE\divedown-signing\divedown-upload.p12" -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias divedown
```

- `keytool` fragt das **Keystore-Passwort** ab: lang und zufällig, direkt in den Passwortmanager.
- Danach fragt es Name, Organisation usw. Ein Name reicht, der Rest darf leer bleiben. Diese Angaben stehen im Zertifikat und sind öffentlich sichtbar.
- Bei PKCS12 (dem heutigen Standardformat) gilt das Keystore-Passwort auch für den Schlüssel, ein zweites wird nicht abgefragt.
- `-validity 10000` sind gut 27 Jahre. Das Zertifikat darf nicht ablaufen, solange die App benutzt wird.

## 3. `android/key.properties` anlegen
Die Datei liegt im Repo-Ordner `android/`, ist aber über `android/.gitignore` von Git ausgeschlossen (T33.4). Inhalt:

```properties
storeFile=C:/Users/<du>/divedown-signing/divedown-upload.p12
storePassword=<Keystore-Passwort>
keyAlias=divedown
keyPassword=<dasselbe Keystore-Passwort>
```

- Im Pfad **Schrägstriche** `/` verwenden, nicht `\`.
- Prüfen, dass Git die Datei ignoriert: `git check-ignore -v android/key.properties` muss eine Zeile ausgeben.

## 4. Fingerabdruck auslesen und Claude melden
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\divedown-signing\divedown-upload.p12" -alias divedown
```
Die Zeile **`SHA256:`** unter „Zertifikatsfingerprints“ an Claude schicken. Sie kommt in die README, damit jeder eine APK prüfen kann (security.md, „Keine Prüfanleitung für die APK“).

## 5. Release-APK bauen
```powershell
flutter build apk --release
```
Ergebnis: `build\app\outputs\flutter-apk\app-release.apk`. Fehlt `key.properties`, bricht der Build mit einem Verweis auf diese Anleitung ab.

Signatur prüfen (das `apksigner` liegt in den Build-Tools des Android-SDK):
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<Version>\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```
Der SHA-256-Wert muss zu Schritt 4 passen.

## 6. Umstieg auf Geräten mit der Debug-App
Eine mit dem Debug-Schlüssel installierte App (alle Testinstallationen per `adb`) lässt sich **nicht** durch die Release-APK ersetzen, Android lehnt das wegen des anderen Schlüssels ab. Deshalb einmalig:
1. In DiveDown **Einstellungen → Logbuch sichern** und die Datei an einem sicheren Ort ablegen.
2. DiveDown deinstallieren.
3. Die Release-APK installieren.
4. **Einstellungen → Logbuch wiederherstellen** mit der gesicherten Datei.

Ab dann gehen alle weiteren Release-APKs direkt als Update drüber. Dazu muss die Build-Nummer in `pubspec.yaml` (`version: 1.0.0+N`) bei jedem Release steigen.

## 7. Sichern
- `divedown-upload.p12` und das Passwort verschlüsselt an **zwei** Orten aufbewahren.
- `key.properties` braucht kein Backup, sie lässt sich aus den Angaben oben neu schreiben.
