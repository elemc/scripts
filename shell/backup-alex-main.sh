#!/bin/sh

DATE=`date +%Y-%m-%d`
TAR_SELINUX="tar cfjvp"

pushd /srv/backups

  # Backup /etc
  ${TAR_SELINUX} etc-${DATE}.tar.bz2 /etc
  
  # Backup /var/named
  ${TAR_SELINUX} var-named-${DATE}.tar.bz2 /var/named
  
  # Backup /var/log
  ${TAR_SELINUX} var-log-${DATE}.tar.bz2 /var/log

  # Backup www - wordpress
  # ${TAR_SELINUX} var-www-html-wordpress-${DATE}.tar.bz2 /var/www/html/wordpress --selinux

  # Backup chatlogs
  # ${TAR_SELINUX} var-www-html-chatlog-${DATE}.tar.bz2 /var/www/html/chatlog --selinux

  # Backup root -www
  ${TAR_SELINUX} var-www-html-root-${DATE}.tar.bz2 /var/www/htdocs

  # Backup /usr/local/bin
  ${TAR_SELINUX} usr-local-bin-${DATE}.tar.bz2 /usr/local/bin/*.py  /usr/local/bin/*.sh

  # Backup mysql database
  # /usr/bin/mysqldump -u root -p3510 wpelemcblog > wp-elemc-blog-${DATE}.sql
  # xz wp-elemc-blog.sql
popd