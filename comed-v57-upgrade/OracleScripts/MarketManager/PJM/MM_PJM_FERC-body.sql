create or replace package body MM_PJM_FERC is
g_MARGINAL_LOSS_DATE DATE := DATE '2007-06-01';
g_LOG_ONLY BINARY_INTEGER := 0;
g_LOG_TYPE BINARY_INTEGER := NULL;
g_TRACE_ON BINARY_INTEGER := NULL;
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_FERC_668_RPT_ML
	(
    p_PSE_ID IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	)
AS

v_PSE_TABLE ID_TABLE;
v_STRING_TABLE STRING_TABLE;
v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

	-- determine the external identifiers for the resources selected
    UT.ID_TABLE_FROM_STRING(p_PSE_ID,',', v_PSE_TABLE);

	select string_type(REPLACE(pse.pse_external_identifier,'PJM-'))
	bulk collect into v_STRING_TABLE
	from purchasing_selling_entity pse
	where pse.pse_id in (SELECT X.ID FROM TABLE(CAST(v_PSE_TABLE AS ID_TABLE)) X);

 	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

   open p_CURSOR for
	SELECT day_hour,
    	   (CASE WHEN da_charge_$ > 0 THEN
    	   		da_net_interchange
    		ELSE
    			0
    		END) DA_FERC_ACCT_555_MWH,
    	   (CASE WHEN da_charge_$ > 0  THEN
    	   		da_charge_$
    		ELSE
    			0
    		END) DA_FERC_ACCT_555_$,
    	   (CASE WHEN da_charge_$ < 0  THEN
    	   		da_net_interchange
    		ELSE
    			0
    		END) DA_FERC_ACCT_447_MWH,
    	   (CASE WHEN da_charge_$ < 0 THEN
    	   		da_charge_$
    		ELSE
    			0
    		END) DA_FERC_ACCT_447_$,
    	   (CASE WHEN bal_charge_$ > 0 THEN
    	   		bal_spot_deviation
    		ELSE
    		    0
    		END) RT_FERC_ACCT_555_MWH,
    	   (CASE WHEN bal_charge_$ > 0 THEN
    	   		bal_charge_$
    		ELSE
    			0
    		END) RT_FERC_ACCT_555_$,
            (CASE WHEN bal_charge_$ < 0 THEN
    	   		bal_spot_deviation
    		ELSE
    		    0
    		END) RT_FERC_ACCT_447_MWH,
    	   (CASE WHEN bal_charge_$ < 0 THEN
    	   		bal_charge_$
    		ELSE
    			0
    		END) RT_FERC_ACCT_447_$
    FROM (
        select FROM_CUT(TRUNC(CUT_DATE, 'hh24'),'EDT') day_hour,
        	   sum(DA_NET_INTERCHANGE) da_net_interchange,
        	   sum(DA_CHARGE) da_charge_$,
        	   sum(BAL_SPOT_PURCHASE_DEV) bal_spot_deviation,
        	   sum(BAL_CHARGE) bal_charge_$
         from pjm_spot_mkt_summary
--		 where org_id in (12008,10713)
		 where org_id in (SELECT X.STRING_VAL FROM TABLE(CAST(v_STRING_TABLE as STRING_TABLE)) X)
		   and cut_date between v_BEGIN_DATE and v_END_DATE
        GROUP BY FROM_CUT(TRUNC(CUT_DATE, 'hh24'),'EDT')
        ORDER BY FROM_CUT(TRUNC(CUT_DATE, 'hh24'),'EDT')
        );

EXCEPTION
	WHEN INSUFFICIENT_PRIVILEGES THEN
		p_STATUS := GA.INSUFFICIENT_PRIVILEGES;
		RETURN;
	WHEN OTHERS THEN
		p_STATUS := GA.GENERAL_EXCEPTION;
		RAISE;
END GET_FERC_668_RPT_ML;
------------------------------------------------------------------------------------------
-- FERC 668 report data
PROCEDURE GET_FERC_668_RPT
	(
    p_PSE_ID IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	)
AS

v_PSE_TABLE ID_TABLE;
v_STRING_TABLE STRING_TABLE;
v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

    IF p_BEGIN_DATE >= g_MARGINAL_LOSS_DATE THEN
        GET_FERC_668_RPT_ML(p_PSE_ID,p_BEGIN_DATE,p_END_DATE,p_TIME_ZONE,p_STATUS, p_CURSOR);
    ELSE

    	-- determine the external identifiers for the resources selected
        UT.ID_TABLE_FROM_STRING(p_PSE_ID,',', v_PSE_TABLE);

    	select string_type(REPLACE(pse.pse_external_identifier,'PJM-'))
    	bulk collect into v_STRING_TABLE
    	from purchasing_selling_entity pse
    	where pse.pse_id in (SELECT X.ID FROM TABLE(CAST(v_PSE_TABLE AS ID_TABLE)) X);

     	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

       open p_CURSOR for
    	SELECT day,
        	   hour,
        	   (CASE WHEN da_purch > da_sale THEN
        	   		da_purch - da_sale
        		ELSE
        			CASE WHEN da_purch = da_sale THEN
        				CASE WHEN da_purch_$ > da_sale_$ THEN
        					da_purch - da_sale
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) DA_FERC_ACCT_555_MWH,
        	   (CASE WHEN da_purch > da_sale THEN
        	   		da_purch_$ - da_sale_$
        		ELSE
        			CASE WHEN da_purch = da_sale THEN
        				CASE WHEN da_purch_$ > da_sale_$ THEN
        					da_purch_$ - da_sale_$
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) DA_FERC_ACCT_555_$,
        	   (CASE WHEN da_sale > da_purch THEN
        	   		da_sale - da_purch
        		ELSE
        			CASE WHEN da_sale = da_purch THEN
        				CASE WHEN da_sale_$ > da_purch_$ THEN
        					da_sale - da_purch
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) DA_FERC_ACCT_447_MWH,
        	   (CASE WHEN da_sale > da_purch THEN
        	   		da_sale_$ - da_purch_$
        		ELSE
        			CASE WHEN da_sale = da_purch THEN
        				CASE WHEN da_sale_$ > da_purch_$ THEN
        					da_sale_$ - da_purch_$
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) DA_FERC_ACCT_447_$,
        	   (CASE WHEN rt_purch > rt_sale THEN
        	   		rt_purch - rt_sale
        		ELSE
        			CASE WHEN rt_purch = rt_sale THEN
        				CASE WHEN rt_purch_$ > rt_sale_$ THEN
        					rt_purch - rt_sale
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) RT_FERC_ACCT_555_MWH,
        	   (CASE WHEN rt_purch > rt_sale THEN
        	   		rt_purch_$ - rt_sale_$
        		ELSE
        			CASE WHEN rt_purch = rt_sale THEN
        				CASE WHEN rt_purch_$ > rt_sale_$ THEN
        					rt_purch_$ - rt_sale_$
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) RT_FERC_ACCT_555_$,
        	   (CASE WHEN rt_sale > rt_purch THEN
        	   		rt_sale - rt_purch
        		ELSE
        			CASE WHEN rt_sale = rt_purch THEN
        				CASE WHEN rt_sale_$ > rt_purch_$ THEN
        					rt_sale - rt_purch
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) RT_FERC_ACCT_447_MWH,
        	   (CASE WHEN rt_sale > rt_purch THEN
        	   		rt_sale_$ - rt_purch_$
        		ELSE
        			CASE WHEN rt_sale = rt_purch THEN
        				CASE WHEN rt_sale_$ > rt_purch_$ THEN
        					rt_sale_$ - rt_purch_$
        				ELSE
        					0
        				END
        			ELSE
        				0
        			END
        		END) RT_FERC_ACCT_447_$
        FROM (
            select day,
            	   hour,
            	   sum(da_spot_purchase) da_purch,
            	   sum(da_charge) da_purch_$,
            	   sum(da_spot_sale) da_sale,
            	   sum(da_credit) da_sale_$,
            	   sum(bal_spot_purchase_dev) rt_purch,
            	   sum(bal_charge) rt_purch_$,
            	   sum(bal_spot_sale_dev) rt_sale,
            	   sum(bal_credit) rt_sale_$
             from pjm_spot_mkt_summary
    --		 where org_id in (12008,10713)
    		 where org_id in (SELECT X.STRING_VAL FROM TABLE(CAST(v_STRING_TABLE as STRING_TABLE)) X)
    		   and cut_date between v_BEGIN_DATE and v_END_DATE
            GROUP BY day,
            		 hour
            ORDER BY day,
            		 hour
            );
    END IF;

EXCEPTION
	WHEN INSUFFICIENT_PRIVILEGES THEN
		p_STATUS := GA.INSUFFICIENT_PRIVILEGES;
		RETURN;
	WHEN OTHERS THEN
		p_STATUS := GA.GENERAL_EXCEPTION;
		RAISE;
	END;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FERC_668_DATA
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
BEGIN     
    MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(p_BEGIN_DATE, p_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_SPOT_MKT_ENERGY_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);


END IMPORT_FERC_668_DATA;
--------------------------------------------------------------------------------------------
end MM_PJM_FERC;
/
