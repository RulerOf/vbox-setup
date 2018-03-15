# vbox-setup

An "automatic" installer and updater for Virtualbox on Mac OS.

Tested on Sierra (10.12) and High Sierra (10.13).

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:0 orderedList:0 -->

## Table of Contents

- [Usage](#usage)
- [Example Output](#example-output)
- [Details](#details)
	- [What does it do?](#what-does-it-do)
	- [What else does it do?](#what-else-does-it-do)
- [Issues](#issues)
- [Why?](#why)
- [Contributing](#contributing)

<!-- /TOC -->

## Usage
```bash
curl -fsSL https://raw.githubusercontent.com/RulerOf/vbox-setup/master/vbox-setup.sh | sudo bash
```

Paste that at a Terminal prompt. Enter your password when prompted.

## Example Output

```shell
$ curl -fsSL https://raw.githubusercontent.com/RulerOf/vbox-setup/master/vbox-setup.sh | sudo bash
Password:
----
Installed VirtualBox version: 5.2.6
Latest VirtualBox version: 5.2.8
----
Downloading VirtualBox 5.2.8
----
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 90.9M  100 90.9M    0     0  11.7M      0  0:00:07  0:00:07 --:--:-- 13.3M
----
Downloading VirtualBox Extension Pack 5.2.8
----
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 18.5M  100 18.5M    0     0  4467k      0  0:00:04  0:00:04 --:--:-- 4470k
----
Mounting VirtualBox DMG
----
Installing VirtualBox
----
installer: Package name is Oracle VM VirtualBox
installer: Upgrading at base path /
installer: The upgrade was successful.
----
Unmounting VirtualBox installation image
----
Deleting VirtualBox-5.2.8-121009-OSX.dmg
----
Installing VirtualBox Extension Pack
----
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
----
Deleting Oracle_VM_VirtualBox_Extension_Pack-5.2.8-121009.vbox-extpack
----
VirtualBox installation complete!
```

## Details

Piping to `sudo bash`?

Yes. The point of this script is to make it easy to use.

### What does it do?

It installs or updates VirtualBox and the Extension Pack to the latest version for Mac OS with no user input.

### What else does it do?

- Checks the installed version of VirtualBox
- Checks the latest version
- Decides to install or update
- If any VMs are running
  - Saves the VMs
  - Closes VirtualBox
- Downloads Virtualbox
- Downloads the Extension Pack
- Verifies Signatures
- Mounts the DMG
- Installs the package
- Unmounts the DMG
- Installs the Extension Pack
- Deletes the installation files

The process is checked for errors at every step, and verbose errors are written to STDERR

## Issues

I tested as much of this as I possibly could without actually writing unit tests.

- If the extension pack installation fails for some reason, `VBoxManage` appears to return 0 anyway.

It also needs to be tested against a vanilla Mac OS instllation. I don't have a Mac without any extra command line utilities installed to test this script against, and I couldn't find a straight list of what's available on a vanilla Mac OS installation.

## Why?

Updating VirtualBox on Mac OS is *extremely* annoying because updates are pretty frequent, and it often takes several minutes to click through all of the steps in the process. The update flyout in the application doesn't even bother to supply a download link. And _then_ you have to relaunch the application and do it all over again for the extension pack. This script takes about 20 seconds to run, does everything automatically, and is fairly robust against minor changes to the update process.

For a product that is so heavily used, I was surprised when basic web searches turned up absolutely nothing in the way of a script to do this automatically. Even if I just suck at using Google and there's a great script out there, I did have fun writing this one.

## Contributing

Fork it and submit a pull request! This thing could use unit tests, and the selection of the `.pkg` file could stand to be made more robust.
