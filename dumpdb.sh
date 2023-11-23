#!/usr/bin/env sh
if [ -z "${DBUSER}" -o -z "${DBPASS}" -o -z "${DBHOST}" ] ;then
    echo "Database parameter not found!"
    exit 1
fi
#db授权信息
DBAUTH="-u${DBUSER} -p${DBPASS} -h${DBHOST} -P${DBPORT:-3306}"
#查询和导出命令
alias dump="/usr/bin/mysqldump ${DBAUTH} --single-transaction --databases "
alias query="/usr/bin/mysql ${DBAUTH} --skip-column-names -B -e "

#备份文件存放位置，可设置环境变量BKPATH，默认/opt/data
BKROOT=${BKPATH:-/opt/data}
#数据库列表
DBS=$(query "show databases" | grep -Evi "information_schema|mysql|sys|performance_schema")
#链接文件存放路径，按年份/月份存放
LINKPATH=${BKROOT}/$(date +%Y/%m)
#文件名, 格式为： 年月日时分秒.sql
FN=$(date +%Y%m%d%H%M%S)
#文件存放路径
mkdir -p ${BKROOT}/all
cd ${BKROOT}/all
#导出到文件
dump $DBS > $FN.sql
#压缩文件
gzip $FN.sql
if [ $? -ne 0 ] ;then
    echo "Database backup failed!"
    exit 2
fi
#创建一个软链接，便于查找
mkdir -p $LINKPATH
cd $LINKPATH
ln -s ${BKROOT}/all/$FN.sql.gz
exit 0
