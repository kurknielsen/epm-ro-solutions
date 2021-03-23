CREATE OR REPLACE PACKAGE MEX_NYISO_BIDPOST IS
-- $Revision: 1.19 $

--
-- file: MEX_NYISO_BIDPOST.SQL
--
-- contains behavior used to post secured requests managed by nyiso
--
  TYPE file_names_t IS TABLE OF VARCHAR2(30);


FUNCTION WHAT_VERSION RETURN VARCHAR2;
  --
  -- Fetch the CSV file for PHYSICAL LOAD  and map into records for MM import.
  -- The parameter map will include needed connect / permissions info
PROCEDURE FETCH_PHYSICAL_LOAD(p_DATE        IN DATE,
							  p_CRED		IN mex_credentials,
							  p_RECORDS     OUT MEX_NY_PHYSICAL_LOAD_TBL,
							  p_STATUS		OUT NUMBER,
							  p_LOGGER 		IN OUT NOCOPY MM_LOGGER_ADAPTER);
							   
  -- Submit the data for PHYSICAL LOAD  and map into records for MM import.
  -- The parameter map will include needed connect / permissions info
  --
PROCEDURE SUBMIT_PHYSICAL_LOAD(p_CRED 		 IN mex_credentials,
							   p_RECORDS_IN  IN MEX_NY_PHYSICAL_LOAD_TBL,
							   p_RECORDS_OUT OUT MEX_NY_PHYSICAL_LOAD_TBL,
							   p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
							   p_STATUS		 OUT NUMBER);



END MEX_NYISO_BIDPOST;
/