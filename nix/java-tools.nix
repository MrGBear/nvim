pkgs:
let
  # Match spotless-maven-plugin 3.5.1 rather than nixpkgs' newer formatter.
  google-java-format = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "google-java-format";
    version = "1.28.0";

    src = pkgs.fetchurl {
      url = "https://github.com/google/google-java-format/releases/download/v${finalAttrs.version}/google-java-format-${finalAttrs.version}-all-deps.jar";
      hash = "sha256-MjQufBtGAPgN80cdpGrugBLT4URdXqG+H7cSibB8xzU=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ pkgs.jre ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,share/${finalAttrs.pname}}
      install -D $src $out/share/${finalAttrs.pname}/${finalAttrs.pname}-${finalAttrs.version}-all-deps.jar

      makeWrapper ${pkgs.jre}/bin/java $out/bin/${finalAttrs.pname} \
        --argv0 ${finalAttrs.pname} \
        --add-flags "--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED" \
        --add-flags "--add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED" \
        --add-flags "--add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED" \
        --add-flags "--add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED" \
        --add-flags "--add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED" \
        --add-flags "-jar $out/share/${finalAttrs.pname}/${finalAttrs.pname}-${finalAttrs.version}-all-deps.jar"

      runHook postInstall
    '';

    meta = {
      description = "Java source formatter by Google (pinned to match spotless)";
      homepage = "https://github.com/google/google-java-format";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "google-java-format";
    };
  });
in
{
  packages = [
    pkgs.jdt-language-server
    google-java-format
  ];
  sessionVariables = {
    JDTLS_JVM_ARGS = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
    JDTLS_DEBUG_PLUGIN = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";
    JDTLS_TEST_PLUGIN = "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server";
  };
}
