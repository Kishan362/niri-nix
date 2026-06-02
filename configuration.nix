{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  ########################################
  # Firmware / microcode
  ########################################
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  ########################################
  # Bootloader
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ########################################
  # Zen kernel (better gaming latency)
  ########################################
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  ########################################
  # Frametime-focused kernel tuning
  ########################################
#   boot.kernel.sysctl = {
#     "vm.swappiness" = 10;
#     "vm.dirty_background_ratio" = 3;
#     "vm.dirty_ratio" = 10;
#     "vm.vfs_cache_pressure" = 50;
#     "vm.page-cluster" = 0;
#     "kernel.sched_autogroup_enabled" = 1;
#   };

  ########################################
  # Hostname / networking
  ########################################
  networking.hostName = "Katana-63";
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    allowPing = false;
  };

  ########################################
  # Hardening / services
  ########################################
  services.openssh.enable = false;
  services.avahi.enable = false;
  services.printing.enable = false;
  services.fwupd.enable = true; #Firmware update services
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;
  hardware.pulseaudio.enable = false;

  services.fstrim = { # hardisk health services
    enable = true;
    interval = "weekly";
  };

  services.thermald.enable = true; #cpu cooling service

  services.smartd = { #smart hardisk monitoring service
    enable = true;
    autodetect = true;
  };

  ########################################
  # Garbage collection
  ########################################
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  ########################################
  # Nix features
  ########################################
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  ########################################
  # Timezone
  ########################################
  time.timeZone = "Asia/Kolkata";

  ########################################
  # X11 + Plasma
  ########################################
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Better NVIDIA stability on laptop
  services.displayManager.sddm.wayland.enable = false;

  ########################################
  # Audio
  ########################################
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ########################################
  # User
  ########################################
  users.users.jesper = { # change your username here 'lki is the username'
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ tree ];
  };

  ########################################
  # Allow unfree
  ########################################
  nixpkgs.config.allowUnfree = true;

  ########################################
  # Graphics
  ########################################
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  ########################################
  # NVIDIA
  ########################################
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    powerManagement.enable = true;

    # Better gaming stability than finegrained on many laptops
    powerManagement.finegrained = false;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      sync.enable = false;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  ########################################
  # Steam / gaming
  ########################################
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "auto";
        renice = 10;
      };

      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        nv_powermizer_mode = 1;
      };
    };
  };

  ########################################
  # TLP / power Custom power settings service
  ########################################
  services.power-profiles-daemon.enable = lib.mkForce false;  # make sure to disable this

  services.tlp = {
    enable = true;
    settings = {
      # AC = gaming
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      # Battery
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 18;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      USB_AUTOSUSPEND = 1;

      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };

  ########################################
  # Programs
  ########################################
  programs.firefox.enable = true;

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    curl
    nano
    tree
    vlc
    obs-studio
    kdePackages.kdenlive
    pciutils
    lmstudio
    iproute2
    libreoffice-fresh

    # Gaming tools
    mangohud
    gamemode
    protonup-ng
    goverlay
    nvtopPackages.nvidia
    vulkan-tools
  ];

  ########################################
  # Version
  ########################################
  system.stateVersion = "25.11";
}