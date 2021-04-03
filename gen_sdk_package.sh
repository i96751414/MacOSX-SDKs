#!/usr/bin/env bash
#
# Package the macOS SDKs into a tar file.
# This script requires the  Xcode Command Line Tools to be installed in order to work.
#

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
  "zip") "${SDK_COMPRESSOR}" -q -5 -r - "$@" >"${output}" ;;
  *) "${TAR}" cf - "$@" | "${SDK_COMPRESSOR}" -5 - >"${output}" ;;
  esac
}

function rreadlink() {
  if [ ! -h "$1" ]; then
    echo "$1"
  else
    local link
    link="$(expr "$(command ls -ld -- "$1")" : '.*-> \(.*\)$')"
    cd "$(dirname "$1")"
    rreadlink "${link}" | sed "s|^\([^/].*\)\$|$(dirname "$1")/\1|"
  fi
}

WORK_DIR=$(pwd)
SDK_DIR="/Library/Developer/CommandLineTools/SDKs"
LIBCXX_DIR="/Library/Developer/CommandLineTools/usr/include/c++/v1"
MAN_DIR="/Library/Developer/CommandLineTools/usr/share/man"

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
  echo "Packaging ${SDK_NAME} SDK (this may take several minutes) ..."

  if [[ "${SDK}" == *.pkg ]]; then
    cp "${SDK}" "${WORK_DIR}"
    continue
  fi

  TMP=$(mktemp -d /tmp/XXXXXXXXXXX)
  cp -r "$(rreadlink "${SDK}")" "${TMP}/${SDK}" &>/dev/null || true

  if [ -d "${LIBCXX_DIR}" ]; then
    echo "Adding ${LIBCXX_DIR} to ${SDK_NAME}"
    mkdir -p "${TMP}/${SDK}/usr/include/c++"
    cp -rf ${LIBCXX_DIR} "${TMP}/${SDK}/usr/include/c++"
  fi

  if [ -d "${MAN_DIR}" ]; then
    echo "Adding ${MAN_DIR} to ${SDK_NAME}"
    mkdir -p "${TMP}/${SDK}/usr/share/man"
    cp -rf "${MAN_DIR}/"* "${TMP}/${SDK}/usr/share/man"
  fi

  pushd "${TMP}" &>/dev/null
  compress "${WORK_DIR}/${SDK}${SDK_EXT}" *
  popd &>/dev/null

  rm -rf "${TMP}"
done

popd &>/dev/null

echo
ls MacOSX*
