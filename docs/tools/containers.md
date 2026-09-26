# Containers: Colima and Docker

Runtime: **Colima**. Colima, Lima, the Docker CLI and the Compose and Buildx
plugins come from Nix (`modules/home/containers.nix`); Home Manager links the
two plugins into `~/.docker/cli-plugins`.

This build supports Apple's `vz` VM type only. nixpkgs wraps Colima and Lima
with QEMU (2.3 GiB), which is dropped here: `--vm-type qemu` and emulating a
non-native architecture (`--arch x86_64`) do not work. Add QEMU back in that
module if a project ever needs them.

## Rules

- Provisioning **installs Colima and stops there**. No VM is created, nothing is started.
- Colima never starts at login. The VM runs, and uses memory, only while containers are needed.
- The `default` profile is a **real default**: whatever Colima itself creates. No custom CPU, memory, disk, VM type or mount type.
- A project needing anything else defines its **own named profile**, started with its own flags, from its own repository.
- VM and runtime state lives in `~/.colima` and stays outside Nix.

## Generic use

```bash
colima start          # real defaults, no flags
colima status
colima stop
```

Check that Docker works:

```bash
docker version
docker compose version
docker buildx version
```

`lazydocker` is the terminal interface for containers, images and logs
([cli.md](cli.md)).

## Project-specific profiles

A project that needs more than the defaults owns that decision, in its own repository:

```bash
colima start --profile myproject --cpu 6 --memory 12 --disk 80 \
             --vm-type vz --mount-type virtiofs

docker context use colima-myproject
```

Put the invocation in a script in that project, not here.

**Sizing flags only apply at creation.** Colima ignores them for a profile that already exists, so changing resources means deleting and recreating that profile. That is why `default` stays unsized: sizing it would be one global guess, made once, serving every project, and awkward to revise.

Inspect what exists:

```bash
colima list
```
