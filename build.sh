if [ $# -lt 0 ];then
    echo "Error: no tag specified"
    echo "Usage:  [tag]"
    echo "eg: `basename $0` 1.0.0"
    exit 1
fi
tag=
docker compose -f example/docker-compose.yml down
tag=${1:-latest}
docker buildx build --platform linux/amd64 -t wgmac/mysql-backup:${tag} -t wgmac/mysql-backup:latest -t harbor.hoyozero.com/library/mysql-backup:${tag}  -t harbor.hoyozero.com/library/mysql-backup:latest .
sed -i -E 's/VERSION=.*$/VERSION='${tag}'/g' example/.env
#echo "VERSION=${tag}" > example/.env
#docker compose -f example/docker-compose.yml  up -d
