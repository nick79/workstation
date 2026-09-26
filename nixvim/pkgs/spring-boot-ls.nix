{ fetchurl, runCommand, unzip }:

# Spring Boot Language Server. Not in nixpkgs: upstream ships it only
# inside the "Spring Boot Tools" VS Code extension, which is a zip. This takes
# the stable release from Open VSX (the Eclipse Foundation's registry), pinned
# by hash, and keeps just the parts Neovim uses:
#   language-server/  the server itself, a Java program (run by spring-boot.nvim
#                     as language-server/language-server.jar)
#   jars/             extensions loaded into jdtls so the two servers cooperate
# Newer versions on Open VSX with a date in the number are nightly builds.
let
  version = "2.4.0";
  vsix = fetchurl {
    name = "vscode-spring-boot-${version}.zip";
    url = "https://open-vsx.org/api/VMware/vscode-spring-boot/${version}/file/VMware.vscode-spring-boot-${version}.vsix";
    hash = "sha256-d0PlCpAopsG6j4KYZXapXGE91iImUPjpeV7Pehquu3k=";
  };
in
runCommand "spring-boot-ls-${version}" { nativeBuildInputs = [ unzip ]; } ''
  unzip -q ${vsix} 'extension/language-server/*' 'extension/jars/*'
  mkdir -p $out/share
  mv extension $out/share/spring-boot-ls
  # A stable name for the versioned server jar (it finds lib/ beside it).
  cd $out/share/spring-boot-ls/language-server
  ln -s spring-boot-language-server-*-exec.jar language-server.jar
''
