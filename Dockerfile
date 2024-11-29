FROM ubuntu:24.04
COPY Shanghai /etc/localtime
COPY scripts/* /usr/local/sbin/
ENV DBUSER="root" DBPASS="root" DBHOST="service-mysql" DBPORT="3306" SAVECOUNT=30 CRON="5 0,12 * * *"
RUN apt-get update && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get install -y cron mysql-client && \
    printf "[client]\ndefault-character-set=utf8mb4\nuser=root\npassword=root\nhost=service-mysql\nport=3306\n" >/etc/mysql/conf.d/mysql.cnf && \
    printf "[mysqldump]\nquick\nquote-names\nmax_allowed_packet=16M\n" >/etc/mysql/conf.d/mysqldump.cnf
CMD [ "/bin/bash", "/usr/local/sbin/init.sh" ]
