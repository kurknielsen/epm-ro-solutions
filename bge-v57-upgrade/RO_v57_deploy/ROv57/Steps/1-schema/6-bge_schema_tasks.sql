DROP TABLE COMPOSITE_WEATHER_WORK CASCADE CONSTRAINTS;

CREATE GLOBAL TEMPORARY TABLE COMPOSITE_WEATHER_WORK
(
  ROOT_ENTITY_ID  NUMBER(9),
  ENTITY_INDEX    NUMBER(4),
  ENTITY_ID       NUMBER(9),
  COEFFICIENT     NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE INDEX COMPOSITE_WEATHER_WORK_IX01 ON COMPOSITE_WEATHER_WORK(ENTITY_INDEX, ENTITY_ID);

-- Remove Attributes And Allow SPECIAL_NOTATION To Be Null --
ALTER TABLE RTO_BGE_TARIFF_CODES DROP CONSTRAINT RTO_BGE_TARIFF_CODES_PK DROP INDEX;
ALTER TABLE RTO_BGE_TARIFF_CODES DROP (DESCRIPTION, ALM_TYPE, POLR_TYPE_PLC_MIN, POLR_TYPE_PLC_MAX);
CREATE INDEX RTO_BGE_TARIFF_CODES_IDX4 ON RTO_BGE_TARIFF_CODES(SOS, DELIVERY_SERVICE, HOURLY_SERVICE, SPECIAL_NOTATION, POLR_TYPE, EFFECTIVE_DATE) TABLESPACE NERO_INDEX;

ALTER TABLE BGE_SUPPLIER_VIEW RENAME COLUMN EMAIL_DISTRIBUTION TO IMPORT_MESSAGE;

ALTER TABLE BGE_RTO_MONTHLY_USAGE ADD (PROFILED_USAGE NUMBER(14,4), USAGE_INTERVALS NUMBER(6), USAGE_FACTOR NUMBER(14,6), UF_PROCESS_ID NUMBER(12));

CREATE INDEX BGE_RTO_MONTHLY_USAGE_IDX006 ON BGE_RTO_MONTHLY_USAGE(BILL_ACCOUNT, SERVICE_POINT, BEGIN_DATE, END_DATE, USAGE_FACTOR) TABLESPACE NERO_LARGE_INDEX;

-- BGE Triggers That Reference RO Objects -- 
DROP TRIGGER DORMANT_PLC;
DROP TRIGGER ALM_TRIGGER;
DROP TRIGGER RIDER_TRIGGER;
DROP TRIGGER CDI_PLC_ICAP_TX_TRG;
DROP TRIGGER TARIFF_TRIGGER;

-- Remove Objects No Longer Referenced --
DROP TYPE PLC_AGGR_TABLE1;

prompt Set RTO_BGE_TARIFF_CODES.SPECIAL_NOTATION To Null
UPDATE RTO_BGE_TARIFF_CODES SET SPECIAL_NOTATION = NULL WHERE SPECIAL_NOTATION NOT IN ('CABLE_DEVICE', 'PBS');
COMMIT;