#!/bin/sh

CLIENT_IP=$1
CLIENT_FOLDER=$2
MOUNT_TARGET=/mnt/remote-bases/$CLIENT_FOLDER
ARCHIVE="/usr/bin/zip -r"
ARCHIVE_DATE=`date +"%Y-%m-%d_%H-%S"`
BACKUPNAME="bases-backup-$CLIENT_FOLDER-$ARCHIVE_DATE"
BACKUPTARGET="/srv/smb/backups"
NEED_MOUNT=YES

# test variables, comment it
# BACKUPTARGET="/Users/alex/temp/backups"
# MOUNT_TARGET="/Users/alex/workspace/bases/test-archive"
# NEED_MOUNT=NO
# CLIENT_FOLDER=CheckTest

# checks for found directories is exist
if [ -d $BACKUPTARGET ]; then
    echo "$BACKUPTARGET is exist, OK!"
else
    mkdir -p $BACKUPTARGET
fi
if [ -d $MOUNT_TARGET ]; then
    echo "$MOUNT_TARGET is exist, OK!"
else
    mkdir -p $MOUNT_TARGET
fi

# 1. mount source
if [ "$NEED_MOUNT" == "YES" ]; then
	echo "Mount resource //$1/bases to $MOUNT_TARGET..."
	/sbin/mount.cifs //$1/bases $MOUNT_TARGET -o guest || exit 1
fi

# 2 backup bases
pushd $MOUNT_TARGET
find . -type d -maxdepth 1 -mindepth 1 | while read dir; do
	bdir=`echo "${dir}" | sed 's| |_|g'`
	bdir=`echo "${bdir}" | sed 's|./||g'`
	$ARCHIVE "$BACKUPTARGET/$BACKUPNAME-${bdir}.zip" "${dir}" -x@/srv/backup-zip-exclude.lst || continue
done
popd

# 3, umount
if [ "$NEED_MOUNT" == "YES" ]; then
	umount $MOUNT_TARGET || exit 1
fi
