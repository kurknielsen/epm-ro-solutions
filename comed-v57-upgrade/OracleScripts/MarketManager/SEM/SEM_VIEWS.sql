CREATE OR REPLACE VIEW SEM_SETTLEMENT_ENTITY AS
SELECT A.PSE_ID "SETTLEMENT_PSE_ID",
       (SELECT C.PSE_ID
        FROM EXTERNAL_SYSTEM_IDENTIFIER B INNER JOIN PSE C ON (B.ENTITY_ID = C.PSE_ID)
        WHERE B.EXTERNAL_SYSTEM_ID = 1000
        AND   B.ENTITY_DOMAIN_ID   = -160
        AND   B.EXTERNAL_IDENTIFIER = SUBSTR(A.PSE_NAME, INSTR(A.PSE_NAME, ':', 1, 1) + 1, INSTR(A.PSE_NAME, ':',1,  2) - INSTR(A.PSE_NAME, ':',1,  1)-1)
       ) "PARTICIPANT_PSE_ID",
       SUBSTR(A.PSE_NAME, INSTR(A.PSE_NAME, ':', 1, 2) + 1) "MARKET_NAME" 
FROM PSE A
WHERE A.IS_BILLING_ENTITY = 1
/
CREATE OR REPLACE VIEW SEM_CFD_MONTHLY_INVOICE AS
SELECT I.INVOICE_NUMBER,
	I.CONTRACT_ID,
	I.INVOICE_MONTH,
	I.STATEMENT_TYPE_ID,
	I.CONTRACT_TYPE,
	'[' || I.CURRENCY || ']' AS CURRENCY,	
	I.INVOICE_DATE,
	I.PAYMENT_DUE_DATE,
	I.BILLING_ENTITY_NAME,
	I.BILLING_ENTITY_STREET,
	I.BILLING_ENTITY_CITY,
	I.BILLING_ENTITY_STATE_CODE,
	I.BILLING_ENTITY_POSTAL_CODE,
	I.BILLING_ENTITY_COUNTRY_CODE,
	I.BILLING_ENTITY_PHONE_NUMBER,
	I.BILLING_ENTITY_VAT_NUMBER,
	I.COUNTER_PARTY_NAME,
	I.COUNTER_PARTY_STREET,
	I.COUNTER_PARTY_CITY,
	I.COUNTER_PARTY_STATE_CODE,
	I.COUNTER_PARTY_POSTAL_CODE,
	I.COUNTER_PARTY_COUNTRY_CODE,
	I.COUNTER_PARTY_VAT_NUMBER,
	L.PRODUCT_TYPE AS TYPE,
	SUM(L.NET) AS NET,
	SUM(L.VAT_AMOUNT) AS VAT,
	SUM(L.GROSS) AS GROSS
FROM SEM_CFD_INVOICE I,
	SEM_CFD_INVOICE_LINE_ITEM L
WHERE L.SEM_CFD_INVOICE_ID = I.SEM_CFD_INVOICE_ID
GROUP BY I.INVOICE_NUMBER,
	I.CONTRACT_ID,
	I.INVOICE_MONTH,
	I.STATEMENT_TYPE_ID,
	I.CONTRACT_TYPE,
	I.CURRENCY,	
	L.PRODUCT_TYPE,
	I.INVOICE_DATE,
	I.PAYMENT_DUE_DATE,
	I.BILLING_ENTITY_NAME,
	I.BILLING_ENTITY_STREET,
	I.BILLING_ENTITY_CITY,
	I.BILLING_ENTITY_STATE_CODE,
	I.BILLING_ENTITY_POSTAL_CODE,
	I.BILLING_ENTITY_COUNTRY_CODE,
	I.BILLING_ENTITY_PHONE_NUMBER,
	I.BILLING_ENTITY_VAT_NUMBER,
	I.COUNTER_PARTY_NAME,
	I.COUNTER_PARTY_STREET,
	I.COUNTER_PARTY_CITY,
	I.COUNTER_PARTY_STATE_CODE,
	I.COUNTER_PARTY_POSTAL_CODE,
	I.COUNTER_PARTY_COUNTRY_CODE,
	I.COUNTER_PARTY_VAT_NUMBER
ORDER BY I.INVOICE_NUMBER, L.PRODUCT_TYPE
/
CREATE OR REPLACE VIEW SEM_CFD_MONTHLY_INVOICE_DATA AS
SELECT I.INVOICE_NUMBER,
	L.TRADE_NAME,
	I.CONTRACT_ID,
	I.INVOICE_MONTH,
	I.STATEMENT_TYPE_ID,
	I.CONTRACT_TYPE,
	L.PRODUCT_TYPE,
	I.CURRENCY,
	STRIKE_PRICE,
	CONTRACT_LEVEL,
	BD_AVG_SMP,
	BD_DIFF_SP_SMP,
	BD_TRADING_PERIODS ,
	BD_VOLUME,
	NBD_AVG_SMP,
	NBD_DIFF_SP_SMP,
	NBD_TRADING_PERIODS,
	NBD_VOLUME,
	NET,
	VAT_AMOUNT,
	GROSS
FROM SEM_CFD_INVOICE I,
	SEM_CFD_INVOICE_LINE_ITEM L
WHERE L.SEM_CFD_INVOICE_ID = I.SEM_CFD_INVOICE_ID
ORDER BY I.INVOICE_NUMBER,
	I.CONTRACT_ID,
	I.INVOICE_MONTH,
	I.STATEMENT_TYPE_ID,
	I.CONTRACT_TYPE,
	L.PRODUCT_TYPE,
	L.TRADE_NAME
/
CREATE OR REPLACE VIEW SEM_SLMT_VAL_COMPONENTS AS
SELECT C.COMPONENT_ID, C.COMPONENT_NAME, C.COMPONENT_CATEGORY, SL.POSITION
  	FROM COMPONENT C,
		SYSTEM_LABEL SL
	WHERE SL.MODEL_ID = 0
		AND SL.MODULE = 'MarketExchange'
		AND SL.KEY1 = 'SEM'
		AND SL.KEY2 = 'Settlement'
		AND SL.KEY3 = 'Comparison Components'
		AND C.COMPONENT_NAME = SL.VALUE
/
CREATE OR REPLACE FORCE VIEW SEM_DISPATCH_EFFECTIVE_INSTR AS
SELECT X.PSE_ID, 
        X.POD_ID, 
        X.INSTRUCTION_TIME_STAMP, 
        X.INSTRUCTION_CODE AS EFFECTIVE_INSTR,
        X.INSTRUCTION_COMBINATION_CODE AS EFFECTIVE_COMBO_CODE,
        X.DISPATCH_INSTRUCTION AS EFFECTIVE_DISPATCH_INSTR,
        MM_SEM_SHADOW_BILL.GET_INSTRUCTION_INTER(X.PSE_ID, X.POD_ID, X.INSTRUCTION_TIME_STAMP, 
            X.INSTRUCTION_CODE, 
            X.INSTRUCTION_COMBINATION_CODE, 
            X.DISPATCH_INSTRUCTION) AS INSTRUCTION_INTERPRETATION
FROM (SELECT SDI.PSE_ID, 
            SDI.POD_ID, 
            SDI.INSTRUCTION_TIME_STAMP,
            SDI.INSTRUCTION_CODE,
            SDI.INSTRUCTION_COMBINATION_CODE,
            SDI.DISPATCH_INSTRUCTION,
            DENSE_RANK() OVER (PARTITION BY SDI.PSE_ID, 
                                                   SDI.POD_ID, 
                                                   SDI.INSTRUCTION_TIME_STAMP
                                       ORDER BY (CASE WHEN SDI.REPORT_TYPE = 'D+3' THEN 1
                                                  WHEN SDI.REPORT_TYPE = 'D+1' THEN 2
                                              END), SDI.INSTRUCTION_ISSUE_TIME DESC, 
                                           (CASE UPPER(NVL(SDI.INSTRUCTION_CODE,'NULL')) WHEN 'TRIP' THEN 10
                                                WHEN 'FAIL' THEN 20
                                                WHEN 'MWOF' THEN 30
                                                WHEN 'MXON' THEN 40
                                                WHEN 'SYNC' THEN 50
                                                WHEN 'GOOP' THEN (CASE UPPER(NVL(SDI.INSTRUCTION_COMBINATION_CODE,'NULL')) 
                                                                    WHEN 'PGEN' THEN 64 
                                                                    WHEN 'PUMP' THEN 63
                                                                    WHEN 'SCT' THEN 62 
                                                                    WHEN 'SCP' THEN 61 
                                                                    ELSE 60 END)
                                                WHEN 'WIND' THEN 70
                                                WHEN 'MXOF' THEN 80
                                                WHEN 'DESY' THEN 90 
                                                WHEN 'NULL' THEN -1
                                                ELSE 0 END) DESC,
                                       SDI.DISPATCH_INSTRUCTION DESC,
                                       SDI.INSTRUCTION_COMBINATION_CODE /* ORDER BY COMBO CODE ARBITRARILY TO MAKE SURE WE JUST HAVE ONE ROW RANKED #1 
                                                                                   (COMBO CODE IS THE LAST PART OF THE PRIMARY KEY NOT ALREADY REPRESENTED */) AS INSTR_RANK
        FROM SEM_DISPATCH_INSTR SDI) X
WHERE X.INSTR_RANK = 1
/
