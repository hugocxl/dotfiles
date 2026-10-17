# dotfiles

My macOS setup: one command turns a fresh Mac into a ready-to-work machine,
and the same command keeps an existing one in sync. Tested on macOS 27 (Apple silicon).

- [Set up a new Mac](#set-up-a-new-mac)
- [Use on a Mac that's already set up](#use-on-a-mac-thats-already-set-up)
- [What it asks you](#what-it-asks-you)
- [After installing](#after-installing)
- [Day to day](#day-to-day)
- [Customizing](#customizing)
- [Undoing changes](#undoing-changes)
- [Troubleshooting](#troubleshooting)

## Set up a new Mac

1. Finish the macOS setup assistant, sign in with your Apple ID and connect to the internet.
2. Open **Terminal** (⌘Space, type "Terminal") and run:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/hugocxl/dotfiles/master/bootstrap.sh | bash
   ```

3. Enter your Mac password when asked. It's asked once and kept for the whole run.
4. Answer the questions as they come up (see [What it asks you](#what-it-asks-you)).
   The whole run takes roughly 15–30 minutes, mostly downloading apps.
5. When it prints **Done**, log out and back in (or restart).

`bootstrap.sh` does three things:

1. Installs the Xcode Command Line Tools, which provide `git`, without the GUI popup.
2. Clones this repo to `~/repos/dotfiles`, or pulls it if it's already there.
3. Runs `install.sh`, passing on any arguments you gave it.

To accept every default without being asked anything:

```sh
curl -fsSL https://raw.githubusercontent.com/hugocxl/dotfiles/master/bootstrap.sh | bash -s -- --yes
```

With `--yes`, a brand-new Mac gets no git email (there's nothing to default to).
Set it afterwards with `./install.sh git`.

To clone somewhere else, set `DOTFILES_DIR` (and `DOTFILES_REPO` for a fork):

```sh
curl -fsSL https://raw.githubusercontent.com/hugocxl/dotfiles/master/bootstrap.sh | DOTFILES_DIR=~/code/dotfiles bash
```

## Use on a Mac that's already set up

### Before the first run

The installer replaces some files in your home folder with links into this repo.
Nothing is deleted: every file it replaces is moved to
`~/.dotfiles-backup/<date-time>/` first. Still, check these:

| Existing file | What happens | What to do first |
| --- | --- | --- |
| `~/.zshrc` | Replaced | Copy anything machine-specific (extra `PATH`s, gcloud, Java, tokens) into `~/.zshrc.local`. |
| `~/.zprofile` | Replaced | Same as above. |
| `~/.gitconfig` | Moved away; your name and email are carried over | Copy any custom settings you want to keep into `~/.config/git/config.local`. |
| VS Code `settings.json` / `keybindings.json` | Replaced | If VS Code Settings Sync is on, it's fine; otherwise compare with `vscode/` first. |
| `~/.ssh/config` | A `Host *` keychain block is added at the end if missing | Nothing. |

Oh My Zsh isn't used any more but isn't removed either. Once you're happy, delete it
with `rm -rf ~/.oh-my-zsh`. The same goes for nvm (`brew uninstall nvm && rm -rf ~/.nvm`),
which mise replaces.

### Running it

```sh
cd ~/repos/dotfiles
./install.sh --list       # see the steps
./install.sh              # run everything
./install.sh git vscode   # run only some steps, in the order given
./install.sh --yes        # accept every default
./install.sh --help
```

Every step checks what's already in place and only changes what's missing, so
running it again is safe.

| Step | What it does |
| --- | --- |
| `xcode` | Installs the Xcode Command Line Tools, without the GUI prompt |
| `homebrew` | Installs Homebrew, turns its analytics off, updates it |
| `packages` | Installs everything in [`Brewfile`](Brewfile) with `brew bundle`. It tries to take over apps you installed by hand, so Homebrew keeps them updated |
| `dotfiles` | Links `~/.zshrc`, `~/.zprofile` and `~/.config/mise/config.toml`; makes zsh your shell |
| `git` | Links `~/.config/git/config` and `~/.config/git/ignore`, saves your name and email, logs into GitHub |
| `ssh` | Creates `~/.ssh/id_ed25519`, stores its passphrase in the keychain, uploads it to GitHub |
| `languages` | Installs Node LTS, pnpm and bun with mise; Rust stable with rustup |
| `vscode` | Links settings and keybindings, installs any missing extension from `vscode/extensions.txt` |
| `macos` | Applies [`macos/defaults.sh`](macos/defaults.sh) and [`macos/security.sh`](macos/security.sh), offers pending macOS updates |

## What it asks you

The Default column is the answer used with `--yes` or when you just press Enter.

| Step | Question | Default | Notes |
| --- | --- | --- | --- |
| start | Mac password | — | Needed for Homebrew, system settings and Touch ID setup |
| `git` | Git name / email | Your current values | Skipped once `~/.config/git/config.local` has an email |
| `git` | Log in to GitHub now? | Y | Opens the browser; uses SSH for git |
| `ssh` | Create an SSH key? | Y | Only if `~/.ssh/id_ed25519` doesn't exist. `ssh-keygen` asks for a passphrase: use one, the keychain remembers it |
| `ssh` | Add this key to your GitHub account? | Y | Only when logged into GitHub and the key isn't there yet |
| `macos` | Apply the macOS defaults? | Y | Answer no to skip all of `defaults.sh` |
| `macos` | Computer name | Current name | Also sets the network host name |
| `macos` | Clear all apps pinned to the Dock? | N | Say yes on a new Mac for an empty Dock |
| `macos` | Use Touch ID for sudo? | Y | Also works inside tmux |
| `macos` | Turn on the firewall? | Y | Includes stealth mode |
| `macos` | Require your password immediately after the screen locks? | Y | Asks your login password again. Skipped with `--yes` |
| `macos` | Install pending macOS updates now? | N | Can restart the Mac. Run it last, or later |

## After installing

A few things can't be scripted:

1. **Log out and back in** so the keyboard, trackpad and Dock settings apply.
2. **Open a new terminal** to get the new shell (or run `exec zsh -l`).
3. **1Password**: sign in. If you want, turn on its SSH agent in Settings → Developer.
4. **Raycast**: open it and set its hotkey to ⌘Space. The installer already freed
   that shortcut from Spotlight.
5. **Docker Desktop**, **Google Drive**, **Spotify**, **Arc**: open each once to sign in
   and grant permissions.
6. **FileVault**: if the installer warned it's off, turn it on in
   System Settings → Privacy & Security. Save the recovery key in 1Password.
7. **VS Code**: sign into Settings Sync if you use it.

## Day to day

| Command | What it does |
| --- | --- |
| `update` | Upgrades Homebrew packages, mise tools and Rust |
| `dotfiles` | `cd` into this repo |
| `reload` | Restarts the shell after editing the config |
| `zshconfig` | Opens `~/.zshrc` in VS Code |
| `git pull && ./install.sh` | Applies the latest version of the repo to this Mac |

Because the config files are symlinks, editing `~/.zshrc`, `~/.config/git/config` or
the VS Code settings edits the files in this repo. Commit them like any other change.

## Customizing

### Apps and CLI tools

Edit [`Brewfile`](Brewfile), then run `./install.sh packages`.

- Add an app: `cask "figma"`. Add a CLI tool: `brew "shellcheck"`. Search names with `brew search <name>`.
- Removing a line doesn't uninstall anything. To see what's installed but not in
  the Brewfile: `brew bundle cleanup --file=Brewfile`. To uninstall those:
  add `--force` (check the list first).
- Save everything currently installed to the Brewfile:
  `brew bundle dump --file=Brewfile --force`. This loses the comments and grouping.

### Node, pnpm, bun

Global versions are in [`mise/config.toml`](mise/config.toml). Per project, add a
`mise.toml`, `.nvmrc` or `.node-version` and mise switches automatically when you `cd` in.

```sh
mise use node@22        # pin a version in the current project
mise use -g node@24     # change the global version (edits mise/config.toml)
mise ls                 # what's installed
```

### Shell

- Shared config: [`zsh/.zshrc`](zsh/.zshrc) (interactive) and [`zsh/.zprofile`](zsh/.zprofile) (PATH).
- Machine-only config and secrets: `~/.zshrc.local`. It's loaded last and never committed.

### Git identity

Your name and email live in `~/.config/git/config.local`, which isn't committed.
To commit with a different email in some folders (for example, work repos), add this
to that file:

```ini
[includeIf "gitdir:~/repos/work/"]
path = ~/.config/git/work
```

and put a `[user]` section with the work email in `~/.config/git/work`.

### macOS settings

Edit [`macos/defaults.sh`](macos/defaults.sh), then run `./install.sh macos`.
To find the key for a setting:

```sh
defaults read > /tmp/before.txt
# change the setting in System Settings
defaults read > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
```

### VS Code extensions

`vscode/extensions.txt` has one extension ID per line; lines starting with `#` are
ignored. Refresh it from what's installed with:

```sh
code --list-extensions > vscode/extensions.txt
```

## Undoing changes

- **A replaced file**: it's in `~/.dotfiles-backup/<date-time>/` at the same path
  relative to your home folder. Put it back with, for example:

  ```sh
  rm ~/.zshrc && mv ~/.dotfiles-backup/<date-time>/.zshrc ~/.zshrc
  ```

- **A macOS setting**: `defaults delete <domain> <key>` returns it to the system
  default, for example `defaults delete com.apple.dock autohide && killall Dock`.
- **Touch ID for sudo**: `sudo rm /etc/pam.d/sudo_local`.
- **Firewall**: System Settings → Network → Firewall.

## Troubleshooting

- **"Some packages failed"**: usually an app that's open or was installed in an
  unusual way. Quit it (or delete it from /Applications) and run `./install.sh packages`.
- **`git` shows raw diffs or complains about `delta`**: the `packages` step didn't
  finish. Run `./install.sh packages`.
- **`command not found` right after installing**: open a new terminal; the current
  one still has the old PATH.
- **Key repeat isn't faster**: it needs a logout.
- **Command Line Tools won't install**: run `xcode-select --install`, finish the
  popup, then run `./install.sh` again.
- **Running it twice**: always safe. Steps that are already done print ✓ and move on.

## Layout

```
bootstrap.sh        curl | bash entry point
install.sh          step runner
Brewfile            CLI tools, fonts and apps
zsh/                .zshrc and .zprofile
git/                config and global ignore → ~/.config/git/
mise/               global Node/pnpm/bun versions → ~/.config/mise/
vscode/             settings, keybindings, extensions.txt
macos/              system defaults and security hardening
lib/utils.sh        logging, prompts, symlink-with-backup
```
