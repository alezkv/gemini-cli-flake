{
  description = "Gemini CLI package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/32f313e49e42f715491e1ea7b306a87c16fe0388";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = self.packages.${system}.gemini-cli;

          gemini-cli = pkgs.buildNpmPackage (finalAttrs: {
            pname = "gemini-cli";
            version = "0.2.2";

            src = pkgs.fetchFromGitHub {
              owner = "google-gemini";
              repo = "gemini-cli";
              tag = "v${finalAttrs.version}";
              hash = "sha256-ykNgtHtH+PPCycRn9j1lc8UIEHqYj54l0MTeVz6OhsQ=";
            };

            patches = [
              ./restore-missing-dependencies-fields.patch
            ];

            npmDepsHash = "sha256-gpNt581BHDA12s+3nm95UOYHjoa7Nfe46vgPwFr7ZOU=";

            preConfigure = ''
              mkdir -p packages/generated
              echo "export const GIT_COMMIT_INFO = { commitHash: '${finalAttrs.src.rev}' };" > packages/generated/git-commit.ts
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/{bin,share/gemini-cli}

              cp -r node_modules $out/share/gemini-cli/

              rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
              rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
              rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-test-utils
              rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion
              cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
              cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core

              ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
              runHook postInstall
            '';

            postInstall = ''
              chmod +x "$out/bin/gemini"
            '';

            passthru.updateScript = pkgs.nix-update-script { };

            meta = {
              description = "AI agent that brings the power of Gemini directly into your terminal";
              homepage = "https://github.com/google-gemini/gemini-cli";
              license = pkgs.lib.licenses.asl20;
              maintainers = with pkgs.lib.maintainers; [
                # Add maintainers here if needed
              ];
              platforms = pkgs.lib.platforms.all;
              mainProgram = "gemini";
            };
          });
        });
    };
}
