{
  description = "Vigrestad Maskin marketing site with intelligent skills and agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    skeletons.url = "github:netbrain/skeletons";
  };

  outputs = { self, nixpkgs, flake-utils, skeletons }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            skeletons.packages.${system}.intent-classifier
            # Astro marketing site dependencies
            nodejs
            playwright-driver.browsers
            gh
          ];

          shellHook = ''
            # Fix execute permissions on scripts (Nix templates don't preserve +x)
            if [ -d .claude ]; then
              find .claude -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
            fi

            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

            echo "🚜 Vigrestad Maskin dev environment"
            echo ""
          '';
        };
      });
}
