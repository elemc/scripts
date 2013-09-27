#!/bin/sh
# 

. "${PM_FUNCTIONS}"

case "$1" in
	hibernate|suspend)
		;;
	thaw|resume)
		if [ -x /sbin/modprobe ]; then
			/sbin/modprobe -r ath9k
			/sbin/modprobe ath9k
		fi
		;;
	*) exit $NA
		;;
esac
