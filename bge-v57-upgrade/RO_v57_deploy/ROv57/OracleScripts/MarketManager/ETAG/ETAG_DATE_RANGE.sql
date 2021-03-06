CREATE OR REPLACE VIEW ETAG_DATE_RANGE AS
SELECT A.ETAG_ID, NVL(MIN(C.START_DATE),LOW_DATE) "BEGIN_DATE", NVL(MAX(C.END_DATE),HIGH_DATE) "END_DATE"
FROM ETAG A, ETAG_PROFILE B, ETAG_PROFILE_VALUE C
WHERE B.ETAG_ID(+) = A.ETAG_ID
	AND C.PROFILE_KEY_ID(+) = B.PROFILE_KEY_ID
GROUP BY A.ETAG_ID;