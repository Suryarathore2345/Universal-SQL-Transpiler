-- SOURCE: GitHub issue / real-world parsing example
-- URL: https://github.com/sqlfluff/sqlfluff/issues/5592
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: COMPOSITE UNIQUE + COMPOSITE FOREIGN KEY
-- DESCRIPTION: Redshift table constraints with multi-column FK syntax.
CREATE TABLE public.t1 (c1 int, c2 int, unique (c1, c2));
