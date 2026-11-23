# Sourced by setup, update and verify. Keep exceptions local to this Mac.
build_package_plan() {
  BUNDLE_FILE="$(mktemp "${TMPDIR:-/tmp}/dotfiles-Brewfile.XXXXXX")" || return
  trap 'rm -f "$BUNDLE_FILE"' EXIT
  PRESERVED_CASKS=()
  local token app line skip found
  local conflicts=()
  while IFS='|' read -r token app; do
    if [[ -d "/Applications/$app" ]] && ! brew list --cask "$token" >/dev/null 2>&1; then
      conflicts+=("$token")
    fi
  done <<'APPS'
onedrive|OneDrive.app
brave-browser|Brave Browser.app
bitwarden|Bitwarden.app
raycast|Raycast.app
APPS
  while IFS= read -r line || [[ -n "$line" ]]; do
    found=0
    for skip in "${conflicts[@]}"; do
      if [[ "$line" == "cask \"$skip\"" ]]; then
        PRESERVED_CASKS+=("$skip")
        found=1
        break
      fi
    done
    if (( found == 0 )); then printf '%s\n' "$line"; fi
  done > "$BUNDLE_FILE"
}

report_preserved_casks() {
  local token
  for token in "${PRESERVED_CASKS[@]}"; do
    printf 'Present, vendor-managed: %s\n' "$token"
  done
}
