IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = '${schema}')
BEGIN
    EXEC('CREATE SCHEMA ${schema}');
END
