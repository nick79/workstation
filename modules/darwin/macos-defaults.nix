{ config, lib, ... }:

# The user-level settings below need system.primaryUser; nix-darwin stops
# with an assertion when a host leaves it unset, so no null case here.
let
  primaryUser = config.system.primaryUser;
  primaryUserHome = config.system.primaryUserHome;
in
{
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    orientation = "right";
    tilesize = 36;
    show-recents = false;
    static-only = true;
    minimize-to-application = true;
    show-process-indicators = true;
  };

  system.defaults.finder = {
    _FXSortFoldersFirst = true;
    _FXSortFoldersFirstOnDesktop = true;
    ShowPathbar = true;
    ShowStatusBar = true;
    QuitMenuItem = true;
    _FXShowPosixPathInTitle = true;
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "Nlsv";
    FXDefaultSearchScope = "SCcf";
    NewWindowTarget = "Home";
  };

  system.defaults.NSGlobalDomain = {
    AppleShowAllExtensions = true;
    AppleShowScrollBars = "Always";
    "com.apple.trackpad.scaling" = 3.0;
    ApplePressAndHoldEnabled = false;
    KeyRepeat = 3;
    InitialKeyRepeat = 25;
    "com.apple.keyboard.fnState" = true;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    AppleKeyboardUIMode = 2;
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
    # Tighter menu-bar icon spacing than macOS's default.
    NSStatusItemSpacing = 12;
    NSStatusItemSelectionPadding = 12;
  };

  # Rectangle arranges windows; macOS's own edge-drag tiling stays off.
  system.defaults.WindowManager = {
    EnableTilingByEdgeDrag = false;
    EnableTopTilingByEdgeDrag = false;
    EnableTilingOptionAccelerator = false;
  };

  # Updates download automatically, but macOS installs only when asked.
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

  system.defaults.screencapture = {
    disable-shadow = true;
    show-thumbnail = false;
    type = "jpg";
    location = "${primaryUserHome}/Desktop/Screenshots";
  };

  system.defaults.ActivityMonitor = {
    OpenMainWindow = true;
    IconType = 5;
    ShowCategory = 100;
  };

  system.defaults.trackpad.Clicking = true;

  # Preferences without dedicated nix-darwin options.
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      QLEnableTextSelection = true;
      FXInfoPanesExpanded = {
        General = true;
        OpenWith = true;
        Privileges = true;
      };
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    "com.apple.Preview".ApplePersistenceIgnoreState = true;

    # Appearance → Liquid Glass tint, adjusted by hand.
    NSGlobalDomain.NSGlassTintAmount = 0.5;

    # Keyboard layouts, in the order System Settings lists them. The last
    # entry is Emoji & Symbols, which macOS always adds.
    "com.apple.HIToolbox".AppleEnabledInputSources = [
      { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = -19521; "KeyboardLayout Name" = "Serbian-Latin"; }
      { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 0; "KeyboardLayout Name" = "U.S."; }
      { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 19521; "KeyboardLayout Name" = "Serbian"; }
      { "Bundle ID" = "com.apple.CharacterPaletteIM"; InputSourceKind = "Non Keyboard Input Method"; }
    ];

    # The whole shortcut table, as System Settings → Keyboard → Shortcuts
    # leaves it; writing it replaces the table, so every entry is listed.
    # Off by the user: 32 Mission Control (^Up), 33 Application windows
    # (^Down), 36 Show Desktop (F11), 52 Dock hiding (Opt-Cmd-D), 60/61
    # previous/next input source (^Space, ^Opt-Space), 79/81 Space left/right
    # (^Left/^Right), 118 Desktop 1 (^1). Off by macOS already: 15-26 (Zoom
    # and contrast), 164 (Do Not Disturb). Applies from the next login.
    "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
      "15" = { enabled = false; };
      "16" = { enabled = false; };
      "17" = { enabled = false; };
      "18" = { enabled = false; };
      "19" = { enabled = false; };
      "20" = { enabled = false; };
      "21" = { enabled = false; };
      "22" = { enabled = false; };
      "23" = { enabled = false; };
      "24" = { enabled = false; };
      "25" = { enabled = false; };
      "26" = { enabled = false; };
      "32" = { enabled = false; value = { parameters = [ 65535 126 8650752 ]; type = "standard"; }; };
      "33" = { enabled = false; value = { parameters = [ 65535 125 8650752 ]; type = "standard"; }; };
      "36" = { enabled = false; value = { parameters = [ 65535 103 8388608 ]; type = "standard"; }; };
      "52" = { enabled = false; value = { parameters = [ 100 2 1572864 ]; type = "standard"; }; };
      "60" = { enabled = false; value = { parameters = [ 32 49 262144 ]; type = "standard"; }; };
      "61" = { enabled = false; value = { parameters = [ 32 49 786432 ]; type = "standard"; }; };
      "79" = { enabled = false; value = { parameters = [ 65535 123 8650752 ]; type = "standard"; }; };
      "80" = { enabled = true; };
      "81" = { enabled = false; value = { parameters = [ 65535 124 8650752 ]; type = "standard"; }; };
      "82" = { enabled = true; value = { parameters = [ 65535 124 8781824 ]; type = "standard"; }; };
      "118" = { enabled = false; value = { parameters = [ 65535 18 262144 ]; type = "standard"; }; };
      "164" = { enabled = false; value = { parameters = [ 65535 65535 0 ]; type = "standard"; }; };
    };

    # Siri off, personalised Apple ads off, clipboard history in Spotlight on.
    "com.apple.assistant.support"."Assistant Enabled" = false;
    "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
    "com.apple.Spotlight".PasteboardHistoryEnabled = true;
  };

  # App Store apps are not updated automatically. The full path matters:
  # activation runs as root, so a bare domain would land in root's own
  # preferences instead of the system-wide file macOS reads.
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.commerce".AutoUpdate = false;

  system.activationScripts.postActivation.text =
    ''
      libraryDir=${lib.escapeShellArg "${primaryUserHome}/Library"}
      screenshotDir=${lib.escapeShellArg "${primaryUserHome}/Desktop/Screenshots"}
      primaryUserName=${lib.escapeShellArg primaryUser}
      if [ -d "$libraryDir" ]; then
        libraryFlags=$(/usr/bin/stat -f '%Sf' "$libraryDir")
        case ",$libraryFlags," in
          *,hidden,*)
            echo >&2 "unhiding $libraryDir..."
            /usr/bin/chflags nohidden "$libraryDir"
            ;;
        esac
      fi

      if [ -e "$screenshotDir" ] && [ ! -d "$screenshotDir" ]; then
        echo >&2 "expected screenshot directory: $screenshotDir"
        exit 1
      elif [ ! -e "$screenshotDir" ]; then
        /bin/mkdir -p "$screenshotDir"
        /usr/sbin/chown "$primaryUserName":staff "$screenshotDir"
      fi

      # Control Center menu bar items live in the per-host domain
      # (ByHost/com.apple.controlcenter.<hardware UUID>.plist). The pinned
      # system.defaults.controlcenter options write a UUID-less ByHost file
      # that macOS does not read, so write through -currentHost instead.
      # Run as the primary user, the same way nix-darwin writes user defaults.
      primaryUserId=$(/usr/bin/id -u -- "$primaryUserName")
      writeControlCenter() {
        /bin/launchctl asuser "$primaryUserId" \
          /usr/bin/sudo --user="$primaryUserName" -- \
          /usr/bin/defaults -currentHost write com.apple.controlcenter "$@"
      }
      writeControlCenter BatteryShowPercentage -bool true
      writeControlCenter Bluetooth -int 18
      writeControlCenter Sound -int 18
    '';
}
