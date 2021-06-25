#! /bin/sh

# adopted from <nixpkgs>/pkgs/stdenv/generic/setup.sh

export PATH=
for i in $buildInputs; do
    if [ "$i" = / ]; then i=; fi
    PATH=$PATH${PATH:+:}$i/bin
done

set -eu

set

# To mimick these commands being provided by the `nix` binary
# we take them from the environment and are impure on purpose.
# The patch polyfill deals with flake inputs and there is no way
# we can have ever access to a nixpkgs.pkgs at this stage.
checkCmd() {
  if ! command -v "${1}" > /dev/null  2>&1
  then
      echo "${1} could not be found, but is required to apply patch ${2}"
      exit
  fi
}

header() { echo "$1"; }

applyPatches() {
  for i in ${patches:-}; do
      checkCmd "patch" "$i"
      header "applying patch $i"
      uncompress="/usr/bin/cat"
      # case "$i" in
      #     *.gz)
      #         checkCmd "gzip" "$i"
      #         uncompress="gzip -gad"
      #         ;;
      #     *.bz2)
      #         checkCmd "bzip2" "$i"
      #         uncompress="bzip2 -d"
      #         ;;
      #     *.xz)
      #         checkCmd "xz" "$i"
      #         uncompress="xz -d"
      #         ;;
      #     *.lzma)
      #         checkCmd "lzma" "$i"
      #         uncompress="lzma -d"
      #         ;;
      #     *)
      #         checkCmd "cat" "$i"
      #         uncompress="cat"
      #         ;;
      # esac

      # "2>&1" is a hack to make patch fail if the decompressor fails (nonexistent patch, etc.)
      # shellcheck disable=SC2086
      $uncompress < "$i" 2>&1 | patch ${patchFlags:--p1}
  done
}
cp -rp "${src}" "${out}"
cd "${out}"
applyPatches

