# Docker镜像 用于备份 MySQL数据库

## 使用方法

### docker-compose.yaml

``` yaml
services:
  mysql-backup:
    image: "wgmac/mysql-backup:3.0.0"
    container_name: "mysql-backup"
    environment:
      #mysql数据库服务器地址，可写IP，域名，默认：localhost
      - DBHOST=172.30.71.0
      #mysql数据库端口，默认: 3306
      - DBPORT=3306
      #mysql数据库用户名
      - DBUSER=root
      #mysql数据库密码
      - DBPASS=root
      #最多保留文件数目，默认: 30
      - SAVECOUNT=20
      #备份文件存储路径，默认: /opt/data
      - BKPATH=/opt/data
      #备份策略，crond表达式, 默认: 5 0,12 * * *
      - CRON=2 0,6,12,18 * * *
      #保留日志
      - DEBUG=true
    volumes:
      #备份文件存储路径
      - ./data:/opt/data
```

### 立即备份

```bash
# 在宿主机中执行
docker exec -it <container_id> dumpdb.sh
```
