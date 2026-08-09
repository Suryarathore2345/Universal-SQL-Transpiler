-- ============================================================================
-- Fabric Data Warehouse: Security Features
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric Data Warehouse (T-SQL subset)
-- Key constructs: Dynamic Data Masking, Row-Level Security (RLS),
--                 Column-Level Security, DENY/GRANT, SECURITY POLICY
-- ============================================================================

-- ==========================================================
-- Dynamic Data Masking
-- ==========================================================

CREATE TABLE dbo.Customers
(
    CustomerID INT NOT NULL,
    FirstName varchar(50) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,
    LastName varchar(50) NOT NULL,
    Phone varchar(20) MASKED WITH (FUNCTION = 'default()') NULL,
    Email varchar(50) MASKED WITH (FUNCTION = 'email()') NULL
);

INSERT dbo.Customers (CustomerID, FirstName, LastName, Phone, Email) VALUES
(29485,'Catherine','Abel','555-555-5555','catherine0@adventure-works.com'),
(29486,'Kim','Abercrombie','444-444-4444','kim2@adventure-works.com'),
(29489,'Frances','Adams','333-333-3333','frances0@adventure-works.com');

-- ==========================================================
-- Row-Level Security (RLS) with Security Policy
-- ==========================================================

CREATE SCHEMA rls;
GO

CREATE FUNCTION rls.fn_securitypredicate(@SalesRep AS VARCHAR(60))
    RETURNS TABLE
WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @SalesRep = USER_NAME();
GO

CREATE SECURITY POLICY SalesFilter
ADD FILTER PREDICATE rls.fn_securitypredicate(SalesRep)
ON dbo.Sales
WITH (STATE = ON);
GO

-- ==========================================================
-- Column-Level Security (DENY on specific columns)
-- ==========================================================

DENY SELECT ON dbo.Orders (CreditCard) TO [user1@domain.com];
GO

-- ==========================================================
-- Object-Level Security (DENY table, GRANT procedure)
-- ==========================================================

DENY SELECT on dbo.Parts to [user1@domain.com];
GRANT EXECUTE on dbo.sp_PrintMessage to [user1@domain.com];
GO
