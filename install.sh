#!/usr/bin/env bash
# Install Balaji's configs on a new laptop (Linux or macOS).
# Usage: bash install.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; }

has() { command -v "$1" >/dev/null 2>&1; }

backup() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        cp -a "$target" "${target}.bak-${STAMP}"
        warn "backed up $target -> ${target}.bak-${STAMP}"
    fi
}

# ---- detect platform -----------------------------------------------------
OS="$(uname -s)"
PM=""           # package manager: apt | dnf | pacman | zypper | brew
SUDO="sudo"

case "$OS" in
    Linux)
        if has apt-get;  then PM="apt"
        elif has dnf;    then PM="dnf"
        elif has pacman; then PM="pacman"
        elif has zypper; then PM="zypper"
        fi
        [ "$(id -u)" -eq 0 ] && SUDO=""
        ;;
    Darwin)
        if ! has brew; then
            log "installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
            if [ -x /usr/local/bin/brew ];   then eval "$(/usr/local/bin/brew shellenv)";   fi
        fi
        PM="brew"
        SUDO=""
        ;;
    *)
        err "unsupported OS: $OS"; exit 1 ;;
esac
log "detected OS=$OS  package-manager=$PM"

# ---- install packages ----------------------------------------------------
# Package names differ slightly across managers; kept in one place here.
install_pkgs() {
    case "$PM" in
        apt)
            $SUDO apt-get update
            $SUDO apt-get install -y \
                fish kitty neovim fd-find ripgrep eza zoxide bat btop htop \
                curl wget git build-essential \
                python3 python3-venv python3-pip \
                fontconfig unzip ca-certificates
            ;;
        dnf)
            $SUDO dnf install -y \
                fish kitty neovim fd-find ripgrep eza zoxide bat btop htop \
                curl wget git @development-tools \
                python3 python3-pip python3-virtualenv \
                fontconfig unzip ca-certificates
            ;;
        pacman)
            $SUDO pacman -Sy --needed --noconfirm \
                fish kitty neovim fd ripgrep eza zoxide bat btop htop \
                curl wget git base-devel \
                python python-pip \
                fontconfig unzip ca-certificates
            ;;
        zypper)
            $SUDO zypper --non-interactive install \
                fish kitty neovim fd ripgrep eza zoxide bat btop htop \
                curl wget git patterns-devel-base-devel_basis \
                python3 python3-pip \
                fontconfig unzip ca-certificates
            ;;
        brew)
            brew update
            brew install fish neovim fd ripgrep eza zoxide bat btop htop \
                         curl wget git python@3 unzip
            brew install --cask kitty font-hasklug-nerd-font || true
            ;;
        "")
            warn "no known package manager — install fish, kitty, neovim, fd, eza, zoxide, bat manually"
            ;;
    esac
}
log "installing packages"
install_pkgs

# fd-find on Debian/Ubuntu installs as 'fdfind' — symlink to 'fd' in ~/.local/bin
if [ "$PM" = "apt" ] && has fdfind && ! has fd; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "symlinked fdfind -> ~/.local/bin/fd"
fi

# ---- rust / cargo --------------------------------------------------------
if [ ! -d "$HOME/.cargo" ] && ! has cargo; then
    log "installing rustup + cargo"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
else
    ok "cargo already installed"
fi

# ---- atuin (shell history) ----------------------------------------------
if ! has atuin; then
    log "installing atuin"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
else
    ok "atuin already installed"
fi

# ---- Hasklug Nerd Font Mono ---------------------------------------------
install_hasklug_font() {
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hasklig.zip"
    local font_dir

    if [ "$OS" = "Darwin" ]; then
        # on macOS brew already installed the cask above; nothing to do.
        if fc-list 2>/dev/null | grep -qi 'hasklug'; then ok "Hasklug Nerd Font already present"; return; fi
        font_dir="$HOME/Library/Fonts"
    else
        if has fc-list && fc-list | grep -qi 'hasklug'; then ok "Hasklug Nerd Font already present"; return; fi
        font_dir="$HOME/.local/share/fonts"
    fi

    log "downloading Hasklug Nerd Font"
    mkdir -p "$font_dir"
    local tmp; tmp="$(mktemp -d)"
    if ! curl -fL --retry 3 -o "$tmp/Hasklig.zip" "$font_url"; then
        warn "font download failed — skipping (you can install 'Hasklug Nerd Font Mono' manually)"
        rm -rf "$tmp"; return
    fi
    unzip -oq "$tmp/Hasklig.zip" -d "$tmp/extracted"
    # keep only the Mono variants we actually use
    find "$tmp/extracted" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -exec cp {} "$font_dir/" \;
    rm -rf "$tmp"
    if has fc-cache; then fc-cache -f "$font_dir" >/dev/null; fi
    ok "installed Hasklug Nerd Font into $font_dir"
}
install_hasklug_font

# ---- copy configs --------------------------------------------------------
log "installing ~/.bashrc"
backup "$HOME/.bashrc"
cp "$DIR/.bashrc" "$HOME/.bashrc"

log "installing ~/.config/fish/config.fish"
mkdir -p "$HOME/.config/fish"
backup "$HOME/.config/fish/config.fish"
cp "$DIR/config.fish" "$HOME/.config/fish/config.fish"

log "installing ~/.config/kitty/kitty.conf"
mkdir -p "$HOME/.config/kitty"
backup "$HOME/.config/kitty/kitty.conf"
cp "$DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# ---- default shell -------------------------------------------------------
if has fish; then
    FISH_PATH="$(command -v fish)"
    if ! grep -qx "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "$FISH_PATH" | $SUDO tee -a /etc/shells >/dev/null
    fi
    if [ "${SHELL:-}" != "$FISH_PATH" ]; then
        log "setting fish as default shell (you may be prompted for your password)"
        chsh -s "$FISH_PATH" || warn "chsh failed — run 'chsh -s $FISH_PATH' manually"
    fi
fi

ok "done. open a new terminal to pick up the new shell, font, and configs."
