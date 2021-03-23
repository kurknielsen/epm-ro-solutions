CREATE OR REPLACE VIEW CDI_INTERVAL_ACCOUNT_SERVICE$ AS
SELECT 
   A.ACCOUNT_ID,
   A.ACCOUNT_NAME,
   A.ACCOUNT_MODEL_OPTION,
   A.ACCOUNT_EXTERNAL_IDENTIFIER,
   A.ACCOUNT_METER_EXT_IDENTIFIER,
   B.BEGIN_DATE                                       "ACTIVE_BEGIN_DATE",
   NVL(B.END_DATE,TO_DATE('12/31/9999','MM/DD/YYYY')) "ACTIVE_END_DATE",
   C.EDC_ID,
   C.BEGIN_DATE                                       "EDC_BEGIN_DATE",
   NVL(C.END_DATE,TO_DATE('12/31/9999','MM/DD/YYYY')) "EDC_END_DATE",
   D.ESP_ID,
   D.POOL_ID,
   D.BEGIN_DATE                                       "ESP_BEGIN_DATE",
   NVL(D.END_DATE,TO_DATE('12/31/9999','MM/DD/YYYY')) "ESP_END_DATE",
   E.SERVICE_LOCATION_ID,
   E.BEGIN_DATE                                       "SERVICE_LOCATION_BEGIN_DATE",
   NVL(E.END_DATE,TO_DATE('12/31/9999','MM/DD/YYYY')) "SERVICE_LOCATION_END_DATE",
   G.PSE_ID,
   G.BEGIN_DATE                                       "PSE_BEGIN_DATE",
   NVL(G.END_DATE,TO_DATE('12/31/9999','MM/DD/YYYY')) "PSE_END_DATE",
   H.ACCOUNT_SERVICE_ID,
   I.PROVIDER_SERVICE_ID,
   K.SERVICE_DELIVERY_ID,
   L.SERVICE_ID
FROM ACCOUNT                           A
   JOIN ACCOUNT_STATUS                 B ON B.ACCOUNT_ID = A.ACCOUNT_ID AND B.STATUS_NAME = 'Active'
   JOIN ACCOUNT_EDC                    C ON C.ACCOUNT_ID = A.ACCOUNT_ID
   JOIN ACCOUNT_ESP                    D ON D.ACCOUNT_ID = A.ACCOUNT_ID
   JOIN ACCOUNT_SERVICE_LOCATION       E ON E.ACCOUNT_ID = A.ACCOUNT_ID
   JOIN PSE_ESP                        G ON G.ESP_ID = D.ESP_ID
   JOIN ACCOUNT_SERVICE                H ON H.ACCOUNT_ID = A.ACCOUNT_ID AND H.SERVICE_LOCATION_ID = E.SERVICE_LOCATION_ID AND H.METER_ID = 0 AND AGGREGATE_ID = 0
   JOIN PROVIDER_SERVICE               I ON I.EDC_ID = C.EDC_ID AND I.ESP_ID = D.ESP_ID AND I.PSE_ID = G.PSE_ID
   JOIN SERVICE_LOCATION               J ON J.SERVICE_LOCATION_ID = E.SERVICE_LOCATION_ID
   JOIN SERVICE_DELIVERY               K ON K.POOL_ID = D.POOL_ID AND K.SERVICE_POINT_ID = J.SERVICE_POINT_ID AND K.SERVICE_ZONE_ID = NVL(J.SERVICE_ZONE_ID,0)
   JOIN SERVICE                        L ON L.MODEL_ID = 1 AND L.SCENARIO_ID = 1 AND L.AS_OF_DATE = TO_DATE('1/1/1900','MM/DD/YYYY') AND L.ACCOUNT_SERVICE_ID = H.ACCOUNT_SERVICE_ID AND L.PROVIDER_SERVICE_ID = I.PROVIDER_SERVICE_ID AND L.SERVICE_DELIVERY_ID = K.SERVICE_DELIVERY_ID
WHERE A.ACCOUNT_MODEL_OPTION = 'Account'
   AND A.ACCOUNT_METER_TYPE = 'Interval'
   AND A.IS_SUB_AGGREGATE = 0;
