#!/bin/bash
set -eo pipefail

# Add realpath for mac
command -v realpath &>/dev/null || realpath() {
  [[ "$1" == /* ]] && echo "$1" || echo "$(pwd -P)/${1#./}"
}

package="$1"
output="$(realpath "${OUTPUT:-out}")"

if [ -z "${package}" ] || [ ! -f "${package}" ]; then
  echo "usage: $(basename "$0") <package>"
  exit 1
fi

package_dir="${output}/${package%.dmg}"
echo "- Unpacking ${package}"
7z x "${package}" -o"${package_dir}" >/dev/null

pkg_file="$(find "${package_dir}" -name "*.pkg" -print -quit)"
if [ -z "${pkg_file}" ]; then
  echo "- Unable to find .pkg file"
  exit 1
fi

echo "- Unpacking '$(basename "${pkg_file}")'"
pkg_data="${output}/pkg_data"
mkdir -p "${pkg_data}"
xar -xf "${pkg_file}" -C "${pkg_data}"

echo "- Unpacking '$(basename "${pkg_file}")' payload data"
payload_data="${output}/payload"
mkdir -p "${payload_data}"
for pkg in "${pkg_data}"/*.pkg; do
  echo "- Unpacking '$(basename "${pkg}")' payload"
  (cd "${payload_data}" && pbzx -n "${pkg}/Payload" | cpio -i &>/dev/null)
done
