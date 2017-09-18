## My Implementation of Automatic Updates for Orion

A summary of one of the projects I completed during my co-op term at IBM Ottawa in Summer 2016.

This is intended as a reference for the update, build, and release mechanisms for the [Orion Electron app](https://github.com/eclipse/orion.client).

**Table of Contents**

[Updates](#updates)  
[Builds](#builds)  
[Releases](#releases)  

<a name="updates"/>

Updates
------

### Nuts
[Nuts](https://github.com/GitbookIO/nuts) is the application we use to serve our GitHub [releases](https://github.ibm.com/Silenio-Quarti/Orion-Update/releases) for Orion. We deploy it as a [node module](https://nuts.gitbook.com/module.html) and run it on http://grants-imac106.ottawa.ibm.com. Nuts has a built-in [webhook](https://nuts.gitbook.com/github.html) that refreshes the releases on our server every time we upload, delete, or modify a release.

### Windows

![alt text](https://github.com/mzmousa/Orion-Update/blob/master/img/windows_updates.png?raw=true "Windows Update Lifecycle")

### OSX

![alt text](https://github.com/mzmousa/Orion-Update/blob/master/img/osx_updates.png?raw=true "OSX Update Lifecycle")

### Linux

![alt text](https://github.com/mzmousa/Orion-Update/blob/master/img/linux_updates.png?raw=true "Linux Update Lifecycle")


<a name="builds"/> 

Build
------
### Electron-builder

We use [electron-builder](https://github.com/electron-userland/electron-builder) to generate our installer and update files. Most of the configuration necessary requires modification of our development `package.json` and can be found on the [wiki](https://github.com/electron-userland/electron-builder/wiki).

##### An overview of our build process: 

1. Start a Jenkins job at http://grants-imac106.ottawa.ibm.com:8080/job/orion-electron-github.ibm.com  
2. Download the latest orionode build from download.eclipse.org/orion/orionode/orionode_${BUILD_ID}.tar.gz, where `BUILD_ID` is a Jenkins environment variable  
3. Update the Build ID in `build_id.txt` as a commit in the [repo](https://github.ibm.com/Silenio-Quarti/Orion-Update) that we serve releases from - the date and time of this commit will be the date and time of the next release.  
4. Generate and sign binary files using [electron-builder](https://github.com/electron-userland/electron-builder). `Electron-builder` options can be found in the app's `package.json` and follow the [wiki](https://github.com/electron-userland/electron-builder/wiki).  
5. Replace nodegit binaries with our own compiled versions for the respective version of Electron that our app is running  
6. Modify configuration files. In `orion.conf`, `orion.autoUpdater.url` is the root update URL
7. Upload release files to the Github repo where we serve our [releases](https://github.ibm.com/Silenio-Quarti/Orion-Update/releases) using [github-release](https://github.com/aktau/github-release)  

This is the structure of the file directory once a build is completed:

```
├───linux
│   └───orionode
│       └───dist
│           └───linux
│                   Orion-x.y.z.deb
│                   Orion-x.y.z.rpm
│                   Orion-x.y.z.tar.gz
├───osx
│   └───orionode
│       └───dist
│           └───osx
│                   Orion-x.y.z-mac.zip
│                   Orion-x.y.z.dmg
└───win
    └───orionode
        └───dist
            ├───win
            │       Orion-x.y.(z-1)-full.nupkg
            │       Orion-x.y.z-delta.nupkg
            │       Orion-x.y.z-full.nupkg
            │       Orion-x.y.z-setup.exe
            │       RELEASES
            └───win-unpacked
```

Notes:
* Windows build step is about twice as long as the other two platforms due to the creation of delta updates files.
* Build step will fail on OSX if `electron-prebuilt` is found in `node_modules`.
* We build all assets on OSX since code signing an OSX app can only be done on OSX, but Windows and Linux apps can be signed on any platform.
* Building the app without signing on OSX is possible, but it will not be able to update
* The date and time of a release is **NOT** when it got uploaded, but rather the date and time of the most recent commit before it was uploaded.

<a name="releases"/>

Releases
------

### Filetypes and their purpose

**Windows**
- `Orion-x.y.z-setup.exe` - Windows installer.
- `Orion-x.y.z-full.nupkg`- Full archive file downloaded during updates.
- `Orion-x.y.z-delta.nupkg` OPTIONAL: Patch archive file, 5-10% the size of full archive file and has download priority. If this file causes an update failure then the autoUpdater falls back to the full archive file.
- `RELEASES` - Keeps track of the app version and what archive files were used to update; is downloaded during updates.

**OSX**
- `Orion-x.y.z.dmg` - OSX installer.
- `Orion-x.y.z-mac.zip` - Archive file downloaded during updates.

**Linux**
- `Orion-x.y.z.deb` - Downloaded during updates (Debian distributions)
- `Orion-x.y.z.rpm` - Downloaded during updates (Red Hat distributions)
- `Orion-x.y.z.tar.gz` - Archive file

### Release Channels
- Releases are uploaded at the end of the build process using [github-release](http://github.com/aktau/github-release)
- We currently support "stable" and "alpha" release channels. The channel is determined by the suffix of the release tag name, e.g., `v0.0.1-alpha` will be on the `alpha` channel and `v0.0.1` will be on the `stable` channel.
- User updates default to the latest `stable` build or the last update channel they had selected (saved in `prefs`).
- Every build is initially uploaded on the `alpha` release channel. Once it's decided that a build is fit to be `stable`, the tag can be renamed and the old tag can be deleted. This will refresh the Github webhook, causing the Nuts server to update its list of releases. Example: we upload a release with tag named `v0.0.1-alpha` and decide to promote it to the `stable` release channel. We rename the tag to `v0.0.1` - this new tag will be considered a new release with all the files as before, but `v0.0.1-alpha` will be an empty tag which we can now delete.
