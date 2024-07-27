#!/bin/bash
set -e

scripts_path="$(dirname "$(readlink -f "$0")")"
package="$1"

function usage() {
  echo "usage: $(basename "$0") <package>"
  exit 1
}

if [ -z "${package}" ]; then
  package="$(find "$(pwd)" -name "*.dmg" -type f -print -quit)"
  if [ -z "${package}" ]; then
    echo "Unable to find .dmg package"
    usage
  fi
fi

[ ! -f "${package}" ] && usage

tmp_path="$(mktemp -d /tmp/XXXXXXXXXXX)"
trap 'rm -rf "${tmp_path}"' EXIT
OUTPUT="${tmp_path}" \
  "${scripts_path}/unpack_dmg.sh" "${package}"
COMMAND_LINE_TOOLS="${tmp_path}/payload/Library/Developer/CommandLineTools" \
  "${scripts_path}/gen_sdk_package.sh"
