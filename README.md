# vbox-update

An "automatic" updater for Virtualbox on Mac OS.

Tested on Sierra (10.12) and High Sierra (10.13).

## Usage
```bash
curl -fsSL https://raw.githubusercontent.com/RulerOf/vbox-update/master/vbox-install.sh | sudo bash
```

Paste that at a Terminal prompt. Enter your password when prompted.

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
