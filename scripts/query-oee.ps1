param(
    [string]$machine_id = "test_cnc_01",
    [string]$view = "oee_hour_v"
)

docker exec -it postgres psql -U mes -d mesdb -c "
SELECT 
  bucket, 
  availability::numeric(4,2) AS avail,
  performance::numeric(4,2) AS perf,
  quality::numeric(4,2) AS qual,
  oee::numeric(4,2) AS oee
FROM $view 
WHERE machine_id = '$machine_id'
ORDER BY bucket DESC 
LIMIT 10;
"
