CREATE OR REPLACE TYPE GET_TRANSPOSED_VALUES_OBJ AS OBJECT
(
/******************************************************************************
   NAME   :  GET_TRANSPOSED_VALUES_OBJ
   PURPOSE:  To perform custom aggregation for transposition. 

   --Revision: $Revision: 1.1 $
  
   2011-08-22 Rex S. Arul(RSA) 
              1. Initial Release. Implemented the custom ODCI interfaces.
******************************************************************************/

/* Object Attributes */
	v_RETURN_ARRAY	 TRANSPOSED_VALUES_TYPE,

/* Static Method for Initialization */
	STATIC FUNCTION ODCIAGGREGATEINITIALIZE(CTX IN OUT GET_TRANSPOSED_VALUES_OBJ) RETURN NUMBER,

/* Member Method for Iteration */
	MEMBER FUNCTION ODCIAGGREGATEITERATE
	(
		SELF  IN OUT GET_TRANSPOSED_VALUES_OBJ,
		VALUE IN     TIME_SERIES_TYPE
	) RETURN NUMBER,

/* Member Method for Termination */
	MEMBER FUNCTION ODCIAGGREGATETERMINATE
	(
		SELF        IN  GET_TRANSPOSED_VALUES_OBJ,
		RETURNVALUE OUT TRANSPOSED_VALUES_TYPE,
		FLAGS       IN  NUMBER
	) RETURN NUMBER,

/* Member Method for Merging */
	MEMBER FUNCTION ODCIAGGREGATEMERGE
	(
		SELF IN OUT GET_TRANSPOSED_VALUES_OBJ,
		CTX  IN     GET_TRANSPOSED_VALUES_OBJ 
	) RETURN NUMBER
);
/
CREATE OR REPLACE TYPE BODY GET_TRANSPOSED_VALUES_OBJ
IS
/******************************************************************************
   NAME:      GET_TRANSPOSED_VALUES_OBJ 
   PURPOSE:   To perform custom aggregation for commification. Implemented
	      OOP concepts to implement Oracle Data Cartridge interface for
	      Commification and subsequent pipelining.

   REVISIONS: $Revision: 1.1 $
   
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2011-08-22  Rex S. Arul(RSA) 1. Initial Release. Implemented the custom
 		  			      interfaces for custom pipelining.
******************************************************************************/

   /* Static Method for Initialization  */
   STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT GET_TRANSPOSED_VALUES_OBJ )
   RETURN NUMBER
   IS
   BEGIN
		 -- transposedObject, rollupLevel
       ctx := GET_TRANSPOSED_VALUES_OBJ ( TRANSPOSED_VALUES_TYPE(
		  			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
					   )
					 );
       RETURN ODCIConst.Success;
	   EXCEPTION
	  	WHEN OTHERS THEN
			RETURN ODCIConst.Error;
   END;
/******************************************************************************/
	/* Member Method for Aggregation  */
   MEMBER FUNCTION ODCIAggregateIterate(self  IN OUT GET_TRANSPOSED_VALUES_OBJ ,
                                        VALUE IN     TIME_SERIES_TYPE)
   RETURN NUMBER
   IS
	v_SYSDATE	 DATE := SYSDATE;
	v_IDX 		 PLS_INTEGER;
    v_ORDINAL_POSITION PLS_INTEGER := 0;
   BEGIN
    -- If the SERVICE_LOAD value is NOT NULL 	
    IF VALUE.TS_VAL IS NOT NULL THEN
        -- If this is at the level of DAY, WEEK, MONTH, QUARTER or YEAR
        IF VALUE.TS_DATE_INTERVAL_TYPE IN (CONSTANTS.INTERVAL_DAY, CONSTANTS.INTERVAL_WEEK,
                                           CONSTANTS.INTERVAL_MONTH, CONSTANTS.INTERVAL_QUARTER,
                                           CONSTANTS.INTERVAL_YEAR) THEN
            v_RETURN_ARRAY.TIME_SLOT_001 := NVL(v_RETURN_ARRAY.TIME_SLOT_001 , 0)  + VALUE.TS_VAL;
        ELSE
            -- If this is at the level of HOUR, 15-MINUTE, or 30-MINUTE level 
            v_ORDINAL_POSITION := DATE_UTIL.GET_ORDINAL_NUMBER_LOCAL_DATE(VALUE.TS_DATE,  
                                                                          VALUE.TS_DATE_INTERVAL_TYPE);  
																	             																		  
          CASE
            WHEN v_ORDINAL_POSITION = 1    THEN v_RETURN_ARRAY.TIME_SLOT_001 := NVL(v_RETURN_ARRAY.TIME_SLOT_001 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 2    THEN v_RETURN_ARRAY.TIME_SLOT_002 := NVL(v_RETURN_ARRAY.TIME_SLOT_002 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 3    THEN v_RETURN_ARRAY.TIME_SLOT_003 := NVL(v_RETURN_ARRAY.TIME_SLOT_003 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 4    THEN v_RETURN_ARRAY.TIME_SLOT_004 := NVL(v_RETURN_ARRAY.TIME_SLOT_004 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 5    THEN v_RETURN_ARRAY.TIME_SLOT_005 := NVL(v_RETURN_ARRAY.TIME_SLOT_005 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 6    THEN v_RETURN_ARRAY.TIME_SLOT_006 := NVL(v_RETURN_ARRAY.TIME_SLOT_006 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 7    THEN v_RETURN_ARRAY.TIME_SLOT_007 := NVL(v_RETURN_ARRAY.TIME_SLOT_007 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 8    THEN v_RETURN_ARRAY.TIME_SLOT_008 := NVL(v_RETURN_ARRAY.TIME_SLOT_008 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 9    THEN v_RETURN_ARRAY.TIME_SLOT_009 := NVL(v_RETURN_ARRAY.TIME_SLOT_009 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 10   THEN v_RETURN_ARRAY.TIME_SLOT_010 := NVL(v_RETURN_ARRAY.TIME_SLOT_010 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 11   THEN v_RETURN_ARRAY.TIME_SLOT_011 := NVL(v_RETURN_ARRAY.TIME_SLOT_011 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 12   THEN v_RETURN_ARRAY.TIME_SLOT_012 := NVL(v_RETURN_ARRAY.TIME_SLOT_012 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 13   THEN v_RETURN_ARRAY.TIME_SLOT_013 := NVL(v_RETURN_ARRAY.TIME_SLOT_013 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 14   THEN v_RETURN_ARRAY.TIME_SLOT_014 := NVL(v_RETURN_ARRAY.TIME_SLOT_014 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 15   THEN v_RETURN_ARRAY.TIME_SLOT_015 := NVL(v_RETURN_ARRAY.TIME_SLOT_015 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 16   THEN v_RETURN_ARRAY.TIME_SLOT_016 := NVL(v_RETURN_ARRAY.TIME_SLOT_016 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 17   THEN v_RETURN_ARRAY.TIME_SLOT_017 := NVL(v_RETURN_ARRAY.TIME_SLOT_017 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 18   THEN v_RETURN_ARRAY.TIME_SLOT_018 := NVL(v_RETURN_ARRAY.TIME_SLOT_018 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 19   THEN v_RETURN_ARRAY.TIME_SLOT_019 := NVL(v_RETURN_ARRAY.TIME_SLOT_019 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 20   THEN v_RETURN_ARRAY.TIME_SLOT_020 := NVL(v_RETURN_ARRAY.TIME_SLOT_020 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 21   THEN v_RETURN_ARRAY.TIME_SLOT_021 := NVL(v_RETURN_ARRAY.TIME_SLOT_021 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 22   THEN v_RETURN_ARRAY.TIME_SLOT_022 := NVL(v_RETURN_ARRAY.TIME_SLOT_022 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 23   THEN v_RETURN_ARRAY.TIME_SLOT_023 := NVL(v_RETURN_ARRAY.TIME_SLOT_023 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 24   THEN v_RETURN_ARRAY.TIME_SLOT_024 := NVL(v_RETURN_ARRAY.TIME_SLOT_024 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 25   THEN v_RETURN_ARRAY.TIME_SLOT_025 := NVL(v_RETURN_ARRAY.TIME_SLOT_025 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 26   THEN v_RETURN_ARRAY.TIME_SLOT_026 := NVL(v_RETURN_ARRAY.TIME_SLOT_026 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 27   THEN v_RETURN_ARRAY.TIME_SLOT_027 := NVL(v_RETURN_ARRAY.TIME_SLOT_027 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 28   THEN v_RETURN_ARRAY.TIME_SLOT_028 := NVL(v_RETURN_ARRAY.TIME_SLOT_028 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 29   THEN v_RETURN_ARRAY.TIME_SLOT_029 := NVL(v_RETURN_ARRAY.TIME_SLOT_029 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 30   THEN v_RETURN_ARRAY.TIME_SLOT_030 := NVL(v_RETURN_ARRAY.TIME_SLOT_030 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 31   THEN v_RETURN_ARRAY.TIME_SLOT_031 := NVL(v_RETURN_ARRAY.TIME_SLOT_031 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 32   THEN v_RETURN_ARRAY.TIME_SLOT_032 := NVL(v_RETURN_ARRAY.TIME_SLOT_032 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 33   THEN v_RETURN_ARRAY.TIME_SLOT_033 := NVL(v_RETURN_ARRAY.TIME_SLOT_033 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 34   THEN v_RETURN_ARRAY.TIME_SLOT_034 := NVL(v_RETURN_ARRAY.TIME_SLOT_034 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 35   THEN v_RETURN_ARRAY.TIME_SLOT_035 := NVL(v_RETURN_ARRAY.TIME_SLOT_035 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 36   THEN v_RETURN_ARRAY.TIME_SLOT_036 := NVL(v_RETURN_ARRAY.TIME_SLOT_036 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 37   THEN v_RETURN_ARRAY.TIME_SLOT_037 := NVL(v_RETURN_ARRAY.TIME_SLOT_037 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 38   THEN v_RETURN_ARRAY.TIME_SLOT_038 := NVL(v_RETURN_ARRAY.TIME_SLOT_038 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 39   THEN v_RETURN_ARRAY.TIME_SLOT_039 := NVL(v_RETURN_ARRAY.TIME_SLOT_039 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 40   THEN v_RETURN_ARRAY.TIME_SLOT_040 := NVL(v_RETURN_ARRAY.TIME_SLOT_040 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 41   THEN v_RETURN_ARRAY.TIME_SLOT_041 := NVL(v_RETURN_ARRAY.TIME_SLOT_041 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 42   THEN v_RETURN_ARRAY.TIME_SLOT_042 := NVL(v_RETURN_ARRAY.TIME_SLOT_042 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 43   THEN v_RETURN_ARRAY.TIME_SLOT_043 := NVL(v_RETURN_ARRAY.TIME_SLOT_043 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 44   THEN v_RETURN_ARRAY.TIME_SLOT_044 := NVL(v_RETURN_ARRAY.TIME_SLOT_044 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 45   THEN v_RETURN_ARRAY.TIME_SLOT_045 := NVL(v_RETURN_ARRAY.TIME_SLOT_045 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 46   THEN v_RETURN_ARRAY.TIME_SLOT_046 := NVL(v_RETURN_ARRAY.TIME_SLOT_046 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 47   THEN v_RETURN_ARRAY.TIME_SLOT_047 := NVL(v_RETURN_ARRAY.TIME_SLOT_047 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 48   THEN v_RETURN_ARRAY.TIME_SLOT_048 := NVL(v_RETURN_ARRAY.TIME_SLOT_048 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 49   THEN v_RETURN_ARRAY.TIME_SLOT_049 := NVL(v_RETURN_ARRAY.TIME_SLOT_049 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 50   THEN v_RETURN_ARRAY.TIME_SLOT_050 := NVL(v_RETURN_ARRAY.TIME_SLOT_050 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 51   THEN v_RETURN_ARRAY.TIME_SLOT_051 := NVL(v_RETURN_ARRAY.TIME_SLOT_051 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 52   THEN v_RETURN_ARRAY.TIME_SLOT_052 := NVL(v_RETURN_ARRAY.TIME_SLOT_052 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 53   THEN v_RETURN_ARRAY.TIME_SLOT_053 := NVL(v_RETURN_ARRAY.TIME_SLOT_053 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 54   THEN v_RETURN_ARRAY.TIME_SLOT_054 := NVL(v_RETURN_ARRAY.TIME_SLOT_054 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 55   THEN v_RETURN_ARRAY.TIME_SLOT_055 := NVL(v_RETURN_ARRAY.TIME_SLOT_055 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 56   THEN v_RETURN_ARRAY.TIME_SLOT_056 := NVL(v_RETURN_ARRAY.TIME_SLOT_056 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 57   THEN v_RETURN_ARRAY.TIME_SLOT_057 := NVL(v_RETURN_ARRAY.TIME_SLOT_057 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 58   THEN v_RETURN_ARRAY.TIME_SLOT_058 := NVL(v_RETURN_ARRAY.TIME_SLOT_058 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 59   THEN v_RETURN_ARRAY.TIME_SLOT_059 := NVL(v_RETURN_ARRAY.TIME_SLOT_059 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 60   THEN v_RETURN_ARRAY.TIME_SLOT_060 := NVL(v_RETURN_ARRAY.TIME_SLOT_060 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 61   THEN v_RETURN_ARRAY.TIME_SLOT_061 := NVL(v_RETURN_ARRAY.TIME_SLOT_061 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 62   THEN v_RETURN_ARRAY.TIME_SLOT_062 := NVL(v_RETURN_ARRAY.TIME_SLOT_062 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 63   THEN v_RETURN_ARRAY.TIME_SLOT_063 := NVL(v_RETURN_ARRAY.TIME_SLOT_063 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 64   THEN v_RETURN_ARRAY.TIME_SLOT_064 := NVL(v_RETURN_ARRAY.TIME_SLOT_064 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 65   THEN v_RETURN_ARRAY.TIME_SLOT_065 := NVL(v_RETURN_ARRAY.TIME_SLOT_065 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 66   THEN v_RETURN_ARRAY.TIME_SLOT_066 := NVL(v_RETURN_ARRAY.TIME_SLOT_066 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 67   THEN v_RETURN_ARRAY.TIME_SLOT_067 := NVL(v_RETURN_ARRAY.TIME_SLOT_067 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 68   THEN v_RETURN_ARRAY.TIME_SLOT_068 := NVL(v_RETURN_ARRAY.TIME_SLOT_068 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 69   THEN v_RETURN_ARRAY.TIME_SLOT_069 := NVL(v_RETURN_ARRAY.TIME_SLOT_069 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 70   THEN v_RETURN_ARRAY.TIME_SLOT_070 := NVL(v_RETURN_ARRAY.TIME_SLOT_070 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 71   THEN v_RETURN_ARRAY.TIME_SLOT_071 := NVL(v_RETURN_ARRAY.TIME_SLOT_071 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 72   THEN v_RETURN_ARRAY.TIME_SLOT_072 := NVL(v_RETURN_ARRAY.TIME_SLOT_072 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 73   THEN v_RETURN_ARRAY.TIME_SLOT_073 := NVL(v_RETURN_ARRAY.TIME_SLOT_073 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 74   THEN v_RETURN_ARRAY.TIME_SLOT_074 := NVL(v_RETURN_ARRAY.TIME_SLOT_074 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 75   THEN v_RETURN_ARRAY.TIME_SLOT_075 := NVL(v_RETURN_ARRAY.TIME_SLOT_075 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 76   THEN v_RETURN_ARRAY.TIME_SLOT_076 := NVL(v_RETURN_ARRAY.TIME_SLOT_076 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 77   THEN v_RETURN_ARRAY.TIME_SLOT_077 := NVL(v_RETURN_ARRAY.TIME_SLOT_077 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 78   THEN v_RETURN_ARRAY.TIME_SLOT_078 := NVL(v_RETURN_ARRAY.TIME_SLOT_078 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 79   THEN v_RETURN_ARRAY.TIME_SLOT_079 := NVL(v_RETURN_ARRAY.TIME_SLOT_079 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 80   THEN v_RETURN_ARRAY.TIME_SLOT_080 := NVL(v_RETURN_ARRAY.TIME_SLOT_080 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 81   THEN v_RETURN_ARRAY.TIME_SLOT_081 := NVL(v_RETURN_ARRAY.TIME_SLOT_081 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 82   THEN v_RETURN_ARRAY.TIME_SLOT_082 := NVL(v_RETURN_ARRAY.TIME_SLOT_082 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 83   THEN v_RETURN_ARRAY.TIME_SLOT_083 := NVL(v_RETURN_ARRAY.TIME_SLOT_083 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 84   THEN v_RETURN_ARRAY.TIME_SLOT_084 := NVL(v_RETURN_ARRAY.TIME_SLOT_084 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 85   THEN v_RETURN_ARRAY.TIME_SLOT_085 := NVL(v_RETURN_ARRAY.TIME_SLOT_085 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 86   THEN v_RETURN_ARRAY.TIME_SLOT_086 := NVL(v_RETURN_ARRAY.TIME_SLOT_086 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 87   THEN v_RETURN_ARRAY.TIME_SLOT_087 := NVL(v_RETURN_ARRAY.TIME_SLOT_087 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 88   THEN v_RETURN_ARRAY.TIME_SLOT_088 := NVL(v_RETURN_ARRAY.TIME_SLOT_088 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 89   THEN v_RETURN_ARRAY.TIME_SLOT_089 := NVL(v_RETURN_ARRAY.TIME_SLOT_089 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 90   THEN v_RETURN_ARRAY.TIME_SLOT_090 := NVL(v_RETURN_ARRAY.TIME_SLOT_090 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 91   THEN v_RETURN_ARRAY.TIME_SLOT_091 := NVL(v_RETURN_ARRAY.TIME_SLOT_091 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 92   THEN v_RETURN_ARRAY.TIME_SLOT_092 := NVL(v_RETURN_ARRAY.TIME_SLOT_092 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 93   THEN v_RETURN_ARRAY.TIME_SLOT_093 := NVL(v_RETURN_ARRAY.TIME_SLOT_093 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 94   THEN v_RETURN_ARRAY.TIME_SLOT_094 := NVL(v_RETURN_ARRAY.TIME_SLOT_094 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 95   THEN v_RETURN_ARRAY.TIME_SLOT_095 := NVL(v_RETURN_ARRAY.TIME_SLOT_095 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 96   THEN v_RETURN_ARRAY.TIME_SLOT_096 := NVL(v_RETURN_ARRAY.TIME_SLOT_096 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 97   THEN v_RETURN_ARRAY.TIME_SLOT_097 := NVL(v_RETURN_ARRAY.TIME_SLOT_097 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 98   THEN v_RETURN_ARRAY.TIME_SLOT_098 := NVL(v_RETURN_ARRAY.TIME_SLOT_098 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 99   THEN v_RETURN_ARRAY.TIME_SLOT_099 := NVL(v_RETURN_ARRAY.TIME_SLOT_099 , 0)  + VALUE.TS_VAL;
            WHEN v_ORDINAL_POSITION = 100  THEN v_RETURN_ARRAY.TIME_SLOT_100 := NVL(v_RETURN_ARRAY.TIME_SLOT_100 , 0)  + VALUE.TS_VAL;
            END CASE;
          END IF; 
       END IF;
       RETURN ODCIConst.Success;
       EXCEPTION
         WHEN OTHERS THEN
           RETURN ODCIConst.Error;
   END;
/******************************************************************************/
   /* Member Method to Terminate the Aggregation */
   MEMBER FUNCTION ODCIAggregateTerminate(self IN GET_TRANSPOSED_VALUES_OBJ,
                                          returnValue OUT TRANSPOSED_VALUES_TYPE,
                                          flags IN NUMBER)
   RETURN NUMBER
   IS      
   BEGIN
	   returnValue := v_RETURN_ARRAY;	   
     RETURN ODCIConst.Success;
	 EXCEPTION
	  	WHEN OTHERS THEN
			RETURN ODCIConst.Error;
   END;
/******************************************************************************/
   /* Member Method to Merge the Aggregates */
   MEMBER FUNCTION ODCIAggregateMerge(self IN OUT GET_TRANSPOSED_VALUES_OBJ ,
                                      ctx  IN GET_TRANSPOSED_VALUES_OBJ )
   RETURN NUMBER
   IS
   BEGIN
      CASE 
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_001 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_001 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_001, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_001;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_002 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_002 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_002, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_002;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_003 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_003 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_003, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_003;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_004 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_004 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_004, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_004;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_005 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_005 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_005, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_005;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_006 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_006 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_006, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_006;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_007 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_007 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_007, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_007;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_008 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_008 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_008, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_008;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_009 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_009 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_009, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_009;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_010 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_010 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_010, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_010;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_011 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_011 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_011, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_011;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_012 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_012 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_012, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_012;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_013 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_013 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_013, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_013;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_014 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_014 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_014, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_014;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_015 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_015 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_015, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_015;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_016 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_016 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_016, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_016;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_017 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_017 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_017, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_017;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_018 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_018 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_018, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_018;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_019 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_019 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_019, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_019;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_020 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_020 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_020, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_020;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_021 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_021 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_021, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_021;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_022 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_022 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_022, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_022;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_023 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_023 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_023, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_023;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_024 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_024 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_024, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_024;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_025 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_025 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_025, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_025;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_026 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_026 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_026, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_026;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_027 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_027 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_027, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_027;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_028 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_028 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_028, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_028;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_029 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_029 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_029, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_029;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_030 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_030 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_030, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_030;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_031 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_031 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_031, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_031;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_032 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_032 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_032, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_032;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_033 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_033 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_033, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_033;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_034 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_034 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_034, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_034;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_035 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_035 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_035, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_035;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_036 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_036 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_036, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_036;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_037 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_037 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_037, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_037;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_038 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_038 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_038, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_038;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_039 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_039 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_039, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_039;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_040 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_040 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_040, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_040;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_041 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_041 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_041, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_041;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_042 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_042 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_042, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_042;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_043 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_043 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_043, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_043;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_044 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_044 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_044, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_044;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_045 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_045 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_045, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_045;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_046 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_046 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_046, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_046;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_047 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_047 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_047, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_047;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_048 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_048 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_048, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_048;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_049 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_049 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_049, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_049;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_050 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_050 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_050, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_050;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_051 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_051 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_051, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_051;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_052 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_052 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_052, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_052;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_053 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_053 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_053, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_053;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_054 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_054 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_054, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_054;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_055 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_055 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_055, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_055;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_056 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_056 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_056, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_056;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_057 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_057 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_057, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_057;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_058 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_058 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_058, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_058;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_059 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_059 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_059, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_059;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_060 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_060 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_060, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_060;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_061 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_061 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_061, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_061;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_062 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_062 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_062, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_062;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_063 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_063 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_063, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_063;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_064 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_064 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_064, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_064;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_065 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_065 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_065, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_065;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_066 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_066 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_066, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_066;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_067 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_067 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_067, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_067;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_068 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_068 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_068, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_068;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_069 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_069 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_069, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_069;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_070 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_070 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_070, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_070;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_071 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_071 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_071, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_071;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_072 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_072 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_072, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_072;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_073 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_073 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_073, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_073;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_074 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_074 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_074, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_074;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_075 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_075 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_075, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_075;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_076 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_076 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_076, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_076;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_077 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_077 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_077, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_077;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_078 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_078 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_078, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_078;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_079 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_079 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_079, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_079;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_080 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_080 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_080, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_080;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_081 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_081 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_081, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_081;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_082 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_082 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_082, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_082;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_083 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_083 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_083, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_083;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_084 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_084 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_084, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_084;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_085 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_085 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_085, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_085;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_086 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_086 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_086, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_086;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_087 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_087 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_087, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_087;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_088 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_088 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_088, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_088;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_089 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_089 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_089, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_089;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_090 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_090 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_090, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_090;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_091 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_091 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_091, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_091;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_092 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_092 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_092, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_092;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_093 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_093 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_093, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_093;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_094 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_094 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_094, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_094;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_095 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_095 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_095, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_095;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_096 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_096 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_096, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_096;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_097 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_097 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_097, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_097;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_098 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_098 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_098, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_098;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_099 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_099 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_099, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_099;
		 WHEN CTX.v_RETURN_ARRAY.TIME_SLOT_100 IS NOT NULL THEN 
			 SELF.v_RETURN_ARRAY.TIME_SLOT_100 := NVL(SELF.v_RETURN_ARRAY.TIME_SLOT_100, 0) + CTX.v_RETURN_ARRAY.TIME_SLOT_100;

	  END CASE;
	  
      RETURN ODCIConst.Success;
	  EXCEPTION
	  	WHEN OTHERS THEN
			RETURN ODCIConst.Error;
   END;
/******************************************************************************/
END;
/
