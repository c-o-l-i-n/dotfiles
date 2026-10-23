<p align="center">
  <img src="https://dotfiles.github.io/images/dotfiles-logo.png" height="72" />
</p>

<p align="center">
  <i>My personal configuration files for macOS.</i>
</p>

## Quick Start

Sign in to the App Store first. The `Brewfile` installs App Store apps with `mas`, which only works while signed in.

Then clone this repository and run the setup script:

```sh
git clone https://github.com/c-o-l-i-n/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh && exec zsh
```

`exec zsh` replaces your current shell, so the new shell configuration is active as soon as setup finishes.

## What It Does

The setup script:

- Installs Homebrew and everything in the `Brewfile`
- Links dotfiles into `~` with GNU Stow
- Installs node, pnpm, bun, and python with mise (`.config/mise/config.toml`)
- Installs Übersicht, simple-bar, and simple-bar-server
- Sets up yabai, skhd, and the yabai scripting addition's sudoers entry
- On macOS 27, rebuilds yabai 7.1.25 with `patches/yabai-macos27.patch` so space switching works, and pins it in Homebrew. Source: https://svenfrank.eu/posts/yabai-macos-27-scripting-addition/
- Configures Mousecape for the Banana cursor
- Applies the desktop wallpaper

The script is safe to run multiple times. It skips steps that are already done.

## Keeping It in Sync

List packages installed since the last `Brewfile` update. Anything under "Would uninstall" is missing from the `Brewfile`:

```sh
brew bundle cleanup --file="$HOME/dotfiles/Brewfile"
```

Don't add `--force`. It uninstalls those packages instead of listing them.

Installers like pnpm and vite+ append to `~/.zshrc`. Because `~/.zshrc` links into this repo, their changes show up in `git status`. Move them into `.config/zsh/init` before committing. The vite+ line is the exception: vite+ re-adds it unless it finds its own line in `.zshrc` and `.zshenv` themselves.

`~/.config` must stay a real directory. If it is ever a symlink into this repo, apps write their state and credentials into the working tree.

## Manual Steps

Some features need manual configuration after the script runs. The script lists them at the end.
