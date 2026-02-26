{ lib
, stdenv
, makeWrapper
, gh
, jq
, gum
, bash
}:

stdenv.mkDerivation rec {
  pname = "brigit";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ bash ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/brigit

    # Install main script
    cp brigit $out/bin/brigit
    chmod +x $out/bin/brigit

    # Install library
    cp _lib.sh $out/share/brigit/_lib.sh

    # Install configuration
    cp ghbranchprotection.json $out/share/brigit/ghbranchprotection.json

    # Install example files
    cp repos-ignore.txt.example $out/share/brigit/repos-ignore.txt.example

    # Wrap the binary to set PATH and point to the shared library
    wrapProgram $out/bin/brigit \
      --prefix PATH : ${lib.makeBinPath [ gh jq gum bash ]} \
      --set BRIGIT_LIB_DIR $out/share/brigit

    runHook postInstall
  '';

  meta = with lib; {
    description = "Branch Integrity Guard for Git - GitHub branch protection management tool";
    homepage = "https://github.com/wearetechnative/brigit";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}
