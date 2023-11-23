#!/usr/bin/env sh
BKROOT=${BKPATH:-/opt/data}
#删除源文件
ls -1t ${BKROOT}/all/*.gz | awk "NR>${SAVECOUNT:-30}" | xargs rm -rf
#删除链接文件
for lnk in $(find ${BKROOT} -type l)
do
    if [ ! -e $lnk ] ; then rm -f $lnk ; fi
done