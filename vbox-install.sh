#!/usr/bin/env bash
# shellcheck disable=SC2046

# We're catching errors manually here
set +e

# Start off the output formatting for this whole thing
echo "----"

if command -v VBoxManage >/dev/null 2>&1 ; then
  ## VirtualBox is installed ##

  # Get vbox version string
  vboxVersionLocalRaw=$(VBoxManage --version)
  # Extract SemVer format from front of string
  vboxVersionLocal=$(echo $vboxVersionLocalRaw | grep -o '\d*\.\d*\.\d*')
  # Return if not SemVer formatted string
  if [ -z "$vboxVersionLocal" ]; then
    >&2 echo "Error — Unable to parse VirtualBox version string as a SemVer format: $vboxVersionLocalRaw"
    exit 1
  fi
  # Print installed version info
  echo "Installed VirtualBox version: $vboxVersionLocal"
else
  ## VirtualBox is not installed ##

  # Set local version to zero to force installatin
  vboxVersionLocal=0.0.0
fi

# Get latest version from Oracle site
vboxVersionLatest=$(curl -s http://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
# Check for errors
curlRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Problem while checking for latest version of VirtualBox, cURL error: $curlRetval"
  exit 1
fi

# Print latest version info

echo "Latest VirtualBox version: $vboxVersionLatest"
echo "----"

# If an upgrade isn't necessary, we should just quit
if [ "$vboxVersionLocal" = "$vboxVersionLatest" ]; then
  echo "Your local VirtualBox installation is up to date."
  exit 0
fi

# Check for running VMs if vbox is installed
if [ ! $vboxVersionLocal = "0.0.0" ]; then
  # Find out which users are running the VirtualBoxVM binary. We're doing this because VBoxManage doesn't see other users VMs when run as root
  usersWithRunningVms=$(ps aux | grep VirtualBoxVM | grep -v grep | ps aux | grep VirtualBoxVM | grep -v grep | cut -d" " -f1)

  for user in $usersWithRunningVms; do
    runningVmList=$(su $user VBoxManage list runningvms)
    vboxManageRetval=$?
    if [ $vboxManageRetval -ne 0 ]; then
      >&2 echo "Error — Problem retrieving list of running VMs: $vboxManageRetval"
      exit 1
    fi
    runningVmGuids=$(echo $runningVmList | egrep -o '(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})')
    runningVmCount=$(echo $runningVmGuids | wc -w)
    if [ "$runningVmCount" -ne 0 ]; then
      echo "Saving state of running VMs..."
      echo "----"
      for guid in $runningVmGuids; do
        su $user VBoxManage controlvm $guid savestate
      done
      # Wait just a few seconds
      sleep 5
      echo "----"
    fi
    # Check if Virtualbox.app is running
    ps aux | grep -i virtualbox | grep -v grep > /dev/null
    if [ "$?" -eq 0 ]; then
      echo "Closing VirtualBox.app"
      # Close virtualbox.app
      osascript -e 'quit app "VirtualBox"' > /dev/null 2>&1
      # Wait just a few seconds
      sleep 5
      echo "----"
    fi
  done
fi

# Get the list of SHA sums for these downloads
vboxHashList=$(curl -s "http://download.virtualbox.org/virtualbox/${vboxVersionLatest}/SHA256SUMS")
# Check for errors
curlRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Problem retrieving list of SHA256 fingerprints, cURL error: $curlRetval"
  exit 1
fi

## Construct download URL for the DMG file from Hash list
vboxImageDetails=$(printf "$vboxHashList" | grep '\.dmg$' | head -1)
vboxImageHash=$(echo $vboxImageDetails | cut -d'*' -f1)
vboxImageName=$(echo $vboxImageDetails | cut -d'*' -f2)
vboxImageUrl="http://download.virtualbox.org/virtualbox/${vboxVersionLatest}/${vboxImageName}"

# Sanity check all of those variables and the URL
if [ -z "$vboxImageDetails" ] || [ -z "$vboxImageHash" ] || [ -z "$vboxImageName" ] || [ "$vboxImageUrl" = 'http://download.virtualbox.org/virtualbox//' ] ; then
  >&2 echo "Error — Problem constructing download URL: $vboxImageUrl"
  exit 1
fi

## Download VirtualBox DMG
echo "Downloading VirtualBox $vboxVersionLatest"
echo "----"
curl -o "/tmp/$vboxImageName" "$vboxImageUrl"
echo "----"

# Check for errors
curlRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Problem downloading VirtualBox DMG file, cURL error: $curlRetval"
  exit 1
fi

# Verify file checksum
vboxDownloadHash=$(shasum -a 256 "/tmp/$vboxImageName" | grep "$vboxImageHash")
shasumRetval=$?
if [ $shasumRetval -ne 0 ]; then
  >&2 echo "Error — Downloaded file hash does not match."
  >&2 echo "Expected: $vboxImageHash"
  >&2 echo "Received: $vboxDownloadHash"
  exit 1
fi

## Construct download URL for the Extension Pack
extPackDetails=$(printf "$vboxHashList" | grep 'extpack$' | head -1)
extPackHash=$(echo $extPackDetails | cut -d'*' -f1)
extPackName=$(echo $extPackDetails | cut -d'*' -f2)
extPackUrl="http://download.virtualbox.org/virtualbox/${vboxVersionLatest}/${extPackName}"

# Sanity check all of those variables and the URL
if [ -z "$extPackDetails" ] || [ -z "$extPackHash" ] || [ -z "$extPackName" ] || [ "$extPackUrl" = 'http://download.virtualbox.org/virtualbox//' ] ; then
  >&2 echo "Error — Problem constructing download URL: $vboxImageUrl"
  exit 1
fi

echo "Downloading VirtualBox Extension Pack $vboxVersionLatest"
echo "----"
curl -o "/tmp/$extPackName" "$extPackUrl"
echo "----"

# Check for errors
curlRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Problem downloading Extension Pack file, cURL error: $curlRetval"
  exit 1
fi

# Unmount any existing VirtualBox disk image
if [ -e "/Volumes/VirtualBox" ]; then
  echo "Unmounting existing VirtualBox installation image"
  echo "----"
  hdiutil detach "/Volumes/VirtualBox" >/dev/null 2>&1
  if [ -e "/Volumes/VirtualBox" ]; then
    >&2 echo "Error – Couldn't unmount /Volumes/VirtualBox"
    exit 1
  fi
fi

echo "Mounting VirtualBox DMG"
echo "----"
mountOutput=$(hdiutil attach "/tmp/$vboxImageName")
# Check for errors
mountRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Problem mounting DMG: $mountRetval"
  exit 1
fi

# Get the directory that the DMG mounted to based on hdiutil output
mountDir=$(echo $mountOutput | cut -d" " -f$(echo $mountOutput | wc -w))

# Get the number of .pkg files in the disk image
packageCount=$(ls $mountDir/*.pkg | wc -w)

# Check that there's only one package and quit if we find more
if [ "$packageCount" -ne 1 ]; then
  >&2 echo "Error — More than one package found in $mountDir"
  exit 1
fi

echo "Installing VirtualBox"
echo "----"

# Install VirtualBox
sudo installer -pkg $mountDir/*.pkg -target LocalSystem
# Check for errors
installerRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Installation error: $installerRetval"
  exit 1
fi
echo "----"


# Unmount disk image
echo "Unmounting VirtualBox installation image"
echo "----"
hdiutil detach "/Volumes/VirtualBox" >/dev/null 2>&1
if [ -e "/Volumes/VirtualBox" ]; then
  >&2 echo "Error – Could not unmount /Volumes/VirtualBox. Continuing anyway."
else
  echo "Deleting $vboxImageName"
  echo "----"
  rm -f "/tmp/$vboxImageName"
fi

echo "Installing VirtualBox Extension Pack"
echo "----"
yes | sudo VBoxManage extpack install --replace "/tmp/$extPackName" > /dev/null
extPackRetval=$?
if [ $curlRetval -ne 0 ]; then
  >&2 echo "Error — Installation error: $extPackRetval"
  exit 1
fi
echo "----"

echo "Deleting $extPackName"
echo "----"
rm -f $extPackName

echo "VirtualBox installation complete!"

exit 0
