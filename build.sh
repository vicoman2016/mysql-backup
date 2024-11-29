docker rmi -f harbor.hoyozero.com/library/mysql-backup:3.0.0
docker rmi -f harbor.hoyozero.com/library/mysql-backup:latest
docker build -t harbor.hoyozero.com/library/mysql-backup:3.0.0 .
docker tag harbor.hoyozero.com/library/mysql-backup:3.0.0 harbor.hoyozero.com/library/mysql-backup:latest
echo -n "push to harbor? [y/n] " && read -r answer
if [ "$answer" = "y" ]; then
  docker push harbor.hoyozero.com/library/mysql-backup:3.0.0
  docker push harbor.hoyozero.com/library/mysql-backup:latest
fi