{
  binaryen,
  cargo,
  cargo-leptos,
  fetchFromGitHub,
  lib,
  llvmPackages,
  makeWrapper,
  nixosTests,
  pkgs,
  rustPlatform,
  sqlite,
  stdenv,
  writeShellScriptBin,
}:
let
  version = "f4bafa37cc195831d7ed6f52ef69b0de5b880b9f";
  src = stdenv.mkDerivation {
    name = "source";
    src = fetchFromGitHub {
      owner = "typhon-ci";
      repo = "typhon";
      rev = version;
      sha256 = "1jRuMCCSabHPcaNvkcyd+4HdDFnn4Wr2JiB57kwba40=";
    };
    patches = [ ./wasm-bindgen.diff ];
    buildPhase = "true";
    installPhase = "cp -r . $out";
  };
  nodeDependencies =
    (import ./node-composition.nix {
      inherit pkgs;
      inherit (stdenv.hostPlatform) system;
    }).nodeDependencies;
  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "typhon-deps";
    sha256 = "Pyhs/YcFiGurHATXyclF9EqH7PmrOJbBMEh86YamJKA=";
  };
  rust-lld = writeShellScriptBin "rust-lld" ''lld "$@"'';
in
stdenv.mkDerivation {
  pname = "typhon";
  inherit version src cargoDeps;
  RUSTC_BOOTSTRAP = 1;
  TYPHON_FLAKE = "${src}/typhon-flake";
  nativeBuildInputs = [
    binaryen
    cargo
    cargo-leptos
    llvmPackages.bintools
    makeWrapper
    rust-lld
    rustPlatform.cargoSetupHook
    sqlite.dev
  ];
  buildPhase = "cargo-leptos build --release";
  installPhase = ''
    mkdir -p $out/bin
    cp target/release/typhon $out/bin/
    cp -r target/site $out/bin/
    cp -r ${nodeDependencies}/lib/node_modules $out/bin/site
    wrapProgram $out/bin/typhon --set LEPTOS_SITE_ROOT $out/bin/site
  '';
  passthru = {
    tests.nixos = nixosTests.typhon;
  };
  meta = {
    description = "Nix-based continuous integration";
    mainProgram = "typhon";
    homepage = "https://typhon-ci.org/";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.pnmadelaine ];
    platforms = [ "x86_64-linux" ];
  };
}
