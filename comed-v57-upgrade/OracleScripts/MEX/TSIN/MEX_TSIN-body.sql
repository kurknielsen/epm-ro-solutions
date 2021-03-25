CREATE OR REPLACE PACKAGE BODY MEX_TSIN IS
g_DATE_FORMAT CONSTANT CHAR(10) := 'mm/dd/yyyy';
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE TRUNCATE_TABLE
(
    p_TABLENAME IN VARCHAR2,
    p_STATUS    OUT NUMBER,
    p_MESSAGE   OUT VARCHAR
) AS

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || p_TABLENAME;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.TRUNCATE_TABLE: ' || SQLERRM;
    
END TRUNCATE_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CA_REGISTRY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW	 TSIN_CA_REGISTRY%ROWTYPE;
    v_LINES  PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS   PARSE_UTIL.STRING_TABLE;
    v_IDX    BINARY_INTEGER;

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;
	TRUNCATE_TABLE('TSIN_CA_REGISTRY', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;
    
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
	
        v_ROW.Tagging_Entity_ID := TO_NUMBER(v_COLS(1));
        v_ROW.Tag_Code          := v_COLS(2);
        v_ROW.Entity_Name       := v_COLS(3);
        v_ROW.Contact24         := v_COLS(4);
        v_ROW.Phone24           := v_COLS(5);
        v_ROW.Fax               := v_COLS(6);
        v_ROW.Agent_URL         := v_COLS(7);
        v_ROW.Authority_URL     := v_COLS(8);
        v_ROW.Approval_URL      := v_COLS(9);
        v_ROW.Forward_URL       := v_COLS(10);
        v_ROW.Entity_Code       := v_COLS(11);
        v_ROW.Tag_Code_Type     := v_COLS(12);
    
        IF v_COLS(13) IS NOT NULL THEN
            v_ROW.NERC_ID := TO_NUMBER(v_COLS(13));
        END IF;
    
        IF v_COLS(14) IS NOT NULL THEN
            v_ROW.Begin_Date := TO_DATE(v_COLS(14), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(15) IS NOT NULL THEN
            v_ROW.End_Date := TO_DATE(v_COLS(15), g_DATE_FORMAT);
        END IF;
    
        v_ROW.SC_Code              := v_COLS(16);
        v_ROW.Region               := v_COLS(17);
        v_ROW.Zero_NHMBAM_Flag     := v_COLS(18);
        v_ROW.ALT1_Desc            := v_COLS(19);
        v_ROW.ALT1_Phone           := v_COLS(20);
        v_ROW.ALT2_Desc            := v_COLS(21);
        v_ROW.ALT2_Phone           := v_COLS(22);
        v_ROW.ALT3_Desc            := v_COLS(23);
        v_ROW.ALT3_Phone           := v_COLS(24);
        v_ROW.Market_Operator_Flag := v_COLS(25);
        v_ROW.Pseudo_CA            := v_COLS(26);
    
        INSERT INTO TSIN_CA_REGISTRY VALUES v_ROW;
    
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_CA_REGISTRY: ' || SQLERRM;
    
END PARSE_CA_REGISTRY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_PSE_REGISTRY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_PSE_REGISTRY%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_PSE_REGISTRY', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN
        RETURN;
    END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.Tagging_Entity_ID := TO_NUMBER(v_COLS(1));
        v_ROW.Tag_Code          := v_COLS(2);
        v_ROW.Entity_Name       := v_COLS(3);
        v_ROW.Contact24         := v_COLS(4);
        v_ROW.Phone24           := v_COLS(5);
        v_ROW.Fax               := v_COLS(6);
        v_ROW.Agent_URL         := v_COLS(7);
        v_ROW.Authority_URL     := v_COLS(8);
        v_ROW.Approval_URL      := v_COLS(9);
        v_ROW.Forward_URL       := v_COLS(10);
        v_ROW.Entity_Code       := v_COLS(11);
        v_ROW.Tag_Code_Type     := v_COLS(12);
    
        IF v_COLS(13) IS NOT NULL THEN
            v_ROW.NERC_ID := TO_NUMBER(v_COLS(13));
        END IF;
    
        IF v_COLS(14) IS NOT NULL THEN
            v_ROW.Begin_Date := TO_DATE(v_COLS(14), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(15) IS NOT NULL THEN
            v_ROW.End_Date := TO_DATE(v_COLS(15), g_DATE_FORMAT);
        END IF;
    
        v_ROW.SC_Code              := v_COLS(16);
        v_ROW.Region               := v_COLS(17);
        v_ROW.Zero_NHMBAM_Flag     := v_COLS(18);
        v_ROW.ALT1_Desc            := v_COLS(19);
        v_ROW.ALT1_Phone           := v_COLS(20);
        v_ROW.ALT2_Desc            := v_COLS(21);
        v_ROW.ALT2_Phone           := v_COLS(22);
        v_ROW.ALT3_Desc            := v_COLS(23);
        v_ROW.ALT3_Phone           := v_COLS(24);
        v_ROW.Market_Operator_Flag := v_COLS(25);
        v_ROW.Pseudo_CA            := v_COLS(26);
    
        INSERT INTO TSIN_PSE_REGISTRY VALUES v_ROW;
    
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_PSE_REGISTRY: ' || SQLERRM;
    
END PARSE_PSE_REGISTRY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ENTITY_REGISTRY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_ENTITY_REGISTRY%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
	v_LINE  VARCHAR(32767);

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_ENTITY_REGISTRY', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    	
		v_LINE := v_LINES(v_IDX);
        v_ROW.Record_ID := TO_NUMBER(v_COLS(1));
    
        IF v_COLS(2) IS NOT NULL THEN
            v_ROW.NERC_ID := TO_NUMBER(v_COLS(2));
        END IF;
    
        v_ROW.Duns := v_COLS(3);    
    
        v_ROW.Entity_Code      := v_COLS(4);
        v_ROW.Entity_Type      := v_COLS(5);
        v_ROW.Entity_Name      := v_COLS(6);
        v_ROW.Address_Line_One := v_COLS(7);
        v_ROW.Address_Line_Two := v_COLS(8);
        v_ROW.City             := v_COLS(9);
        v_ROW.State            := v_COLS(10);
        v_ROW.Zip_Code         := v_COLS(11);
        v_ROW.Country          := v_COLS(12);
        v_ROW.Prim_Contact     := v_COLS(13);
        v_ROW.Prim_Phone       := v_COLS(14);
        v_ROW.Prim_Fax         := v_COLS(15);
        v_ROW.strPrimaryEmail  := v_COLS(16);
        v_ROW.Admin_Contact    := v_COLS(17);
        v_ROW.Admin_Phone      := v_COLS(18);
        v_ROW.Admin_Fax        := v_COLS(19);
        v_ROW.Admin_Email      := v_COLS(20);
        v_ROW.Entity_URL       := v_COLS(21);
    
        IF v_COLS(22) IS NOT NULL THEN
            v_ROW.Begin_Date := TO_DATE(v_COLS(22), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(23) IS NOT NULL THEN
            v_ROW.End_Date := TO_DATE(v_COLS(23), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(24) IS NOT NULL THEN
            v_ROW.Initial_Date := TO_DATE(v_COLS(24), g_DATE_FORMAT);
        END IF;
    
        INSERT INTO TSIN_ENTITY_REGISTRY VALUES v_ROW;
    
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error AT:' || v_LINE;
        --p_MESSAGE := 'Error in MEX_TSIN.PARSE_ENTITY_REGISTRY: ' || SQLERRM;
    
END PARSE_ENTITY_REGISTRY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SC_REGISTRY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_SC_REGISTRY%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_SC_REGISTRY', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.Tagging_Entity_ID := TO_NUMBER(v_COLS(1));
        v_ROW.Tag_Code          := v_COLS(2);
        v_ROW.Entity_Name       := v_COLS(3);
        v_ROW.Contact24         := v_COLS(4);
        v_ROW.Phone24           := v_COLS(5);
        v_ROW.Fax               := v_COLS(6);
        v_ROW.Agent_URL         := v_COLS(7);
        v_ROW.Authority_URL     := v_COLS(8);
        v_ROW.Approval_URL      := v_COLS(9);
        v_ROW.Forward_URL       := v_COLS(10);
        v_ROW.Entity_Code       := v_COLS(11);
        v_ROW.Tag_Code_Type     := v_COLS(12);
    
        IF v_COLS(13) IS NOT NULL THEN
            v_ROW.NERC_ID := TO_NUMBER(v_COLS(13));
        END IF;
    
        IF v_COLS(14) IS NOT NULL THEN
            v_ROW.Begin_Date := TO_DATE(v_COLS(14), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(15) IS NOT NULL THEN
            v_ROW.End_Date := TO_DATE(v_COLS(15), g_DATE_FORMAT);
        END IF;
    
        v_ROW.SC_Code              := v_COLS(16);
        v_ROW.Region               := v_COLS(17);
        v_ROW.Zero_NHMBAM_Flag     := v_COLS(18);
        v_ROW.ALT1_Desc            := v_COLS(19);
        v_ROW.ALT1_Phone           := v_COLS(20);
        v_ROW.ALT2_Desc            := v_COLS(21);
        v_ROW.ALT2_Phone           := v_COLS(22);
        v_ROW.ALT3_Desc            := v_COLS(23);
        v_ROW.ALT3_Phone           := v_COLS(24);
        v_ROW.Market_Operator_Flag := v_COLS(25);
    
        INSERT INTO TSIN_SC_REGISTRY VALUES v_ROW;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_SC_REGISTRY: ' || SQLERRM;
    
END PARSE_SC_REGISTRY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TP_REGISTRY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_TP_REGISTRY%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_TP_REGISTRY', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN
        RETURN;
    END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.Tagging_Entity_ID := TO_NUMBER(v_COLS(1));
        v_ROW.Tag_Code          := v_COLS(2);
        v_ROW.Entity_Name       := v_COLS(3);
        v_ROW.Contact24         := v_COLS(4);
        v_ROW.Phone24           := v_COLS(5);
        v_ROW.Fax               := v_COLS(6);
        v_ROW.Agent_URL         := v_COLS(7);
        v_ROW.Authority_URL     := v_COLS(8);
        v_ROW.Approval_URL      := v_COLS(9);
        v_ROW.Forward_URL       := v_COLS(10);
        v_ROW.Entity_Code       := v_COLS(11);
        v_ROW.Tag_Code_Type     := v_COLS(12);
    
        IF v_COLS(13) IS NOT NULL THEN
            v_ROW.NERC_ID := TO_NUMBER(v_COLS(13));
        END IF;
    
        IF v_COLS(14) IS NOT NULL THEN
            v_ROW.Begin_Date := TO_DATE(v_COLS(14), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(15) IS NOT NULL THEN
            v_ROW.End_Date := TO_DATE(v_COLS(15), g_DATE_FORMAT);
        END IF;
    
        v_ROW.SC_Code              := v_COLS(16);
        v_ROW.Region               := v_COLS(17);
        v_ROW.Zero_NHMBAM_Flag     := v_COLS(18);
        v_ROW.ALT1_Desc            := v_COLS(19);
        v_ROW.ALT1_Phone           := v_COLS(20);
        v_ROW.ALT2_Desc            := v_COLS(21);
        v_ROW.ALT2_Phone           := v_COLS(22);
        v_ROW.ALT3_Desc            := v_COLS(23);
        v_ROW.ALT3_Phone           := v_COLS(24);
        v_ROW.Market_Operator_Flag := v_COLS(25);
    
        INSERT INTO TSIN_TP_REGISTRY VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_TP_REGISTRY: ' || SQLERRM;
    
END PARSE_TP_REGISTRY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_PRODUCT_REGISTRY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_PRODUCT_REGISTRY%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_PRODUCT_REGISTRY', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.productid := TO_NUMBER(v_COLS(1));
        IF v_COLS(2) IS NOT NULL THEN
            v_ROW.producttypeid := TO_NUMBER(v_COLS(2));
        END IF;
    
        v_ROW.code    := v_COLS(3);
        v_ROW.product := v_COLS(4);
    
        INSERT INTO TSIN_PRODUCT_REGISTRY VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_PRODUCT_REGISTRY: ' || SQLERRM;
    
END PARSE_PRODUCT_REGISTRY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_PRODUCT_TYPE
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_PRODUCT_TYPE%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_PRODUCT_TYPE', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.producttypeid          := TO_NUMBER(v_COLS(1));
        v_ROW.producttypedescription := v_COLS(2);
    
        INSERT INTO TSIN_PRODUCT_TYPE VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_PRODUCT_TYPE: ' || SQLERRM;
    
END PARSE_PRODUCT_TYPE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REGISTRY_VERSION
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_REGISTRY_VERSION%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_REGISTRY_VERSION', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN
        RETURN;
    END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.version_id := TO_NUMBER(v_COLS(1));
        v_ROW.version    := v_COLS(2);
    
        IF v_COLS(3) IS NOT NULL THEN
            v_ROW.creation_date := TO_DATE(v_COLS(3), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(4) IS NOT NULL THEN
            v_ROW.effective_date := TO_DATE(v_COLS(4), g_DATE_FORMAT);
        END IF;
    
        INSERT INTO TSIN_REGISTRY_VERSION VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_REGISTRY_VERSION: ' || SQLERRM;
    
END PARSE_REGISTRY_VERSION;
  ----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_POR_POD_ROLE
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_POR_POD_ROLE%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_POR_POD_ROLE', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		
        v_ROW.porpodroleid          := TO_NUMBER(v_COLS(1));
        v_ROW.porpodroledescription := v_COLS(2);
    
        INSERT INTO TSIN_POR_POD_ROLE VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_POR_POD_ROLE: ' || SQLERRM;
    
END PARSE_POR_POD_ROLE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_POR_POD_POINT
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_POR_POD_POINT%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_POR_POD_POINT', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.porpodpointid := TO_NUMBER(v_COLS(1));
    
        IF v_COLS(2) IS NOT NULL THEN
            v_ROW.nerc_id := TO_NUMBER(v_COLS(2));
        END IF;
    
        v_ROW.pointname := v_COLS(3);
    
        IF v_COLS(4) IS NOT NULL THEN
            v_ROW.tp_entity_id := TO_NUMBER(v_COLS(4));
        END IF;
    
        IF v_COLS(5) IS NOT NULL THEN
            v_ROW.ca_entity_id := TO_NUMBER(v_COLS(5));
        END IF;
    
        IF v_COLS(6) IS NOT NULL THEN
            v_ROW.porpodroleid := TO_NUMBER(v_COLS(6));
        END IF;
    
        IF v_COLS(7) IS NOT NULL THEN
            v_ROW.creation_date := TO_DATE(v_COLS(7), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(8) IS NOT NULL THEN
            v_ROW.deactivation_date := TO_DATE(v_COLS(8), g_DATE_FORMAT);
        END IF;
    
        INSERT INTO TSIN_POR_POD_POINT VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_POR_POD_POINT: ' || SQLERRM;
    
END PARSE_POR_POD_POINT;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SOURCE_SINK_ROLE
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_SOURCE_SINK_ROLE%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_SOURCE_SINK_ROLE', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.sourcesinkroleid   := TO_NUMBER(v_COLS(1));
        v_ROW.sourcesinkroledesc := v_COLS(2);
    
        INSERT INTO TSIN_SOURCE_SINK_ROLE VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_SOURCE_SINK_ROLE: ' || SQLERRM;
    
END PARSE_SOURCE_SINK_ROLE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SOURCE_SINK_POINT
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_SOURCE_SINK_POINT%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_SOURCE_SINK_POINT', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.sourcesinkpointid := TO_NUMBER(v_COLS(1));
    
        IF v_COLS(2) IS NOT NULL THEN
            v_ROW.nerc_id := TO_NUMBER(v_COLS(2));
        END IF;
    
        v_ROW.pointname := v_COLS(3);
    
        IF v_COLS(4) IS NOT NULL THEN
            v_ROW.hostcataggingid := TO_NUMBER(v_COLS(4));
        END IF;
    
        IF v_COLS(5) IS NOT NULL THEN
            v_ROW.gpelsetaggingentityid := TO_NUMBER(v_COLS(5));
        END IF;
    
        IF v_COLS(6) IS NOT NULL THEN
            v_ROW.mrdresourceid := TO_NUMBER(v_COLS(6));
        END IF;
    
        IF v_COLS(7) IS NOT NULL THEN
            v_ROW.approvaltaggingentityid := TO_NUMBER(v_COLS(7));
        END IF;
    
        v_ROW.approvaltaggingentitytype := v_COLS(8);
    
        IF v_COLS(9) IS NOT NULL THEN
            v_ROW.sourcesinkroleid := TO_NUMBER(v_COLS(9));
        END IF;
    
        IF v_COLS(10) IS NOT NULL THEN
            v_ROW.creation_date := TO_DATE(v_COLS(10), g_DATE_FORMAT);
        END IF;
    
        IF v_COLS(11) IS NOT NULL THEN
            v_ROW.deactivation_date := TO_DATE(v_COLS(11), g_DATE_FORMAT);
        END IF;
    
        INSERT INTO TSIN_SOURCE_SINK_POINT VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_SOURCE_SINK_POINT: ' || SQLERRM;
    
END PARSE_SOURCE_SINK_POINT;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MRD_RESOURCES
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_MRD_RESOURCES%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_MRD_RESOURCES', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.mrdresourceid := TO_NUMBER(v_COLS(1));
		v_ROW.common_name := NVL(v_COLS(2), ' ');
        v_ROW.resource_name  := v_COLS(3);
        v_ROW.contact24      := v_COLS(4);
        v_ROW.resource_phone := v_COLS(5);
        v_ROW.resource_fax   := v_COLS(6);
    
        INSERT INTO TSIN_MRD_RESOURCES VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_MRD_RESOURCES: ' || SQLERRM;
    
END PARSE_MRD_RESOURCES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MRD_FLOWGATES
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR
) AS

    v_ROW   TSIN_MRD_FLOWGATES%ROWTYPE;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
    TRUNCATE_TABLE('TSIN_MRD_FLOWGATES', p_STATUS, p_MESSAGE); -- does a COMMIT after TRUNCATE
    -- abort on any error 
    IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN RETURN; END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
    
        v_ROW.fgate_no   := TO_NUMBER(v_COLS(1));
        v_ROW.fgate_name := v_COLS(2);
        v_ROW.sec_coord  := v_COLS(3);
        v_ROW.con_areas  := v_COLS(4);
    
        INSERT INTO TSIN_MRD_FLOWGATES VALUES v_ROW;
		
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	COMMIT;
	
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_TSIN.PARSE_MRD_FLOWGATES: ' || SQLERRM;
    
END PARSE_MRD_FLOWGATES;
--------------------------------------------------------------------------------------------- 
PROCEDURE FETCH_TSIN_DATA
(
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
    p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER
) IS

    v_RESPONSE_CLOB CLOB;
    v_TSIN_URL      VARCHAR2(255);
    v_TSIN_FILENAME VARCHAR2(255);
    v_TSIN_BASE_URL SYSTEM_DICTIONARY.VALUE%TYPE;
    v_RESULT        MEX_RESULT;
    v_TABLE_NAME    VARCHAR2(255);

    TYPE TSIN_LIST IS TABLE OF VARCHAR2(30);
    TSIN_FILES TSIN_LIST := TSIN_LIST('CA_REGISTRY',
                                      'PSE_REGISTRY',
                                      'ENTITY_REGISTRY',
                                      'SC_REGISTRY',
                                      'TP_REGISTRY',
                                      'PRODUCT_REGISTRY',
                                      'PRODUCT_TYPE',
                                      'REGISTRY_VERSION',
                                      'POR_POD_POINT',
                                      'POR_POD_ROLE',
                                      'SOURCE_SINK_POINT',
                                      'SOURCE_SINK_ROLE',
                                      'MRD_RESOURCES',
                                      'MRD_FLOWGATES');

BEGIN
    p_STATUS        := MEX_UTIL.g_SUCCESS;
    v_TSIN_BASE_URL := GET_DICTIONARY_VALUE('URL', 0, 'MarketExchange', 'TSIN');

    FOR IDX IN TSIN_FILES.FIRST .. TSIN_FILES.LAST LOOP
    
        --Build the URL based on the file name
        v_TSIN_FILENAME := TSIN_FILES(IDX) || '.CSV';
        v_TSIN_URL      := v_TSIN_BASE_URL || v_TSIN_FILENAME;
        v_TABLE_NAME    := 'TSIN_' || TSIN_FILES(IDX);
    
        p_LOGGER.EXCHANGE_NAME := 'Import ' || v_TSIN_FILENAME;
        p_LOGGER.LOG_INFO('Fetch ' || v_TSIN_FILENAME);
		
        v_RESULT := MEX_SWITCHBOARD.FETCHURL(v_TSIN_URL, p_LOGGER);
        p_STATUS := v_RESULT.STATUS_CODE;
    
        IF v_RESULT.STATUS_CODE <> MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
            v_RESPONSE_CLOB := NULL;
        ELSE
            v_RESPONSE_CLOB := v_RESULT.RESPONSE;
        END IF;
    
        IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
            p_LOGGER.LOG_INFO('Parse ' || v_TSIN_FILENAME);
        
            CASE v_TABLE_NAME
                WHEN 'TSIN_CA_REGISTRY' THEN
                    PARSE_CA_REGISTRY(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_PSE_REGISTRY' THEN
                    PARSE_PSE_REGISTRY(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_ENTITY_REGISTRY' THEN
                    PARSE_ENTITY_REGISTRY(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_SC_REGISTRY' THEN
                    PARSE_SC_REGISTRY(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_TP_REGISTRY' THEN
                    PARSE_TP_REGISTRY(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_PRODUCT_REGISTRY' THEN
                    PARSE_PRODUCT_REGISTRY(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_PRODUCT_TYPE' THEN
                    PARSE_PRODUCT_TYPE(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_REGISTRY_VERSION' THEN
                    PARSE_REGISTRY_VERSION(v_RESPONSE_CLOB, p_STATUS,p_MESSAGE);
                WHEN 'TSIN_POR_POD_POINT' THEN
                    PARSE_POR_POD_POINT(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_POR_POD_ROLE' THEN
                    PARSE_POR_POD_ROLE(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_SOURCE_SINK_POINT' THEN
                    PARSE_SOURCE_SINK_POINT(v_RESPONSE_CLOB,p_STATUS, p_MESSAGE);
                WHEN 'TSIN_SOURCE_SINK_ROLE' THEN
                    PARSE_SOURCE_SINK_ROLE(v_RESPONSE_CLOB,p_STATUS,p_MESSAGE);
                WHEN 'TSIN_MRD_RESOURCES' THEN
                    PARSE_MRD_RESOURCES(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                WHEN 'TSIN_MRD_FLOWGATES' THEN
                    PARSE_MRD_FLOWGATES(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
                ELSE
                    NULL;
            END CASE;
        
			IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN p_LOGGER.LOG_ERROR('Import of ' || v_TSIN_FILENAME || ' failed.' || p_MESSAGE); END IF;
			
        END IF;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        P_STATUS  := SQLCODE;
        P_MESSAGE := 'Error in MEX_TSIN.FETCH_TSIN_DATA: ' || SQLERRM;
END FETCH_TSIN_DATA;
---------------------------------------------------------------------------------------------
END MEX_TSIN;
/
