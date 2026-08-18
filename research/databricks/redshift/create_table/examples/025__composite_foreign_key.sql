-- SOURCE: GitHub issue / real-world parsing example
-- URL: https://github.com/sqlfluff/sqlfluff/issues/5592
-- DATABASE: Redshift
-- OBJECT TYPE: CREATE TABLE
-- FEATURE: COMPOSITE FOREIGN KEY
-- DESCRIPTION: Composite foreign key referencing a composite unique key.
CREATE TABLE public.t2
(
  c1 int,
  c2 int,
  foreign key (c1, c2) references public.t1 (c1, c2)
);
