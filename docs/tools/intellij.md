# IntelliJ IDEA

IntelliJ IDEA Ultimate is the IDE for development on this workstation. It also
connects to databases and to Docker. Neovim stays as the editor for quick edits
in the terminal. See [neovim.md](neovim.md).

Homebrew installs IntelliJ IDEA as the cask `intellij-idea`. The cask is in
the shared list in `modules/darwin/homebrew.nix`, thus each Mac gets it. The
cask also installs the `idea` command in `/opt/homebrew/bin`.

IntelliJ IDEA updates itself. Activation does not update it. The settings, the
plugins and the licence stay outside this repository, in
`~/Library/Application Support/JetBrains`.

## First start

1. Start IntelliJ IDEA from the Dock or from Spotlight.
2. Sign in with your JetBrains account. The licence comes from that account.
3. Select the colour theme and the keymap. These settings stay on the Mac.
4. Install the plugins. See [Install the plugins](#install-the-plugins).

## Open a project from the terminal

```bash
cd ~/github/myapp
idea .
```

`idea` is a shell function of this workstation. It opens the directory as a
project and gives the terminal back immediately. The `idea` command of the
cask keeps the terminal busy until IntelliJ IDEA quits. To use that command,
for example for `idea diff`, type `command idea`.

## The toolchain of a project

Each project gets its toolchain from its Nix dev shell. See
[projects.md](projects.md). IntelliJ IDEA uses that toolchain in two ways:

- The SDK or interpreter of each language, for example the JDK, the GOROOT
  of Go or the Node interpreter. This is a setting of the IDE. You set it one
  time for each project.
- The environment of the processes that IntelliJ IDEA starts: run
  configurations, tests, the build, Gradle, Maven and the terminal. The
  direnv Everywhere plugin gives these processes the environment of the dev
  shell.

The terminal of IntelliJ IDEA starts zsh in the project directory. direnv
loads the dev shell there, as it does in Ghostty.

### Stable paths in .direnv/sdk

The path of a toolchain in the Nix store changes after each update. Thus the
dev shell makes a link to each toolchain in the `.direnv/sdk` directory of the
project, and the IDE settings use the links. After `nix flake update`, direnv
changes the links, and the IDE settings stay correct.

The `flake.nix` files in [projects.md](projects.md) make these links in their
`shellHook`. For example, a Java project gets this link:

```console
$ readlink .direnv/sdk/jdk
/nix/store/<hash>-zulu-ca-jdk-21.0.11/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home
```

The global Git ignore list contains `.direnv/`. Thus the links are never
committed.

### Install the plugins

Do these steps one time on each Mac:

1. Open **Settings > Plugins > Marketplace**.
2. Install **direnv Everywhere**. It loads the `.envrc` file of a project when
   the project opens, and it loads it again when a file of the dev shell
   changes. It never runs `direnv allow`. Run that command in a terminal.
3. Install the plugin of each language that you use. The table in the next
   section gives the names.
4. Restart IntelliJ IDEA.

### The setting for each language

In the table, "Settings: `GOROOT`" means: open **Settings** (`Cmd-,`) and type
`GOROOT` in the search field. "Project Structure" opens with `Cmd-;`.

The paths are relative to the project root. Type or paste the full path in the
dialog, for example `/Users/<user>/github/myapp/.direnv/sdk/jdk`.

| Language | Plugin | Setting | Value |
|---|---|---|---|
| Java, Kotlin, Spring | Included | Project Structure > Project > SDK > Add JDK from disk | `.direnv/sdk/jdk` |
| Gradle | Included | Settings: `Gradle JVM` | Project SDK |
| Maven | Included | Settings: `JDK for importer` | The JDK of the project |
| JavaScript, TypeScript, Vue, React | Included | Settings: `Node interpreter` | `.direnv/sdk/node/bin/node` |
| | | Settings: `Package manager` | `.direnv/sdk/pnpm/bin/pnpm` |
| Python | Python | Project Structure > SDKs > + > Add Python SDK from disk > Existing uv environment | The `.venv` of the project. See [Python with uv](#python-with-uv) |
| Jupyter notebooks | Jupyter | None | See [Jupyter notebooks](#jupyter-notebooks) |
| Go | Go | Settings: `GOROOT` | `.direnv/sdk/go` |
| Rust | Rust | Settings: `Toolchain location` | `.direnv/sdk/rust` |
| | | Settings: `Standard library` | `.direnv/sdk/rust-src` |
| C, C++ | C/C++ from JetBrains | Settings: `Toolchains`, the CMake field | `.direnv/sdk/cmake` |
| Ruby | Ruby | Project Structure > SDKs > + > Ruby SDK | `.direnv/sdk/ruby/bin/ruby` |
| PHP | PHP | Settings: `CLI Interpreter` | `.direnv/sdk/php/bin/php` |
| | | Settings: `Composer` | `.direnv/sdk/composer/bin/composer` |
| Elixir | Elixir (intellij-elixir, not from JetBrains) | Project Structure > SDKs > + > Erlang SDK | `.direnv/sdk/erlang` |
| | | Project Structure > SDKs > + > Elixir SDK | `.direnv/sdk/elixir` |
| Terraform | Terraform and HCL | Settings: `Terraform` | `.direnv/sdk/terraform/bin/terraform` |
| Nix | NixIDEA | None | |
| Lua | Lua from JetBrains | None | |
| Shell, Markdown, YAML, JSON, TOML, SQL | Included | None | |

The SDK list is the same for all projects. Thus give each SDK the name of its
project, for example `myapp JDK 21`.

### Set up a project one time

1. Make sure that direnv loaded the dev shell, and that the links are there:

   ```bash
   cd ~/github/myapp
   direnv allow
   ls .direnv/sdk
   ```

2. Open the project with `idea .`.
3. In the **Project** tool window, right-click `.direnv`, and select **Mark
   Directory as > Excluded**. IntelliJ IDEA then does not index the Nix files
   in that directory.
4. Set the values for the languages of the project. See the table above.

### Example: a Java project with Maven

The project has the `flake.nix` and the `.envrc` from the Java section of
[projects.md](projects.md#java--spring).

1. Load the dev shell, and make sure that the link is there:

   ```console
   $ cd ~/github/myapp
   direnv: loading ~/github/myapp/.envrc
   direnv: using flake
   $ ls .direnv/sdk
   jdk
   ```

2. Run `idea .`.
3. Mark `.direnv` as excluded.
4. Press `Cmd-;`. In **Project > SDK**, select **Add SDK > Add JDK from
   disk**, and type `/Users/<user>/github/myapp/.direnv/sdk/jdk`.
5. Change the name of the SDK to `myapp JDK 21`, and click **OK**.
6. Open **Settings**, type `JDK for importer`, and select `myapp JDK 21`.
7. Open the **Maven** tool window, and click **Reload All Maven Projects**.

A run configuration or a test now gets the environment of the dev shell
through direnv Everywhere.

## Python with uv

uv supplies Python and the packages. IntelliJ IDEA uses the `.venv` directory
that uv makes in the project. A Python project has no `flake.nix`. Thus it has
no links in `.direnv/sdk`. See [projects.md](projects.md#python) for the
files of a Python project.

The tools have these tasks:

| Tool | Task |
|---|---|
| The Python plugin | Completion, navigation, type checks, refactoring, the debugger and the test runner |
| Ruff | The lint rules and the format. Its settings are in `pyproject.toml` |
| pytest | The tests |

You do not need ty. The Python plugin has its own type checker. In IntelliJ
IDEA, ty is a preview, and two type checkers show the same problems two times.

### Set up a Python project one time

1. Add pytest and Ruff to the project. The project then sets their versions,
   and IntelliJ IDEA uses the Ruff in `.venv`:

   ```bash
   cd ~/github/myapp
   uv add --dev pytest ruff
   ```

2. Open the project with `idea .`.
3. Press `Cmd-;`. Select **SDKs**, click **+**, and select **Add Python SDK
   from disk**.
4. Select **Existing uv environment**, and select the environment of the
   project from the list. If IntelliJ IDEA does not find uv, type its path:
   `/etc/profiles/per-user/<user>/bin/uv`.
5. Give the SDK the name of the project, for example `myapp Python`, and
   click **OK**.
6. In **Project > SDK**, select the new SDK, and click **OK**.
7. Open **Settings**, and type `Ruff`. Set Ruff to on, and set its
   **Formatting** feature to on.
8. Open **Settings**, type `Actions on Save`, and select **Reformat code**.
   Ruff then formats each file when you save it.
9. Open **Settings**, type `Default test runner`, and make sure that the value
   is `pytest`.

When a file has an error, the Problems tool window (`Cmd-6`) shows the
results of the Python plugin and of Ruff together.

### Tests and the debugger

- Click the run icon next to a test function to run that test. Right-click
  the `tests` directory and select **Run** to run all tests.
- To debug, click in the gutter to set a breakpoint, then select **Debug** in
  place of **Run**. The debugger is part of IntelliJ IDEA. debugpy is not
  necessary.

### Jupyter notebooks

The notebooks use the Jupyter plugin, and the `jupyter` package in the `.venv`
of the project.

1. Add Jupyter to the project:

   ```bash
   uv add --dev jupyter
   ```

2. Make sure that the Jupyter plugin is installed and enabled. See
   [Install the plugins](#install-the-plugins).
3. Open an `.ipynb` file, or create one with **File > New > Jupyter
   Notebook**.
4. Click the run icon of a cell. IntelliJ IDEA starts a Jupyter server for the
   project. The **Jupyter** tool window shows that server. The server stops
   when IntelliJ IDEA closes.

Example: a project for data analysis.

```bash
mkcd ~/github/analysis
uv init
uv add pandas matplotlib
uv add --dev jupyter ruff
idea .
```

Set the Python SDK as in steps 3 to 6 above. Then create `explore.ipynb`, and
run this cell:

```python
import pandas as pd
pd.DataFrame({"a": [1, 2, 3]}).describe()
```

To use JupyterLab in the browser, without IntelliJ IDEA, run
`uv run jupyter lab` in the project.

## Docker and Colima

IntelliJ IDEA is a Docker client. It shows the containers, the images and the
logs in the **Services** tool window (`Cmd-8`), and it runs `compose.yaml` and
`Dockerfile` files. The Docker engine is Colima. Thus Colima must run before
IntelliJ IDEA can show containers. See [containers.md](containers.md).

IntelliJ IDEA does not find Colima without a setting. Its default connection
uses `/var/run/docker.sock`, the socket of Docker Desktop. Colima does not make
that socket. Each Colima profile has its own socket, in
`~/.colima/<profile>/docker.sock`, and a Docker context that points to it.

Add the connection one time on each Mac:

1. Start Colima. This also makes the Docker context `colima`:

   ```console
   $ colima start
   $ docker context ls
   NAME       DESCRIPTION                               DOCKER ENDPOINT                                    ERROR
   colima *   colima                                    unix:///Users/<user>/.colima/default/docker.sock
   default    Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
   ```

2. In IntelliJ IDEA, open the **Services** tool window (`Cmd-8`).
3. Click **+** (Add Service), and select **Docker Connections from Docker
   Contexts**. IntelliJ IDEA adds a connection for each context.
4. Select the connection `colima`, and click **Connect**.

IntelliJ IDEA keeps the connection. When Colima runs, the connection works.
When Colima does not run, IntelliJ IDEA shows that it cannot connect.

A project with its own Colima profile has its own context, for example
`colima-myapp` for the profile `myapp`. Do step 3 again after the first start
of that profile.

If the list of contexts is empty, add the connection by its socket:

1. Open **Settings > Build, Execution, Deployment > Docker**, and click **+**.
2. Select **TCP socket**.
3. In **Engine API URL**, type the socket of the profile:

   ```text
   unix:///Users/<user>/.colima/default/docker.sock
   ```

4. Make sure that IntelliJ IDEA shows **Connection successful**, and click
   **OK**.

Example: start the services of a project and read the logs.

1. Run `colima start` in a terminal.
2. Open the project in IntelliJ IDEA.
3. Open `compose.yaml`, and click the run icon next to `services:`.
4. In the **Services** tool window, select a container and open its **Log**
   tab.

## Databases

IntelliJ IDEA Ultimate contains the database tools. Open the **Database** tool
window with **View > Tool Windows > Database**.

Example: connect to a PostgreSQL database on port 5432 of the Mac.

1. In the **Database** tool window, click **+**, then **Data Source >
   PostgreSQL**.
2. Type the host `localhost`, the port `5432`, the user and the database.
3. If IntelliJ IDEA shows **Download missing driver files**, click it.
4. Click **Test Connection**, then **OK**.
5. Right-click the data source and select **New > Query Console** to write SQL.

IntelliJ IDEA keeps the passwords in the macOS Keychain, not in the project.
The data source itself goes into the `.idea` directory of the project.

For a database behind a bastion host, start an SSH tunnel first. See
[ssh.md](ssh.md#a-database-port-on-your-mac).

## Claude Code

The Claude Code plugin connects Claude Code to IntelliJ IDEA. Claude then sees
the current file and the selection, and IntelliJ IDEA shows each proposed edit
in its diff viewer.

1. Open **Settings > Plugins > Marketplace**.
2. Search for `Claude Code`, and install the plugin from Anthropic.
3. Restart IntelliJ IDEA.
4. Run `claude` in the terminal of IntelliJ IDEA. The connection starts
   automatically.

Claude Code in a Ghostty window can also connect. Run `/ide` in Claude Code
while the project is open in IntelliJ IDEA.

IntelliJ IDEA also contains the JetBrains AI Assistant plugin. This
workstation uses Claude Code. To turn the AI Assistant off, disable its plugin
in **Settings > Plugins > Installed**.

## Problems and solutions

### A run configuration does not find a tool or a variable

IntelliJ IDEA is one process for all projects. That process gets its own
environment only at its start: from the terminal, or from a login shell in
`/` when you start it from the Dock. direnv does not load the dev shell there.
Thus the toolchain of a project comes only from direnv Everywhere and from the
settings in the table above.

Do these checks:

1. Run `direnv allow` in the project directory. direnv Everywhere loads
   nothing until you approve the `.envrc` file.
2. Make sure that direnv Everywhere is installed and enabled in **Settings >
   Plugins > Installed**.
3. Make sure that the link exists, for example with `ls .direnv/sdk`.

### The SDK shows the old version after `nix flake update`

1. Run `direnv reload` in the project directory. This changes the links in
   `.direnv/sdk`.
2. Restart IntelliJ IDEA. It then reads the SDK again.

### IntelliJ IDEA indexes the Nix sources

The search shows files from `.direnv/flake-inputs`. Mark `.direnv` as
excluded. See [Set up a project one time](#set-up-a-project-one-time).

### Remove IntelliJ IDEA

First remove `"intellij-idea"` from `modules/darwin/homebrew.nix`, and run
`ws switch`. Then remove the application and its data:

```bash
ws remove intellij-idea
```

See [ws.md](ws.md#remove-an-application-or-a-tool).
