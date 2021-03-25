CREATE OR REPLACE FUNCTION DECODE_DATE
	(
	p_NUMBER IN NUMBER
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer a date derived from an encoded integer.
--c ENCODE_DATE()
--c	RETURN ROUND((p_DATE - TO_DATE('1-JAN-2000','DD-MON-YYYY')) / (3600 / 86400));

BEGIN

	RETURN TO_DATE('1-JAN-2000','DD-MON-YYYY') + (p_NUMBER * (3600 / 86400));
	
END DECODE_DATE;
/

