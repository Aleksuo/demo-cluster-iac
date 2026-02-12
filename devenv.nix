{ pkgs, lib, config, inputs, ... }:

let 
  otfPkgs = inputs.nix-pkgs-opentofu-1_10_6.legacyPackages.${pkgs.stdenv.system};
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.system;
  };
in   
{
  # https://devenv.sh/packages/
  packages = [ 
    pkgs.git
    pkgs.kubectl
    pkgs.kubectx
    pkgs.talosctl
    pkgs.packer
    pkgs.gitleaks
    pkgsUnstable.secretspec
   ];

  # https://devenv.sh/languages/
  #languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/

  languages.opentofu.enable = true;
  languages.opentofu.package = otfPkgs.opentofu;

  languages.helm.enable = true;

  scripts.init.exec = ''
    secretspec run -- tofu -chdir=infra init
  '';

  scripts.plan.exec = ''
    secretspec run -- tofu -chdir=infra plan
  '';

  scripts.apply.exec = ''
    secretspec run -- tofu -chdir=infra apply
    tofu -chdir=infra output -raw talosconfig > ./.talosconfig
    talosctl --talosconfig ./.talosconfig kubeconfig --merge --force
    ./scripts/bootstrap-cilium.sh
    secretspec run -- ./scripts/bootstrap-hetzner-ccm.sh
    talosctl --talosconfig ./.talosconfig health
  '';

  scripts.destroy.exec = ''
    secretspec run -- tofu -chdir=infra destroy
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

  git-hooks.hooks.gitleaks = {
    enable = true;
    name = "gitleaks (staged)";
    entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --redact";
    language = "system";
    stages = [ "pre-commit" ];
    pass_filenames = false;
  };

  # See full reference at https://devenv.sh/reference/options/
}