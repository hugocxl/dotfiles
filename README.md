# dotfiles

My macOS setup: one command turns a fresh Mac into a ready-to-work machine,
and the same command keeps an existing one in sync. Tested on macOS 27 (Apple silicon).

## New Mac

```sh
curl -fsSL https://raw.githubusercontent.com/hugocxl/dotfiles/master/bootstrap.sh | bash
```

This installs the Xcode Command Line Tools, clones the repo to `~/repos/dotfiles`
and runs `install.sh`. You'll be asked a few questions along the way (git identity,
SSH key, Touch ID for sudo…). Add `-s -- --yes` after `bash` to accept every default.

## Existing Mac

```sh
./install.sh              # everything
./install.sh git vscode   # only some steps
./install.sh --list       # what each step does
./install.sh --yes        # no questions
```

Every step is idempotent. Files that would be replaced are moved to
`~/.dotfiles-backup/<timestamp>/` first, never deleted.

| Step        | What it does                                                         |
| ----------- | -------------------------------------------------------------------- |
| `xcode`     | Xcode Command Line Tools, installed without the GUI prompt           |
| `homebrew`  | Installs Homebrew and turns analytics off                            |
| `packages`  | `brew bundle` from [`Brewfile`](Brewfile)                             |
| `dotfiles`  | Links `~/.zshrc`, `~/.zprofile` and the mise config                  |
| `git`       | Links the git config, asks for your name/email, logs into GitHub     |
| `ssh`       | Creates an ed25519 key, stores it in the keychain, uploads to GitHub |
| `languages` | Node LTS, pnpm and bun via mise; Rust stable via rustup              |
| `vscode`    | Links settings and keybindings, installs missing extensions          |
| `macos`     | [`defaults.sh`](macos/defaults.sh), [`security.sh`](macos/security.sh), optional OS update |

## Layout

```
bootstrap.sh        curl | bash entry point
install.sh          step runner
Brewfile            CLI tools, fonts and apps
zsh/                .zshrc (no framework, ~0.1s startup) and .zprofile (PATH)
git/                config and global ignore → ~/.config/git/
mise/               global Node/pnpm/bun versions → ~/.config/mise/
vscode/             settings, keybindings, extensions.txt
macos/              system defaults and security hardening
lib/utils.sh        logging, prompts, symlink-with-backup
```

## Not tracked on purpose

- `~/.zshrc.local`: machine-specific PATHs, tokens, work-only aliases.
- `~/.config/git/config.local`: name and email, written by `install.sh git`.
  For a separate work identity, add to it:

  ```ini
  [includeIf "gitdir:~/repos/work/"]
  path = ~/.config/git/work
  ```

## Day to day

- `update`: upgrade Homebrew packages, mise tools and Rust.
- `dotfiles`: cd into this repo.
- Installed something new with brew? `brew bundle dump --file=Brewfile --force`
  to save it, or `brew bundle cleanup --file=Brewfile` to see strays.
