docker compose -f example/docker-compose.yml down
tag=${1:-latest}
docker buildx build --platform linux/amd64 -t wgmac/mysql-backup:${tag} -t wgmac/mysql-backup:latest -t harbor.hoyozero.com/library/mysql-backup:${tag}  -t harbor.hoyozero.com/library/mysql-backup:latest .

echo "VERSION=${tag}" > example/.env
#docker compose -f example/docker-compose.yml  up -d
