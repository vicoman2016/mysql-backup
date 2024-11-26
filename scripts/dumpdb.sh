#!/usr/bin/env bash
# 设置MySQL用户名和密码
MYSQL_USER="${DBUSER:-root}"
MYSQL_PASSWORD="${DBPASS:-root}"
MYSQL_HOST="${DBHOST:-localhost}"
MYSQL_PORT=${DBPORT:-3306}
EXPORT_DIR_ROOT="${BKPATH:-/opt/data}"
SAVE_COUNT="${SAVECOUNT:-30}"

### 打印日志 ###
log(){
    # 创建日志目录
    LOGPATH=${EXPORT_DIR_ROOT}/logs
    mkdir -p ${LOGPATH}
    LOGF=$LOGPATH/$(date +"%Y-%m-%d").log
    touch $LOGF
    echo "[$(date +'%Y-%m-%d %H:%M:%S')][$$] $*" | tee -a $LOGF
}

#查询和导出命令
query(){
    mysql ${DBAUTH} --skip-column-names -B -e "$*" 2>/dev/null
}

dump_schema_and_data(){
    # 获取需要导出的所有数据库
    DATABASES=$( query "SHOW DATABASES;" | grep -Ev "(\binformation_schema\b|\bperformance_schema\b|\bmysql\b|\bsys\b)" | awk '{printf("%s ", $1);}' )
    CMD="mysqldump ${DBAUTH} --single-transaction --routines --compact --databases ${DATABASES} --result-file=${EXPORT_DIR}/schemas-and-data.sql"
    log "正在导出数据库......"
    ${CMD} 2>/dev/null
    log "导出表结构和数据完成，执行结果: $?"
}

dump_user_and_grants(){
    log "正在导出用户和权限......"
    touch ${EXPORT_DIR}/grants.sql
    query "select concat_ws('@', concat_ws(user, '''', ''''), concat_ws(host, '''', '''')) from mysql.user where user not in ('root', 'mysql.infoschema', 'mysql.session', 'mysql.sys') and user not like 'mysql.%';" | while read USER_WITH_HOST ; do
        ( echo "CREATE USER IF NOT EXISTS ${USER_WITH_HOST} IDENTIFIED BY '${MYSQL_PASSWORD}';"
        query "SHOW GRANTS FOR ${USER_WITH_HOST};" | while read GRANT_LINE ; do
            echo "${GRANT_LINE};"
        done
        ) >> ${EXPORT_DIR}/grants.sql
    done
    log "导出用户和权限完成"
}

####################################################################################
log "开始备份"

# 设置数据库连接参数
DBAUTH="-h${MYSQL_HOST} -u${MYSQL_USER}"
if [ ! -s "${MYSQL_PASSWORD}" ]; then
    DBAUTH="${DBAUTH} -p${MYSQL_PASSWORD}"
fi
if [ ! -s "${MYSQL_PORT}" ]; then
    DBAUTH="${DBAUTH} -P${MYSQL_PORT}"
fi

# 创建导出目录
TS="$(date +%Y%m%d-%H%M%S)"
EXPORT_DIR=${EXPORT_DIR_ROOT}/${TS}
mkdir -p ${EXPORT_DIR}

# 导出数据库结构和数据
dump_schema_and_data

# 导出用户和权限
dump_user_and_grants

# 压缩导出目录
log "压缩备份文件......"
cd ${EXPORT_DIR_ROOT}
tar -zcf ${TS}.tgz ${TS}
rm -rf ${TS}/

# 清理压缩包，只保留最近的${SAVE_COUNT}个压缩包
log "清理过期的压缩包......"
if [  0 -lt $SAVE_COUNT ]; then
    ls -t *.tgz | tail -n +$(($SAVE_COUNT + 1)) | xargs -I {} rm -f {}
fi
log "备份完成，备份文件路径: ${EXPORT_DIR_ROOT}/${TS}.tgz"
