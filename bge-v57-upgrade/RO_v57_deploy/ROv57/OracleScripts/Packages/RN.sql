create or replace package RN is
--Revision $Revision: 1.8 $

  -- Author  : SBHAN
  -- Created : 6/16/2005 2:43:15 PM
  -- Purpose : REMOTE NOTIFICATION

 -- Shared Globals
  NOT_ASSIGNED NUMBER(1) := 0;
  SUCCESS NUMBER(1) := 0;
  -- Private Globals
--g_SITE_ADMINISTRATION SITE_ADMINISTRATION%ROWTYPE;

-------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR;
-------------------------------------------------------------------------------------
  PROCEDURE GET_ALERT_NOTIFICATION
  (
  p_USER_NAME IN VARCHAR2,
  p_ALL_MESSAGES IN VARCHAR2,
  p_SYSDATE OUT DATE,
  p_STATUS OUT NUMBER,
  p_CURSOR IN OUT GA.REFCURSOR
  );
-------------------------------------------------------------------------------------
  /*PROCEDURE GET_SITE_ADMINISTRATION;*/
-------------------------------------------------------------------------------------
  PROCEDURE PUT_ALERT_ACKNOWLEDGED
  (
      P_USER_NAME IN VARCHAR2,
      p_OCCURRENCE_ID IN VARCHAR2,
      p_STATUS OUT NUMBER
  );
-------------------------------------------------------------------------------------
  PROCEDURE PUT_ALERT_EXPIRED
  (
      P_USER_NAME IN VARCHAR2,
      p_OCCURRENCE_ID IN VARCHAR2,
      p_STATUS OUT NUMBER
  );
-------------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_REPORT
  (
  p_MODEL_ID IN NUMBER,
  p_SCHEDULE_TYPE IN NUMBER,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_AS_OF_DATE IN DATE,
  p_TIME_ZONE IN VARCHAR2,
  p_NOTUSED_ID1 IN NUMBER,
  p_NOTUSED_ID2 IN NUMBER,
  p_NOTUSED_ID3 IN NUMBER,
  p_REPORT_NAME IN VARCHAR2,
  p_STATUS OUT NUMBER,
  p_CURSOR IN OUT GA.REFCURSOR
  );
-------------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_REPORT_UPDATE
  	(
  	p_ALERT_ID IN NUMBER,
    p_ALERT_DATE IN DATE,
    p_ALERT_TIME IN VARCHAR2,
    p_ALERT_EXPIRY_DATE IN DATE,
    p_ALERT_EXPIRY_TIME IN VARCHAR2,
    p_ALERT_MESSAGE IN VARCHAR2,
    p_OCCURRENCE_ID IN NUMBER,
    p_PRIORITY IN VARCHAR2,
    p_ROLE_ID IN NUMBER,
    p_STATUS OUT NUMBER
    );
-------------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_REPORT_DELETE
  	(
    p_OCCURRENCE_ID IN NUMBER,
    p_STATUS OUT NUMBER
    );
-------------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_ROLE_LIST
  	(
    p_STATUS OUT NUMBER,
  	p_CURSOR IN OUT GA.REFCURSOR
  	);
-------------------------------------------------------------------------------------
 /* PROCEDURE AUTHENTICATE_USER
	(
	p_USER_NAME IN VARCHAR,
	p_PASSWORD IN VARCHAR,
	p_ATTEMPT_NUM IN NUMBER,
	p_USER_ID OUT NUMBER,
	p_SUPPLIER_ID OUT NUMBER,
	p_SUPPLIER_DIRECTORY OUT VARCHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR,
	p_CURSOR OUT GA.REFCURSOR
  );*/
-------------------------------------------------------------------------------------
  PROCEDURE TEST_CON
  	(
  	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
  	);
-------------------------------------------------------------------------------------
PROCEDURE SEND_ALERT
	(
	p_ALERT_NAME IN VARCHAR2,
	p_ALERT_MESSAGE IN VARCHAR2,
	p_PRIORITY IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_ALERT_DATE IN DATE DEFAULT NULL,
	p_ALERT_EXPIRY_DATE IN DATE DEFAULT NULL,
	p_ROLE_NAME IN VARCHAR2 DEFAULT NULL,
	p_OCCURRENCE_ID IN NUMBER DEFAULT NULL
	);

end RN;
/
create or replace package body RN is

g_HIGH_DATE DATE := HIGH_DATE();
----------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.8 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
  PROCEDURE GET_ALERT_NOTIFICATION_old
  	(
      p_USER_NAME IN VARCHAR2,
      p_ALL_MESSAGES IN VARCHAR2,
      p_SYSDATE OUT DATE,
      p_STATUS OUT NUMBER,
      p_CURSOR IN OUT GA.REFCURSOR
      ) AS
  BEGIN
      p_STATUS := GA.SUCCESS;
      p_SYSDATE := SYSDATE;

      IF p_ALL_MESSAGES = 'A' THEN

        OPEN p_CURSOR FOR
        	SELECT C.ALERT_NAME, B.OCCURRENCE_ID, B.ALERT_ID, B.ALERT_DATE, B.ALERT_EXPIRY, B.ALERT_MESSAGE, B.PRIORITY
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_DATE<=SYSDATE
                   AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL)
    		ORDER BY B.ALERT_DATE, B.PRIORITY;

      ELSE

        OPEN p_CURSOR FOR
        	SELECT C.ALERT_NAME, B.*
        FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.RECIEVED_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_DATE<=SYSDATE
                   AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL)
    		ORDER BY B.ALERT_DATE, B.PRIORITY;

      END IF;

      UPDATE SYSTEM_ALERT_ACKNOWLEDGEMENT A
               SET A.RECIEVED_DATE=SYSDATE
               WHERE UPPER(A.USER_NAME)=UPPER(p_USER_NAME)
                     AND A.RECIEVED_DATE IS NULL
                     AND A.OCCURRENCE_ID IN (SELECT B.OCCURRENCE_ID FROM SYSTEM_ALERT_OCCURRENCE B
                         WHERE B.ALERT_DATE<=SYSDATE
                         AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL));

  EXCEPTION
  	WHEN OTHERS THEN
      	p_STATUS := SQLCODE;

  END GET_ALERT_NOTIFICATION_old;
----------------------------------------------------------------------------------
  PROCEDURE GET_ALERT_NOTIFICATION
  	(
      p_USER_NAME IN VARCHAR2,
      p_ALL_MESSAGES IN VARCHAR2,
      p_SYSDATE OUT DATE,
      p_STATUS OUT NUMBER,
      p_CURSOR IN OUT GA.REFCURSOR
      ) AS
  BEGIN
      p_STATUS := GA.SUCCESS;
      p_SYSDATE := SYSDATE;

      IF p_ALL_MESSAGES = 'A' THEN

        OPEN p_CURSOR FOR

          SELECT concat(count(*),  ' Pending messages') "Status"
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_DATE<=SYSDATE
                   AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL)

          UNION ALL

          	-- Append all unchecked expired messages for popup
           SELECT concat(count(*) , ' Expired messages') "Status"
                      FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
              WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                     AND A.ACKNOWLEDGE_DATE IS NULL
                     AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                     AND B.ALERT_ID=C.ALERT_ID
                     AND B.ALERT_EXPIRY<=SYSDATE
                     AND (A.COMPLETED_DATE<>g_HIGH_DATE OR A.COMPLETED_DATE is Null);



        	-- select all valid messages for popup
/*          SELECT B.OCCURRENCE_ID, B.PRIORITY, B.ALERT_DATE, B.ALERT_EXPIRY, C.ALERT_NAME, B.ALERT_MESSAGE, '0ALL' "Status"
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_DATE<=SYSDATE
                   AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL)

        UNION ALL
        	-- Append all unchecked expired messages for popup
         SELECT B.OCCURRENCE_ID, B.PRIORITY, B.ALERT_DATE, B.ALERT_EXPIRY, C.ALERT_NAME, B.ALERT_MESSAGE, '2Expired' "Status"
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_EXPIRY<=SYSDATE
                   AND A.COMPLETED_DATE<>'12/31/9999'
    		ORDER BY 7, 3, 2;
*/
      ELSIF p_ALL_MESSAGES = 'N' THEN

        OPEN p_CURSOR FOR
        	-- select new messages for popup
        SELECT C.ALERT_NAME, B.ALERT_MESSAGE, B.PRIORITY, B.ALERT_DATE
        FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.RECIEVED_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_DATE<=SYSDATE
                   AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL)

        UNION ALL
        	-- Append all recently expired messages for popup
         SELECT C.ALERT_NAME, B.ALERT_MESSAGE, '5' "PRIORITY", B.ALERT_DATE
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_EXPIRY<=SYSDATE
                   AND ((A.COMPLETED_DATE<>to_date('01/01/9999','mm/dd/yyyy') AND A.COMPLETED_DATE<>g_HIGH_DATE) OR A.Completed_Date is Null)
    		ORDER BY 4;


      ELSIF p_ALL_MESSAGES = 'D' THEN

        OPEN p_CURSOR FOR
        	-- select All vaid messages for main display
          SELECT B.OCCURRENCE_ID, B.PRIORITY, B.ALERT_DATE, B.ALERT_EXPIRY, C.ALERT_NAME, B.ALERT_MESSAGE, '0ALL' "Status"
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_DATE<=SYSDATE
                   AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL)

        UNION ALL
        	-- Append all expired messages for main display
         SELECT B.OCCURRENCE_ID, B.PRIORITY, B.ALERT_DATE, B.ALERT_EXPIRY, C.ALERT_NAME, B.ALERT_MESSAGE, '2Expired' "Status"
                    FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A, SYSTEM_ALERT_OCCURRENCE B, SYSTEM_ALERT C
            WHERE  UPPER(A.USER_NAME) = UPPER(p_USER_NAME)
                   AND A.ACKNOWLEDGE_DATE IS NULL
                   AND A.OCCURRENCE_ID=B.OCCURRENCE_ID
                   AND B.ALERT_ID=C.ALERT_ID
                   AND B.ALERT_EXPIRY<=SYSDATE
                   AND A.COMPLETED_DATE=to_date('01/01/9999','mm/dd/yyyy')
    		ORDER BY 7, 3, 2;


      END IF;

      UPDATE SYSTEM_ALERT_ACKNOWLEDGEMENT A
               SET A.RECIEVED_DATE=SYSDATE
               WHERE UPPER(A.USER_NAME)=UPPER(p_USER_NAME)
                     AND A.RECIEVED_DATE IS NULL
                     AND A.OCCURRENCE_ID IN (SELECT B.OCCURRENCE_ID FROM SYSTEM_ALERT_OCCURRENCE B
                         WHERE B.ALERT_DATE<=SYSDATE
                         AND (B.ALERT_EXPIRY>=SYSDATE OR B.ALERT_EXPIRY IS NULL));

      UPDATE SYSTEM_ALERT_ACKNOWLEDGEMENT A
               SET A.Completed_Date=to_date('01/01/9999','mm/dd/yyyy')
               WHERE UPPER(A.USER_NAME)=UPPER(p_USER_NAME)
                     AND A.ACKNOWLEDGE_DATE IS NULL
                     AND A.COMPLETED_DATE IS NULL
                     AND A.OCCURRENCE_ID IN (SELECT B.OCCURRENCE_ID FROM SYSTEM_ALERT_OCCURRENCE B
                         WHERE B.ALERT_EXPIRY<=SYSDATE);

  EXCEPTION
  	WHEN OTHERS THEN
      	p_STATUS := SQLCODE;

  END GET_ALERT_NOTIFICATION;
----------------------------------------------------------------------------------
  PROCEDURE PUT_ALERT_ACKNOWLEDGED
  	(
      P_USER_NAME IN VARCHAR2,
      p_OCCURRENCE_ID IN VARCHAR2,
      p_STATUS OUT NUMBER
      ) AS
  BEGIN
      p_STATUS := GA.SUCCESS;

      UPDATE SYSTEM_ALERT_ACKNOWLEDGEMENT A
             SET A.ACKNOWLEDGE_DATE=SYSDATE
             WHERE UPPER(A.USER_NAME)=UPPER(p_USER_NAME)
                   AND A.OCCURRENCE_ID= TO_NUMBER(p_OCCURRENCE_ID);
  EXCEPTION
  	WHEN OTHERS THEN
      	p_STATUS := SQLCODE;

  END PUT_ALERT_ACKNOWLEDGED;
----------------------------------------------------------------------------------
  PROCEDURE PUT_ALERT_EXPIRED
  	(
      P_USER_NAME IN VARCHAR2,
      p_OCCURRENCE_ID IN VARCHAR2,
      p_STATUS OUT NUMBER
      ) AS
  BEGIN
      p_STATUS := GA.SUCCESS;

      UPDATE SYSTEM_ALERT_ACKNOWLEDGEMENT A
             SET A.COMPLETED_DATE=g_HIGH_DATE
             WHERE UPPER(A.USER_NAME)=UPPER(p_USER_NAME)
                   AND A.OCCURRENCE_ID= TO_NUMBER(p_OCCURRENCE_ID);
  EXCEPTION
  	WHEN OTHERS THEN
      	p_STATUS := SQLCODE;

  END PUT_ALERT_EXPIRED;
-------------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_REPORT
  	(
  	p_MODEL_ID IN NUMBER,
  	p_SCHEDULE_TYPE IN NUMBER,
  	p_BEGIN_DATE IN DATE,
  	p_END_DATE IN DATE,
  	p_AS_OF_DATE IN DATE,
      p_TIME_ZONE IN VARCHAR2,
      p_NOTUSED_ID1 IN NUMBER,
      p_NOTUSED_ID2 IN NUMBER,
      p_NOTUSED_ID3 IN NUMBER,
  	p_REPORT_NAME IN VARCHAR2,
  	p_STATUS OUT NUMBER,
  	p_CURSOR IN OUT GA.REFCURSOR
  	) AS

  BEGIN

  	p_STATUS := GA.SUCCESS;


  	OPEN p_CURSOR FOR
  	 	SELECT A.ALERT_ID,
             TO_DATE(TO_CHAR(A.ALERT_DATE,'MM/DD/YYYY'),'MM/DD/YYYY') ALERT_DATE,
             TO_CHAR(A.ALERT_DATE,'HH24:MI') ALERT_TIME,
             TO_DATE(TO_CHAR(A.ALERT_EXPIRY,'MM/DD/YYYY'),'MM/DD/YYYY') ALERT_EXPIRY_DATE,
             TO_CHAR(A.ALERT_EXPIRY,'HH24:MI') ALERT_EXPIRY_TIME,
             A.ALERT_MESSAGE,
             A.OCCURRENCE_ID,
             A.PRIORITY,
             A.ROLE_ID,
             B.ROLE_NAME
  	 	FROM SYSTEM_ALERT_OCCURRENCE A, APPLICATION_ROLE B
  	 	WHERE A.ALERT_DATE>=p_BEGIN_DATE
            AND A.ALERT_DATE<p_END_DATE + 1
            AND A.ROLE_ID=B.ROLE_ID(+)
  		ORDER BY A.ALERT_DATE;

  EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

  END ADMIN_CUST_ALERT_REPORT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ALERT_OCCURRENCE
	(
	p_ALERT_ID IN NUMBER,
	p_ALERT_DATE IN DATE,
	p_ALERT_EXPIRY_DATE IN DATE,
	p_ALERT_MESSAGE IN VARCHAR2,
	p_OCCURRENCE_ID IN NUMBER,
	p_PRIORITY IN VARCHAR2,
	p_ROLE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS

	v_OID NUMBER;
	v_OCCURRENCE_ID NUMBER;

	v_ALERT_DATE DATE;
	v_ALERT_EXPIRY_DATE DATE;
BEGIN

	p_STATUS := GA.SUCCESS;

	v_ALERT_DATE := NVL(CASE p_ALERT_DATE WHEN HIGH_DATE THEN SYSDATE ELSE p_ALERT_DATE END, SYSDATE);
	v_ALERT_EXPIRY_DATE := NVL(p_ALERT_EXPIRY_DATE,HIGH_DATE);

	IF p_OCCURRENCE_ID IS NULL OR p_OCCURRENCE_ID = 0 THEN

		SELECT OID.NEXTVAL INTO v_OID FROM DUAL;

		INSERT INTO SYSTEM_ALERT_OCCURRENCE(ALERT_ID,ALERT_DATE,ALERT_EXPIRY,ALERT_MESSAGE,OCCURRENCE_ID,PRIORITY,ROLE_ID)
		VALUES (p_ALERT_ID,v_ALERT_DATE,v_ALERT_EXPIRY_DATE,p_ALERT_MESSAGE,v_OID,p_PRIORITY,p_ROLE_ID);

		v_OCCURRENCE_ID := v_OID;

	ELSE
		UPDATE SYSTEM_ALERT_OCCURRENCE A
		SET A.ALERT_ID=p_ALERT_ID,
			A.ALERT_DATE=v_ALERT_DATE,
			A.ALERT_EXPIRY=v_ALERT_EXPIRY_DATE,
			A.ALERT_MESSAGE=p_ALERT_MESSAGE,
			A.PRIORITY=p_PRIORITY,
			A.ROLE_ID=p_ROLE_ID
		WHERE A.OCCURRENCE_ID=p_OCCURRENCE_ID;

		v_OCCURRENCE_ID := p_OCCURRENCE_ID;
	END IF;


	DELETE FROM SYSTEM_ALERT_ACKNOWLEDGEMENT A
	WHERE A.OCCURRENCE_ID=v_OCCURRENCE_ID;


	--UT.DEBUG_TRACE ('ROLEID="' || TO_CHAR(p_ROLE_ID) || '" OCCID="' || TO_CHAR(v_OCCURRENCE_ID) || '"');

	IF p_ROLE_ID IS NULL OR p_ROLE_ID=0 THEN
		INSERT INTO SYSTEM_ALERT_ACKNOWLEDGEMENT(OCCURRENCE_ID, USER_NAME)
		SELECT DISTINCT v_OCCURRENCE_ID "OCCURRENCE_ID", U.USER_NAME "USER_NAME"
		FROM APPLICATION_USER_ROLE UR, APPLICATION_USER U, SYSTEM_ALERT_ROLE D
		WHERE D.ALERT_ID = p_ALERT_ID
			AND UR.ROLE_ID = D.ROLE_ID
			AND U.USER_ID = UR.USER_ID;
			
	ELSE
		INSERT INTO SYSTEM_ALERT_ACKNOWLEDGEMENT(OCCURRENCE_ID, USER_NAME)
		SELECT v_OCCURRENCE_ID "OCCURRENCE_ID", U.USER_NAME
		FROM APPLICATION_USER_ROLE UR, APPLICATION_USER U
		WHERE UR.ROLE_ID = p_ROLE_ID
			AND U.USER_ID = UR.USER_ID;
	END IF;

END PUT_ALERT_OCCURRENCE;
----------------------------------------------------------------------------------
PROCEDURE ADMIN_CUST_ALERT_REPORT_UPDATE
	(
	p_ALERT_ID IN NUMBER,
	p_ALERT_DATE IN DATE,
	p_ALERT_TIME IN VARCHAR2,
	p_ALERT_EXPIRY_DATE IN DATE,
	p_ALERT_EXPIRY_TIME IN VARCHAR2,
	p_ALERT_MESSAGE IN VARCHAR2,
	p_OCCURRENCE_ID IN NUMBER,
	p_PRIORITY IN VARCHAR2,
	p_ROLE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS

	v_ALERT_DATE_COMBINE DATE := TO_DATE(TO_CHAR(p_ALERT_DATE,'MM/DD/YYYY') || ' ' || p_ALERT_TIME || ':00','MM/DD/YYYY HH24:MI:SS');
	v_ALERT_EXPIRY_DATE_COMBINE DATE := TO_DATE(TO_CHAR(p_ALERT_EXPIRY_DATE,'MM/DD/YYYY') || ' ' || p_ALERT_EXPIRY_TIME || ':00','MM/DD/YYYY HH24:MI:SS');

BEGIN

	PUT_ALERT_OCCURRENCE(p_ALERT_ID, v_ALERT_DATE_COMBINE, v_ALERT_EXPIRY_DATE_COMBINE, p_ALERT_MESSAGE, p_OCCURRENCE_ID, p_PRIORITY, p_ROLE_ID, p_STATUS);

END ADMIN_CUST_ALERT_REPORT_UPDATE;
----------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_REPORT_DELETE
  	(
    p_OCCURRENCE_ID IN NUMBER,
    p_STATUS OUT NUMBER
    ) AS

  BEGIN

  	p_STATUS := GA.SUCCESS;

       DELETE FROM SYSTEM_ALERT_OCCURRENCE A
              WHERE A.OCCURRENCE_ID=p_OCCURRENCE_ID;

--    IF SQL%NOTFOUND THEN
--    END IF;
  EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

  END ADMIN_CUST_ALERT_REPORT_DELETE;
----------------------------------------------------------------------------------
  PROCEDURE ADMIN_CUST_ALERT_ROLE_LIST
  	(
    p_STATUS OUT NUMBER,
  	p_CURSOR IN OUT GA.REFCURSOR
  	) AS

  BEGIN

  	p_STATUS := GA.SUCCESS;

  	OPEN p_CURSOR FOR
  	 	SELECT A.ROLE_NAME, A.ROLE_ID
  	 	FROM APPLICATION_ROLE A
    ORDER BY A.ROLE_NAME;

  EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

  END ADMIN_CUST_ALERT_ROLE_LIST;
----------------------------------------------------------------------------------
/*PROCEDURE AUTHENTICATE_USER
	(
	p_USER_NAME IN VARCHAR,
	p_PASSWORD IN VARCHAR,
	p_ATTEMPT_NUM IN NUMBER,
	p_USER_ID OUT NUMBER,
	p_SUPPLIER_ID OUT NUMBER,
	p_SUPPLIER_DIRECTORY OUT VARCHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR,
	p_CURSOR OUT GA.REFCURSOR
	) AS

v_USER_ACCOUNT USER_ACCOUNT%ROWTYPE;

BEGIN

	p_USER_ID := NOT_ASSIGNED;
	p_SUPPLIER_ID := NOT_ASSIGNED;

	GET_SITE_ADMINISTRATION;

	GET_USER_ACCOUNT(p_USER_NAME, v_USER_ACCOUNT, p_STATUS);
	IF NOT p_STATUS = SUCCESS THEN
		p_MESSAGE := 'USER NOT FOUND';
		OPEN p_CURSOR FOR SELECT NULL FROM DUAL;
		RETURN;
	ELSIF UPPER(v_USER_ACCOUNT.ACCESS_STATUS) = Gws_Shared.DISABLE_ACCESS THEN
		p_STATUS := -2;
		p_MESSAGE := 'USER ACCESS IS DISABLED';
		OPEN p_CURSOR FOR SELECT NULL FROM DUAL;
		RETURN;
	ELSIF NOT v_USER_ACCOUNT.PASSWORD = p_PASSWORD THEN
		IF p_ATTEMPT_NUM >= g_SITE_ADMINISTRATION.PASSWORD_ATTEMPTS THEN
			DISABLE_USER_ACCESS (p_USER_NAME, p_STATUS);
			p_STATUS := -5;
			p_MESSAGE := 'TOO MANY FAILED LOGIN ATTEMPTS';
			OPEN p_CURSOR FOR SELECT NULL FROM DUAL;
		ELSE
			p_STATUS := -4;
			p_MESSAGE := 'INVALID PASSWORD';
			OPEN p_CURSOR FOR SELECT NULL FROM DUAL;
		END IF;
		RETURN;
	ELSIF v_USER_ACCOUNT.CHANGE_PASSWORD <= TRUNC(SYSDATE) THEN
		p_STATUS := -3;
		p_MESSAGE := 'PASSWORD HAS EXPIRED';
		OPEN p_CURSOR FOR SELECT NULL FROM DUAL;
		RETURN;
	END IF;

	p_USER_ID := v_USER_ACCOUNT.USER_ID;
	p_SUPPLIER_ID := v_USER_ACCOUNT.SUPPLIER_ID;
	p_SUPPLIER_DIRECTORY := GET_SUPPLIER_DIRECTORY(v_USER_ACCOUNT.SUPPLIER_ID);
	p_STATUS := SUCCESS;
	p_MESSAGE := 'OK';
	OPEN p_CURSOR FOR	SELECT DOMAIN_NAME, ACCESS_CODE FROM USER_ACCESS WHERE USER_ID = p_USER_ID;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := SQLERRM;
		OPEN p_CURSOR FOR SELECT NULL FROM DUAL;

END AUTHENTICATE_USER;*/
---------------------------------------------------------------------------------------------------
/*PROCEDURE GET_SITE_ADMINISTRATION AS

BEGIN

	SELECT * INTO g_SITE_ADMINISTRATION FROM SITE_ADMINISTRATION;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		g_SITE_ADMINISTRATION.PASSWORD_LENGTH := 0;
		g_SITE_ADMINISTRATION.PASSWORD_LIFETIME := 999;
		g_SITE_ADMINISTRATION.PASSWORD_ATTEMPTS := 99;
		g_SITE_ADMINISTRATION.PASSWORD_CYCLE := 99;
		g_SITE_ADMINISTRATION.AUTHENTICATION_CASE := 0;
	WHEN OTHERS THEN
		RAISE;

END GET_SITE_ADMINISTRATION;*/
---------------------------------------------------------------------------------------------------
/*FUNCTION GET_SUPPLIER_DIRECTORY
	(
	p_SUPPLIER_ID IN NUMBER
	) RETURN VARCHAR IS

v_SUPPLIER_DIRECTORY SUPPLIER.SUPPLIER_DIRECTORY%TYPE;

BEGIN

	SELECT SUPPLIER_DIRECTORY
	INTO v_SUPPLIER_DIRECTORY
	FROM SUPPLIER
	WHERE SUPPLIER_ID = p_SUPPLIER_ID;

    RETURN v_SUPPLIER_DIRECTORY;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
	WHEN OTHERS THEN
		RAISE;

END GET_SUPPLIER_DIRECTORY;*/
---------------------------------------------------------------------------------------------------
  PROCEDURE test_con
  	(
  	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
  	) AS

  BEGIN

  	p_STATUS := GA.SUCCESS;

  	OPEN p_CURSOR FOR
  	 	SELECT A.*
  	 	FROM SYSTEM_ALERT A;

  EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

  END test_con;
-------------------------------------------------------------------------------------
PROCEDURE SEND_ALERT
	(
	p_ALERT_NAME IN VARCHAR2,
	p_ALERT_MESSAGE IN VARCHAR2,
	p_PRIORITY IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_ALERT_DATE IN DATE DEFAULT NULL,
	p_ALERT_EXPIRY_DATE IN DATE DEFAULT NULL,
	p_ROLE_NAME IN VARCHAR2 DEFAULT NULL,
	p_OCCURRENCE_ID IN NUMBER DEFAULT NULL
	) AS
	v_ALERT_ID NUMBER(9);
	v_ROLE_ID NUMBER(9);
BEGIN

	SELECT ALERT_ID	INTO v_ALERT_ID FROM SYSTEM_ALERT WHERE ALERT_NAME = p_ALERT_NAME;

	IF p_ROLE_NAME IS NULL THEN
		v_ROLE_ID := 0;
	ELSE
		SELECT ROLE_ID INTO v_ROLE_ID FROM APPLICATION_ROLE WHERE ROLE_NAME = p_ROLE_NAME;
	END IF;

	PUT_ALERT_OCCURRENCE(v_ALERT_ID, p_ALERT_DATE, p_ALERT_EXPIRY_DATE, p_ALERT_MESSAGE, p_OCCURRENCE_ID, p_PRIORITY, v_ROLE_ID, p_STATUS);

END SEND_ALERT;
-------------------------------------------------------------------------------------
end RN;
/