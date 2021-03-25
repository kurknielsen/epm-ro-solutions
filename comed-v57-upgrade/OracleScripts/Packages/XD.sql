CREATE OR REPLACE PACKAGE XD AS
--Revision $Revision: 1.17 $

-- EXTERNAL DATA ACCESS TYPES.

TYPE METER_XREF_ID_TABLE IS TABLE OF VARCHAR(16) INDEX BY BINARY_INTEGER;

TYPE METER_XREF_USAGE_RECORD IS RECORD (
    XREF_ID VARCHAR(16),
	USAGE_DATE DATE,
	USAGE_VAL NUMBER(11,4));

TYPE METER_XREF_USAGE_CURSOR IS REF CURSOR RETURN METER_XREF_USAGE_RECORD;

TYPE METER_XREF_STATUS_RECORD IS RECORD (
    XREF_ID VARCHAR(16),
	XREF_STATUS NUMBER(3),
	XREF_STATUS_MSG VARCHAR(64));

TYPE METER_XREF_STATUS_CURSOR IS REF CURSOR RETURN METER_XREF_STATUS_RECORD;

END XD;
/
