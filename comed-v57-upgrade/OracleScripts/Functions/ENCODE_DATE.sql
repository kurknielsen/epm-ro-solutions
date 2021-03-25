CREATE OR REPLACE FUNCTION ENCODE_DATE
	(
	p_DATE IN DATE
	)
	RETURN NUMBER IS
--Revision: $Revision: 1.17 $

--c	Answer an encoded date as an integer

BEGIN

	RETURN ROUND((p_DATE - TO_DATE('1-JAN-2000','DD-MON-YYYY')) / (3600 / 86400));

END ENCODE_DATE;
/

