# Set up a project for each language

No language tool is installed globally. A project supplies its own toolchain,
and two small files in the project root load that toolchain automatically:

- `flake.nix` names the tools that the project uses, for example the compiler,
  the runtime and the build tool. Nix gets exactly those versions.
- `.envrc` tells direnv to load the tools when you go into the directory and to
  unload them when you go out. It has one line: `use flake`.

[direnv.md](direnv.md) describes how direnv and nix-direnv work, and gives the
solutions to their usual problems. This guide gives the files for each
language.

Python is different. `uv` supplies Python, because the Python from nixpkgs had
problems when it loaded libraries (libffi) on macOS. Examine the state of that
problem again before you change this rule. A Python project keeps all its
configuration in `pyproject.toml`. uv, ruff and pytest read that file. A
`flake.nix` is not necessary.

## The procedure for all languages

1. Create `flake.nix` and `.envrc` from the section for your language below.
2. Add the two files to Git. A flake reads only the files that Git knows:

   ```bash
   git add flake.nix .envrc
   ```

3. Approve the `.envrc` file one time:

   ```bash
   direnv allow
   ```

4. Wait for the first load. It downloads the tools. This can take seconds or
   minutes.
5. Commit the new `flake.lock` file. The versions then stay the same until you
   run `nix flake update` and `direnv reload`.
6. Open the project in IntelliJ IDEA with `idea .`, and set its SDK one time.
   See [intellij.md](intellij.md#set-up-a-project-one-time).

Each `flake.nix` in this guide also makes a link to each toolchain in
`.direnv/sdk`, in its `shellHook`. The path of a link does not change when
Nix updates the toolchain. Thus IntelliJ IDEA uses the links as its SDK paths.
See [intellij.md](intellij.md#stable-paths-in-direnvsdk).

All repositories ignore `.direnv/`. Do not commit that directory.

### Example: a new Go project

```console
$ mkcd ~/github/hello
$ git init
$ nvim flake.nix .envrc          # copy the two files from the Go section
$ git add flake.nix .envrc
$ direnv allow
direnv: loading ~/github/hello/.envrc
direnv: using flake
$ go version
go version go1.25.1 darwin/arm64
$ ls .direnv/sdk
go
$ go mod init example.com/hello
$ git add flake.lock go.mod
$ idea .
```

In IntelliJ IDEA, set GOROOT to `.direnv/sdk/go` one time. The Go plugin then
uses the Go from the dev shell.

## Why the files use mkShellNoCC

The files in this guide use `pkgs.mkShellNoCC`. This function makes a shell
that contains only the packages in the list.

`pkgs.mkShell` also adds the C toolchain of Nix, and it sets `DEVELOPER_DIR`
and `SDKROOT`. These two variables point the developer tools of macOS to the
Nix SDK. This has two bad effects in the shell:

- `/usr/bin/python3` fails with the message `tool 'python3' not found`.
- The compiler is not Apple clang.

Use `mkShell` only for a project that must build with the compiler toolchain
of Nix.

## What IntelliJ IDEA gets from the project

IntelliJ IDEA and its plugins supply the language support. The project
supplies the toolchain. The dev shell links the toolchain into `.direnv/sdk`
for the SDK settings of the IDE.

| Language | The links in `.direnv/sdk` | The project also supplies |
|---|---|---|
| Python | None. IntelliJ IDEA uses `.venv` | Python (through uv), pytest, packages |
| Java / Spring | `jdk` | Maven or Gradle, or their wrappers |
| JavaScript / TypeScript / Vue | `node`, `pnpm` | TypeScript, eslint, prettier (`node_modules`) |
| Go | `go` | golangci-lint |
| Rust | `rust`, `rust-src` | rustfmt and clippy, in the `rust` link |
| C / C++ | `cmake` | The compiler (Apple clang), libraries |
| Ruby | `ruby` | Bundler and the gems in `.gems` |
| PHP | `php`, `composer` | php-cs-fixer, phpstan or pint (`vendor/bin`) |
| Elixir | `elixir`, `erlang` | The caches of mix and hex in the project |
| Terraform | `terraform` | tflint |

[intellij.md](intellij.md#the-setting-for-each-language) gives the setting of
the IDE for each link.

## Python

A Python project has no `flake.nix`. Nix installs `uv` globally, and `uv`
supplies the interpreter and the packages. All configuration of the project and
of its tools goes in `pyproject.toml`:

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
]

[tool.uv]
package = false          # an application. Remove this line for a library that you publish

[tool.ruff]              # the settings of the ruff linter and formatter
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]   # pycodestyle, pyflakes, imports, bugbear, pyupgrade

[tool.pytest.ini_options]
testpaths = ["tests"]
```

To start a new project, run `uv init` or write the file. Then use these
commands:

```bash
uv sync                  # creates .venv with the correct Python and all dependencies
uv add requests          # adds a dependency (edits pyproject.toml and uv.lock)
uv add --dev ruff        # adds a development tool
uv run pytest            # runs a command in the environment
```

Commit `pyproject.toml`, `uv.lock` and `.python-version`. Do not commit
`.venv/`.

### Example: a new Python project

```bash
mkcd ~/github/myapp
uv init
uv add httpx
uv add --dev pytest ruff
uv run pytest
idea .
```

`uv init` creates `pyproject.toml` and `.python-version`. The first `uv add`
creates `.venv` and `uv.lock`. In IntelliJ IDEA, select the uv environment of
the project as the Python SDK one time. See
[intellij.md](intellij.md#python-with-uv).

For Jupyter notebooks, also run `uv add --dev jupyter`. See
[intellij.md](intellij.md#jupyter-notebooks).

### The optional .envrc file

An `.envrc` file is optional for Python. Without it, `uv run <command>` works,
and IntelliJ IDEA uses `.venv` as the interpreter.

With it, `python` and `pytest` work directly in the shell. The effect is the
same as `source .venv/bin/activate`:

```bash
# .envrc
[[ -d .venv ]] || uv sync
export VIRTUAL_ENV="$PWD/.venv"
PATH_add "$VIRTUAL_ENV/bin"
watch_file pyproject.toml uv.lock
```

Some Python projects also use tools that are not Python tools, for example a
database client or Node for a frontend. Add a `flake.nix` for those tools, and
put `use flake` as the first line of this `.envrc`. Python continues to come
from uv.

```bash
# .envrc for a Python project that also has a flake.nix
use flake
[[ -d .venv ]] || uv sync
export VIRTUAL_ENV="$PWD/.venv"
PATH_add "$VIRTUAL_ENV/bin"
watch_file pyproject.toml uv.lock
```

## Java / Spring

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      jdk = pkgs.jdk21;
      # The JDK inside its macOS bundle. IntelliJ IDEA and Gradle expect this
      # directory, not the top directory of the Nix package.
      javaHome = "${jdk.bundle}/Contents/Home";
    in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          jdk
          pkgs.maven             # or pkgs.gradle. Remove both if the project uses ./mvnw or ./gradlew
        ];
        JAVA_HOME = javaHome;
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${javaHome} .direnv/sdk/jdk
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

Use the JDK version that the project targets: `jdk17`, `jdk21` or `jdk25`.
Change only the line `jdk = pkgs.jdk21;`.

If the repository has a Maven wrapper or a Gradle wrapper, the wrapper
downloads its own build tool. Then only the JDK is necessary in the dev shell.

Example: make sure that the shell and the link use the JDK of the project.

```console
$ java -version 2>&1 | head -1
openjdk version "21.0.11" 2026-04-21 LTS
$ readlink .direnv/sdk/jdk
/nix/store/<hash>-zulu-ca-jdk-21.0.11/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home
$ ./mvnw -v
```

The output of `./mvnw -v` contains the Java version and the path of the JDK.

## JavaScript / TypeScript / Vue / React

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.nodejs_22         # must match "engines" in package.json
          pkgs.pnpm              # or remove this line and use npm, which comes with Node
        ];
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md). Remove
        # the pnpm line if the project uses npm.
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${pkgs.nodejs_22} .direnv/sdk/node
          ln -sfn ${pkgs.pnpm} .direnv/sdk/pnpm
        '';
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
`package.json`. `pnpm install` or `npm install` puts them in `node_modules`,
and IntelliJ IDEA uses those versions.

The tools in `node_modules/.bin` are Node scripts. They start only with a Node
interpreter. Thus set the Node interpreter of IntelliJ IDEA to
`.direnv/sdk/node/bin/node`.

Example: start work on a cloned project.

```console
$ cd ~/github/webapp
direnv: loading ~/github/webapp/.envrc
direnv: using flake
$ pnpm install
$ pnpm dev
```

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
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${pkgs.go}/share/go .direnv/sdk/go
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

Put the linter settings in the `.golangci.yml` file of the project. A small
example:

```yaml
# .golangci.yml
version: "2"
linters:
  enable:
    - errcheck
    - govet
    - staticcheck
```

## Rust

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      # cargo, rustc, rustfmt and clippy in one directory. The Rust plugin of
      # IntelliJ IDEA expects all of them in its toolchain directory.
      rust = pkgs.symlinkJoin {
        name = "rust-toolchain";
        paths = [ pkgs.rustc pkgs.cargo pkgs.rustfmt pkgs.clippy ];
      };
    in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [ rust ];
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${rust}/bin .direnv/sdk/rust
          ln -sfn ${pkgs.rustPlatform.rustLibSrc} .direnv/sdk/rust-src
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

rustfmt and clippy come from the project, because they must match its
compiler. `.direnv/sdk/rust-src` is the source of the standard library, for
the Rust plugin.

Some projects pin a toolchain in `rust-toolchain.toml`. For such a project, a
Rust overlay (fenix or rust-overlay) is necessary in place of these packages.
Each project makes that decision.

Example: a new Rust project.

```console
$ mkcd ~/github/hello-rs
$ git init
$ nvim flake.nix .envrc          # copy the two files from this section
$ git add flake.nix .envrc
$ direnv allow
$ cargo init
$ cargo run
Hello, world!
```

## C / C++

The compiler is Apple clang from the Xcode Command Line Tools. The flake adds
the build tools and the libraries.

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
          # the libraries that the project links, for example pkgs.openssl
        ];
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${pkgs.cmake}/bin/cmake .direnv/sdk/cmake
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

IntelliJ IDEA opens a CMake project from its `CMakeLists.txt`. Set the CMake
path of the toolchain to `.direnv/sdk/cmake` one time.

A project without CMake must supply a `compile_commands.json` file in its
root. IntelliJ IDEA then opens the project from that file. To make the file
with CMake, run these commands:

```bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON    # configure the project
ln -s build/compile_commands.json .                  # link the result into the project root
```

## Ruby (Rails, Sinatra, Padrino)

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.ruby_3_4          # must match .ruby-version
          # the libraries for gems with native extensions, for example pkgs.libyaml, pkgs.postgresql
        ];
        # The gems go into the project. The link is a stable path for
        # IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          export GEM_HOME="$PWD/.gems"
          export PATH="$GEM_HOME/bin:$PATH"
          mkdir -p .direnv/sdk
          ln -sfn ${pkgs.ruby_3_4} .direnv/sdk/ruby
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

Add the linter to the `Gemfile`. IntelliJ IDEA shows its results in the
editor:

```ruby
group :development do
  gem "rubocop", require: false   # or "standard"
end
```

Then run `bundle install`. Bundler installs the gems into `.gems/` in the
project. Add `.gems/` to the `.gitignore` of the project. The run
configurations of IntelliJ IDEA get `GEM_HOME` through direnv Everywhere.

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
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${pkgs.php84} .direnv/sdk/php
          ln -sfn ${pkgs.php84Packages.composer} .direnv/sdk/composer
        '';
      };
    };
}
```

```bash
# .envrc
use flake
PATH_add vendor/bin
```

Put php-cs-fixer, phpstan or pint in `composer.json` below `require-dev`.
`composer install` puts them in `vendor/bin`.

```json
{
  "require-dev": {
    "laravel/pint": "^1.24",
    "phpstan/phpstan": "^2.1"
  }
}
```

## Elixir / Phoenix

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      # Elixir and the Erlang that it was built with, from one package set.
      beam = pkgs.beam.packages.erlang;
    in {
      devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
        packages = [
          beam.elixir            # includes an Erlang that matches
        ];
        # The caches of mix and hex go into the project. The links are
        # stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          export MIX_HOME="$PWD/.nix-mix"
          export HEX_HOME="$PWD/.nix-hex"
          export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"
          mkdir -p .direnv/sdk
          ln -sfn ${beam.elixir}/lib/elixir .direnv/sdk/elixir
          ln -sfn ${beam.erlang}/lib/erlang .direnv/sdk/erlang
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

`mix` and `hex` keep their caches in the project. Add `.nix-mix/` and
`.nix-hex/` to the `.gitignore` of the project. The formatter obeys the
`.formatter.exs` file of the project. The run configurations of IntelliJ IDEA
get `MIX_HOME` and `HEX_HOME` through direnv Everywhere.

## Terraform

The licence of Terraform is not a free software licence, and Nix refuses such
packages by default. Thus the flake lets Nix install only that one package:

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
        # Stable paths for IntelliJ IDEA (docs/tools/intellij.md).
        shellHook = ''
          mkdir -p .direnv/sdk
          ln -sfn ${pkgs.terraform} .direnv/sdk/terraform
        '';
      };
    };
}
```

```bash
# .envrc
use flake
```

## Environment variables and secrets

A setting that is not a secret can go in `flake.nix`, as `JAVA_HOME` does
above. It can also go in `.envrc`, for example `export APP_ENV=dev`.

Caution: do not put a secret in `flake.nix` or in `.envrc`. You commit the two
files, and a commit makes the secret available to each person who can read the
repository.

Put the secrets in a `.env` file:

1. Create `.env` in the project root:

   ```bash
   DATABASE_URL=postgres://localhost:5432/myapp_dev
   API_TOKEN=<token>
   ```

2. Add `.env` to the `.gitignore` of the project.
3. Load the file from `.envrc`:

   ```bash
   # .envrc
   use flake
   dotenv_if_exists
   ```

4. Run `direnv allow`.

`dotenv_if_exists` does nothing when the file is not there. Thus the project
also loads on a Mac that has no `.env` file.

## The limits of these files

The files in this guide are a start for a project. They are not a framework.
If more tools are necessary, add them to `packages`. If services are
necessary, for example a database, use containers. See
[containers.md](containers.md).

To update the tools of a project, run `nix flake update` in that project. This
command does not change the workstation.
