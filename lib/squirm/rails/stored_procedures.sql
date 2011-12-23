/*
This is the stored_procedures.sql file used by Squirm. Define your Postgres
stored procedures in this file and they will be loaded at the end of any calls
to the db:schema:load Rake task.
*/

CREATE OR REPLACE FUNCTION hello_world() RETURNS TEXT AS $$
  BEGIN
    RETURN 'hello world!';
  END;
$$ LANGUAGE 'PLPGSQL'