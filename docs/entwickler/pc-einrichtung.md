# PC einrichten (Entwicklungsrechner)

> Ab jetzt wird **auf dem PC** entwickelt. Der Laptop hat nur die Planung erstellt.
> **GitHub** ist die Hauptquelle (Remote `origin`). Die Kopie auf dem NAS unter `P:\IT Projekte\DiveDown` wird bei jedem Push mit aktualisiert.

## 1. Werkzeuge installieren (einmalig, auf dem PC)
In einem Terminal (PowerShell):

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id Google.AndroidStudio -e
```

Flutter in genau der Version aus ADR 0005 holen:

```powershell
git clone --branch 3.47.0 --depth 1 https://github.com/flutter/flutter.git C:\src\flutter
```

Dann `C:\src\flutter\bin` zum **Benutzer-PATH** hinzufügen: Windows-Suche → „Umgebungsvariablen für dieses Konto bearbeiten“ → `Path` → Neu.
Danach ein neues Terminal öffnen.

Android Studio einmal starten und den Einrichtungsassistenten durchlaufen (SDK, Emulator). Anschließend:

```powershell
flutter doctor --android-licenses
flutter doctor
```

`flutter doctor` sollte bei **Flutter** und **Android toolchain** einen grünen Haken zeigen. „Visual Studio“ und „Chrome“ dürfen fehlen, weil wir weder für Windows noch fürs Web bauen.

## 2. Repo holen
```powershell
gh auth login
git clone https://github.com/wessleph/DiveDown.git C:\Users\<du>\DiveDown
cd C:\Users\<du>\DiveDown
git config user.name "wessleph"
git config user.email "273623875+wessleph@users.noreply.github.com"
```

Den Push zum NAS gleich mit einrichten, damit jeder `git push` beide Ziele aktualisiert:

```powershell
git remote set-url --add --push origin https://github.com/wessleph/DiveDown.git
git remote set-url --add --push origin "P:/IT Projekte/DiveDown"
git remote -v
```

`git remote -v` muss **zwei** `(push)`-Zeilen zeigen: GitHub und P:.

Referenz-Code von Submersion daneben legen (nicht im Repo, siehe README):

```powershell
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/submersion-app/submersion.git submersion-referenz
```

## 3. Handy vorbereiten
- Android: Einstellungen → Über das Telefon → 7× auf „Build-Nummer“ tippen → Entwickleroptionen → **USB-Debugging** an.
- Per USB verbinden, dann `flutter devices`. Das Handy muss in der Liste stehen.

## 4. Arbeitsablauf
- Ein Task = ein Commit (Constitution).
- Nach jedem Commit `git push`. Das aktualisiert GitHub **und** `P:\IT Projekte\DiveDown`.
- Ist das NAS nicht erreichbar (z. B. unterwegs), schlägt nur der Push zum NAS fehl, GitHub ist trotzdem aktuell. Sobald du wieder im Heimnetz bist, holt ein erneuter `git push` den Stand auf dem NAS nach.
