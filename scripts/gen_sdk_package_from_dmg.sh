#!/bin/bash
set -e

scripts_path=$(dirname "$(readlink -f "$0")")
package=$1

if [ -z "${package}" ] || [ ! -f "${package}" ]; then
  echo "usage: $(basename "$0") <package>"
  exit 1
fi

tmp_path=$(mktemp -d /tmp/XXXXXXXXXXX)
OUTPUT="${tmp_path}" \
  "${scripts_path}/unpack_dmg.sh" "${package}"
COMMAND_LINE_TOOLS="${tmp_path}/payload/Library/Developer/CommandLineTools" \
  "${scripts_path}/gen_sdk_package.sh"
rm -rf "${tmp_path}"
