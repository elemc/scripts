#!/bin/sh

MNT_POINT=/mnt/desk
LOG_FILE=/var/log/alex-main-move-backups.log
DATE=`date +%Y-%m-%d-%H:%M`
BACKUPS_TARGET_DIR=${MNT_POINT}/temp/backups
BACKUPS_SOURCE_DIR=/srv/backups
FILES=`ls ${BACKUPS_SOURCE_DIR}`

function error() {
    echo "${DATE}: $1" >> $LOG_FILE
    exit 1
}

if [ "$FILES" != "" ]; then
    mount -t cifs -o user=alex //172.16.32.101/alex $MNT_POINT || error "Mount failed."
    if [ -d $BACKUPS_TARGET_DIR ]; then
	echo "${DATE}: Destination directory exist." >> $LOG_FILE
    else
	mkdir -p ${BACKUPS_TARGET_DIR} || error "Make directory ${BACKUPS_DIR} failed."
    fi
    for backup_file in $FILES; do
	cp -f ${BACKUPS_SOURCE_DIR}/$backup_file ${BACKUPS_TARGET_DIR}/
	rm -rf ${BACKUPS_SOURCE_DIR}/$backup_file
    done

    umount $MNT_POINT || error "Umount failed."
fi

    
    