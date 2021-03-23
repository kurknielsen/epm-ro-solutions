CREATE OR REPLACE VIEW LOAD_PROFILE_RETAIL_ACT_WRF (
	PROFILE_ID, WRF_ID, WRF_HOUR, COEFF_0, COEFF_1, 
	COEFF_2, TSTAT_0, TSTAT_1, TSTAT_2, PROFILE_SEASON,
	PROFILE_ACCOUNT_REF, PROFILE_WRF_WEATHER_VAR_2,
	PROFILE_TEMPLATE_ID, T_MIN, T_MAX, P_MIN, P_MAX, 
	AS_OF_DATE, WRF_LINE_NBR
	) AS
SELECT B.PROFILE_ID,   
	A.WRF_ID,   
	A.WRF_HOUR,   
	A.COEFF_0,   
	A.COEFF_1,   
	A.COEFF_2,   
	A.TSTAT_0,   
	A.TSTAT_1,   
	A.TSTAT_2,   
	B.PROFILE_SEASON,   
	B.PROFILE_ACCOUNT_REF,   
	F.PARAMETER_NAME,   
	B.PROFILE_TEMPLATE_ID,   
	C.SEGMENT_MIN,   
	C.SEGMENT_MAX,   
	D.PROFILE_NZ_MIN,   
	D.PROFILE_MAX,   
	C.AS_OF_DATE,   
	C.WRF_LINE_NBR   
FROM LOAD_PROFILE_WRF_LINE A,   
	LOAD_PROFILE B,   
	LOAD_PROFILE_WRF C,   
	LOAD_PROFILE_STATISTICS D,   
	LOAD_PROFILE_WRF_WEATHER E,   
	WEATHER_PARAMETER F   
WHERE C.WRF_ID = A.WRF_ID   
	AND C.PROFILE_ID = B.PROFILE_ID   
	AND D.PROFILE_ID = B.PROFILE_ID   
	AND D.AS_OF_DATE = C.AS_OF_DATE   
	AND E.PROFILE_ID = B.PROFILE_ID   
	AND E.VARIABLE_NBR = (SELECT MAX(X.VARIABLE_NBR)   
					FROM LOAD_PROFILE_WRF_WEATHER X   
					WHERE X.PROFILE_ID = E.PROFILE_ID)   
	AND F.PARAMETER_ID = E.PARAMETER_ID   
	AND D.PROFILE_STATUS = 'Production'   
	AND D.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)   
					FROM LOAD_PROFILE_STATISTICS LPS   
					WHERE LPS.PROFILE_ID = D.PROFILE_ID   
					AND LPS.PROFILE_STATUS = 'Production');
