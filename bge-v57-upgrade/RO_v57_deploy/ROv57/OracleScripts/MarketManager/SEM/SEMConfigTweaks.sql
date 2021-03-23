-- Change the currency format from 'Currency' to '#,##0.00'
UPDATE SYSTEM_OBJECT_ATTRIBUTE SOA
SET SOA.ATTRIBUTE_VAL = '#,##0.00'
WHERE SOA.ATTRIBUTE_VAL = 'Currency'
	AND SOA.ATTRIBUTE_ID IN 
		(SELECT ATTRIBUTE_ID 
		 FROM SYSTEM_ATTRIBUTE A 
		 WHERE ATTRIBUTE_NAME = 'Format' 
			AND OBJECT_CATEGORY = 'Column');
