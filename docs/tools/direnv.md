# direnv: per-project environments

Nothing language-specific is installed globally. Each project declares
its own tools in a Nix dev shell, and **direnv** loads that shell automatically
when you `cd` into the project and unloads it when you leave.
**nix-direnv** caches the shell, so after the first build entering the
directory takes a fraction of a second, and it protects the shell from garbage
collection while the project's `.direnv/` exists.

Configured in `modules/home/cli.nix`.

## Give a project its own environment

Ready-made `flake.nix` and `.envrc` files for each language are in
[projects.md](projects.md). The general shape:

In the project root, create `flake.nix`:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [ pkgs.go pkgs.gopls ];   # whatever the project needs
        # Environment variables can go here too, e.g. APP_ENV = "dev";
      };
    };
}
```

and `.envrc` containing one line:

```bash
use flake
```

Then:

```bash
git add flake.nix .envrc   # flakes only see files Git knows about
direnv allow               # trust this .envrc once
```

The first load builds the shell (seconds to minutes, depending on the tools);
`flake.lock` is created, and should be committed so everyone gets the same
versions. `.direnv/` is ignored globally, so it never needs committing.

Python projects are the exception: they use `uv` for the interpreter and
packages and keep all configuration in `pyproject.toml`
([projects.md](projects.md#python)). A dev shell can still provide non-Python
tools.

Entering a project prints `direnv: loading …` but not the long list of exported
variables (`hide_env_diff`). `direnv status` shows what is loaded.

## Everyday commands

| Command | Does |
|---|---|
| `direnv allow` | Trust the current `.envrc`; needed again after every edit to it |
| `direnv deny` | Stop loading it |
| `direnv reload` | Rebuild and reload after changing `flake.nix` |
| `direnv status` | What is loaded and why |
| `nix flake update` | In the project: update its pinned nixpkgs, then `direnv reload` |

Leaving the directory unloads everything; `which go` outside it shows nothing
(or the global version, if there were one).

## When something looks wrong

- **"direnv: error .envrc is blocked"**: run `direnv allow`.
- **Changed `flake.nix` but nothing happened**: `direnv reload`. New files must
  be `git add`ed first.
- **Slow on every `cd`**: the cache is being invalidated; check that
  `flake.nix`/`flake.lock` are not rewritten by a tool on every run.
- **Free disk space from an old project**: delete that project's `.direnv/`
  folder; the next weekly garbage collection can then remove its shell.
