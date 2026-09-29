{ lib, pkgs, ... }:

# The work Mac. Its host name and computer name are not declared: macOS
# keeps whatever the Mac is called, and the name stays out of this repository.
# Nothing work-specific belongs here: private hosts go in ~/.ssh/config.local,
# the Git email in ~/.config/git/local.
let
  # ZAP, the web app security scanner. Its Homebrew cask is disabled (the app
  # fails the Gatekeeper check), so it comes from nixpkgs, whose package is
  # ZAP's platform-independent Java build but is marked Linux-only. Two
  # changes make it run here: allow the platform, and start ZAP with
  # `-dir ~/.ZAP`. The package's launcher prepares a writable config in
  # ~/.ZAP, the Linux home; on macOS ZAP would otherwise use
  # ~/Library/Application Support/ZAP and copy its read-only default config
  # from the Nix store, which it then cannot save. --replace-fail makes the
  # build fail loudly if an update changes the launcher line.
  #
  # ZAP.app is a small launcher for Spotlight and Launchpad: Home Manager
  # copies it to ~/Applications/Home Manager Apps. The icon is built from
  # ZAP's only icon, a Windows .ico. zap.sh sets the Dock icon from
  # ../Resources/ZAP.icns relative to its own directory, so a copy at
  # share/Resources covers `zap` started from a terminal as well.
  zap = pkgs.zap.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      pkgs.imagemagick
      pkgs.libicns
    ];
    postInstall = (old.postInstall or "") + ''
      substituteInPlace "$out/bin/zap" \
        --replace-fail 'zap.sh"  "$@"' 'zap.sh" -dir "$HOME/.ZAP" "$@"'

      magick "$out/share/zap/zap.ico" -set filename:w '%w' 'ico-%[filename:w].png'
      for s in 16 32 128; do magick ico-256.png -resize "$s"x"$s" "icon-$s.png"; done
      mkdir -p "$out/share/Resources"
      png2icns "$out/share/Resources/ZAP.icns" icon-16.png icon-32.png icon-128.png ico-256.png

      app="$out/Applications/ZAP.app/Contents"
      mkdir -p "$app/MacOS" "$app/Resources"
      cp "$out/share/Resources/ZAP.icns" "$app/Resources/ZAP.icns"
      printf '#!/bin/sh\nexec "%s" "$@"\n' "$out/bin/zap" > "$app/MacOS/ZAP"
      chmod +x "$app/MacOS/ZAP"
      cat > "$app/Info.plist" <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key><string>ZAP</string>
        <key>CFBundleDisplayName</key><string>ZAP</string>
        <key>CFBundleIdentifier</key><string>org.zaproxy.zap.nix</string>
        <key>CFBundleExecutable</key><string>ZAP</string>
        <key>CFBundleIconFile</key><string>ZAP</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>${old.version}</string>
        <key>NSHighResolutionCapable</key><true/>
      </dict>
      </plist>
      EOF
    '';
    meta = old.meta // { platforms = lib.platforms.unix; };
  });
in
{
  # The account; every home path derives from it (modules/darwin/user.nix).
  system.primaryUser = "milannikicnik";

  # Power differs by source here, which power.sleep cannot express: on
  # battery the display sleeps after 5 minutes; on the power adapter the Mac
  # itself never sleeps. No Energy Mode: this Mac has no High Power Mode
  # (`pmset -g cap` lists only lowpowermode), so `powermode 2` fails here.
  # Activation runs as root.
  system.activationScripts.postActivation.text = ''
    /usr/bin/pmset -b displaysleep 5
    /usr/bin/pmset -c sleep 0
  '';

  # Apps for this Mac only, on top of the shared list in modules/darwin/homebrew.nix.
  homebrew.casks = [
    "chatgpt"
    "codex"
    "google-chrome"
    "parallels"
    "slack"
  ];

  home-manager.users.milannikicnik = {
    # Security tooling for this Mac only: CycloneDX SBOMs, static analysis,
    # and ZAP (a GUI app, started with `zap`).
    home.packages = [
      pkgs.cdxgen
      pkgs.semgrep
      zap
    ];

    # This Mac's GitHub key (docs/tools/ssh.md). The key itself is never in
    # the repository; each Mac names its own.
    programs.ssh.settings."github.com" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/id_rsa_work";
      IdentitiesOnly = "yes";
    };
  };
}
