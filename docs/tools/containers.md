# Containers: Colima and Docker

Colima is the container runtime. Nix installs Colima, Lima, the Docker CLI, and
the Compose and Buildx plugins from `modules/home/containers.nix`. Home Manager
links the two plugins into `~/.docker/cli-plugins`.

This build of Colima supports only the `vz` VM type from Apple. nixpkgs
normally adds QEMU (2.3 GiB) to Colima and Lima, and this configuration removes
it. As a result, two options do not work:

- `--vm-type qemu`
- `--arch x86_64`, or a different architecture that is not the architecture of
  the Mac

If one of these options is necessary for a project, add QEMU again in
`modules/home/containers.nix`.

## Rules

- The setup of a Mac only installs Colima. It does not create a VM and it does
  not start a VM.
- Colima does not start at login. The VM runs, and uses memory, only while you
  use containers.
- The `default` profile uses the defaults of Colima. It has no custom CPU,
  memory, disk, VM type or mount type.
- A project that must have different values defines its own named profile. The
  project starts that profile with its own flags, from its own repository.
- The state of the VM and of the runtime is in `~/.colima`. It stays outside
  Nix.

## Daily use

```bash
colima start          # start the default profile, with no flags
colima status
colima stop
```

To make sure that Docker works, run these commands:

```bash
docker version
docker compose version
docker buildx version
```

### Example: run one container

```console
$ colima start
$ docker run --rm hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
$ colima stop
```

`--rm` removes the container after it stops.

### Example: start the services of a project

```bash
colima start
cd ~/github/myapp
docker compose up -d          # start the services in the background
docker compose logs -f db     # read the logs of one service
docker compose down           # stop the services
colima stop
```

`lazydocker` shows the containers, the images and the logs in the terminal.
See [cli.md](cli.md#containers-lazydocker).

## A profile for one project

If the defaults are not sufficient for a project, the project makes that
decision in its own repository. Do not put its flags in this repository.

Put the command in a script in the project. This example is
`scripts/colima-up.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

colima start --profile myproject --cpu 6 --memory 12 --disk 80 \
             --vm-type vz --mount-type virtiofs

docker context use colima-myproject
```

`docker context use` points the Docker CLI to the VM of that profile. To go
back to the default profile, run `docker context use colima`.

To see the profiles that exist, run `colima list`. The values in this example
are not real results:

```console
$ colima list
PROFILE      STATUS     ARCH       CPUS    MEMORY    DISK      RUNTIME    ADDRESS
default      Stopped    aarch64    2       2GiB      100GiB    docker
myproject    Running    aarch64    6       12GiB     80GiB     docker
```

When no profile exists, `colima list` shows only the header line and a warning.

## Change the size of a profile

Colima applies the size flags (`--cpu`, `--memory`, `--disk`) only when it
creates a profile. It ignores them for a profile that exists.

Thus, to change the resources of a profile, you must delete it and create it
again:

```bash
colima stop --profile myproject
colima delete --profile myproject
./scripts/colima-up.sh
```

Caution: `colima delete` deletes the VM of that profile, with its containers,
images and volumes.

This is the reason why the `default` profile has no size. A size for `default`
is one decision for all projects. You make it one time, and it is not easy to
change.
