{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # -------------------------
  # Bootloader (GRUB)
  # -------------------------
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # -------------------------
  # Networking
  # -------------------------
  networking.hostName = "nixos-niri";
  networking.networkmanager.enable = true;

  # -------------------------
  # Time & Locale
  # -------------------------
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_IN";

  # -------------------------
  # XDG User Directories
  # -------------------------
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # -------------------------
  # Bluetooth
  # -------------------------
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # -------------------------
  # NVIDIA Graphics
  # -------------------------
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  # -------------------------
  # Niri (Official module)
  # -------------------------
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  # -------------------------
  # Display Manager (GDM)
  # -------------------------
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;

  # -------------------------
  # Audio (PipeWire)
  # -------------------------
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  services.pulseaudio.enable = false;

  # -------------------------
  # Input
  # -------------------------
  services.libinput.enable = true;

  # -------------------------
  # Flatpak & Power
  # -------------------------
  services.flatpak.enable = true;
  services.power-profiles-daemon.enable = true;

  # -------------------------
  # XDG Portal
  # -------------------------
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # -------------------------
  # Steam + Gaming
  # -------------------------
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # -------------------------
  # System Packages
  # -------------------------
  environment.systemPackages = with pkgs; [

    # Core
    git wget curl unzip vim neovim

    # Terminal
    kitty

    # File manager
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.spectacle

    # Noctalia runtime
    quickshell

    # Wayland essentials
    fuzzel
    mako
    wl-clipboard
    grim slurp swappy

    # System utilities
    brightnessctl
    playerctl
    networkmanagerapplet
    pavucontrol
    blueman
    udiskie

    # Gaming tools
    mangohud
    goverlay
    protonup-qt
    lutris
    heroic
    bottles

    # CLI tools
    ripgrep
    fd
    bat
    eza
    btop
    fastfetch
    jq

    # Media
    mpv
    imv

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    font-awesome

    # Polkit agent
    kdePackages.polkit-kde-agent-1
  ];

  # -------------------------
  # User
  # -------------------------
  users.users.lki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "gamemode" ];
  };

  # -------------------------
  # Programs
  # -------------------------
  programs.zsh.enable = true;

  # -------------------------
  # Security
  # -------------------------
  security.polkit.enable = true;

  # -------------------------
  # Environment
  # -------------------------
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    XDG_SESSION_TYPE = "wayland";
  };

  # -------------------------
  # Nix (NO experimental)
  # -------------------------
  nix.settings.experimental-features = [ ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}