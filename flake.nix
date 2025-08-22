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

          gemini-cli = pkgs.buildNpmPackage rec {
            pname = "gemini-cli";
            version = "0.1.22";

            src = pkgs.fetchFromGitHub {
              owner = "google-gemini";
              repo = "gemini-cli";
              tag = "v${version}";
              hash = "sha256-taQyrthHrlHc6Zy8947bpxvbHeSq0+JbgxROtQOGq44=";
            };

            npmDepsHash = "sha256-5vF4ojal3RFv9qbRW9mvX8NaRzajiXNCDC3ZvmS2eAw=";
            patches = [
                ./package-lock.json.patch
            ];

            preConfigure = ''
              mkdir -p packages/generated
              echo "export const GIT_COMMIT_INFO = { commitHash: 'v${version}' };" > packages/generated/git-commit.ts
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
              cp -r packages/test-utils $out/share/gemini-cli/node_modules/@google/gemini-cli-core-test-utils

              ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
              runHook postInstall
            '';

            postInstall = ''
              chmod +x "$out/bin/gemini"
            '';

            passthru.updateScript = pkgs.gitUpdater { };

            meta = with pkgs.lib; {
              description = "An open-source AI agent that brings the power of Gemini directly into your terminal";
              homepage = "https://github.com/google-gemini/gemini-cli";
              license = licenses.asl20;
              platforms = platforms.all;
              mainProgram = "gemini";
            };
          };
        });
    };
}
