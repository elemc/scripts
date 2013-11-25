#!/bin/sh

# Settings
BACKUP_DIRS="/etc /var /home"
DATE_PART=$(date +%Y-%m-%d)
TMP_DIR="/tmp/backup-${DATE_PART}"
BACKUP_FILES=""
FTP_BACKUP_DIR="backups"
FTP_URI=""

# 1. Configure
if [ ! -d ${TMP_DIR} ]; then
    mkdir -p ${TMP_DIR}
fi

# 1. Backup 
for dir in ${BACKUP_DIRS}; do
    name_part=$(echo ${dir} | cut -c 2- | sed 's|/|_|g')
    backup_name=${name_part}_${DATE_PART}.tar.xz
    /bin/tar cfJvp ${TMP_DIR}/${backup_name} ${dir}
    BACKUP_FILES="${BACKUP_FILES} ${backup_name}"
done

# 2. Send backups in to FTP
/usr/bin/lftp -c "open ${FTP_URI}; cd ${FTP_BACKUP_DIR}; mput ${TMP_DIR}/*.tar.xz; close; exit"

# 3. Remove temporary directory
rm -rf ${TMP_DIR}
