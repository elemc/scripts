#!/bin/sh

BACKUP_DIR=/srv/samba/backup

CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)

PREV_YEAR=${CURRENT_YEAR}
RAW_PREV_MONTH=$(expr ${CURRENT_MONTH} - 2)
PREV_MONTH=""
if [ "${RAW_PREV_MONTH}" -eq "-1" ]; then
    PREV_YEAR=$(expr ${CURRENT_YEAR} - 1)
    RAW_PREV_MONTH="11"
elif [ "${RAW_PREV_MONTH}" -eq "0" ]; then
   PREV_YEAR=$(expr ${CURRENT_YEAR} - 1)
   RAW_PREV_MONTH="12" 
fi

RAW_PREV_LENGTH=${#RAW_PREV_MONTH}
if [ "${RAW_PREV_LENGTH}" -eq "1" ]; then
    PREV_MONTH=$(expr ${#2}${RAW_PREV_MONTH})
else
    PREV_MONTH=${RAW_PREV_MONTH}
fi

# Debug
#echo "${CURRENT_MONTH} > ${PREV_MONTH}"
#echo "${CURRENT_YEAR} > ${PREV_YEAR}"

PREV_PATTERN="*-${PREV_YEAR}-${PREV_MONTH}-*"

# Clean backups localy
pushd ${BACKUP_DIR} > /dev/null 2>&1
rm -rf ${PREV_PATTERN}
popd > /dev/null 2>&1

# Clean backups remotely
/usr/bin/lftp -u ariadna,shaiB2ai atisserv.ru -e "glob -a rm -rf ${PREV_PATTERN}" > /dev/null 2>&1
