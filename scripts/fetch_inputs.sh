#!/bin/bash
# Holt IPA + Provisioning Profile(s) (Repo-Pfad oder URL) und das Zertifikat in ./work.
# Kompatibel mit macOS bash 3.2.
set -euo pipefail

IPA_SRC="${IPA_SRC:-input/app.ipa}"
PROFILE_SRC="${PROFILE_SRC:-input/*.mobileprovision}"
WORK="${GITHUB_WORKSPACE:-$PWD}/work"
OUT="${GITHUB_WORKSPACE:-$PWD}/out"

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/profiles" "$OUT"

is_url() { case "$1" in http://*|https://*) return 0 ;; *) return 1 ;; esac; }
trim() { echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

# --- IPA ---
IPA_SRC="$(trim "$IPA_SRC")"
if is_url "$IPA_SRC"; then
  echo "Lade IPA: $IPA_SRC"
  curl -fL --retry 3 -o "$WORK/input.ipa" "$IPA_SRC"
  name="$(basename "${IPA_SRC%%\?*}")"
else
  [ -f "$IPA_SRC" ] || { echo "::error::IPA nicht gefunden: $IPA_SRC"; exit 1; }
  cp "$IPA_SRC" "$WORK/input.ipa"
  name="$(basename "$IPA_SRC")"
fi
case "$name" in *.ipa) ;; *) name="app.ipa" ;; esac
base="${name%.ipa}"

# --- Profile (kommagetrennt, Pfade/Globs oder URLs) ---
n=0
IFS=',' read -r -a items <<< "$PROFILE_SRC"
for item in "${items[@]}"; do
  item="$(trim "$item")"
  [ -n "$item" ] || continue
  if is_url "$item"; then
    n=$((n + 1))
    echo "Lade Profil: $item"
    curl -fL --retry 3 -o "$WORK/profiles/$n.mobileprovision" "$item"
  else
    # shellcheck disable=SC2086
    for f in $item; do
      [ -f "$f" ] || continue
      n=$((n + 1))
      cp "$f" "$WORK/profiles/$n.mobileprovision"
    done
  fi
done
[ "$n" -ge 1 ] || { echo "::error::Kein Provisioning Profile gefunden: $PROFILE_SRC"; exit 1; }

# --- Zertifikat aus Secrets ---
[ -n "${P12_BASE64:-}" ] || { echo "::error::Secret P12_BASE64 fehlt (siehe README)"; exit 1; }
printf '%s' "$P12_BASE64" | openssl base64 -d -A > "$WORK/cert.p12"

{
  echo "RESIGN_WORK=$WORK"
  echo "OUT_IPA=$OUT/${base}-resigned.ipa"
  echo "KEYCHAIN_PASSWORD=$(openssl rand -base64 24)"
} >> "$GITHUB_ENV"

echo "IPA: $name | Profile: $n"
