CREATE OR REPLACE FUNCTION GET_TRANSPOSED_VALUES( INPUT TIME_SERIES_TYPE)
--Revision: $Revision: 1.1 $
RETURN TRANSPOSED_VALUES_TYPE
PARALLEL_ENABLE AGGREGATE USING GET_TRANSPOSED_VALUES_OBJ;
/
