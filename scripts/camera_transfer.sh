#!/bin/bash
#
# This script automates transferring of files from an SD card
# defined by memdir and into a local directory defined by destdir
#
# Destination directory will create subdirectories with the file timestamp
# and extension.
#
# Source file will be removed on copy.
# 
# Script was designed to run on Mac OSX to get around an issue where
# deleting files from an SD card doesn't actually delete the file 
# and instead places it into a trash directory until the trash
# is emptied. And to automate the workflow with retrieving 
# images from a camera SD card.
#
# Overview:
# 1. SD detected with the memdir variable
# 2. Destination directory defined with the destdir variable
# 3. SD card scanned for unique file extensions
# 4. Script loops through all files on SD card and
#    retrieves the file timestamp and extension
# 5. Moves file from SD card to destination subdirectory
#    with file timestamp and extension
#    ex. $destdir/2017_01_03_DNG/IMAGE.DNG
# 6. Uses mv command to make sure that the source file is
#    removed from the SD card and not placed in a trash
#    directory (when using finder).
#
# Reinier Jugao
# 1/3/17: Initial script
#

echo "Starting Script..."

IFS='
'

# get current date
dt=$(date '+%Y_%m_%d')
#echo $dt

# get current user
user=`whoami`

# hardcoded source directory for now, SD card must be named NO_NAME
# * we can monitor the Volumes directory and look for new directories as user inserts the card
memdir='/Volumes/NO_NAME/DCIM'

# set destination folder in user document folder
destdir="/Users/$user/Documents/camera/RicohGR"

# function to check if memory card is mounted
function _checkmemcard {
  if [ ! -d $memdir ]
  then
    echo "Memory card not detected"
    exit
  fi
}

# function to move file from source to destination
function _copyfile {
  src=$1
  dest=$2
  ext=$3

  if [ ! -f $src ]
  then
    return
  fi

  # get base filename of file
  filename=$(basename "$src")

  # get extension of file if it isn't defined
  if [ ! $ext ]
  then
    ext=`echo $filename | sed 's|.*\.||'`
  fi

  # get timestamp of file
  filestamp=`/usr/bin/stat -f "%Sm" -t "%Y_%m_%d" $src`

  # check if folder already exists in destination directory
  dirname=$dest/$filestamp\_$ext

  if [ ! -d $dirname ]
  then
    echo "Creating backup directory $dirname"
    /bin/mkdir -p $dirname
  fi

  # move file into destination directory
  echo Copying $src to $dirname/$filename
  /bin/mv -f $src $dirname/$filename 
}

# check memory card
_checkmemcard

pushd $memdir > /dev/null
echo Checking memory card directory $memdir for file types

for x in `find . -type f -name '*.*' | sed 's|.*\.||' | sort -u`
do
  files=$(find . -name "*.$x")
  for f in $files
  do
    _copyfile $memdir/$f $destdir
  done  
done
popd > /dev/null

echo "Done."
echo ""

