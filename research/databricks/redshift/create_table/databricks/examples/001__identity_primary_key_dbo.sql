CREATE TABLE `dbo`.`venue_ident` (
    `venueid` BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 0 INCREMENT BY 1),
    `venuename` STRING(100),
    `venuecity` STRING(30),
    `venuestate` CHAR(2),
    `venueseats` INT,
    PRIMARY KEY (`venueid`) NOT ENFORCED
)
USING DELTA;