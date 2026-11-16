pkgs: {
  packages = [
    pkgs.jdt-language-server
    pkgs.google-java-format
  ];
  sessionVariables = {
    JDTLS_JVM_ARGS = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
    JDTLS_DEBUG_PLUGIN = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";
    JDTLS_TEST_PLUGIN = "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server";
  };
}
