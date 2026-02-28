{ pkgs, lib, config, inputs, ... }:

let 
  otfPkgs = inputs.nix-pkgs-opentofu-1_10_6.legacyPackages.${pkgs.stdenv.system};
  talosctlPkgs = inputs.nix-pkgs-talosctl-1_11_5.legacyPackages.${pkgs.stdenv.system};
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
    pkgs.openssl
    talosctlPkgs.talosctl
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

  scripts."sandbox:opencode".exec = ''
    docker sandbox run opencode
  '';

  scripts.pack-image.exec = ''
    secretspec run -- packer init ./packer
    secretspec run -- packer build ./packer
  '';

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
    secretspec run -- ./scripts/bootstrap.sh
    talosctl --talosconfig ./.talosconfig health
  '';

  scripts.destroy.exec = ''
    secretspec run -- tofu -chdir=infra destroy
  '';

  scripts.gitleaks-check.exec = ''
    gitleaks detect --source . --redact --verbose --log-opts="--all"
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
