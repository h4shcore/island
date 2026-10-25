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

    home.packages = [ pkg ] ++ shared.fonts cfg;
    fonts.fontconfig.enable = lib.mkIf cfg.installFonts true;

    systemd.user.services.island = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "island shell";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe pkg;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
