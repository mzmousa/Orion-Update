#!/bin/bash

# remove multi-user dependencies from package.json
remove_multi_dependencies() {
	echo "Removing multi-user dependencies from package.json"
	sed -i.bak -E '/(passport*|mongoose|mongodb|nodemailer|connect-mongo)/d' package.json
}

# node module clean up
cleanup_nodemodules() {
	echo "Cleaning up node modules" 
	rm -rf orionode/node_modules/passport*
	rm -rf orionode/node_modules/mongoose
	rm -rf orionode/node_modules/mongodb
	rm -rf orionode/node_modules/nodemailer
	rm -rf orionode/node_modules/connect-mongo
	rm orionode/node_modules/nodegit/build/Release/nodegit.node
}

# upload a file under the specified github release
# $1: file name/path
upload () {
	echo $1
	github-release upload --user "${user}" --repo "${repo}" --tag v"${pkg_version}" --name $1 --file $1
}

if [ -z "$UPDATE_SERVER" ]; then
    UPDATE_SERVER="http://orion-update.mybluemix.net/"
fi
update_url=$(echo ${UPDATE_SERVER}"update" | sed -e 's/[\/&.-]/\\&/g') # for autoUpdater
download_url=$(echo ${UPDATE_SERVER}"download" | sed -e 's/[\/&.-]/\\&/g') # for remoteReleases

# update orion.conf and package.json
update_config_files() {
	electron_version=$(jsawk -i orionode/package.json 'return this.build.electronVersion')
	nodegit_version=$(jsawk -i orionode/package.json 'return this.dependencies.nodegit')
	pkg_version=$(jsawk -i orionode/package.json 'return this.version')
	name=$(jsawk -i orionode/package.json 'return this.name')
	old_version=${pkg_version}
	pkg_version=`echo ${pkg_version} | sed 's/.0$/.'"${BUILD_NUMBER}"'/'`
	sed -i .bak 's/\"version\": \"'"${old_version}"'\"/\"version\"\:\ \"'"${pkg_version}"'\"/' orionode/package.json
	sed -i .bak 's/orion\.autoUpdater\.url\=/orion\.autoUpdater\.url\='"${update_url}"'/' orionode/orion.conf
}

echo "----- OSX build -----"
mkdir osx
pushd osx
echo "Extracting build"
tar -xzf ../orionode_${BUILD}.tar.gz

cleanup_nodemodules
update_config_files

# copy over nodegit binary to workaround in memory ssh limitation
cp ~/downloads/orion/orionode/nodegit/v${nodegit_version}/electron/v${electron_version}/mac/nodegit.node ./orionode/node_modules/nodegit/build/Release

pushd orionode

# generates osx artifacts: dmg, -mac.zip
remove_multi_dependencies
npm run dist:osx
echo "osx artifacts generated"
