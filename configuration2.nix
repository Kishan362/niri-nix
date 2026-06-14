{ config, pkgs, lib, ... }:

let
  # 1. Fetch Home Manager branch pinned for 26.05 stability
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";
  };

  # 2. Fetch the automated Zen Browser Flake wrapper layer
  zen-browser-flake = import (builtins.fetchTarball {
    url = "https://github.com/youwen5/zen-browser-flake/archive/master.tar.gz";
  }) { inherit pkgs; };

  # 3. Fetch the Noctalia Shell ecosystem stable repository source
  noctalia-src = builtins.fetchTarball {
    url = "https://github.com/noctalia-dev/noctalia/archive/legacy-v4.tar.gz";
  };
  
  # Load the official home module layout safely from the root structure
  noctalia-home-module = import "${noctalia-src}/hm-module.nix"; 
in
{
  imports = [
    "${home-manager}/nixos"
  ];

  # ============================================================================
  # 1. SYSTEM & BOOT CONFIGURATION
  # ============================================================================

  boot.kernelPackages = pkgs.linuxPackages_zen;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters for stable NVIDIA / Wayland interaction
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  services.fstrim.enable = true;

  # ============================================================================
  # 2. NIX PACKAGE MANAGER SETTINGS & AUTOMATIC STORAGE CLEANUP
  # ============================================================================

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true; 
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d"; 
    };
  };
  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # 3. NETWORKING, FIREWALL & SECURITY
  # ============================================================================

  networking.hostName = "Katana-63";
  networking.networkmanager.enable = true;
  networking.enableIPv6 = true;

  networking.firewall = {
    enable = true;
    allowPing = false; 

    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    allowedUDPPortRanges = [
      { from = 27000; to = 27100; }
      { from = 4380; to = 4380; }
    ];
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      server_names = [ "adguard-dns" ];
      ipv6_servers = true;
      require_dnssec = true;
      require_nolog = true;
      listen_addresses = [ "127.0.0.1:53" ];
      cache = true;
      timeout = 2500;
    };
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.openssh.enable = false;

  # ============================================================================
  # 4. HARDWARE & GRAPHICS (NVIDIA PRIME OPTIMIZATION)
  # ============================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false; 
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      sync.enable = false;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.usbmuxd.enable = true;
  services.printing.enable = false;

  # ============================================================================
  # 5. POWER MANAGEMENT & DESKTOP HARDWARE DEPENDENCIES
  # ============================================================================

  services.power-profiles-daemon.enable = true; # Required backplane framework for Noctalia's power status metrics
  services.upower.enable = true;                 
  services.thermald.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      CPU_MAX_PERF_ON_BAT = 60;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      RUNTIME_PM_ON_BAT = "auto";
      USB_AUTOSUSPEND = 1;
      PCIE_ASPM_ON_BAT = "balanced";
    };
  };

  # ============================================================================
  # 6. DESKTOP, DESKTOP PORTALS (KDE NATIVE) & AUDIO
  # ============================================================================

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;
  services.desktopManager.plasma6.enable = true;

  programs.niri.enable = true;
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = [ "kde" ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # ============================================================================
  # 7. GLOBAL SYSTEM USERS & FONTS
  # ============================================================================

  time.timeZone = "Asia/Kolkata";
  programs.fish.enable = true;

  users.users.jasper = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "video" "networkmanager" ];
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.hack
      nerd-fonts.noto
      nerd-fonts.symbols-only

      inter roboto cantarell-fonts ubuntu-classic
      jetbrains-mono fira-code iosevka iosevka-comfy.comfy
      noto-fonts-color-emoji noto-fonts noto-fonts-cjk-sans
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
        sansSerif = [ "Inter" "Roboto" ];
        serif     = [ "Noto Serif" ];
        emoji     = [ "Noto Color Emoji" ];
      };
    };
  };

  # ============================================================================
  # 8. SYSTEM GLOBAL PACKAGES
  # ============================================================================

  programs.firefox.enable = true;
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git gh curl wget axel jq ripgrep fd zip unzip p7zip unrar cabextract
    nano neovim btop htop pciutils iproute2 fastfetch libimobiledevice
    kitty starship vlc kazam obs-studio libreoffice-fresh
    playerctl wl-clipboard cliphist grim slurp swappy cava pavucontrol brightnessctl
    gcc gnumake lua5_4 python313 uv nodejs_26 pnpm vscode 
    mangohud protonup-ng goverlay vulkan-tools nvtopPackages.nvidia
    heroic lutris winetricks protonup-qt wineWow64Packages.stable
  ];

  # ============================================================================
  # 9. HOME MANAGER USER SPACE DECLARATIONS (Inline Context)
  # ============================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.jasper = { pkgs, ... }: {
      imports = [
        noctalia-home-module
      ];

      home.stateVersion = "26.05";

      home.packages = [
        zen-browser-flake
      ];

      # Verified configuration path layout for the Noctalia framework
      programs.noctalia-shell = {
        enable = true;
        settings = {
          bar = {
            position = "top";
            density = "compact";
          };
        };
      };

      xdg.configFile."niri/config.kdl".text = ''
        binds {
            "XF86AudioRaiseVolume" allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" "-m" "1.5"; }
            "XF86AudioLowerVolume" allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" "-m" "1.5"; }
            "XF86AudioMute"        allow-when-locked=true { spawn "wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle"; }
            
            "XF86MonBrightnessUp"   allow-when-locked=true { spawn "brightnessctl" "set" "10%+"; }
            "XF86MonBrightnessDown" allow-when-locked=true { spawn "brightnessctl" "set" "10%-"; }

            "XF86AudioPlay"  allow-when-locked=true { spawn "playerctl" "play-pause"; }
            "XF86AudioNext"  allow-when-locked=true { spawn "playerctl" "next"; }
            "XF86AudioPrev"  allow-when-locked=true { spawn "playerctl" "previous"; }
        }
      '';
    };
  };

  # ============================================================================
  # 10. SYSTEM STATE CONTEXT
  # ============================================================================

  system.stateVersion = "26.05"; 
}
