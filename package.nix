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
  version = lib.trim (builtins.readFile ./VERSION);

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ bash ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/brigit

    # Install main script to share directory
    cp brigit $out/share/brigit/brigit
    chmod +x $out/share/brigit/brigit

    # Install library
    cp _lib.sh $out/share/brigit/_lib.sh

    # Install VERSION file
    cp VERSION $out/share/brigit/VERSION

    # Install configuration
    cp ghbranchprotection.json $out/share/brigit/ghbranchprotection.json

    # Install example files
    cp repos-ignore.txt.example $out/share/brigit/repos-ignore.txt.example

    # Create wrapper in bin directory that preserves binary name
    makeWrapper $out/share/brigit/brigit $out/bin/brigit \
      --argv0 brigit \
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
