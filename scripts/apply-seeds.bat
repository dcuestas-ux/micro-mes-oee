@echo off
echo Aplicando seeds...

docker cp data\sql\seeds\01-shifts.sql postgres:/01-shifts.sql
docker exec -it postgres psql -U mes -d mesdb -f /01-shifts.sql

docker cp data\sql\seeds\02-machines.sql postgres:/02-machines.sql
docker exec -it postgres psql -U mes -d mesdb -f /02-machines.sql

docker cp data\sql\seeds\02-planned-hours.sql postgres:/02-planned-hours.sql
docker exec -it postgres psql -U mes -d mesdb -f /02-planned-hours.sql

echo. ✅ Seeds aplicados