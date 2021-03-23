		
CREATE OR REPLACE VIEW MISO_BUYER_COMMENTS 
		AS SELECT B.ATTRIBUTE_VAL AS BUYER_COMMENTS,  
                B.OWNER_ENTITY_ID AS TRANSACTION_ID  
        FROM ENTITY_ATTRIBUTE A,  
                TEMPORAL_ENTITY_ATTRIBUTE B  
        WHERE A.ENTITY_DOMAIN_ID = -200  
                AND A.ATTRIBUTE_NAME = 'BuyerComments'  
                AND B.ATTRIBUTE_ID = A.ATTRIBUTE_ID  
                AND B.BEGIN_DATE =  
                        (SELECT MAX(BEGIN_DATE)  
                        FROM TEMPORAL_ENTITY_ATTRIBUTE  
                        WHERE OWNER_ENTITY_ID = B.OWNER_ENTITY_ID  
                                AND ATTRIBUTE_ID = B.ATTRIBUTE_ID);  


CREATE OR REPLACE VIEW MISO_SELLER_COMMENTS 
		AS SELECT B.ATTRIBUTE_VAL AS SELLER_COMMENTS,  
                B.OWNER_ENTITY_ID AS TRANSACTION_ID  
        FROM ENTITY_ATTRIBUTE A,  
                TEMPORAL_ENTITY_ATTRIBUTE B  
        WHERE A.ENTITY_DOMAIN_ID = -200  
                AND A.ATTRIBUTE_NAME = 'SellerComments'  
                AND B.ATTRIBUTE_ID = A.ATTRIBUTE_ID  
                AND B.BEGIN_DATE =  
                        (SELECT MAX(BEGIN_DATE)  
                        FROM TEMPORAL_ENTITY_ATTRIBUTE  
                        WHERE OWNER_ENTITY_ID = B.OWNER_ENTITY_ID  
                                AND ATTRIBUTE_ID = B.ATTRIBUTE_ID);  

								
CREATE OR REPLACE VIEW MISO_FIN_CONTRACTS AS SELECT A.TRANSACTION_ID AS "TRANSACTION_ID",  
                SUBSTR(A.TRANSACTION_IDENTIFIER,6,INSTR(A.TRANSACTION_IDENTIFIER,':')-6) AS "PARTY",
                SUBSTR(A.TRANSACTION_IDENTIFIER,INSTR(A.TRANSACTION_IDENTIFIER,':')+1) AS "name",
                B.PSE_EXTERNAL_IDENTIFIER AS "buyer",
                A.AGREEMENT_TYPE AS "type",
                C.PSE_EXTERNAL_IDENTIFIER AS "seller",
                A.BEGIN_DATE AS "EffectiveStart",
                A.END_DATE AS "EffectiveEnd",
                D.EXTERNAL_IDENTIFIER AS "SourceLocation",
                E.EXTERNAL_IDENTIFIER AS "SinkLocation",
                F.EXTERNAL_IDENTIFIER AS "DeliveryPoint",
                A.APPROVAL_TYPE AS "ScheduleApproval",
                G.MARKET_TYPE AS "SettlementMarket",
                A.LOSS_OPTION AS "CongestionLosses",
                I.BUYER_COMMENTS AS "BuyerComments",
                J.SELLER_COMMENTS AS "SellerComments"
        FROM INTERCHANGE_TRANSACTION A,  
                PURCHASING_SELLING_ENTITY B,  
                PURCHASING_SELLING_ENTITY C,  
                SERVICE_POINT D,  
                SERVICE_POINT E,  
                SERVICE_POINT F,  
                IT_COMMODITY G,  
                MISO_BUYER_COMMENTS I,
				MISO_SELLER_COMMENTS J
        WHERE B.PSE_ID = A.PURCHASER_ID  
                AND C.PSE_ID = A.SELLER_ID  
                AND D.SERVICE_POINT_ID = A.SOURCE_ID  
                AND E.SERVICE_POINT_ID = A.SINK_ID  
                AND F.SERVICE_POINT_ID = A.POD_ID  
                AND G.COMMODITY_ID = A.COMMODITY_ID  
				AND A.IS_IMPORT_EXPORT = 0
				AND A.TRANSACTION_TYPE IN ('Purchase','Sale')
                AND I.TRANSACTION_ID(+) = A.TRANSACTION_ID
				AND J.TRANSACTION_ID(+) = A.TRANSACTION_ID
				AND A.SC_ID = (SELECT SC.SC_ID FROM SC WHERE SC.SC_NAME='MISO');

CREATE OR REPLACE VIEW MISO_5MIN_LMP_POINTS AS
SELECT B.OWNER_ENTITY_ID AS SERVICE_POINT_ID
        FROM ENTITY_ATTRIBUTE A,
                TEMPORAL_ENTITY_ATTRIBUTE B
        WHERE A.ENTITY_DOMAIN_ID = -210
                AND A.ATTRIBUTE_NAME = 'Use for MISO 5min LMP'
                AND B.ATTRIBUTE_ID = A.ATTRIBUTE_ID
				AND B.ATTRIBUTE_VAL = '1'
                AND B.BEGIN_DATE =
                        (SELECT MAX(BEGIN_DATE)
                        FROM TEMPORAL_ENTITY_ATTRIBUTE
                        WHERE OWNER_ENTITY_ID = B.OWNER_ENTITY_ID
                                AND ATTRIBUTE_ID = B.ATTRIBUTE_ID);
