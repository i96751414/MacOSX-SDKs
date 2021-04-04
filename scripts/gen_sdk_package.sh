#!/bin/bash
set -e

export LC_ALL=C

if command -v gnutar &>/dev/null; then
  TAR=gnutar
else
  TAR=tar
fi

if [ -z "${SDK_COMPRESSOR}" ]; then
  if command -v xz &>/dev/null; then
    SDK_COMPRESSOR=xz
    SDK_EXT="tar.xz"
  else
    SDK_COMPRESSOR=bzip2
    SDK_EXT="tar.bz2"
  fi
fi

case "${SDK_COMPRESSOR}" in
"gz")
  SDK_COMPRESSOR=gzip
  SDK_EXT=".tar.gz"
  ;;
"bzip2") SDK_EXT=".tar.bz2" ;;
"xz") SDK_EXT=".tar.xz" ;;
"zip") SDK_EXT=".zip" ;;
*)
  echo "error: unknown compressor \"${SDK_COMPRESSOR}\"" >&2
  exit 1
  ;;
esac

function compress() {
  local output
  output="$1"
  shift
  case "${SDK_COMPRESSOR}" in
  "zip") "${SDK_COMPRESSOR}" -q -9 -r - "$@" >"${output}" ;;
  *) "${TAR}" cf - "$@" | "${SDK_COMPRESSOR}" -9 - >"${output}" ;;
  esac
}

function rreadlink() {
  local target_file
  target_file=$1

  cd "$(dirname "${target_file}")"
  target_file=$(basename "${target_file}")

  while [ -L "${target_file}" ]; do
    target_file=$(readlink "${target_file}")
    cd "$(dirname "${target_file}")"
    target_file=$(basename "${target_file}")
  done

  echo "$(pwd -P)/${target_file}"
}

WORK_DIR=$(pwd)

if [ -z "${COMMAND_LINE_TOOLS}" ]; then
  COMMAND_LINE_TOOLS="/Library/Developer/CommandLineTools"
fi

SDK_DIR="${COMMAND_LINE_TOOLS}/SDKs"
LIBCXX_DIR="${COMMAND_LINE_TOOLS}/usr/include/c++/v1"
MAN_DIR="${COMMAND_LINE_TOOLS}/usr/share/man"

if [ ! -d "${SDK_DIR}" ]; then
  echo "SDKs directory does not exist: ${SDK_DIR}"
  exit 1
fi

pushd "${SDK_DIR}" &>/dev/null

SDKS=()
while IFS= read -r -d $'\0'; do
  SDKS+=("${REPLY}")
done < <(find -- * -name "MacOSX1*" -a ! -name "*Patch*" -print0)

if [ ${#SDKS[@]} -eq 0 ]; then
  echo "No SDK found" 1>&2
  exit 1
fi

for SDK in "${SDKS[@]}"; do
  SDK_NAME=$(sed -E "s/(.sdk|.pkg)//g" <<<"${SDK}")
  echo "Packaging ${SDK_NAME} SDK (this may take several minutes)"

  if [[ "${SDK}" == *.pkg ]]; then
    cp "${SDK}" "${WORK_DIR}"
    continue
  fi

  TMP=$(mktemp -d /tmp/XXXXXXXXXXX)
  cp -r "$(rreadlink "${SDK}")" "${TMP}/${SDK}" &>/dev/null || true

  if [ -d "${LIBCXX_DIR}" ]; then
    echo "Adding c++ directory to ${SDK_NAME}"
    mkdir -p "${TMP}/${SDK}/usr/include/c++"
    cp -rf ${LIBCXX_DIR} "${TMP}/${SDK}/usr/include/c++"
  fi

  if [ -d "${MAN_DIR}" ]; then
    echo "Adding man directory to ${SDK_NAME}"
    mkdir -p "${TMP}/${SDK}/usr/share/man"
    cp -rf "${MAN_DIR}/"* "${TMP}/${SDK}/usr/share/man"
  fi

  (cd "${TMP}" && compress "${WORK_DIR}/${SDK}${SDK_EXT}" *)

  rm -rf "${TMP}"
done

popd &>/dev/null

echo
ls MacOSX*
