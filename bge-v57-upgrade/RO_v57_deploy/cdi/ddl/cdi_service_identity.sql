BEGIN CDI_DROP_OBJECT('CDI_SERVICE_IDENTITY', 'TABLE'); END;
/

CREATE TABLE CDI_SERVICE_IDENTITY
(
  SERVICE_DATE            DATE,
  ACCOUNT_EXTERNAL_IDENT  VARCHAR2(128),
  ACCOUNT_ID              NUMBER(9),
  EDC_ID                  NUMBER(9),
  ESP_ID                  NUMBER(9),
  PSE_ID                  NUMBER(9),
  POOL_ID                 NUMBER(9),
  SERVICE_LOCATION_ID     NUMBER(9),
  SERVICE_POINT_ID        NUMBER(9),
  SERVICE_ZONE_ID         NUMBER(9),
  METER_ID                NUMBER(9),
  AGGREGATE_ID            NUMBER(9),
  SC_ID                   NUMBER(9),
  SCHEDULE_GROUP_ID       NUMBER(9),
  SUPPLY_TYPE             CHAR(1),
  IS_BUG                  NUMBER(1),
  IS_WHOLESALE            NUMBER(1),
  IS_AGGREGATE_POOL       NUMBER(1),
  ACCOUNT_SERVICE_ID      NUMBER(9),
  PROVIDER_SERVICE_ID     NUMBER(9),
  SERVICE_DELIVERY_ID     NUMBER(9),
  SERVICE_ID              NUMBER(9),
  LOSS_FACTOR_ID          NUMBER(9),
  DX_EXPANSION_FACTOR     NUMBER(8,6),
  TX_EXPANSION_FACTOR     NUMBER(8,6),
  IDENTITY_ID             NUMBER(38),
  STAGING_STATUS          VARCHAR2(32),
  STAGING_MESSAGE         VARCHAR2(4000),
  CONSTRAINT PK_CDI_SERVICE_IDENTITY PRIMARY KEY(SERVICE_DATE, ACCOUNT_EXTERNAL_IDENT) USING INDEX
);

BEGIN CDI_DROP_OBJECT('CDI_SERVICE_IDENTITY_SEQ', 'SEQUENCE'); END;
/

CREATE SEQUENCE CDI_SERVICE_IDENTITY_SEQ START WITH 1;

CREATE OR REPLACE TRIGGER CDI_SERVICE_IDENTITY_VALIDATE
   BEFORE INSERT ON CDI_SERVICE_IDENTITY FOR EACH ROW
DECLARE
BEGIN
   :new.IDENTITY_ID := CDI_SERVICE_IDENTITY_SEQ.NEXTVAL;
   :new.STAGING_STATUS := 'Success';
   :new.STAGING_MESSAGE := '';
   SELECT MAX(ACCOUNT_ID) INTO :new.ACCOUNT_ID FROM ACCOUNT WHERE ACCOUNT_EXTERNAL_IDENTIFIER = :new.ACCOUNT_EXTERNAL_IDENT;
   :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.ACCOUNT_ID IS NULL THEN 'Account Not Defined;' ELSE '' END;
   SELECT MAX(EDC_ID) INTO :new.EDC_ID FROM ACCOUNT_EDC WHERE ACCOUNT_ID = :new.ACCOUNT_ID AND :new.SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, :new.SERVICE_DATE);
   :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.EDC_ID IS NULL THEN 'EDC Not Assigned;' ELSE '' END;
   IF :new.EDC_ID IS NOT NULL THEN
      SELECT MAX(EDC_SC_ID) INTO :new.SC_ID FROM ENERGY_DISTRIBUTION_COMPANY WHERE EDC_ID = :new.EDC_ID; 
      :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.SC_ID IS NULL THEN 'EDC Scheduling Coordinator Not Assigned;' ELSE '' END;
   END IF;
   SELECT MAX(ESP_ID) INTO :new.ESP_ID FROM ACCOUNT_ESP WHERE ACCOUNT_ID = :new.ACCOUNT_ID AND :new.SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, :new.SERVICE_DATE); 
   :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.ESP_ID IS NULL THEN 'ESP Not Assigned;' ELSE '' END;
   SELECT MAX(POOL_ID) INTO :new.POOL_ID FROM ACCOUNT_ESP WHERE ACCOUNT_ID = :new.ACCOUNT_ID AND :new.SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, :new.SERVICE_DATE); 
   :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.POOL_ID IS NULL THEN 'Pool Not Assigned;' ELSE '' END;
   SELECT NVL(MAX(PSE_ID),0) INTO :new.PSE_ID FROM PSE_ESP WHERE ESP_ID = :new.ESP_ID AND :new.SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, :new.SERVICE_DATE); 
   SELECT MAX(SERVICE_LOCATION_ID) INTO :new.SERVICE_LOCATION_ID FROM ACCOUNT_SERVICE_LOCATION WHERE ACCOUNT_ID = :new.ACCOUNT_ID AND :new.SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, :new.SERVICE_DATE);
   :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.SERVICE_LOCATION_ID IS NULL THEN 'Service Location Not Assigned;' ELSE '' END;
   SELECT NVL(MAX(SERVICE_POINT_ID),0), NVL(MAX(SERVICE_ZONE_ID),0) INTO :new.SERVICE_POINT_ID, :new.SERVICE_ZONE_ID FROM SERVICE_LOCATION WHERE SERVICE_LOCATION_ID = :new.SERVICE_LOCATION_ID;
   IF :new.ESP_ID IS NOT NULL THEN
      SELECT NVL(UPPER(SUBSTR(ESP_TYPE,1,1)),'?') INTO :new.SUPPLY_TYPE FROM ENERGY_SERVICE_PROVIDER WHERE ESP_ID = :new.ESP_ID; 
   END IF;
   IF :new.PSE_ID IS NOT NULL THEN
      SELECT NVL(MAX(PSE_IS_BACKUP_GENERATION), 0) INTO :new.IS_BUG FROM PURCHASING_SELLING_ENTITY WHERE PSE_ID = :new.PSE_ID; 
   END IF;
   IF :new.POOL_ID IS NOT NULL THEN
      SELECT NVL(CASE WHEN UPPER(POOL_CATEGORY) = 'AGGREGATE POOL' THEN 1 ELSE 0 END, 0) INTO :new.IS_AGGREGATE_POOL FROM POOL WHERE POOL_ID = :new.POOL_ID; 
   END IF;
   :new.METER_ID  := CONSTANTS.NOT_ASSIGNED;
   :new.AGGREGATE_ID := CONSTANTS.NOT_ASSIGNED;
   :new.IS_WHOLESALE := CONSTANTS.NOT_ASSIGNED;
   :new.SCHEDULE_GROUP_ID := CONSTANTS.NOT_ASSIGNED;
   SELECT MAX(ACCOUNT_SERVICE_ID)  INTO :new.ACCOUNT_SERVICE_ID  FROM ACCOUNT_SERVICE  WHERE ACCOUNT_ID = :new.ACCOUNT_ID AND SERVICE_LOCATION_ID = :new.SERVICE_LOCATION_ID AND METER_ID = :new.METER_ID AND AGGREGATE_ID = :new.AGGREGATE_ID;
   SELECT MAX(PROVIDER_SERVICE_ID) INTO :new.PROVIDER_SERVICE_ID FROM PROVIDER_SERVICE WHERE EDC_ID = :new.EDC_ID AND ESP_ID = :new.ESP_ID AND PSE_ID = :new.PSE_ID;
   SELECT MAX(SERVICE_DELIVERY_ID) INTO :new.SERVICE_DELIVERY_ID FROM SERVICE_DELIVERY WHERE POOL_ID = :new.POOL_ID AND SERVICE_POINT_ID = :new.SERVICE_POINT_ID AND SERVICE_ZONE_ID = :new.SERVICE_ZONE_ID AND SCHEDULE_GROUP_ID = :new.SCHEDULE_GROUP_ID AND SC_ID = :new.SC_ID AND SUPPLY_TYPE = :new.SUPPLY_TYPE AND IS_BUG = :new.IS_BUG AND IS_WHOLESALE = :new.IS_WHOLESALE;
   SELECT MAX(SERVICE_ID) INTO :new.SERVICE_ID FROM SERVICE WHERE ACCOUNT_SERVICE_ID = :new.ACCOUNT_SERVICE_ID AND PROVIDER_SERVICE_ID = :new.PROVIDER_SERVICE_ID AND SERVICE_DELIVERY_ID = :new.SERVICE_DELIVERY_ID AND MODEL_ID = 1 AND SCENARIO_ID = 1 AND AS_OF_DATE = TO_DATE('1/1/1900','MM/DD/YYYY');
   SELECT MAX(LOSS_FACTOR_ID) INTO :new.LOSS_FACTOR_ID FROM ACCOUNT_LOSS_FACTOR WHERE ACCOUNT_ID = :new.ACCOUNT_ID AND :new.SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, :new.SERVICE_DATE);
   :new.STAGING_MESSAGE := :new.STAGING_MESSAGE || CASE WHEN :new.LOSS_FACTOR_ID IS NULL THEN 'Loss Factor Not Assigned;' ELSE '' END;
   IF LENGTH(:new.STAGING_MESSAGE) > 0 THEN
      :new.STAGING_STATUS := 'Error';
      :new.STAGING_MESSAGE := RTRIM(:new.STAGING_MESSAGE, ';');
   END IF;
END CDI_SERVICE_IDENTITY_VALIDATE;
/
