@echo off
echo Inicializando base de datos...

docker cp data\sql\ddl.sql postgres:/ddl.sql
docker exec -it postgres psql -U mes -d mesdb -f /ddl.sql

docker cp data\sql\patch.sql postgres:/patch.sql
docker exec -it postgres psql -U mes -d mesdb -f /patch.sql

echo. ✅ Base de datos inicializada