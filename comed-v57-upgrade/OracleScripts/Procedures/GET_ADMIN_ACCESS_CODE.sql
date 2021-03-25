CREATE OR REPLACE PROCEDURE GET_ADMIN_ACCESS_CODE
	(
	p_ADMIN_ACCESS_CODE OUT CHAR
	) AS
--Revision: $Revision: 1.13 $

-- Answer the Admin access code -- S (Select), U (Update), D (Delete) or N (None)

BEGIN

  p_ADMIN_ACCESS_CODE := 'N';
  
  IF CAN_READ('Admin') THEN
     p_ADMIN_ACCESS_CODE := 'S';
  END IF;
  
  IF CAN_WRITE('Admin') THEN
     p_ADMIN_ACCESS_CODE := 'U';
  END IF;

	IF can_delete('Admin') THEN
     p_ADMIN_ACCESS_CODE := 'D';
  END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_ADMIN_ACCESS_CODE := 'N';

END GET_ADMIN_ACCESS_CODE;
/
