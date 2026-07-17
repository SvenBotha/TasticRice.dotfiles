# AGENTS.md — Bring-up runbook for TasticRice.dotfiles

This is the end-to-end procedure to take a **fresh macOS machine** to a fully
working setup from this repo alone. It is written for an automated agent, but a
human can follow it verbatim. Steps are marked **[auto]** (the script does it)
or **[manual]** (a human must do it — usually because a password or a GUI
permission is required, which no script or headless agent can supply).

---

## 0. Prerequisites

- macOS (Apple Silicon or Intel).
- Command Line Tools for Xcode (Homebrew installs these if missing).
- Network access.

---

## 1. Clone **[auto]**

```bash
git clone https://github.com/SvenBotha/TasticRice.dotfiles.git ~/dotfiles
cd ~/dotfiles
```

> `nvim/` is committed as plain files (NOT a git submodule), so a plain clone is
> complete. Do **not** pass `--recurse-submodules`.

---

## 2. Run the installer **[auto]**

```bash
./install.sh
```

The script is idempotent — re-running skips anything already installed and
re-copies configs (backing up existing ones with a timestamp first). It:

- Installs Homebrew (if missing) and updates it.
- Installs all CLI formulae (git, zsh, tmux, neovim, fzf, lazygit, node,
  python@3.12, eza, zoxide, ripgrep, fd, bat, htop, tree, wget, curl, jq, gh).
- Taps **and trusts** `nikitabobko/tap` (AeroSpace) and `FelixKratz/formulae`
  (sketchybar) — Homebrew 6+ refuses untrusted taps, so the trust step is
  required.
- Installs GUI casks: firefox, google-chrome, visual-studio-code, cursor,
  microsoft-teams, microsoft-outlook, whatsapp, obsidian, wezterm, zed,
  aerospace, raycast, and Nerd Fonts (Meslo/FiraCode/Hack).
- Installs Powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting.
- Copies configs to their destinations (see table below).
- Sets the wallpaper, installs tmux TPM + plugins, and starts sketchybar.

### Config destinations

| Source                     | Destination                     |
| -------------------------- | ------------------------------- |
| `Zshrc/zshrc`              | `~/.zshrc`                      |
| `WezTerm/wezterm.lua`      | `~/.wezterm.lua`                |
| `AeroSpace/aerospace.toml` | `~/.aerospace.toml`             |
| `Tmux/tmux.conf`           | `~/.tmux.conf`                  |
| `nvim/`                    | `~/.config/nvim/`               |
| `Zed/settings.json`        | `~/.config/zed/settings.json`   |
| `Sketchybar/`              | `~/.config/sketchybar/`         |

---

## 3. Headless / non-interactive runs (important for agents) **[auto]**

Two casks — **microsoft-teams** and **microsoft-outlook** — are `.pkg`
installers that call `sudo` and **prompt for a password at an interactive
terminal**. A background/headless agent cannot answer that prompt.

- Cask/formula failures are **non-fatal** (the script logs a warning and keeps
  going), so a password prompt failing will NOT abort the config-copy phase.
- To skip them cleanly (and avoid a wasted ~1.5 GB Outlook download that will
  fail anyway), set `SKIP_CASKS`:

  ```bash
  SKIP_CASKS="microsoft-teams microsoft-outlook whatsapp" ./install.sh
  ```

- Then install those apps **[manual]** in an interactive terminal where you can
  type your password (skip any that are already present in `/Applications`):

  ```bash
  brew install --cask --adopt microsoft-teams microsoft-outlook whatsapp
  ```

  `--adopt` takes over an already-installed copy instead of erroring.

---

## 4. After-commands (manual steps the script cannot do) **[manual]**

Run these once, in order, after `install.sh` finishes:

1. **Grant AeroSpace Accessibility permission**, then launch it. Tiling does
   nothing until this is granted:
   - System Settings → Privacy & Security → Accessibility → enable **AeroSpace**.
   - Launch AeroSpace (Applications, or `open -a AeroSpace`). It starts at login
     thereafter (`start-at-login = true`).

2. **Reload the shell and configure the prompt:**
   ```bash
   source ~/.zshrc
   p10k configure
   ```

3. **Bootstrap Neovim plugins** — launch nvim once and let Lazy.nvim install,
   then quit and reopen:
   ```bash
   nvim
   ```

4. **Verify Zed** — open it and confirm the Tokyo Night theme + MesloLGS font;
   install the Tokyo Night extension if prompted.

5. **Confirm the terminal font** — set WezTerm/your terminal to
   "MesloLGS Nerd Font Mono" if glyphs look wrong.

6. **(Optional) tmux plugins** — inside tmux press `Ctrl-Space` then `I` to
   force a TPM install if the auto-install was skipped.

---

## 5. Verification **[auto]**

```bash
# Window manager + status bar
[ -d /Applications/AeroSpace.app ] && echo "AeroSpace: ok"
pgrep -x sketchybar >/dev/null && echo "sketchybar: running"
brew services list | grep sketchybar

# Configs in place
for f in ~/.zshrc ~/.wezterm.lua ~/.aerospace.toml ~/.tmux.conf \
         ~/.config/nvim/init.lua ~/.config/zed/settings.json \
         ~/.config/sketchybar/sketchybarrc; do
  [ -e "$f" ] && echo "ok $f" || echo "MISSING $f"
done

# Core tools resolve
for c in nvim tmux eza zoxide rg fd bat fzf lazygit aerospace sketchybar; do
  command -v "$c" >/dev/null && echo "ok $c" || echo "MISSING $c"
done
```

---

## 6. Notes & gotchas

- **Sketchybar ↔ AeroSpace:** `aerospace.toml` runs
  `sketchybar --trigger aerospace_workspace_change` +
  `~/.config/sketchybar/plugins/update_workspace_icons.sh` on every workspace
  change. Both are provided by this repo. If you remove sketchybar, also delete
  the `exec-on-workspace-change` line from `aerospace.toml`.
- **Pre-existing apps:** casks use `--adopt`, so manually-installed apps are
  taken over rather than causing an error.
- **Already on zsh:** the `chsh` step compares the shell *basename*, so it won't
  prompt for a password if your login shell is already any `zsh`.
- **Firefox download flakiness:** Mozilla's CDN occasionally 404s a specific
  version mid-roll. If firefox fails, just re-run `install.sh` (or
  `brew install --cask firefox`); the non-fatal handler won't block the rest.

---

## 7. Updating

```bash
cd ~/dotfiles
git pull
./install.sh   # idempotent; backs up existing configs before overwriting
```
