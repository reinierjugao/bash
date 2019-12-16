#!/bin/bash

####
#
# This script should exist on an external memory card.
# Manual execution is required upon mounting of memory card
# to transfer the contents.
#
# Improvements can be made with a script that will monitor
# mounting of new volumes and automatically executing
# specific scripts if they exist. Similar to Autorun with
# CDs on Windows.
#
# 5/24/2018: Initial script
#
####


# set this to 1 do a dry run
TESTMODE=1

# set this to 1 if source file should only be copied,
# set to 0 if file to be moved (source file deleted)
KEEPSRC=1

# list of extensions to ingore
IGNOREEXT=("sh" "txt")

# list of supported extensions 
ALLOWEXT=("jpg" "jpeg" "JPG" "JPEG" "dng" "DNG" "cr2" "CR2" "pef" "PEF" "raf" "RAF" "avi" "AVI" "mpeg" "MPEG")

# list of extensions to put in the sync directory
SYNCEXT=("jpg" "jpeg" "JPG" "JPEG")

# get current user
USER=`whoami`

# check if we're running in Linux or OSX
OSX=`uname | grep -q "Darwin"`

# determine destination path
DESTDIR="/Users/$USER/Documents/camera/g7xii"

# determine synced directory for JPG files
SYNCDIR="/Users/$USER/Documents/photos_sync"

# determine script path
SELFDIR="$(cd "$(dirname "$0")" && pwd)"

# read config.ini file for destination path
CONFPATH="$SELFDIR/config.ini"

if [ -e "$CONFPATH" ];
then
    DESTDIR=$(awk -F "=" '/dest_path/ {print $2}' $CONFPATH)
    echo $DESTDIR
fi


# function to check if extension is in a given list
# returns 0 if extension found
# returns 1 if extension not found
_check_extension() {
    local NEEDLE="$1"; shift
    local IN=1
    for HAYSTACK; do
        if [[ $HAYSTACK == $NEEDLE ]]; then
            IN=0
            break
        fi
    done
    return $IN
}

# function to move file from source to destination
_copyfile() {
    SRC=$1
    DEST=$2
    EXT=$3

    # get base filename of file
    FILENAME=$(basename "$SRC")

    # get timestamp of file
    if [ $OSX ];
    then
        FILETIMESTAMP=`/usr/bin/stat -f "%Sm" -t "%Y_%m_%d" $SRC`
    else
        FILETIMESTAMP=`/bin/date -r $SRC +%Y_%m_%d`
    fi
#    echo "  Detected timestamp=$FILETIMESTAMP"

    DESTPATH=$DEST/$FILETIMESTAMP/$EXT

    if [ ! -d $DESTPATH ];
    then
        echo "Dest path does not exist, need to create"
        /bin/mkdir -p $DESTPATH
    fi

    DESTPATH=$DESTPATH/$FILENAME

    echo "Copying from $SRC to $DESTPATH"
    if [ $KEEPSRC -eq 1 ];
    then
        # keep original file, copy only
        if [ $TESTMODE -eq 1 ];
        then
            echo "cp -p -u $SRC $DESTPATH"
        else
            cp -p -u $SRC $DESTPATH
        fi
    else
        # do not keep original file, delete source
        if [ $TESTMODE -eq 1 ];
        then
            echo "mv $SRC $DESTPATH"
        else
            mv $SRC $DESTPATH
        fi
    fi
}

echo "Starting script..."
if [ $TESTMODE -eq 1 ];
then
    echo "Running dry mode. Will not copy or move files."
fi

if [ $OSX ];
then
    echo "Detected OSX..."
fi

# get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Processing from directory $DIR"
pushd $DIR > /dev/null

echo ""

for x in `find . -type f -name '*.*' | sed 's|.*\.||' | sort -u`
do
    # check if we need to ignore this extension
    _check_extension "$x" "${IGNOREEXT[@]}"
    if [ $? -eq 0 ];
    then
#        echo "Ignoring file extension \"$x\""
        continue
    fi

    # check extension whitelist
    _check_extension "$x" "${ALLOWEXT[@]}"
    if [ $? -eq 1 ];
    then
        echo "==========================="
        echo "WARNING: Unhandled file extension \"$x\""
        continue
    fi

    echo "==========================="
    echo "Processing extension \"$x\""

    FILES=$(find . -name "*.$x" | sed 's|^./||')
    for f in $FILES
    do
#        echo "  Found file $f"

        # check extensions to sync
        if [ -d $SYNCDIR ];
        then
            _check_extension "$x" "${SYNCEXT[@]}"
            if [ $? -ne 1 ];
            then
                FILENAME=$(basename "$SRC")
                echo "Copying from $DIR/$f to $SYNCDIR/$FILENAME"
                if [ $TESTMODE -eq 1 ];
                then
                    cp -p -u $DIR/$f $SYNCDIR/$FILENAME
                else
                    echo "cp -p -u $DIR/$f $SYNCDIR/$FILENAME"
                fi
            fi
        fi
        _copyfile $DIR/$f $DESTDIR $x
    done
done

popd > /dev/null

echo ""
echo "Done."
echo ""

