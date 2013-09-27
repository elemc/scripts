#!/bin/sh

# Debug
#LOGS_DIR=/home/alex/temp/pgsql
#MOUNT_POINT=/home/alex/old-pgsql

# Release
LOGS_DIR=/var/lib/pgsql/data/pg_log
MOUNT_POINT=/mnt/disk/
MOUNT_CMD="/sbin/mount.cifs //192.168.10.251/1C-Base2 ${MOUNT_POINT} -o username=semen,password=02239-45"

DATE_VALUE=`date +%Y-%m-%d`
CURRENT_LOGS=`find $LOGS_DIR -name *${DATE_VALUE}*.log`
ALL_LOGS=`find $LOGS_DIR -name *.log`
DEST_DIR=${MOUNT_POINT}/SQL/backup-logs/

# Directory for mount
if [ -d ${MOUNT_POINT} ]; then
    mkdir -p ${MOUNT_POINT} || exit 1
fi

# Check mount point
MOUNT_PRESENT=`mount | grep ${MOUNT_POINT} | grep -v grep`
if [ "1" == "${MOUNT_PRESENT}1" ]; then
    umount ${MOUNT_POINT} || exit 1
fi

# Mount
${MOUNT_CMD} || exit 1

for logfile in ${ALL_LOGS}; do
    REMOVE_IT="YES"
    for clogfile in ${CURRENT_LOGS}; do
        if [ "${logfile}" == "${clogfile}" ]; then
            REMOVE_IT="NO"
        fi
    done

    #echo "${logfile} - remove it: ${REMOVE_IT}"
    if [ "${REMOVE_IT}" == "YES" ]; then
        gzip ${logfile}
        # TODO: make a mount process

        DEST_DIR_EXIST="NO"
        if [ -d ${DEST_DIR} ]; then
            DEST_DIR_EXIST="YES"
        else
            mkdir -p ${DEST_DIR} && DEST_DIR_EXIST="YES"
        fi

        if [ "${DEST_DIR_EXIST}" == "YES" ]; then
            mv ${logfile}.gz ${DEST_DIR}/
        else
            echo "ERROR: ${DEST_DIR_EXIST} doesn't exist and don't be a create."
        fi
    fi
done

# Umount
umount ${MOUNT_POINT}
