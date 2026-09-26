# Work host placeholder

The second Mac's configuration is not instantiated yet: its user account is
not known, so this directory stays a placeholder rather than inventing values
or exposing a second active `darwinConfiguration`.

The configuration is named `work`. The name is only a label for the flake
entry; this host file declares no host name or computer name, so the Mac keeps
whatever name it is given and that name stays out of this public repository.
The first bootstrap run passes `--host work`; activation then records the name
in `/etc/workstation-host`.

To instantiate it, add `default.nix` here (user account, work-only apps,
per-machine SSH key) and `darwinConfigurations.work = mkHost "work";` in
`flake.nix`. Keep shared configuration in `modules/` and put work-specific
values only in this host module.
