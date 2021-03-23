CREATE OR REPLACE PACKAGE CRYSTAL_REPORTS IS
-- $Revision: 1.3 $
-- These constants define the type of export formats supported.
c_EXPORT_PDF		NUMBER := 5;
c_EXPORT_RTF		NUMBER := 3;
c_EXPORT_MSWORD		NUMBER := 1;
c_EXPORT_MSEXCEL	NUMBER := 2;
c_EXPORT_CRYSTAL	NUMBER := 0;

-- This type is returned from the method below that opens a Report Template. This
-- value must be passed to API methods that will interact with the Report Template to
-- produce formatted content. It is recommended to only use a single Report Template
-- at a time: i.e. close the current template before opening a new one. However,
-- multiple templates can be opened at once and the handle is the way the
-- application determines which is which after they are opened.
SUBTYPE t_RPT_HANDLE IS PLS_INTEGER;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- RETURNS THE FILE EXTENSION FOR THE GIVEN EXPORT FORMAT
FUNCTION GET_FILE_EXTENSION
	(
	p_EXPORT_FMT IN PLS_INTEGER
	) RETURN VARCHAR2;

-- This procedure will verify that the database has the Crystal Reports SDK is
-- installed. If it does not, an exception will be thrown. This method is the first
-- thing invoked by OPEN_REPORT.
PROCEDURE CHECK_CRYSTAL;

--=== When processing the report in a single step:

-- Produces formatted report output, all in one method invocation. If only a single,
-- formatted output is needed, this is the simplest way to do it. If multiple outputs
-- will be created from the same report template, however, the subsequent methods
-- should be used to do the export in several steps (which can eliminate some of the
-- overhead compared to calling this procedure multiple times). Also note that using
-- Report Templates that require more than one data source is not supported by this
-- method. Such templates require using the subsequent methods to do the export in
-- multiple steps.
-- %param p_RPT		A BLOB containing the contents of the Report Template file.
-- %param p_QUERY		A string containing a query or PL/SQL block that will be
--				evaluated to generate the resultset used to populate the
--				report.
-- %param p_EXPORT_FMT	A number indicating the export format to use. Use one of
--				the constants defined above.
-- %param p_RESULT		The outbound, formatted content.
-- %param p_ROWCOUNT 	The number of records produced when p_QUERY was executed.
-- %param p_PARMS		Parameters to the Crystal Report template.
PROCEDURE FORMAT_REPORT
	(
	p_RPT IN BLOB,
	p_QUERY IN VARCHAR2,
	p_EXPORT_FMT IN PLS_INTEGER,
	p_RESULT OUT BLOB,
	p_ROWCOUNT OUT PLS_INTEGER,
	p_PARMS IN UT.STRING_MAP := UT.c_EMPTY_MAP
	);


--=== When processing the report in multiple steps:
--=== First step - open the report template

-- Opens a Report Template file for processing. In order to open the template, the
-- BLOB's contents must first be recorded to a temporary file. The location of that
-- file is defined in the System Dictionary:
--	Global -> System -> Crystal Reports -> Server Temp Folder
-- The application schema must have appropriate java.io.FilePermission grants in order
-- to create files in this folder (granted by a DBA using DBMS_JAVA.GRANT()).
-- %param p_RPT	A BLOB containing the contents of the Report Template file.
-- %return		A handle that is used in subsequent method calls to identify this
--			Report Template.
FUNCTION OPEN_REPORT
	(
	p_RPT IN BLOB
	) RETURN t_RPT_HANDLE;

--=== Second step - define the data source(s)

-- Sets a single data source. If the Report Template needs more than one data source
-- then this method can be used to set them positionally, one-by-one.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_SQL		A string containing a query or PL/SQL block that will be
--				evaluated to generate the resultset used to populate the
--				report.  The PL/SQL block must have a single OUT parameter of type REF_CURSOR.
-- %param p_TBL_POS		The position of the table in the Report Template's list of
-- 				sources that is to be populated with p_QUERY's results. If
--				the template needs only one data source, this value can be
-- 				left unspecified.
PROCEDURE SET_DATASOURCE
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_TBL_POS IN PLS_INTEGER := 0
	);

-- Sets a single data source. If the Report Template needs more than one data source
-- then this method can be used to set them by name, one-by-one.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_SQL		A string containing a query or PL/SQL block that will be
--				evaluated to generate the resultset used to populate the
--				report. The PL/SQL block must have a single OUT parameter of type REF_CURSOR.
-- %param p_TBL_POS		The name of the table in the Report Template's list of
-- 				sources that is to be populated with p_QUERY's results.
PROCEDURE SET_DATASOURCE
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_TBL_NAME IN VARCHAR2
	);

-- Sets multiple data sources. This sets the Report Templates data sources
-- positionally. The first element in the specified collection will be used as the
-- source for the template's first data source, and so on.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_SQL_BLOCKS	A list of strings containing a query or PL/SQL block that
--				will be evaluated to generate the resultset used to
--				populate the report.
PROCEDURE SET_DATASOURCES
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL_BLOCKS IN STRING_COLLECTION
	);

-- Sets multiple data sources. This sets the Report Templates data sources
-- by name.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_QUERIES		A map of strings containing a query or PL/SQL block that
--				will be evaluated to generate the resultset used to
--				populate the report. The map keys are the names of
--				data sources in the template, and the map values are
--				the queries used to populate those sources.
PROCEDURE SET_DATASOURCES
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_QUERIES IN UT.STRING_MAP
	);

--=== Third step - define any parameters (optional - most templates don't use them)

-- Sets multiple parameters at once. This can only be used to supply string and
-- numeric values. Numeric values must be represented as string values that can
-- readily be parsed by the VM (via Double.parse(), Integer.parse() or the like).
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_PARMS		A map of parameters to provide to the template. The map
--				keys are the names of the parameters, and the map values
--				are the parameter values.
PROCEDURE SET_PARAMETERS
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARMS	IN UT.STRING_MAP
	);

-- Sets a single parameter.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_PARM_NAME	The name of the parameter to set.
-- %param p_STRING_VAL	The string value for the named parameter.
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_STRING_VAL IN VARCHAR2
	);

-- Sets a single parameter.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_PARM_NAME	The name of the parameter to set.
-- %param p_NUM_VAL		The numeric value for the named parameter.
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_NUM_VAL IN NUMBER
	);

-- Sets a single parameter.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_PARM_NAME	The name of the parameter to set.
-- %param p_INT_VAL		The integer value for the named parameter.
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_INT_VAL IN PLS_INTEGER
	);

-- Sets a single parameter.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_PARM_NAME	The name of the parameter to set.
-- %param p_DATE_VAL	The date value for the named parameter.
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_DATE_VAL IN DATE
	);

--=== Fourth step - perform the export!

-- Produces formatted report output from an open Report Template.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
-- %param p_EXPORT_FMT	A number indicating the export format to use. Use one of
--				the constants defined above.
-- %param p_RESULT		The outbound, formatted content.
-- %param p_ROWCOUNT 	The number of records produced when p_QUERY was executed.
PROCEDURE PRODUCE_REPORT
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_EXPORT_FMT IN PLS_INTEGER,
	p_RESULT OUT BLOB,
	p_ROWCOUNT	OUT PLS_INTEGER
	);

--=== Fifth step - go back to second step and repeat to perform another export

--=== Sixth and final step - clean up

-- Closes an open Report Template.
-- %param p_RPT_HANDLE	The handle to an open Report Template.
PROCEDURE CLOSE_REPORT(p_RPT_HANDLE IN t_RPT_HANDLE);

END CRYSTAL_REPORTS;
/
CREATE OR REPLACE PACKAGE BODY CRYSTAL_REPORTS IS

	g_TEMP_DIRECTORY SYSTEM_DICTIONARY.VALUE%TYPE;

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION CHECK_CRYSTAL_BOOLEAN RETURN BOOLEAN IS

	v_SHORT_NAME USER_OBJECTS.OBJECT_NAME%TYPE;
	v_TEST PLS_INTEGER;

BEGIN

--	v_SHORT_NAME := DBMS_JAVA.SHORTNAME('com/newenergyassoc/ro/oracleStoredProcs/CrystalReportExporter');

	SELECT COUNT(1)
	INTO v_TEST
	FROM USER_OBJECTS UO
	WHERE UO.OBJECT_TYPE = 'JAVA CLASS'
		AND UO.OBJECT_NAME = v_SHORT_NAME
		AND UO.STATUS = 'VALID';

	IF v_TEST <= 0 THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;

END CHECK_CRYSTAL_BOOLEAN;
---------------------------------------------------------------------------------------------------
-- This procedure will verify that the database has the Crystal Reports SDK is
-- installed. If it does not, an exception will be thrown. This method is the first
-- thing invoked by OPEN_REPORT.
PROCEDURE CHECK_CRYSTAL AS

BEGIN

	IF NOT CHECK_CRYSTAL_BOOLEAN THEN
		ERRS.RAISE(MSGCODES.c_ERR_CRYSTAL_SDK_MISSING);
	END IF;

END CHECK_CRYSTAL;
---------------------------------------------------------------------------------------------------
PROCEDURE FORMAT_REPORT
	(
	p_RPT IN BLOB,
	p_QUERY IN VARCHAR2,
	p_EXPORT_FMT IN PLS_INTEGER,
	p_RESULT OUT BLOB,
	p_ROWCOUNT OUT PLS_INTEGER,
	p_PARMS IN UT.STRING_MAP := UT.c_EMPTY_MAP
	) AS

	v_RPT_ID t_RPT_HANDLE;

BEGIN

	v_RPT_ID := OPEN_REPORT(p_RPT);

	SET_DATASOURCE(v_RPT_ID, p_QUERY);

	SET_PARAMETERS(v_RPT_ID, p_PARMS);

	PRODUCE_REPORT(v_RPT_ID, p_EXPORT_FMT, p_RESULT, p_ROWCOUNT);

	CLOSE_REPORT(v_RPT_ID);

END FORMAT_REPORT;
---------------------------------------------------------------------------------------------------
FUNCTION OPEN_REPORT_INTERNAL
	(
	p_RPT IN BLOB
	) RETURN t_RPT_HANDLE
  AS LANGUAGE JAVA
  NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.openReport(oracle.sql.BLOB) return int';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_TEMPORARY_PATH
	(
	p_TEMPORARY_FILE_PATH IN VARCHAR2
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setTempPath(java.lang.String)';
---------------------------------------------------------------------------------------------------
FUNCTION OPEN_REPORT
	(
	p_RPT IN BLOB
	) RETURN t_RPT_HANDLE AS

BEGIN

	CHECK_CRYSTAL;

	RETURN OPEN_REPORT_INTERNAL(p_RPT);

END OPEN_REPORT;
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PROCEDURE
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_SOURCE_INDEX IN PLS_INTEGER
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setProcedure(int, java.lang.String, int)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PROCEDURE
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_SOURCE_NAME IN VARCHAR2
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setProcedure(int, java.lang.String, java.lang.String)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_QUERY
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_SOURCE_INDEX IN PLS_INTEGER
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setQuery(int, java.lang.String, int)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_QUERY
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_SOURCE_NAME IN VARCHAR2
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setQuery(int, java.lang.String, java.lang.String)';
---------------------------------------------------------------------------------------------------
-- CHECKS THE SQL BLOCK p_SQL TO SEE IF IT IS A PROCEDURE CALL OR A SQL QUERY (BY CHECKING THE FIRST WORD)
FUNCTION IS_SQL_BLOCK_QUERY
	(
	p_SQL IN VARCHAR2
	) RETURN BOOLEAN IS

BEGIN

	-- STARTS WITH BEGIN OR DECLARE? THEN THIS IS A PROCEDURE CALL
	IF SUBSTR(TRIM(p_SQL), 1, 5) IN ('BEGIN', 'DECLA') THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;

END IS_SQL_BLOCK_QUERY;
---------------------------------------------------------------------------------------------------
PROCEDURE SET_DATASOURCE
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_TBL_POS IN PLS_INTEGER := 0
	) AS

BEGIN
	IF IS_SQL_BLOCK_QUERY(p_SQL) THEN
		SET_QUERY(p_RPT_HANDLE, p_SQL, p_TBL_POS);
	ELSE
		SET_PROCEDURE(p_RPT_HANDLE, p_SQL, p_TBL_POS);
	END IF;
END SET_DATASOURCE;
---------------------------------------------------------------------------------------------------
PROCEDURE SET_DATASOURCE
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL IN VARCHAR2,
	p_TBL_NAME IN VARCHAR2
	) AS

BEGIN
	IF IS_SQL_BLOCK_QUERY(p_SQL) THEN
		SET_QUERY(p_RPT_HANDLE, p_SQL, p_TBL_NAME);
	ELSE
		SET_PROCEDURE(p_RPT_HANDLE, p_SQL, p_TBL_NAME);
	END IF;
END SET_DATASOURCE;
---------------------------------------------------------------------------------------------------
PROCEDURE SET_DATASOURCES
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_SQL_BLOCKS IN STRING_COLLECTION
	) AS

BEGIN

	FOR v_IDX IN 1..p_SQL_BLOCKS.COUNT LOOP
		SET_DATASOURCE(p_RPT_HANDLE, p_SQL_BLOCKS(v_IDX), v_IDX);
	END LOOP;

END SET_DATASOURCES;
---------------------------------------------------------------------------------------------------
PROCEDURE SET_DATASOURCES
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_QUERIES IN UT.STRING_MAP
	) AS

	v_PARAM_NAME VARCHAR2(2000);

BEGIN

	v_PARAM_NAME := p_QUERIES.FIRST;

	WHILE p_QUERIES.EXISTS(v_PARAM_NAME) LOOP

		SET_DATASOURCE(p_RPT_HANDLE, p_QUERIES(v_PARAM_NAME), v_PARAM_NAME);

		v_PARAM_NAME := p_QUERIES.NEXT(v_PARAM_NAME);
	END LOOP;

END SET_DATASOURCES;
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_STRING_VAL IN VARCHAR2
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setParameter(int, java.lang.String, java.lang.String)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_NUM_VAL IN NUMBER
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setParameter(int, java.lang.String, double)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_INT_VAL IN PLS_INTEGER
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setParameter(int, java.lang.String, int)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PARAMETER
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARM_NAME IN VARCHAR2,
	p_DATE_VAL IN DATE
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.setParameter(int, java.lang.String, java.sql.Date)';
---------------------------------------------------------------------------------------------------
PROCEDURE SET_PARAMETERS
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_PARMS	IN UT.STRING_MAP
	) AS

v_PARAM_NAME VARCHAR2(2000);

BEGIN

	v_PARAM_NAME := p_PARMS.FIRST;

	WHILE p_PARMS.EXISTS(v_PARAM_NAME) LOOP

		SET_PARAMETER(p_RPT_HANDLE, v_PARAM_NAME, p_PARMS(v_PARAM_NAME));

		v_PARAM_NAME := p_PARMS.NEXT(v_PARAM_NAME);
	END LOOP;

END SET_PARAMETERS;
---------------------------------------------------------------------------------------------------
PROCEDURE PRODUCE_REPORT
	(
	p_RPT_HANDLE IN t_RPT_HANDLE,
	p_EXPORT_FMT IN PLS_INTEGER,
	p_RESULT OUT BLOB,
	p_ROWCOUNT	OUT PLS_INTEGER
	) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.produceReport(int, int, oracle.sql.BLOB[], int[])';
---------------------------------------------------------------------------------------------------
PROCEDURE CLOSE_REPORT
	(p_RPT_HANDLE IN t_RPT_HANDLE) AS LANGUAGE JAVA
	NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.closeReport(int)';
---------------------------------------------------------------------------------------------------
FUNCTION GET_FILE_EXTENSION
	(
	p_EXPORT_FMT IN PLS_INTEGER
	) RETURN VARCHAR2 AS

BEGIN

	IF p_EXPORT_FMT = c_EXPORT_PDF THEN
		RETURN 'pdf';
	ELSIF p_EXPORT_FMT = c_EXPORT_RTF THEN
		RETURN 'rtf';
	ELSIF p_EXPORT_FMT = c_EXPORT_MSWORD THEN
		RETURN 'doc';
	ELSIF p_EXPORT_FMT = c_EXPORT_MSEXCEL THEN
		RETURN 'xls';
	ELSIF p_EXPORT_FMT = c_EXPORT_CRYSTAL THEN
		RETURN 'rpt';
	ELSE
		RETURN NULL;
	END IF;

END GET_FILE_EXTENSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_PDF_CODE RETURN PLS_INTEGER
	AS LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.getPDFCode() return int';
---------------------------------------------------------------------------------------------------
FUNCTION GET_RTF_CODE RETURN PLS_INTEGER
	AS LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.getRTFCode() return int';
---------------------------------------------------------------------------------------------------
FUNCTION GET_MSWORD_CODE RETURN PLS_INTEGER
	AS LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.getMSWordCode() return int';
---------------------------------------------------------------------------------------------------
FUNCTION GET_MSEXCEL_CODE RETURN PLS_INTEGER
	AS LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.getMSExcelCode() return int';
---------------------------------------------------------------------------------------------------
FUNCTION GET_CRYSTAL_CODE RETURN PLS_INTEGER
	AS LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.CrystalReportExporter.getCrystalCode() return int';
---------------------------------------------------------------------------------------------------

BEGIN

	-- INITIALIZE THE CONSTANTS USING CrystalReportExporter (If it is present)
	IF CHECK_CRYSTAL_BOOLEAN THEN
		c_EXPORT_PDF := GET_PDF_CODE;
		c_EXPORT_RTF := GET_RTF_CODE;
		c_EXPORT_MSWORD	:= GET_MSWORD_CODE;
		c_EXPORT_MSEXCEL := GET_MSEXCEL_CODE;
		c_EXPORT_CRYSTAL := GET_CRYSTAL_CODE;

		SP.GET_SYSTEM_DICTIONARY_VALUE(GA.DEFAULT_MODEL, 'System', 'Crystal Reports',
			CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE, 'Database Temporary Report Directory',
			g_TEMP_DIRECTORY);

		SET_TEMPORARY_PATH(g_TEMP_DIRECTORY);
	END IF;

END CRYSTAL_REPORTS;
/
