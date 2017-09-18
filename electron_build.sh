#!/bin/bash

## WARNING do not run with sudo, it will break wine and cause many permission issues
# Example usage
# ./electron_build.sh --build <build timestamp> --certificate <certificate name> --description <Github release description>--token <Github API token> --user <Github user> --repo <repo>
# ./electron_build.sh -b <build timestamp> -c <certificate name> -d <Github release description> -t <Github API token> -u <Github user> -r <repo>

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

# create a new release
# $1: String for release description
new_release() {
	github-release release --user "${user}" --repo "${repo}" --tag v"${pkg_version}" --name v"${pkg_version}" --description "${description}"
}

# parse command line arguments
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -t|--token)
    GITHUB_TOKEN="$2"
    shift # past argument
    ;;
    -d|--description)
    description="$2"
    shift # past argument
    ;;
    -u|--user)
    user="$2"
    shift # past argument
    ;;
    -r|--repo)
	repo="$2"
	shift # past argument
	;;
	-c|--certificate)
	CSC_NAME="$2"
	shift # past argument
	;;
	-b|--build)
	BUILD="$2"
	shift
	;;
    *)
    # fall through any other options
    ;;
esac
shift # past argument or value
done

# environment variables
export GITHUB_TOKEN # required for uploading Github releases
export CSC_NAME # required for OSX autoUpdater-functional builds
export BUILD

echo "Setting up build directories"

rm -rf buildTemp
mkdir buildTemp

pushd buildTemp
echo "Copying over orionode_${BUILD} build"
cp ${BUILD_ZIP} .

pkg_version="0.1."${BUILD_NUMBER}
name="Orion"

# Github upload parameters
echo $user
echo $repo
echo $description
echo $name
echo $pkg_version

export user
export repo
export description
export name
export pkg_version

export latest_build=$(curl -s "http://orion-update.mybluemix.net/api/version/latest" | jsawk 'return this.tag')

echo "latest build = ${latest_build}"
echo $latest_build

sh ../electron_build_win.sh
# sh ../electron_build_osx.sh & sh ../electron_build_win.sh & sh ../electron_build_linux.sh
wait
sh ../electron_build_upload.sh
