# direnv: an environment for each project

No language tool is installed globally. Each project declares its own tools in
a Nix dev shell. direnv loads that dev shell when you go into the project
directory and unloads it when you go out.

nix-direnv keeps a cache of the dev shell. After the first build, the dev shell
loads in less than one second. nix-direnv also protects the dev shell from
garbage collection while the `.direnv/` directory of the project exists.

The configuration is in `modules/home/cli.nix`.

## Give a project its own environment

[projects.md](projects.md) has complete `flake.nix` and `.envrc` files for each
language. This section shows the general procedure.

1. In the project root, create `flake.nix`:

   ```nix
   {
     inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

     outputs = { nixpkgs, ... }:
       let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in {
         devShells.aarch64-darwin.default = pkgs.mkShellNoCC {
           packages = [ pkgs.go pkgs.gopls ];   # the tools of the project
           # Environment variables can also go here, for example:
           # APP_ENV = "dev";
         };
       };
   }
   ```

2. Create `.envrc` with one line:

   ```bash
   use flake
   ```

3. Add the two files to Git. A flake reads only the files that Git knows:

   ```bash
   git add flake.nix .envrc
   ```

4. Approve the `.envrc` file:

   ```bash
   direnv allow
   ```

The first load builds the dev shell. This can take seconds or minutes, and the
time depends on the tools. The first load also creates `flake.lock`. Commit
`flake.lock`, because it gives each person the same versions.

The global Git configuration ignores `.direnv/`. Do not commit that directory.

### Example: what you see in the terminal

When you go into the project, direnv writes two lines and the tools become
available. When you go out, direnv removes them.

```console
$ cd ~/github/myapp
direnv: loading ~/github/myapp/.envrc
direnv: using flake
$ which go
/nix/store/<hash>-go-1.25.1/bin/go
$ cd ..
direnv: unloading
$ which go
go not found
```

direnv does not show the long list of variables that it exports
(`hide_env_diff`). To see what direnv loaded, run `direnv status`.

### Python projects

Python projects are different. They use `uv` for the interpreter and the
packages, and they keep all configuration in `pyproject.toml`. See the
[Python section of projects.md](projects.md#python). A dev shell can supply the
tools of the project that are not Python tools.

## Daily commands

| Command | Result |
|---|---|
| `direnv allow` | Approves the `.envrc` file in this directory. Necessary again after each edit of the file |
| `direnv deny` | Stops the load of the `.envrc` file |
| `direnv reload` | Builds and loads the dev shell again after a change to `flake.nix` |
| `direnv status` | Shows what direnv loaded and why |
| `nix flake update` | In the project: updates its pinned nixpkgs. Run `direnv reload` after it |

### Example: add a tool to a project

This example adds `golangci-lint` to the project above.

1. Add the package to the list in `flake.nix`:

   ```nix
   packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
   ```

2. Load the dev shell again:

   ```bash
   direnv reload
   ```

3. Make sure that the tool is available:

   ```console
   $ which golangci-lint
   /nix/store/<hash>-golangci-lint-2.5.0/bin/golangci-lint
   ```

### Example: update the tools of a project

```bash
cd ~/github/myapp
nix flake update        # writes new versions to flake.lock
direnv reload
git add flake.lock
git commit -m "Update flake inputs"
```

The update changes only this project. It does not change the workstation or
other projects.

## Problems and solutions

| Symptom | Cause | Solution |
|---|---|---|
| `direnv: error .envrc is blocked` | The `.envrc` file is new or changed | Run `direnv allow` |
| A change to `flake.nix` has no effect | direnv did not load the dev shell again | Run `direnv reload` |
| Nix cannot find a new file | Git does not know the file | Run `git add <file>`, then `direnv reload` |
| Each `cd` into the project is slow | A tool writes `flake.nix` or `flake.lock` again on each run, and the cache becomes invalid | Find that tool and stop the writes |
| An old project uses disk space | Its `.direnv/` directory protects the dev shell from garbage collection | Delete the `.direnv/` directory of that project. The next weekly garbage collection can then remove the dev shell |
