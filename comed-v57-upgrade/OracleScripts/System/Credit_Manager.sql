SET DEFINE OFF	
--Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Type', 0, 'Cash Payment', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Type', 1, 'Letter of Credit', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Type', 2, 'Parent Guarantee', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Type', 3, 'Surety Bond', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Type', 4, 'Unlimited Parent Guarantee'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Provider', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Amount', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Effective Date', 0, '?', 'd ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Security', 'Expiration Date', 0, '?', 'd ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '01 First Name', 1, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '02 Last Name', 2, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '03 Street Address 1', 3, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '04 Street Address 2', 4, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '05 City', 5, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '06 State', 6, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '07 ZIP', 7, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '08 Phone', 8, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Credit Contact Info', '08.1 Email', 9, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '00.1 Account Name', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '00.2 ABA Number', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '01 First Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '02 Last Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '03 Street Address 1', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '04 Street Address 2', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '05 City', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '06 State', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '07 ZIP', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '00.11 Account Number', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Retail Account Info', '08 Phone', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'BPU Cert ID', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'BPU Expiration Date', 0
, '?', 'd ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'PJM Cert ID', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'PJM Expiration Date', 0
, '?', 'd ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'EDI Confirmed Date', 0
, '?', 'd ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'Training', 0, '?', 'k '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Estimated KWh by Rate Class', 'RS', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 6, 'Application~Credit Account Info'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 7, 'Application~Retail Account Info'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 8, 'Application~CIS Account Info'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 9, 'Application~Certification Info'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 1, 'Application~Company Type'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 2, 'Application~Billing Capability'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 3, 'Application~Company ID'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 4, 'Application~Federal Tax ID'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 5, 'Application~D&B Number'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Accreditation Status', '?', 0, 'Active', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Accreditation Status', '?', 1, 'Global (Gas only)'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Accreditation Status', '?', 2, 'Inactive', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Accreditation Status', '?', 3, 'Queue', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Accreditation Status', '?', 4, 'Reinstated (Gas only)'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Accreditation Status', '?', 5, 'Suspended (Gas only)'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Company Type', '?', 0, 'TPS', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Company Type', '?', 1, 'Consultant', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Debt Rating', 'Moody''s', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Debt Rating', 'S&P', 1, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Debt Rating', 'AM Best', 2, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Debt Rating', 'Fitch', 3, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Application Date', '?', 0, '?', 'd ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Billing Capability', '?', 0, 'No Billing', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Accreditation', 'Investment Grade', '?', 0, '?', 'k ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Non Choice LDC Eligibility', '?', 0, '?', 'k '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Rolling Page Certification', '?', 0, '?', 'k '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Logo Availability', '?', 0, '?', 'k ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Federal Tax ID', '?', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'D&B Number', '?', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'State of Incorporation', '?', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Billing Capability', '?', 1, 'TPS Consolidated Billing Only'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Company ID', '?', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Billing Capability', '?', 2, 'Dual Only', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Billing Capability', '?', 3, 'Dual, LDC Consolidated'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Billing Capability', '?', 4, 'Dual, TPS Consolidated'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Billing Capability', '?', 5, 'Dual, LDC and TPS Consolidated'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Application Status', '?', 0, '?', 'x ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Company Name', '?', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, IS_DEFAULT
, IS_HIDDEN ) VALUES ( 
0, 'Credit Checklist', 'Data Entry', 'Data Keys Tilde Delimited', '?', 0, 'Application~Company Name'
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', '00.01 CIS Account Info', 'Account Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '00.1 Account Number', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '00.11 ABA Number', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '01 First Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '02 Last Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '03 Street Address 1', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '04 Street Address 2', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '05 City', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '06 State', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '07 ZIP', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'CIS Account Info', '08 Phone', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '09.1 Reference Name', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '00.11 ABA Number', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '01 First Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '02 Last Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '03 Street Address 1', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '04 Street Address 2', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '05 City', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '06 State', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '07 ZIP', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '00.1 Account Number', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Bank Reference Info', '08 Phone', 0, '?', 'e ', 0
, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Estimated KWh by Rate Class', 'RHS', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Estimated KWh by Rate Class', 'RLM', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Estimated KWh by Rate Class', 'GLP', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'Legal Name', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'Signatory', 0, '?', 'e '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'Signatory Title', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'Sworn Before Name', 0, '?'
, 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Certification Info', 'Signed Date', 0, '?', 'd '
, 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE
, IS_DEFAULT, IS_HIDDEN ) VALUES ( 
0, 'Credit Manager', 'Application', 'Notes', '?', 0, '?', 'e ', 0, 0); 
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
commit;
SET DEFINE ON	
--Reset
