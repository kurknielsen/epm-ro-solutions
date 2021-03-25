CREATE OR REPLACE TYPE SERVICE_CONSUMPTION_TYPE AS OBJECT
	(
--Revision: $Revision: 1.20 $
	ACCOUNT_SERVICE_ID NUMBER(9),
	PROVIDER_SERVICE_ID NUMBER(9),
	SERVICE_DELIVERY_ID NUMBER(9),
	BEGIN_DATE DATE,
	END_DATE DATE,
	TEMPLATE_ID NUMBER(9),
	PERIOD_ID NUMBER(9),
	BILLED_USAGE NUMBER(16,4)
	);
/

CREATE OR REPLACE TYPE SERVICE_CONSUMPTION_TABLE IS TABLE OF SERVICE_CONSUMPTION_TYPE;
/
