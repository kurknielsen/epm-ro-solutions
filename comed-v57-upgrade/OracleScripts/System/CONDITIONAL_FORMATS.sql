--SET SERVEROUTPUT ON SIZE 500000
DECLARE

	-- Use this query to translate formats in the database into lines for this script:
	
/*	
select '    PUT_CONDITIONAL_FORMAT_ITEM('''||replace(a.conditional_format_name,'''','''''')||''', '||B.item_number||
				', '''||replace(b.color_when_formula,'''','''''')||''', '||nvl(to_char(b.foreground_color),'null')||', '||nvl(to_char(b.background_color),'null')||
			case when nvl(b.is_underline ,0) <> 0 then
				', '||nvl(b.is_bold,0)||', '||nvl(b.is_italic,0)||', '||nvl(b.is_strike_through,0)||', '||nvl(b.is_underline,0)
			when nvl(b.is_strike_through ,0) <> 0 then
				', '||nvl(b.is_bold,0)||', '||nvl(b.is_italic,0)||', '||nvl(b.is_strike_through,0)
			when nvl(b.is_italic ,0) <> 0 then
				', '||nvl(b.is_bold,0)||', '||nvl(b.is_italic,0)
			when nvl(b.is_bold ,0) <> 0 then
				', '||nvl(b.is_bold,0)
			else
				null
			end || ');'
from conditional_Format a,
	conditional_Format_item b
where a.conditional_Format_id = b.conditional_format_id
	and a.conditional_Format_name like '%' -- update this line to filter which formats to print
order by a.conditional_format_id,
	b.item_number;
*/
	


    PROCEDURE PUT_CONDITIONAL_FORMAT_ITEM
    (
    p_CONDITIONAL_FORMAT_NAME IN VARCHAR2,
    p_ITEM_NUMBER IN NUMBER,
	p_COLOR_WHEN_FORMULA IN VARCHAR,
	p_FOREGROUND_COLOR IN NUMBER,
	p_BACKGROUND_COLOR IN NUMBER,
	p_IS_BOLD IN NUMBER := 0,
	p_IS_ITALIC IN NUMBER := 0,
	p_IS_STRIKE_THROUGH IN NUMBER := 0,
	p_IS_UNDERLINE IN NUMBER := 0
    ) AS
        
    v_FORMAT_ID NUMBER(9) := 0;
    v_STATUS NUMBER(9) := 0;
        
	BEGIN
		
        -- Check for existing CONDITIONAL_FORMAT    
        BEGIN
            SELECT CF.CONDITIONAL_FORMAT_ID
            INTO v_FORMAT_ID
            FROM CONDITIONAL_FORMAT CF
            WHERE UPPER(CF.CONDITIONAL_FORMAT_NAME) = UPPER(LTRIM(RTRIM(p_CONDITIONAL_FORMAT_NAME)));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_FORMAT_ID := 0;
        END;
        
        -- Insert/Update CONDITIONAL_FORMAT 
        BEGIN        
            IO.PUT_CONDITIONAL_FORMAT(v_FORMAT_ID, p_CONDITIONAL_FORMAT_NAME, '?', '?', v_FORMAT_ID, '?');            
            DBMS_OUTPUT.PUT_LINE('UPDATED FORMAT SUCCESSFULLY: ' || p_CONDITIONAL_FORMAT_NAME || '.  FORMAT_ID=' || v_FORMAT_ID);            
        EXCEPTION
		    WHEN OTHERS THEN
			    DBMS_OUTPUT.PUT_LINE('IO.PUT_CONDITIONAL_FORMAT:DID NOT SUCCESSFULLY CREATE ' || p_CONDITIONAL_FORMAT_NAME || '.  STATUS=' || SQLCODE);        
        END;                   
        
        -- Insert/Update CONDITIONAL_FORMAT_ITEM
        IF v_FORMAT_ID > 0 THEN 
            BEGIN
                EM.PUT_CONDITIONAL_FORMAT_ITEM(v_FORMAT_ID, p_ITEM_NUMBER, p_COLOR_WHEN_FORMULA, p_FOREGROUND_COLOR, p_BACKGROUND_COLOR, p_IS_BOLD, p_IS_ITALIC, p_IS_STRIKE_THROUGH, p_IS_UNDERLINE);
                DBMS_OUTPUT.PUT_LINE('UPDATED FORMAT ITEM SUCCESSFULLY: ' || p_CONDITIONAL_FORMAT_NAME || '.  FORMAT_ID=' || v_FORMAT_ID);
            EXCEPTION
		        WHEN OTHERS THEN
			        DBMS_OUTPUT.PUT_LINE('EM.PUT_CONDITIONAL_FORMAT_ITEM:DID NOT SUCCESSFULLY CREATE FORMAT ITEM: ' || p_CONDITIONAL_FORMAT_NAME || '.  STATUS=' || v_STATUS);        
            END;
        ELSE        
            DBMS_OUTPUT.PUT_LINE('DID NOT CALL EM.PUT_CONDITIONAL_FORMAT_ITEM(). FORMAT ID <= 0.');        
        END IF;
    
    END;

BEGIN -- MAIN

    -- This script is only responsible for conditional format objects that are not directly referenced from
    -- configuration (SystemObjects\SystemConfig.xml), but *are* required by the application.

    -- The implicit formats used are referenced only be Java code, and they control formatting in
    -- comparison grids and in summary rows. (Summary row format is not found below because there is a
    -- screen that references it, so it is created by the import of SystemConfig.xml now)

    -- Load CONDITIONAL_FORMATS for COMPARISON GRIDS...
    PUT_CONDITIONAL_FORMAT_ITEM('COMPARE_ROW_DIFF', 1, 'TRUE', -16777216, -64);
    PUT_CONDITIONAL_FORMAT_ITEM('COMPARE_ROW_MISS', 1, 'TRUE', -16777216, -3158065);
    PUT_CONDITIONAL_FORMAT_ITEM('COMPARE_COL_MISS', 1, 'TRUE', -16777216, -1644883);
    PUT_CONDITIONAL_FORMAT_ITEM('COMPARE_COL_DIFF', 1, 'TRUE', -16777216, -8000, 1);

   COMMIT;
END;
/
