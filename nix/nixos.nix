self: { config, lib, pkgs, ... }:
let
  cfg = config.programs.island;
  shared = import ./options.nix { inherit lib pkgs self; };
  pkg = shared.finalPackage cfg;
in
{
  options.programs.island = shared.options;

  config = lib.mkIf cfg.enable {
    programs.island.colorsTemplate = "${pkg}/share/island/contrib/quickshell-colors.json";

    environment.systemPackages = [ pkg ];
    fonts.packages = shared.fonts cfg;

    # things the shell talks to
    services.upower.enable = lib.mkDefault true;
    services.udev.packages = [ pkgs.brightnessctl ];   # brightness without root

    warnings =
      lib.optional (!config.networking.networkmanager.enable)
        "programs.island: the Wi-Fi tile needs NetworkManager (networking.networkmanager.enable)."
      ++ lib.optional (!config.services.pipewire.enable)
        "programs.island: the volume slider needs PipeWire (services.pipewire.enable).";

    systemd.user.services.island = lib.mkIf cfg.systemd.enable {
      description = "island shell";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = lib.getExe pkg;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
