#!/bin/bash

# upload a file under the specified github release
# $1: file name/path
upload () {
	echo $1
	github-release upload --user "${user}" --repo "${repo}" --tag v"${pkg_version}" --name $1 --file $1
}

# create a new release
# $1: String for release description
new_release() {
	github-release release --user "${user}" --repo "${repo}" --tag v"${pkg_version}" --name v"${pkg_version}" --description "${description}"
}

# pushd linux/orionode/dist/linux

new_release

# # upload linux artifacts to new release
# upload "${name}-${pkg_version}.deb"
# upload "${name}-${pkg_version}.rpm"
# upload "${name}-${pkg_version}.tar.gz"

# popd # pop linux/orionode/dist/linux

# pushd osx/orionode/dist/osx

# # upload osx artifacts to new release
# upload "${name}-${pkg_version}.dmg"
# upload "${name}-${pkg_version}-mac.zip"

# popd # pop osx/orionode/dist/osx
pushd win/orionode/dist/win

# upload windows artifacts to new release
upload "RELEASES"
upload "${name}-${pkg_version}-setup.exe"
upload "${name}-${pkg_version}-full.nupkg"
if [ -e "${name}-${pkg_version}-delta.nupkg" ]; then
	upload "${name}-${pkg_version}-delta.nupkg"
fi
wait

popd # pop win/orionode/dist/win
