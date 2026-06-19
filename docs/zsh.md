# Zsh configuration

A handcrafted, cross-platform (macOS + openSUSE) zsh setup. No framework —
just zsh built-ins plus a small set of well-chosen tools, each guarded so the
config still loads cleanly when a tool is missing.

- **Files:** `default/dot-zshenv`, `default/dot-zprofile`, `default/dot-zshrc`
  (stowed to `~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
- **Startup:** ~50 ms cold (login + interactive)

---

## Layout — which file does what

| File | Sourced for | Holds |
|------|-------------|-------|
| `.zshenv`   | every shell (incl. scripts) | XDG dirs, `EDITOR`/`VISUAL`/`PAGER`, locale, `less` config |
| `.zprofile` | login shells | Homebrew env, Go vars, `PATH` (deduped) |
| `.zshrc`    | interactive shells | history, options, completion, keybindings, prompt, aliases, functions, plugins |

Splitting these correctly is why `PATH` never doubles up and macOS's
`path_helper` can't shove system paths in front of yours.

---

## Install / provision

```bash
# clone, then symlink everything
cd ~/dotfiles && stow --dotfiles default git

# install the tool stack
brew bundle                         # macOS (uses ./Brewfile)
source init.sh && suse_packages     # openSUSE
```

The config detects what's present at startup. Missing a tool? That feature is
skipped silently and the rest works. After installing, open a new terminal or
run `reload` (alias for `exec zsh`).

**The stack:** `fzf`, `zoxide`, `eza`, `bat`, `fd`, `ripgrep`, plus zsh
`autosuggestions` / `syntax-highlighting` / `history-substring-search` /
`completions`.

---

## Reading the prompt

```
~/dev/dotfiles main ●⇡1                 ← line 1: path · git
❯                                        ← line 2: caret (green ok / red error)
```

| Element | Meaning |
|---------|---------|
| `~/d…/dotfiles` | current dir; shortens to `first/…/last2` once it's 4+ levels deep |
| `main`          | git branch (magenta) |
| `●` yellow      | unstaged changes |
| `●` green       | staged changes |
| `⇡2` / `⇣1`     | commits ahead / behind upstream |
| `\|rebase`      | in-progress git action (rebase, merge, …) |
| `user@host`     | shown **only** over SSH |
| `❯` green/red   | last command succeeded / failed; turns into `❮` in vi-normal mode |
| right side      | wall-clock time of the last command, shown only if it ran ≥ 3 s |

The git data comes from zsh's built-in `vcs_info` (no `git` subshell on every
keystroke), so the prompt stays fast even in large repos.

---

## Vi mode

The line editor is in **vi mode**. You start each line in *insert*; press `ESC`
to reach *normal* mode (the cursor changes **beam → block**, and the caret flips
to `❮`). `KEYTIMEOUT=1` makes that switch feel instant.

| In normal mode | Does |
|----------------|------|
| `h j k l`, `w b e`, `0 $`, `dd`, `cw`, `ciw`, `x`, … | the usual vi motions/edits |
| `j` / `k` | search history **down / up** (by current prefix) |
| `v` | open the current command line in `$EDITOR` (nvim), edit, `:wq` to run |

Comfort keys that still work **in insert mode** (so you don't have to leave it):

| Key | Does |
|-----|------|
| `Ctrl-A` / `Ctrl-E` | start / end of line |
| `Ctrl-W` | delete previous word |
| `Ctrl-U` | delete to start of line |
| `Ctrl-K` | delete to end of line |
| `Ctrl-Y` | paste what you just killed |
| `↑` / `↓` | history search by prefix |

---

## History

- **50 000** lines, stored at `~/.local/state/zsh/history`.
- **Shared** live across every open shell (`SHARE_HISTORY`).
- **Deduped** — re-running a command moves it up instead of piling up.
- **Privacy:** prefix any command with a **leading space** and it's never
  recorded.
- `Ctrl-R` → fuzzy history search (fzf). `↑`/`j`,`k` → prefix history search.
- `HIST_VERIFY`: `!!`, `!$`, `!abc` expand onto the line for you to confirm,
  rather than running blind.

---

## Completion (Tab)

- Press `Tab` to complete; press again to enter a **menu** you arrow through.
- **Case-insensitive & partial:** `cd dot<Tab>` finds `Dotfiles`, `cd ofi<Tab>`
  can find `dotfiles`.
- Colored, grouped, and described matches.
- The completion dump is cached and only rebuilt (with its security audit) once
  a day, so startup stays quick.

---

## Getting around

| You type | Result |
|----------|--------|
| `dotfiles` (a dir name) | `cd dotfiles` — bare directory names are `cd` (`AUTO_CD`) |
| `..`, `...`, `....` | up 1 / 2 / 3 levels |
| `-` | back to the previous directory |
| `cd -<Tab>` | pick from the **stack** of dirs you've visited (`AUTO_PUSHD`) |
| `z proj` | jump to the most-used dir matching `proj` (zoxide) |
| `zi proj` | same, but pick interactively from matches |
| `up 3` | climb 3 directories |
| `mkcd new/deep/dir` | make the dir (and parents) and enter it |

---

## fzf (fuzzy finder)

| Key | What it fuzzy-finds |
|-----|---------------------|
| `Ctrl-R` | command history |
| `Ctrl-T` | files under the cwd (preview via `bat`) — inserts the path |
| `Alt-C`  | subdirectories (preview via `eza --tree`) — `cd`s into the pick |

Searches use `fd`, so they're fast and skip `.git` (but include dotfiles).
Works anywhere you're typing a command, e.g. `nvim <Ctrl-T>`.

---

## Aliases

**Listing** (`eza`, falls back to plain `ls` colors):

| Alias | Command |
|-------|---------|
| `ls`  | `eza --group-directories-first --icons` |
| `ll`  | long view + git status column |
| `la`  | include dotfiles |
| `lla` | long + dotfiles |
| `lt`  | tree, 2 levels deep |

**Viewing:** `cat` → `bat` (syntax-highlighted, no pager); `catp` keeps line
numbers/decorations. `man` pages render through `bat` too.

**git:** `g` `gs` (`status -sb`) `ga` `gc` `gca` `gco` `gb` `gd` `gds`
(`diff --staged`) `gp` `gpl` `gl` (graph log) `glog` (pretty graph).

**Safety / convenience:** `mv` `cp` `rm` prompt before clobbering (`-i`);
`mkdir -p` always; `df`/`du` human-readable; `:q` → exit; `clear` keeps
scrollback; `reload` → `exec zsh`; `path` prints `$PATH` one entry per line;
`ts` → timestamp; `serve` → `python3 -m http.server`.

**macOS only:** `o` (open), `copy` (pbcopy), `flushdns`, `showfiles`/`hidefiles`.

---

## Functions

| Function | Purpose |
|----------|---------|
| `mkcd <dir>` | make a directory (with parents) and `cd` into it |
| `up [n]` | go up `n` directories (default 1) |
| `extract <archive>` | unpack `.tar.*`, `.zip`, `.7z`, `.rar`, `.gz`, `.zst`, … |

---

## Tools at a glance

| Tool | Replaces / adds | Try |
|------|-----------------|-----|
| `eza` | `ls` | `ll`, `lt` |
| `bat` | `cat` / `less` | `bat file`, `cat file` |
| `fd`  | `find` | `fd pattern` |
| `rg`  | `grep -r` | `rg pattern` |
| `fzf` | interactive filter | `Ctrl-R`, `Ctrl-T`, `Alt-C` |
| `zoxide` | smarter `cd` | `z name`, `zi` |
| autosuggestions | — | grey suggestion as you type; `→` / `Ctrl-E` accepts |
| syntax-highlighting | — | commands turn green when valid, red when not |

---

## Tips

- **Accept a suggestion:** when grey ghost-text appears, press `→` (or `Ctrl-E`)
  to take it; `Ctrl-→` to take just one word.
- **Hide a command from history:** start it with a space.
- **Re-run with edits:** `Ctrl-R`, find it, then `←`/`ESC` to edit before
  running instead of pressing Enter.
- **Big edits:** press `v` (vi-normal) to open the line in nvim — great for long
  pipelines or pasted multi-line commands.
- **Faster `cd`:** let `z` learn your habits for a few days, then `z proj`
  beats typing full paths.
- **Open a file fast:** `nvim <Ctrl-T>` then fuzzy-type the name.

---

## Customizing

- **Machine-specific or secret settings:** put them in `~/.zshrc.local`. It's
  sourced last (if present) and is **not** tracked by the dotfiles repo — ideal
  for work tokens, per-host `PATH` tweaks, or one-off aliases.
- **Permanent changes:** edit `default/dot-zshrc` in the repo (the live file is
  a symlink to it), then `reload`.

---

## Troubleshooting

- **`zsh compinit: insecure directories`** — a dir in `fpath` is
  group/other-writable. On macOS this is usually Homebrew's `share`:
  `chmod g-w "$(brew --prefix)/share"`. (Provisioning via `brew_packages` in
  `init.sh` does this for you.) The config also runs `compinit -i`, so it will
  never *hang* on the prompt — worst case it skips the flagged dir.
- **A feature is missing** — the tool probably isn't installed; run
  `brew bundle` / `suse_packages`. Check with e.g. `command -v fzf`.
- **Stale completions** — `rm ~/.cache/zsh/zcompdump && reload` to rebuild.
- **Time a slow startup** — `time zsh -lic exit`, or add
  `zmodload zsh/zprof` at the top of `.zshrc` and run `zprof` to profile.
