IF OBJECT_ID('${schema}.timezone_mapping', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.timezone_mapping (
        iana_timezone     VARCHAR(50),
        windows_timezone  VARCHAR(50)
    );
END;