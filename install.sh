#!/usr/bin/env bash
# Installe le ricing Tokyo Night sur une session GNOME (Fedora testé, GNOME 50).
# Tout s'installe dans le dossier utilisateur : pas besoin de sudo.
#
# Usage : ./install.sh [--wallpaper akihabara|tokyonight] [--no-kitty] [--no-spotify-fix] [--no-claude-usage]
set -euo pipefail

# ─── Options ──────────────────────────────────────────────────────────────────
WALLPAPER="akihabara"
WITH_KITTY=1
SPOTIFY_FIX=1
CLAUDE_USAGE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --wallpaper) WALLPAPER="$2"; shift 2 ;;
    --no-kitty) WITH_KITTY=0; shift ;;
    --no-spotify-fix) SPOTIFY_FIX=0; shift ;;
    --no-claude-usage) CLAUDE_USAGE=0; shift ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share"
CONF="$HOME/.config"
mkdir -p "$BIN" "$SHARE/themes" "$SHARE/icons" "$SHARE/fonts" "$SHARE/backgrounds" "$SHARE/applications" "$CONF"

say()  { printf '\n\033[1;34m→ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m⚠\033[0m %s\n' "$*"; }
gh_latest() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | python3 -I -c 'import sys,json;print(json.load(sys.stdin)["tag_name"])'; }

# ─── Prérequis ────────────────────────────────────────────────────────────────
say "Vérification des prérequis"
for cmd in curl git tar unzip python3 gpg gsettings dconf gnome-extensions gnome-shell fc-cache; do
  command -v "$cmd" >/dev/null || { echo "Commande manquante : $cmd" >&2; exit 1; }
done
SHELL_MAJOR="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
ok "GNOME Shell $SHELL_MAJOR"

# ─── Sauvegarde de l'état actuel ──────────────────────────────────────────────
BACKUP="$HOME/ricing-backup-$(date +%Y-%m-%d_%H%M%S)"
say "Sauvegarde dans $BACKUP"
mkdir -p "$BACKUP/files"
dconf dump / > "$BACKUP/dconf-full.ini"
for f in .zshrc .config/kitty .config/starship.toml .config/fastfetch .config/gtk-3.0/gtk.css .config/gtk-4.0/gtk.css .config/xdg-terminals.list; do
  if [ -e "$HOME/$f" ]; then
    mkdir -p "$BACKUP/files/$(dirname "$f")"
    cp -a "$HOME/$f" "$BACKUP/files/$f"
  fi
done
ls "$SHARE/gnome-shell/extensions" > "$BACKUP/installed-extensions.txt" 2>/dev/null || true
cat > "$BACKUP/restore.sh" <<'EOF'
#!/usr/bin/env bash
# Restaure l'état d'avant install.sh
set -e
B="$(cd "$(dirname "$0")" && pwd)"
dconf reset -f /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/
dconf load / < "$B/dconf-full.ini"
for f in .config/kitty .config/starship.toml .config/fastfetch .config/gtk-3.0/gtk.css .config/gtk-4.0/gtk.css .config/xdg-terminals.list; do
  rm -rf "$HOME/$f"
done
cp -a "$B/files/." "$HOME/"
rm -f "$HOME/.config/gnome-xdg-terminals.list"
for d in "$HOME/.local/share/gnome-shell/extensions/"*; do
  grep -qx "$(basename "$d")" "$B/installed-extensions.txt" 2>/dev/null || rm -rf "$d"
done
flatpak override --user --reset com.spotify.Client 2>/dev/null || true
rm -f "$HOME/.var/app/com.spotify.Client/config/spotify-flags.conf"
echo "✔ Restauré. Déconnecte-toi / reconnecte-toi."
EOF
chmod +x "$BACKUP/restore.sh"
ok "Pour annuler : $BACKUP/restore.sh"

# ─── Police : FiraMono Nerd Font ──────────────────────────────────────────────
say "Police FiraMono Nerd Font"
if fc-list | grep -q 'FiraMono Nerd Font'; then
  ok "déjà installée"
else
  curl -fsSL -o "$TMP/FiraMono.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraMono.tar.xz
  mkdir -p "$SHARE/fonts/FiraMonoNerdFont"
  tar -xJf "$TMP/FiraMono.tar.xz" -C "$SHARE/fonts/FiraMonoNerdFont"
  fc-cache -f >/dev/null
  ok "installée"
fi

# ─── Thème GTK adw-gtk3 ───────────────────────────────────────────────────────
say "Thème GTK adw-gtk3"
TAG="$(gh_latest lassekongo83/adw-gtk3)"
curl -fsSL -o "$TMP/adw.tar.xz" "https://github.com/lassekongo83/adw-gtk3/releases/download/$TAG/adw-gtk3${TAG}.tar.xz"
tar -xJf "$TMP/adw.tar.xz" -C "$SHARE/themes"
ok "adw-gtk3 $TAG"
for v in gtk-3.0 gtk-4.0; do
  mkdir -p "$CONF/$v"
  cp "$REPO/config/gtk/gtk.css" "$CONF/$v/gtk.css"
done
ok "couleurs Tokyo Night (gtk.css)"

# ─── Icônes Tokyonight-Dark ───────────────────────────────────────────────────
say "Icônes Tokyonight-Dark"
git clone -q --depth 1 https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git "$TMP/tokyonight"
rm -rf "$SHARE/icons/Tokyonight-Dark"
cp -a "$TMP/tokyonight/icons/Tokyonight-Dark" "$SHARE/icons/"
gtk-update-icon-cache -q "$SHARE/icons/Tokyonight-Dark" 2>/dev/null || true
ok "installées"

# ─── Starship ─────────────────────────────────────────────────────────────────
say "Starship"
SS=https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
curl -fsSL -o "$TMP/starship.tar.gz" "$SS"
echo "$(curl -fsSL "$SS.sha256")  $TMP/starship.tar.gz" | sha256sum -c --quiet
tar -xzf "$TMP/starship.tar.gz" -C "$BIN" starship
cp "$REPO/config/starship.toml" "$CONF/starship.toml"
ok "$("$BIN/starship" --version | head -1) (somme SHA256 vérifiée)"

# ─── kitty ────────────────────────────────────────────────────────────────────
if [ "$WITH_KITTY" = 1 ]; then
  say "kitty"
  KV="$(gh_latest kovidgoyal/kitty)"; KV="${KV#v}"
  KU="https://github.com/kovidgoyal/kitty/releases/download/v$KV/kitty-$KV-x86_64.txz"
  curl -fsSL -o "$TMP/kitty.txz" "$KU"
  curl -fsSL -o "$TMP/kitty.txz.sig" "$KU.sig"
  curl -fsSL -o "$TMP/kovid.gpg" https://calibre-ebook.com/signatures/kovid.gpg
  mkdir -m 700 "$TMP/gnupg"
  GNUPGHOME="$TMP/gnupg" gpg -q --import "$TMP/kovid.gpg" 2>/dev/null
  # empreinte attendue de la clé de Kovid Goyal
  GPG_STATUS="$(GNUPGHOME="$TMP/gnupg" gpg --status-fd 1 --verify "$TMP/kitty.txz.sig" "$TMP/kitty.txz" 2>/dev/null || true)"
  case "$GPG_STATUS" in
    *"VALIDSIG 3CE1780F78DD88DF45194FD706BC317B515ACE7C"*) ;;
    *) echo "Signature kitty invalide !" >&2; exit 1 ;;
  esac
  rm -rf "$HOME/.local/kitty.app" && mkdir -p "$HOME/.local/kitty.app"
  tar -xJf "$TMP/kitty.txz" -C "$HOME/.local/kitty.app"
  ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$BIN/"
  for f in kitty.desktop kitty-open.desktop; do
    sed -e "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|" \
        -e "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|" \
        "$HOME/.local/kitty.app/share/applications/$f" > "$SHARE/applications/$f"
  done
  mkdir -p "$CONF/kitty" && cp "$REPO/config/kitty/kitty.conf" "$CONF/kitty/kitty.conf"
  echo "kitty.desktop" > "$CONF/xdg-terminals.list"
  echo "kitty.desktop" > "$CONF/gnome-xdg-terminals.list"
  ok "kitty $KV (signature GPG vérifiée), terminal par défaut"
fi

# ─── fastfetch ────────────────────────────────────────────────────────────────
say "fastfetch"
mkdir -p "$CONF/fastfetch"
cp "$REPO/config/fastfetch/"* "$CONF/fastfetch/"
command -v fastfetch >/dev/null && ok "config copiée" || warn "config copiée, mais fastfetch n'est pas installé (sudo dnf install fastfetch)"

# ─── zsh ──────────────────────────────────────────────────────────────────────
say "zsh"
mkdir -p "$CONF/zsh" && cp "$REPO/config/zsh/ricing.zsh" "$CONF/zsh/ricing.zsh"
LINE='[ -f ~/.config/zsh/ricing.zsh ] && source ~/.config/zsh/ricing.zsh'
touch "$HOME/.zshrc"
grep -qxF "$LINE" "$HOME/.zshrc" || printf '\n# Ricing Tokyo Night (prompt Starship)\n%s\n' "$LINE" >> "$HOME/.zshrc"
ok "Starship chargé depuis ~/.zshrc"
grep -qE '^[^#]*(powerlevel10k|p10k)' "$HOME/.zshrc" && warn "Powerlevel10k est actif dans ~/.zshrc : commente ses lignes pour laisser la place à Starship"
[ "$(basename "${SHELL:-}")" = zsh ] || warn "ton shell n'est pas zsh (chsh -s \$(which zsh))"

# ─── Extensions GNOME ─────────────────────────────────────────────────────────
say "Extensions GNOME (compatibles GNOME $SHELL_MAJOR uniquement)"
EXTENSIONS=(
  blur-my-shell@aunetx
  just-perfection-desktop@just-perfection
  rounded-window-corners@fxgn
  appindicatorsupport@rgcjonas.gmail.com
  clipboard-indicator@tudmotu.com
  spotify-controls@Sonath21
  Vitals@CoreCoding.com
)
ENABLED=()
for uuid in "${EXTENSIONS[@]}"; do
  # extension système déjà présente (ex. paquet dnf) : on l'active seulement
  if gnome-extensions info "$uuid" >/dev/null 2>&1 && [ ! -d "$SHARE/gnome-shell/extensions/$uuid" ]; then
    ENABLED+=("$uuid"); ok "$uuid (déjà installée sur le système)"; continue
  fi
  # pk de la version qui déclare EXACTEMENT ce GNOME (le site renvoie sinon une ancienne version)
  PK="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$uuid" | python3 -I -c '
import sys, json
m = json.load(sys.stdin).get("shell_version_map", {})
print(m.get(sys.argv[1], {}).get("pk", ""))' "$SHELL_MAJOR" 2>/dev/null || true)"
  if [ -z "$PK" ]; then
    warn "$uuid : pas de version pour GNOME $SHELL_MAJOR, ignorée"; continue
  fi
  curl -fsSL -o "$TMP/$uuid.zip" "https://extensions.gnome.org/download-extension/$uuid.shell-extension.zip?version_tag=$PK"
  gnome-extensions install --force "$TMP/$uuid.zip"
  ENABLED+=("$uuid"); ok "$uuid"
done
# Claude Usage : extension perso, hors extensions.gnome.org (github.com/BlasterWhite/claude-usage-gnome)
if [ "$CLAUDE_USAGE" = 1 ]; then
  CU=claude-usage@perso
  if [ -L "$SHARE/gnome-shell/extensions/$CU" ]; then
    ok "$CU (lien de dev déjà en place, non modifié)"
  elif command -v glib-compile-schemas >/dev/null; then
    git clone -q --depth 1 https://github.com/BlasterWhite/claude-usage-gnome.git "$TMP/claude-usage"
    glib-compile-schemas "$TMP/claude-usage/$CU/schemas"
    rm -rf "$SHARE/gnome-shell/extensions/$CU"
    cp -a "$TMP/claude-usage/$CU" "$SHARE/gnome-shell/extensions/$CU"
    ok "$CU"
  else
    warn "$CU : glib-compile-schemas manquant, ignorée"
  fi
  [ -e "$SHARE/gnome-shell/extensions/$CU" ] && ENABLED+=("$CU")
fi
# ajoute les extensions à la liste existante sans retirer celles déjà actives
python3 -I - "${ENABLED[@]}" <<'EOF'
import ast, subprocess, sys
cur = ast.literal_eval(subprocess.check_output(["gsettings", "get", "org.gnome.shell", "enabled-extensions"], text=True).replace("@as ", ""))
new = cur + [u for u in sys.argv[1:] if u not in cur]
subprocess.check_call(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(new)])
EOF
gsettings set org.gnome.shell disable-user-extensions false
dconf load /org/gnome/shell/extensions/vitals/ < "$REPO/dconf/vitals.ini"
[ "$CLAUDE_USAGE" = 1 ] && dconf load /org/gnome/shell/extensions/claude-usage/ < "$REPO/dconf/claude-usage.ini"

# ─── Réglages GNOME, fond d'écran, raccourcis ─────────────────────────────────
say "Réglages GNOME"
grep -v '^#' "$REPO/dconf/gnome.ini" | dconf load /
case "$WALLPAPER" in
  tokyonight) WP_SRC="$REPO/wallpapers/tokyonight-city.png" ;;
  *)          WP_SRC="$REPO/wallpapers/akihabara.jpg" ;;
esac
WP="$SHARE/backgrounds/$(basename "$WP_SRC")"
cp "$WP_SRC" "$WP"
gsettings set org.gnome.desktop.background picture-uri "file://$WP"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$WP"
gsettings set org.gnome.desktop.screensaver picture-uri "file://$WP"
ok "thème, icônes, accent bleu, redimensionnement Super + clic droit, fond d'écran"

if [ "$WITH_KITTY" = 1 ]; then
  KB=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
  python3 -I - "$KB" <<'EOF'
import ast, subprocess, sys
kb = sys.argv[1]
key = ["org.gnome.settings-daemon.plugins.media-keys", "custom-keybindings"]
cur = ast.literal_eval(subprocess.check_output(["gsettings", "get", *key], text=True).replace("@as ", ""))
for name in ("ricing-kitty-super", "ricing-kitty-ctrlalt"):
    p = f"{kb}/{name}/"
    if p not in cur:
        cur.append(p)
subprocess.check_call(["gsettings", "set", *key, str(cur)])
EOF
  KITTY="$HOME/.local/kitty.app/bin/kitty"
  dconf write "$KB/ricing-kitty-super/name" "'Terminal (kitty)'"
  dconf write "$KB/ricing-kitty-super/command" "'$KITTY'"
  dconf write "$KB/ricing-kitty-super/binding" "'<Super>t'"
  dconf write "$KB/ricing-kitty-ctrlalt/name" "'Terminal (kitty)'"
  dconf write "$KB/ricing-kitty-ctrlalt/command" "'$KITTY'"
  dconf write "$KB/ricing-kitty-ctrlalt/binding" "'<Control><Alt>t'"
  ok "Super+T et Ctrl+Alt+T ouvrent kitty"
fi

# ─── Spotify (Flatpak) : barre de titre GNOME via XWayland ────────────────────
if [ "$SPOTIFY_FIX" = 1 ] && flatpak info com.spotify.Client >/dev/null 2>&1; then
  say "Spotify"
  flatpak override --user --nosocket=wayland --socket=x11 com.spotify.Client
  mkdir -p "$HOME/.var/app/com.spotify.Client/config"
  printf '# Forcer X11 (XWayland) pour avoir la barre de titre GNOME\n--ozone-platform=x11\n' \
    > "$HOME/.var/app/com.spotify.Client/config/spotify-flags.conf"
  ok "Spotify passe par XWayland (relance-le)"
fi

say "Terminé !"
echo "  • Déconnecte-toi puis reconnecte-toi pour charger les extensions."
echo "  • Pour tout annuler : $BACKUP/restore.sh"
