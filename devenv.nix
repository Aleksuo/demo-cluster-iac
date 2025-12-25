{ pkgs, lib, config, inputs, ... }:

let 
  otfPkgs = inputs.nix-pkgs-opentofu-1_10_6.legacyPackages.${pkgs.stdenv.system};
in   
{
  # https://devenv.sh/basics/
  env.GREET = "devenv";


  # https://devenv.sh/packages/
  packages = [ 
    pkgs.git
    pkgs.kubectl
    pkgs.kubectx
    pkgs.talosctl
    pkgs.packer
   ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/

  languages.opentofu.enable = true;
  languages.opentofu.package = otfPkgs.opentofu;

  languages.helm.enable = true;

  scripts.init-cluster.exec = ''
    (cd infra && tofu apply)
    (cd infra && tofu output -raw talosconfig > ../.talosconfig)
    talosctl --talosconfig ./.talosconfig kubeconfig --merge --force
    ./scripts/bootstrap-cilium.sh
    secretspec run -- ./scripts/bootstrap-hetzner-ccm.sh
    talosctl --talosconfig ./.talosconfig health
  '';

  scripts.destroy-cluster.exec = ''
    (cd infra && tofu destroy)
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}