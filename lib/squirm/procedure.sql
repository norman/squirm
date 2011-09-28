SELECT p.proname AS "name",
  pg_catalog.pg_get_function_result(p.oid) AS "return_type",
  pg_catalog.pg_get_function_arguments(p.oid) AS "arguments",
  p.proargtypes AS "argtypes",
  CASE
    WHEN p.proisagg THEN 'agg'
    WHEN p.proiswindow THEN 'window'
    WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
    ELSE 'normal'
  END AS "procedure_type"
FROM pg_catalog.pg_proc p
LEFT JOIN pg_catalog.pg_namespace n
  ON n.oid = p.pronamespace
WHERE p.proname = $1::text
  AND n.nspname = $2::text
