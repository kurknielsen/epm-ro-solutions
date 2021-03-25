DECLARE
    -- $Revision $
	PROCEDURE PUT_STATEMENT_TYPE(
		p_STATEMENT_TYPE_NAME IN VARCHAR2,
        p_STATEMENT_DESCRIPTION IN VARCHAR2,
        p_STATEMENT_TYPE_ORDER IN NUMBER,
		p_STATEMENT_TYPE_ID IN NUMBER := 0
		) IS
	v_STATEMENT_TYPE_ID NUMBER;
    v_OID NUMBER;
	BEGIN
		BEGIN
			SELECT STATEMENT_TYPE_ID INTO v_STATEMENT_TYPE_ID FROM STATEMENT_TYPE
			WHERE UPPER(STATEMENT_TYPE_ALIAS) = 'ERCOT '||UPPER(TRIM(p_STATEMENT_DESCRIPTION));
		EXCEPTION
			WHEN OTHERS THEN
				v_STATEMENT_TYPE_ID := p_STATEMENT_TYPE_ID;
		END;
		IO.PUT_STATEMENT_TYPE(v_STATEMENT_TYPE_ID, p_STATEMENT_TYPE_NAME, 'ERCOT '||p_STATEMENT_DESCRIPTION, 'ERCOT '||p_STATEMENT_DESCRIPTION, v_STATEMENT_TYPE_ID, p_STATEMENT_TYPE_ORDER);
	END PUT_STATEMENT_TYPE;

BEGIN
	PUT_STATEMENT_TYPE('Initial','Forecast',1,1);
    -- BZ 17186: change Final before Prelim so we don't try to do duplicate names
    PUT_STATEMENT_TYPE('True-Up','Final',3,3);
    PUT_STATEMENT_TYPE('Final','Preliminary',2,2);
    
    COMMIT;
END;
/
