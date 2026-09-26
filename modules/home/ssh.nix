{ ... }:

# SSH client configuration shared by every machine (docs/tools/ssh.md).
# Keys never enter this repository. Per-host identities live in the host
# file; private hosts (labs, work servers, IPs) live in the unmanaged
# ~/.ssh/config.local on each machine.
{
  programs.ssh = {
    enable = true;
    # Home Manager's legacy defaults would add a second `Host *` block of
    # OpenSSH defaults; everything here is declared explicitly instead.
    enableDefaultConfig = false;

    # Written at the top of ~/.ssh/config, before any Host block. OpenSSH uses
    # the first value it finds for each option, so entries in config.local win
    # over the shared ones below. A missing file is silently skipped.
    includes = [
      "~/.ssh/config.local"
      "~/.colima/ssh_config"
    ];

    settings."*" = {
      AddKeysToAgent = "yes";
      # Apple's OpenSSH only: store key passphrases in the macOS Keychain.
      UseKeychain = "yes";
    };
  };
}
