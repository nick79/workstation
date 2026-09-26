{ fetchurl, runCommand, unzip }:

# The JUnit runner bundle for jdtls (vscode-java-test's server/ jars), from
# Open VSX, pinned by hash. nixpkgs has 0.45.0, whose plugin requires the ASM
# library in [9.9, 9.10) while jdtls 1.61 ships ASM 9.10.1: the bundle then
# fails to resolve and no test can run. 0.46.0 matches. Drop this file for
# nixpkgs' vscode-extensions.vscjava.vscode-java-test once that catches up.
let
  version = "0.46.0";
  vsix = fetchurl {
    name = "vscode-java-test-${version}.zip";
    url = "https://open-vsx.org/api/vscjava/vscode-java-test/${version}/file/vscjava.vscode-java-test-${version}.vsix";
    hash = "sha256-VsHhTcc6MOlXTEcEIQb6Uok7+DJbWA9HwUrOB9Xu8lU=";
  };
in
runCommand "java-test-bundles-${version}" { nativeBuildInputs = [ unzip ]; } ''
  unzip -q ${vsix} 'extension/server/*'
  mkdir -p $out/share
  mv extension/server $out/share/java-test
''
