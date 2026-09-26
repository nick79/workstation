# Setting up a project, per language

Nothing language-specific is installed globally. A project brings its
own toolchain, and two small files in its root make that automatic:

- **`flake.nix`** says which tools the project needs (compiler, runtime,
  build tool). Nix fetches exactly those versions.
- **`.envrc`** tells direnv to load them when you `cd` into the directory and
  unload them when you leave. One line: `use flake`.

How direnv and nix-direnv work, and what to do when something looks wrong,
is in [direnv.md](direnv.md). This page is the recipe for each language.

Python is different: `uv` provides Python itself, because nixpkgs Python has
had library-loading problems (libffi) on macOS; re-check that before changing
it. Everything lives in `pyproject.toml`, one file for the project and all its
tools, which uv, ruff, ty, pytest and rumdl all read. It needs no `flake.nix`.

## The steps, for any language

1. Create `flake.nix` and `.envrc` from the section for the language below.
2. Make Git aware of them and trust the `.envrc` once:

   ```bash
   git add flake.nix .envrc      # flakes only see files Git knows about
   direnv allow
   ```

3. The first load downloads the tools (seconds to minutes). A `flake.lock`
   appears: commit it, so the versions stay the same until you run
   `nix flake update` (then `direnv reload`).
4. **Start Neovim from the project directory**, after direnv has loaded.
   Language servers and tools that must match the project (marked "from the
   project" below) are found on the project's `PATH`, so they are missing if
   Neovim was started elsewhere.

`.direnv/` is ignored in every repository already; never commit it.

The recipes use `pkgs.mkShellNoCC`, a shell with only the listed packages.
`pkgs.mkShell` would add Nix's C toolchain and set `DEVELOPER_DIR` and
`SDKROOT`, which redirects macOS's own developer tools to the Nix SDK: inside
such a shell `/usr/bin/python3` fails with "tool 'python3' not found", and
Apple clang is replaced. Use `mkShell` only when a project deliberately builds
with Nix's compiler toolchain instead of Apple's.

Most language servers ship with Neovim, but where a server or linter has to
match the project's toolchain, it comes from the project.

| Language | Editor provides | Project provides |
|---|---|---|
| Python | ty, ruff, debugger launcher | Python (via uv), pytest, packages |
| Java / Spring | jdtls, Lombok, debug and test bundles, Spring Boot LS, and the JDK they run on | the project's JDK, Maven or Gradle |
| JavaScript / TypeScript / Vue | vtsls, vue_ls, eslint and prettier servers | Node, package manager, TypeScript, eslint, prettier (`node_modules`) |
| Go | gopls, delve | Go, golangci-lint |
| Rust | rustaceanvim (debugging with Apple's `lldb-dap`) | rustc, cargo, rust-analyzer, rustfmt, clippy |
| C / C++ | clangd, clang-format (debugging with Apple's `lldb-dap`) | compiler (Apple clang), CMake, libraries, `compile_commands.json` |
| Ruby | nothing | Ruby, Bundler, ruby-lsp and rubocop/standard (Gemfile) |
| PHP | phpactor | PHP, Composer, php-cs-fixer/phpstan (`vendor/bin`) |
| Elixir | Expert | Elixir, Erlang |
| Terraform | terraform-ls | terraform, tflint |
| Nix, Lua, shell, Markdown, YAML, JSON, TOML | everything | nothing |

## Python

No `flake.nix`: `uv` (installed globally, from Nix) provides the interpreter
and packages. All configuration, for the project and for its tools, goes in
**`pyproject.toml`**:

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "httpx>=0.28",
]

[dependency-groups]
dev = [
    "pytest>=8",
    "debugpy>=1.8",      # optional: the debugger adds it for the session if missing
]

[tool.uv]
package = false          # an application; remove for a library you build and publish

[tool.ruff]              # this section also turns on format on save in Neovim
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]   # pycodestyle, pyflakes, imports, bugbear, pyupgrade

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.rumdl]             # optional: Markdown style for this project's docs
disable = ["MD013"]
```

Start a new one with `uv init`, or write the file by hand, then:

```bash
uv sync                  # creates .venv with the right Python and all dependencies
uv add requests          # add a dependency (edits pyproject.toml and uv.lock)
uv add --dev ruff        # add a development tool
uv run pytest            # run anything inside the environment
```

Commit `pyproject.toml`, `uv.lock` and `.python-version`; never `.venv/`.

An **`.envrc` is optional**. Without one, `uv run …` works and Neovim finds
`.venv` by itself. With one, `python` and `pytest` work directly in the
shell, the same as after `source .venv/bin/activate`:

```bash
# .envrc
[[ -d .venv ]] || uv sync
export VIRTUAL_ENV="$PWD/.venv"
PATH_add "$VIRTUAL_ENV/bin"
watch_file pyproject.toml uv.lock
```

A Python project that also needs non-Python tools (a database client, Node
for a frontend) can add a `flake.nix` for those and put `use flake` as the
first line of this `.envrc`. Python itself still comes from uv.

## Java / Spring

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.jdk21
          pkgs.maven             # or pkgs.gradle; drop both if the project uses ./mvnw or ./gradlew
        ];
        JAVA_HOME = pkgs.jdk21.home;
      };
    };
}
```

```bash
# .envrc
use flake
```

Use the JDK version the project targets (`jdk17`, `jdk21`, `jdk25`). The
Maven or Gradle wrapper in the repository, if there is one, downloads its own
build tool and only needs the JDK.

## JavaScript / TypeScript / Vue / React

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.nodejs_22         # match "engines" in package.json
          pkgs.pnpm              # or leave out and use npm, which comes with Node
        ];
      };
    };
}
```

```bash
# .envrc
use flake
PATH_add node_modules/.bin
```

TypeScript, eslint, prettier and biome are `devDependencies` in
`package.json`, installed into `node_modules` by `pnpm install` (or `npm
install`). The editor uses those versions. Prettier formats only when the
project has a prettier config file; biome only when it has a `biome.json`,
and biome wins where both exist. eslint's diagnostics appear only with an
eslint config file, Tailwind's completions only where `package.json` lists
`tailwindcss` or there is a `tailwind.config.*`.

Open Neovim from inside the project, so direnv has put this Node on PATH.
Tools under `node_modules/.bin` (biome, and eslint or Tailwind servers when a
project installs its own) are Node scripts: without the project's Node they
fail to start (`env: node: No such file or directory` in `:LspLog`).

## Go

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.go
          pkgs.golangci-lint
        ];
      };
    };
}
```

```bash
# .envrc
use flake
```

Linter settings go in the project's `.golangci.yml`.

## Rust

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.rustc
          pkgs.cargo
          pkgs.rust-analyzer
          pkgs.rustfmt
          pkgs.clippy
        ];
        # Lets rust-analyzer read the standard library's source.
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };
    };
}
```

```bash
# .envrc
use flake
```

rust-analyzer, rustfmt and clippy come from the project so they match its
compiler. A project that pins a toolchain in `rust-toolchain.toml` needs a
Rust overlay (fenix or rust-overlay) instead of these packages; that is a
per-project choice.

## C / C++

The compiler is Apple clang from the Xcode Command Line Tools; the flake adds
the build tools and libraries.

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.cmake
          pkgs.pkg-config
          # libraries the project links against, e.g. pkgs.openssl
        ];
      };
    };
}
```

```bash
# .envrc
use flake
```

clangd needs to know how each file is compiled. With CMake, configure once
with `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` and link the result
into the root: `ln -s build/compile_commands.json .`.

## Ruby (Rails, Sinatra, Padrino)

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.ruby_3_4          # match .ruby-version
          # libraries for gems with native extensions, e.g. pkgs.libyaml, pkgs.postgresql
        ];
        shellHook = ''
          export GEM_HOME="$PWD/.gems"
          export PATH="$GEM_HOME/bin:$PATH"
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

In the `Gemfile`, the editor's tools:

```ruby
group :development do
  gem "ruby-lsp", require: false
  gem "rubocop", require: false   # or "standard"
end
```

Then `bundle install`. Gems install into `.gems/` inside the project; add
`.gems/` to the project's `.gitignore`.

## PHP

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.php84
          pkgs.php84Packages.composer
        ];
      };
    };
}
```

```bash
# .envrc
use flake
PATH_add vendor/bin
```

php-cs-fixer, phpstan or pint go in `composer.json` under `require-dev`;
`composer install` puts them in `vendor/bin`.

## Elixir / Phoenix

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.elixir            # brings a matching Erlang
        ];
        shellHook = ''
          export MIX_HOME="$PWD/.nix-mix"
          export HEX_HOME="$PWD/.nix-hex"
          export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

`mix` and `hex` keep their caches inside the project; add `.nix-mix/` and
`.nix-hex/` to its `.gitignore`. Formatting follows the project's
`.formatter.exs`.

## Terraform

Terraform's licence is not free software, so the flake allows exactly that
one package:

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfreePredicate = pkg: (nixpkgs.lib.getName pkg) == "terraform";
      };
    in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.terraform
          pkgs.tflint
        ];
      };
    };
}
```

```bash
# .envrc
use flake
```

## Environment variables and secrets

Non-secret settings for the shell can go in `flake.nix` (as `JAVA_HOME`
above) or in `.envrc` (`export APP_ENV=dev`). **Secrets never go in either**:
both are committed. Put them in a `.env` file, add `.env` to the project's
`.gitignore`, and load it from `.envrc` with `dotenv_if_exists`.

## Where the recipes stop

These are starting points, not frameworks. A project with more needs (a
database, several services) adds packages to `packages` or, for services,
uses containers ([containers.md](containers.md)). Updating a
project's tools is `nix flake update`
in that project; it never touches the workstation.
