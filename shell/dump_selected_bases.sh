#!/bin/sh

BASES="kauzela2 BaseZUP_2011"
EXT_MACHINE="\\192.168.10.251\1C-Base2\SQL"
DEST_MNT_POINT="/mnt/sql-archive"
CURRENT_DATE_TIME=`date +%Y-%m-%d_%H-%M`

if [ -d	$DEST_MNT_POINT ]; then
    echp "Cool"
else
    mkdir -p $DEST_MNT_POINT
fi

/sbin/mount.cifs $EXT_MACHINE $DEST_MNT_POINT -o guest || exit 1
for base in $BASES; do
    FILENAME={base}-"${CURRENT_DATE_TIME}.sql"
    su - postgres -c "pg_dump $base > ~/${FILENAME}"
    cp -f /var/lib/pgsql/${FILENAME} $DEST_MNT_POINT/
done
