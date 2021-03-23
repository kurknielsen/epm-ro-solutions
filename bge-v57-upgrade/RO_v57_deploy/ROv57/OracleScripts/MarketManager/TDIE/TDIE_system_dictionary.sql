DECLARE
    ------------------------------
    PROCEDURE PUT_NEW_DICTIONARY_VALUE
    (
    p_SETTING_NAME IN VARCHAR2,
    p_VALUE IN VARCHAR2,
    p_MODEL_ID IN NUMBER := 0,
    p_MODULE IN VARCHAR2 := '?',
    p_KEY1 IN VARCHAR2 := '?',
    p_KEY2 IN VARCHAR2 := '?',
    p_KEY3 IN VARCHAR2 := '?',
    p_MATCH_CASE IN NUMBER := 1
    ) AS 
    
        v_TEST NUMBER := 0;
    
    BEGIN
    
        IF p_MATCH_CASE = 0 THEN
            SELECT COUNT(1)
            INTO v_TEST
            FROM SYSTEM_DICTIONARY
            WHERE MODEL_ID = p_MODEL_ID
                AND UPPER(MODULE) = UPPER(p_MODULE)
                AND UPPER(KEY1) = UPPER(p_KEY1)
                   AND UPPER(KEY2) = UPPER(p_KEY2)
                AND UPPER(KEY3) = UPPER(p_KEY3)
                AND UPPER(SETTING_NAME) = UPPER(p_SETTING_NAME);
        ELSE
            SELECT COUNT(1)
            INTO v_TEST
            FROM SYSTEM_DICTIONARY
            WHERE MODEL_ID = p_MODEL_ID
                AND MODULE = p_MODULE
                AND KEY1 = p_KEY1
                   AND KEY2 = p_KEY2
                AND KEY3 = p_KEY3
                AND SETTING_NAME = p_SETTING_NAME;
        END IF;
        
        -- ONLY PUT DICTIONARY VALUES IF THERE ISN'T AN EXISTING VALUE
        IF v_TEST <= 0 THEN
            PUT_DICTIONARY_VALUE(p_SETTING_NAME, p_VALUE, p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_MATCH_CASE);
        END IF;
    
    END PUT_NEW_DICTIONARY_VALUE;
    ------------------------------

begin

--------------------------------------------------------------
-------------------Date Constants-----------------------------
--------------------------------------------------------------
PUT_NEW_DICTIONARY_VALUE('TDIE Txn End Date', '2020-12-31', 0, 'MarketExchange', 'TDIE','Settings');

--------------------------------------------------------------
------------------------Date Thresholds-----------------------
--------------------------------------------------------------
PUT_NEW_DICTIONARY_VALUE('Static Data Date Threshold', '1', 0, 'MarketExchange', 'TDIE','Settings');

--------------------------------------------------------------
-------34x Register Type Code Matchings to Op Code------------
--------------------------------------------------------------
PUT_NEW_DICTIONARY_VALUE('50', 'A', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('51', 'A', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('52', 'S', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('53', 'S', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('IS', 'A', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('ES', 'S', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('60', 'A', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('61', 'A', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('62', 'S', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');
PUT_NEW_DICTIONARY_VALUE('63', 'S', 0, 'MarketExchange', 'TDIE','RegisterTypeCodeMapping');

---------------------------------------------------------------------------------------------------------
------------------------Skip Processing Of Losses For Import Of Actual Meter Data -----------------------
---------------------------------------------------------------------------------------------------------
PUT_NEW_DICTIONARY_VALUE('Skip Processing Of Losses For Import Of Actual Meter Data', '0', 0, 'MarketExchange', 'TDIE','Settings');

--------------------------------------------------------------
-------Enduring Solution 300 Schema Version for NI------------
--------------------------------------------------------------
PUT_NEW_DICTIONARY_VALUE('NI Schema Version', '10.00.00', 0, 'MarketExchange', 'TDIE','Harmonisation');
PUT_NEW_DICTIONARY_VALUE('NI Harmonisation Start Date', '2012-05-21', 0, 'MarketExchange', 'TDIE','Harmonisation');

end;
/
