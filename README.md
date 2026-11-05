# IPA Re-Signing Tool

IPA neu signieren mit **fastlane** auf einem **GitHub `macos-latest` Runner**.

- kein Xcode-Projekt, kein Quellcode-Build
- kein Apple-Login (nur Zertifikat `.p12` + Provisioning Profile)
- kein Git LFS

## Einmalige Einrichtung

Du brauchst ein Signier-Zertifikat als `.p12` (Development, Ad Hoc oder Enterprise/Distribution), das **im Provisioning Profile enthalten** ist.

1. `.p12` in Base64 umwandeln:
   ```bash
   base64 -i zertifikat.p12 | pbcopy      # macOS
   base64 -w0 zertifikat.p12              # Linux
   ```
2. Im Repo unter **Settings → Secrets and variables → Actions** anlegen:

   | Secret         | Inhalt                       |
   |----------------|------------------------------|
   | `P12_BASE64`   | Base64 der `.p12`            |
   | `P12_PASSWORD` | Passwort der `.p12`          |

> Das Repo am besten **privat** halten. IPA und Profile stehen sonst oeffentlich im Repo.

## Benutzung

### Variante A: Hochladen im Repo (automatisch)
1. IPA nach `input/` laden (z. B. `input/app.ipa`), Profil als `input/xyz.mobileprovision`
   (GitHub Web: **Add file → Upload files**, bis 25 MB; per `git push` bis 100 MB).
2. Der Workflow startet automatisch bei jedem Push von `input/*.ipa` oder `input/*.mobileprovision`.

### Variante B: Manuell starten
**Actions → IPA neu signieren → Run workflow** und ausfuellen:

| Feld           | Bedeutung |
|----------------|-----------|
| `ipa`          | Pfad im Repo **oder** Download-URL (fuer grosse Dateien, kein LFS noetig) |
| `profile`      | Pfad/Glob oder URL; mehrere mit Komma (z. B. App + Extensions) |
| `bundle_id`    | optional, sonst aus dem Profil (bei Wildcard-Profil bleibt die Original-ID) |
| `display_name` | optional, neuer App-Name |
| `version`      | optional, neue Versionsnummer |
| `release`      | zusaetzlich als GitHub Release veroeffentlichen |

### Ergebnis
Die signierte IPA liegt am Ende des Runs unter **Artifacts → `resigned-ipa`** (14 Tage) oder, mit `release`, im Bereich **Releases**.

## Ablauf
1. `scripts/fetch_inputs.sh` holt IPA, Profile und `.p12`.
2. `fastlane resign_ipa` (siehe `fastlane/Fastfile`):
   temporaere Keychain, Zertifikat importieren, passende Identitaet zum Profil waehlen, `resign`, anschliessend `codesign --verify`.
3. Keychain wird danach geloescht.

## Hinweise
- Das Zertifikat muss zum Profil passen, sonst bricht der Lauf mit einer klaren Fehlermeldung ab.
- Die Geraete-UDIDs muessen im Profil stehen (Development/Ad Hoc).
- Workflows mit `workflow_dispatch` erscheinen in GitHub erst, wenn die Datei auf dem Default-Branch liegt.
