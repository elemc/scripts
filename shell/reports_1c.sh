#!/bin/sh

SOURCE_DIR=$1
DEST_DIR=$2

pushd $DEST_DIR
DIRS=`find . -iname extforms -type d`
find . -iname extforms -type d | while read dir; do
  #echo "Using $dir..."
  pushd "$DEST_DIR/$dir" > /dev/null
  RES_USN=""
  RES_PROF=""
  for rep in `find . -name 1SBINSTR.TXT`; do
    USN=`iconv --from-code=cp1251 --to-code=utf8 $rep | grep "Упрощенн"`
	PROF=`iconv --from-code=cp1251 --to-code=utf8 $rep | grep "Комплексн"`
	RES_USN=$RES_USN$USN
	RES_PROF=$RES_PROF$PROF
  done
  
  if [ "$RES_PROF" != "" ]; then
	  echo "Found PROF at $dir"
	  cp -rf $SOURCE_DIR/PROF/* "${DEST_DIR}/${dir}/"
  fi

  if [ "$RES_USN" != "" ]; then
	  echo "Found USN at $dir"
	  cp -rf $SOURCE_DIR/USN/* "${DEST_DIR}/${dir}/"
  fi
  popd > /dev/null
done
popd
