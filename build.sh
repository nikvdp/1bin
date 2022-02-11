#!/usr/bin/env bash
set -eu
set -x

# Usage:
# ./build.sh <some-conda-package-with-an-executable>
#  eg. `./build.sh jq`
# will put a jq exec in the ./out folder
RUN_ID="$(date +%s)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_TO_INSTALL_NAME=(${@:-"nlpentities"})
CMD_TO_RUN=(${CMD_TO_RUN:-$PKG_TO_INSTALL_NAME})
# @note that CMD_TO_RUN is not used as an array below, which in bash means
# CONDA_ENV_NAME to the first item of CMD_TO_RUN. so below means: if
# CONDA_ENV_NAME is not set, set it to first item of CMD_TO_RUN array
CONDA_ENV_NAME="${CONDA_ENV_NAME:-${CMD_TO_RUN}}-$RUN_ID"
OUTPUT_DIR="$SCRIPT_DIR/out"
OUTPUT_BIN_NAME="${OUTPUT_BIN_NAME:-${CMD_TO_RUN}}"
CONDAPACK_TARBALL="$SCRIPT_DIR/$CMD_TO_RUN.tar.gz"
BUNDLE_WORK_DIR="${SCRIPT_DIR}/build/conda-pack-workdir-$RUN_ID"
WARP_ENTRY_POINT="${BUNDLE_WORK_DIR}/bin/warp-entrypoint.sh"
WARP_ARCH="$(uname | sed 's/Darwin/macos/' | sed 's/Linux/linux/')-x64"

write-warp-entrypoint() {
  # writes a small stub script that prepends the directory it finds itself in
  # to the PATH before calling into the python script. This ensures the
  # shebang at the beginning of the python script calls the bundled python
  # interpreter.
  # the odd `echo ${CMD_TO_RUN[@]@Q}` bit takes care of quoting CMD_TO_RUN
  # properly, see [1]
  #
  # WARNING: be sure not to insert a new-line in front of #!/usr/bin/env bash or
  # you'll get confusing 'Exec format error' messages!
  # [1]: https://listed.to/@dhamidi/29004/bash-quoting-code
  echo >"$WARP_ENTRY_POINT" '#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

export PATH="$SCRIPT_DIR:$PATH"

exec '${CMD_TO_RUN[@]@Q}' "$@"
'
  chmod +x "$WARP_ENTRY_POINT"
}
pack-binary() {
  mkdir -p "$OUTPUT_DIR" &>/dev/null
  # ⚠️   @NOTE! This requires the custom appid fork of warp from [1] to be on PATH!
  # [1]: https://github.com/marcellus-trixus/warp/tree/customAppId
  warp-packer \
    --arch "$WARP_ARCH" \
    --input_dir "$BUNDLE_WORK_DIR" \
    --exec "bin/$(basename "${WARP_ENTRY_POINT}")" \
    --unique_id \
    --output "${OUTPUT_DIR}/$OUTPUT_BIN_NAME"
}

create-conda-env() {
  conda create --name "$CONDA_ENV_NAME"
  conda run --name "$CONDA_ENV_NAME" conda install --yes --use-local "$PKG_TO_INSTALL_NAME"
}

create-conda-env-from-env-yaml() {
  if conda env list | grep -q "$CONDA_ENV_NAME"; then
    echo "Updating existing conda env '$CONDA_ENV_NAME'"
    conda env update --name "$CONDA_ENV_NAME" --file "$SCRIPT_DIR/environment.yaml"
  else
    echo "Creating new conda env '$CONDA_ENV_NAME'"
    conda env create --name "$CONDA_ENV_NAME" --file "$SCRIPT_DIR/environment.yaml"
  fi

  # install nlpentities into the conda env
  cd "$SCRIPT_DIR"/..
  conda run -n "$CONDA_ENV_NAME" pip install .
}

pack-conda-env() {
  conda-pack --name "$CONDA_ENV_NAME" --force --output "$CONDAPACK_TARBALL"
  mkdir -p "$BUNDLE_WORK_DIR"
  echo "Creating bundle work dir: '$BUNDLE_WORK_DIR'"
  tar -C "$BUNDLE_WORK_DIR" -xf "$CONDAPACK_TARBALL"
  rm "$CONDAPACK_TARBALL"
}

cleanup() {
  rm -rf "$BUNDLE_WORK_DIR"
  conda env remove --name "$CONDA_ENV_NAME"
}

main() {
  create-conda-env
  pack-conda-env
  write-warp-entrypoint
  pack-binary
  cleanup
}

# echo SCRIPT_DIR="$SCRIPT_DIR"
# echo CMD_TO_RUN="${CMD_TO_RUN[@]}"
#  # @note that CMD_TO_RUN is not used as an array here, which in bash will set
#  # 👇 CONDA_ENV_NAME to the first item of CMD_TO_RUN
# echo CONDA_ENV_NAME="$CONDA_ENV_NAME"
# echo OUTPUT_BIN_NAME="$OUTPUT_BIN_NAME"
# echo CONDAPACK_TARBALL="$CONDAPACK_TARBALL"
# echo BUNDLE_WORK_DIR="$BUNDLE_WORK_DIR"
# echo WARP_ENTRY_POINT="$WARP_ENTRY_POINT"
# echo WARP_ARCH="$WARP_ARCH"

echo "PKG_TO_INSTALL_NAME: " $PKG_TO_INSTALL_NAME
echo "CMD_TO_RUN: " $CMD_TO_RUN

main
