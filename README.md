# Ricing Tokyo Night — GNOME / Fedora

Thème Tokyo Night pour GNOME (testé sur Fedora 44, GNOME 50), installable sur un autre PC en une commande, **sans sudo**.

## Contenu

| Élément | Détail |
|---|---|
| Thème GTK | adw-gtk3-dark + couleurs Tokyo Night (`config/gtk/gtk.css`) |
| Icônes | Tokyonight-Dark |
| Terminal | kitty (sans barre de titre, onglets, splits), terminal par défaut |
| Prompt | Starship, preset Tokyo Night |
| fastfetch | logo perso 3 vagues + infos en sections |
| Extensions | Blur my Shell, Just Perfection, Rounded Window Corners, AppIndicator, Clipboard Indicator, Spotify Controls, Vitals, [Claude Usage](https://github.com/BlasterWhite/claude-usage-gnome) |
| Applications | fastfetch, Claude Code, VS Code (archive officielle), Spotify et Discord (Flatpak) — ignorées si déjà installées |
| Fond d'écran | Akihabara (par défaut) ou skyline Tokyo Night générée |
| Divers | Spotify en XWayland (barre de titre GNOME), redimensionnement Super + clic droit |

## Installation sur un autre PC

```bash
git clone <url-de-ton-dépôt> ~/ricing
cd ~/ricing
./install.sh
```

Puis **déconnexion / reconnexion** (obligatoire sous Wayland pour charger les extensions).

Options :

```bash
./install.sh --wallpaper tokyonight   # fond d'écran skyline au lieu d'Akihabara
./install.sh --no-kitty               # garder le terminal actuel
./install.sh --no-spotify-fix         # ne pas toucher à Spotify
./install.sh --no-claude-usage        # sans l'extension Claude Usage
./install.sh --no-apps                # n'installe aucune application
```

Prérequis : GNOME, `zsh`, `curl`, `git`, `gpg`, `python3`, `unzip`, `flatpak` (présents de base sur Fedora Workstation).
Les applications ne sont pas retirées par `restore.sh`.

## Ce que fait le script

1. **Sauvegarde** l'état actuel dans `~/ricing-backup-<date>/` avec un `restore.sh` pour tout annuler.
2. Télécharge depuis les sources officielles, avec vérification :
   - kitty : signature GPG de l'auteur (empreinte `3CE1 780F 78DD 88DF 4519 4FD7 06BC 317B 515A CE7C`)
   - Starship : somme SHA256
   - extensions : uniquement la version qui déclare **exactement** ta version de GNOME (sinon elle est ignorée, pas d'installation cassée)
3. Copie les configs dans `~/.config/`.
4. Ajoute **une seule ligne** à `~/.zshrc` pour charger Starship (le reste de ton `.zshrc` n'est pas touché).
5. Ajoute les raccourcis Super+T / Ctrl+Alt+T **sans écraser** tes raccourcis existants.

## Annuler

```bash
~/ricing-backup-<date>/restore.sh
```

## Raccourcis kitty

| Raccourci | Action |
|---|---|
| Ctrl+T | nouvel onglet (même dossier) |
| Ctrl+W | fermer l'onglet |
| Ctrl+Shift+Entrée | nouveau split |
| Ctrl+flèches | changer de split |
| Ctrl+Shift+L | changer la disposition |
| Super + glisser | déplacer la fenêtre |
| Super + clic droit | redimensionner |

## Personnaliser

- **Logo fastfetch** : `python3 config/fastfetch/wave_logo.py ~/.config/fastfetch/logo.txt 34 14` (largeur, hauteur)
- **Couleurs** : palette Tokyo Night — fond `#1a1b26`, texte `#c0caf5`, bleu `#7aa2f7`, violet `#bb9af7`, cyan `#7dcfff`
- **Mettre à jour le dépôt** après une modif sur ce PC :
  ```bash
  cp ~/.config/kitty/kitty.conf config/kitty/
  cp ~/.config/starship.toml config/
  cp ~/.config/fastfetch/{config.jsonc,logo.txt} config/fastfetch/
  ```

## Notes

- Le shell GNOME (barre du haut, menus) garde le style par défaut : le thème Tokyo Night du shell demande `sassc` (sudo) pour être compilé.
- `wallpapers/akihabara.jpg` est une photo tierce : si le dépôt est **public**, retire-la ou vérifie sa licence.
- `dconf/vitals.ini` contient un capteur de ventilateur ASUS : sur un autre PC il sera simplement ignoré.
