#!/usr/bin/env sh
### 打印日志 ###
log(){
    LOGP=/var/log/mysql-backup
    LOGF=$LOGP/$(date +"%Y-%m-%d").log
    mkdir -p $LOGP
    touch $LOGF
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> $LOGF
}

if [ -z "${DBUSER}" -o -z "${DBPASS}" -o -z "${DBHOST}" ] ;then
    log "Database parameter not found!"
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
if [ $? -ne 0 ] ;then
    log "Database query failed!"
    exit 2
fi
#文件名, 格式为： 年月日时分秒.sql
FN=$(date +%Y%m%d%H%M%S)
#文件存放路径
mkdir -p ${BKROOT}/all
cd ${BKROOT}/all
#导出到文件
dump $DBS > $FN.sql
if [ ! -s $FN.sql ] ;then
    log "Database dump failed!"
    exit 3
fi
#压缩文件
gzip $FN.sql
#清除历史文件，保留${SAVECOUNT}个
ls -1t ${BKROOT}/all/*.gz | awk "NR>${SAVECOUNT:-30}" | xargs rm -rf
log "Database backup successful!"