/*
These are used in the ETAG_17 package to retrieve and store energy profiles for an eTAG.
*/
create or replace type ProfileRecord as object
(
--Revision: $Revision: 1.3 $
    blockStartDate DATE,
    startDate DATE,
    stopDate DATE,
    amount NUMBER
);
/
create or replace type ProfileRecordTable as TABLE OF ProfileRecord;
/
