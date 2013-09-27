#!/bin/sh

PRESENT=`ps ax | grep 'python2.7 isida.py' | grep -v grep`
LOG_DATE=`date +"%Y-%m-%d %H:%M"`

if [ "$PRESENT" == "" ]; then
    pushd /home/isidabot/isida > /dev/null
    sh launch.sh
    popd > /dev/null
else
    echo "$LOG_DATE: Bot is present" >> /tmp/check-bot.log
fi
