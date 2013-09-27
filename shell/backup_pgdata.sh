#!/bin/sh

SERVICES="srv1cv82 postgresql" #srv1cv82
SERVICE_CMD="/sbin/service %%NAME%% %%CMD%%"
#SERVICE_CMD="/bin/systemctl %%CMD%% %%NAME%%.service"
DATA_DIR="/var/lib/pgsql/data" # /var/lib/pgsql/data2"
BACKUP_DIR="/srv/backup"
MOUNT_CMD="/sbin/mount.cifs //192.168.10.251/1C-Base2 ${MOUNT_POINT} -o username=semen,password=02239-45"
MOUNT_POINT="/mnt/disk"
#MOUNT_CMD="/sbin/mount.cifs //172.16.32.101/public ${MOUNT_POINT} -o guest"
EXTERNAL_DIR="/mnt/disk/SQL"
PGSQL_VERSION=`/usr/bin/psql --version | awk '{print $3}' | head -n 1`
DATE_RAW=`date +%Y-%m-%d`
DATE="${DATE_RAW}_pgsql${PGSQL_VERSION}"
ALARM_EMAIL="abuse@atisserv.ru"

TEMPORARY_LOG="/tmp/backup_pgdata_${DATE_RAW}"
MAIL_CMD=`which mail`

DEBUG=1

function command_fail {
    reason=$1
    echo "${MAIL_CMD} -s \"${reason}\" \"${ALARM_EMAIL}\" < ${TEMPORARY_LOG}"
    exit 1
}

function command_exec {
    cmd=$1
    if [ "${DEBUG}T" == "1T" ]; then
        echo $cmd
    fi
    $cmd  >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $cmd"
}

# Step 1. stop services
for srv in $SERVICES; do
    PRE_CMD=`echo "$SERVICE_CMD" | sed "s|%%NAME%%|$srv|g"`
    DONE_CMD=`echo "$PRE_CMD" | sed "s|%%CMD%%|stop|g"`

    command_exec "$DONE_CMD"
    #$DONE_CMD >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in ${DONE_CMD}
done

# Step 2. copy data
BACKUPS=""
for data in $DATA_DIR; do
    SUFFIX_DIR=`echo "$data" | sed "s|/|_|g"`
    DEST_DIR="${BACKUP_DIR}/$DATE/${SUFFIX_DIR:1}"
    command_exec "mkdir -p ${DEST_DIR}"
    #mkdir -p ${DEST_DIR} >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"
    command_exec "cp -pR $data ${DEST_DIR}/"
    #cp -pR $data ${DEST_DIR}/ >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"

    BACKUPS="${BACKUPS} $DEST_DIR"
done

# Step 3. start services
for srv in $SERVICES; do
    PRE_CMD=`echo "$SERVICE_CMD" | sed "s|%%NAME%%|$srv|g"`
    DONE_CMD=`echo "$PRE_CMD" | sed "s|%%CMD%%|start|g"`

    command_exec "$DONE_CMD"
    #$DONE_CMD >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"
done

# Step 4. archive the data dir
ARCHIVES=""
command_exec "pushd $BACKUP_DIR"
for backup in $BACKUPS; do
    PRE_BACKUP_NAME=`echo "$backup" | sed "s|/|_|g"`
    BACKUP_NAME=${PRE_BACKUP_NAME:1}
    
    command_exec "/bin/tar cfp ${BACKUP_NAME}.tar $backup"
    #tar cfp ${BACKUP_NAME}.tar $backup >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"
    command_exec "/usr/bin/xz -f ${BACKUP_NAME}.tar"
    #xz ${BACKUP_NAME}.tar >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"
    ARCHIVES="${ARCHIVES} ${BACKUP_NAME}.tar.xz"
done
command_exec "popd"

# Step 5. Mount fs
command_exec "mkdir -p ${MOUNT_POINT}"
# Check existing mounts
EXIST_MOUNTS=`mount | grep ${MOUNT_POINT} | awk '{print $1}'`
for e in $EXIST_MOUNTS; do
    umount $MOUNT_POINT
done
command_exec "$MOUNT_CMD"
#$MOUNT_CMD  >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"

# Step 6. Move archives
command_exec "mkdir -p ${EXTERNAL_DIR}/${DATE_RAW}"
#$CMD  >> $TEMPORARY_LOG 2>&1 || command_fail "Fail in $CMD"
command_exec "pushd $BACKUP_DIR"
for archive in $ARCHIVES; do
    command_exec "mv $archive ${EXTERNAL_DIR}/${DATE_RAW}/"
done
command_exec "popd"

# Step 7. Unmount
command_exec "umount ${MOUNT_POINT}"

# Step 7. Clean up
for backup in $BACKUPS; do
    command_exec "rm -r $backup"
done
