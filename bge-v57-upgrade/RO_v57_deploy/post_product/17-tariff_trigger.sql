CREATE OR REPLACE TRIGGER TARIFF_TRIGGER
AFTER DELETE OR INSERT OR UPDATE
ON RTO_BGE_TARIFF_CODES 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
      v_USERNAME    VARCHAR2(400);
	  v_OSUSER      VARCHAR2(400);
	  v_TERMINAL    VARCHAR2(400);
      v_type        VARCHAR2(10);
      v_entity_id   ENTITY_DOMAIN.entity_domain_id%TYPE;
      v_COLS VARCHAR2(512) := '';
			v_OLDVALS VARCHAR2(4000) := '';
			v_NEWVALS VARCHAR2(4000) := '';
BEGIN

/*CREATE OR REPLACE TRIGGER ACCOUNT_EDC_UPDATE
	AFTER UPDATE ON ACCOUNT_EDC
	FOR EACH ROW
DECLARE
*/

  SELECT entity_domain_id
  INTO   v_entity_id
  FROM   ENTITY_DOMAIN a
  WHERE  a.ENTITY_DOMAIN_ALIAS = 'TARIFF_CODE';

SELECT NVL(USERNAME, 'NA'), NVL(OSUSER, 'NA'), NVL(TERMINAL, 'NA')
   INTO
	  v_USERNAME,
	  v_OSUSER,
	  v_TERMINAL
   FROM V$SESSION
   WHERE AUDSID = USERENV('SESSIONID') AND ROWNUM=1;
/*   
   IF INSERTING THEN
       v_type:= 'Insert';
       Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id, 
                                     v_entity_id, 
                                     :NEW.EFFECTIVE_DATE, 
                                     :NEW.END_DATE, 
                                     '?', 
                                     NULL,
                                     NULL, 
                                     'RTO_BGE_TARIFF_CODES', 
                                     '*', 
                                     SYSDATE, 
                                     'INSERT',
                                     v_OSUSER, 
                                     NULL, 
                                     '?',
                                     NULL, 
                                      SUBSTR(:NEW.SOS ||'_'||   
                                             :NEW.DELIVERY_SERVICE ||'_'|| 
                                             :NEW.HOURLY_SERVICE  ||'_'|| 
                                             :NEW.DESCRIPTION  ||'_'|| 
                                             :NEW.ALM_TYPE   ||'_'|| 
                                             :NEW.SPECIAL_NOTATION  ||'_'|| 
                                             :NEW.PROFILE   ||'_'|| 
                                             :NEW.REPORTED_SEGMENT  ||'_'|| 
                                             :NEW.VOLTAGE_CLASS ||'_'|| 
                                             :NEW.POLR_TYPE  ||'_'|| 
                                             :NEW.EFFECTIVE_DATE    ||'_'|| 
                                             :NEW.POLR_TYPE_PLC_MIN ||'_'|| 
                                             :NEW.POLR_TYPE_PLC_MAX  ||'_'|| 
                                             :NEW.METER_TYPE      ||'_'|| 
                                             :NEW.PROCESS_DATE  ||'_'|| 
                                             :NEW.END_DATE
                                             ,1,4000)
                                     );
          v_newvals:= :NEW.SOS ||'_'||   
                  :NEW.DELIVERY_SERVICE ||'_'|| 
                  :NEW.HOURLY_SERVICE  ||'_'|| 
                  :NEW.DESCRIPTION  ||'_'|| 
                  :NEW.ALM_TYPE   ||'_'|| 
                  :NEW.SPECIAL_NOTATION  ||'_'|| 
                  :NEW.PROFILE   ||'_'|| 
                  :NEW.REPORTED_SEGMENT  ||'_'|| 
                  :NEW.VOLTAGE_CLASS ||'_'|| 
                  :NEW.POLR_TYPE  ||'_'|| 
                  :NEW.EFFECTIVE_DATE    ||'_'|| 
                  :NEW.POLR_TYPE_PLC_MIN ||'_'|| 
                  :NEW.POLR_TYPE_PLC_MAX  ||'_'|| 
                  :NEW.METER_TYPE      ||'_'|| 
                  :NEW.PROCESS_DATE  ||'_'|| 
                  :NEW.END_DATE;
          v_COLS  :='*';
   ELSIF UPDATING THEN
       v_type:= 'Update';
            IF :NEW.SOS <> :OLD.SOS THEN
                 v_COLS    := v_COLS||', SOS_ID';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.SOS;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.SOS;
            END IF; 
            IF :NEW.DELIVERY_SERVICE <> :OLD.DELIVERY_SERVICE THEN
                 v_COLS    := v_COLS||', DELIVERY_SERVICE';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.DELIVERY_SERVICE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.DELIVERY_SERVICE;
            END IF; 
            IF :NEW.HOURLY_SERVICE <>   :OLD.HOURLY_SERVICE THEN
                  v_COLS    := v_COLS||', HOURLY_SERVICE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.HOURLY_SERVICE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.HOURLY_SERVICE;
            END IF; 
            IF :NEW.DESCRIPTION <>      :OLD.DESCRIPTION THEN
                  v_COLS    := v_COLS||', DESCRIPTION';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.DESCRIPTION;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.DESCRIPTION;
            END IF; 
            IF :NEW.ALM_TYPE <> :OLD.ALM_TYPE THEN
                 v_COLS    := v_COLS||', ALM_TYPE';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.ALM_TYPE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.ALM_TYPE;
            END IF; 
            IF :NEW.PROFILE <> :OLD.PROFILE THEN
                 v_COLS    := v_COLS||', PROFILE';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.PROFILE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.PROFILE;
            END IF; 
            IF :NEW.SPECIAL_NOTATION <> :OLD.SPECIAL_NOTATION THEN
                 v_COLS    := v_COLS||', SPECIAL_NOTATION';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.SPECIAL_NOTATION;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.SPECIAL_NOTATION;
            END IF; 
            IF :NEW.REPORTED_SEGMENT <> :OLD.REPORTED_SEGMENT THEN
                  v_COLS    := v_COLS||', REPORTED_SEGMENT';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.REPORTED_SEGMENT;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.REPORTED_SEGMENT;
            END IF; 
            IF :NEW.VOLTAGE_CLASS <> :OLD.VOLTAGE_CLASS THEN
                  v_COLS    := v_COLS||', VOLTAGE_CLASS';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.VOLTAGE_CLASS;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.VOLTAGE_CLASS;
            END IF; 
            IF :NEW.POLR_TYPE <> :OLD.POLR_TYPE THEN
                  v_COLS    := v_COLS||', POLR_TYPE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.POLR_TYPE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.POLR_TYPE;
            END IF; 
            IF :NEW.EFFECTIVE_DATE <> :OLD.EFFECTIVE_DATE THEN
                  v_COLS    := v_COLS||', EFFECTIVE_DATE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.EFFECTIVE_DATE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.EFFECTIVE_DATE;
            END IF; 
            IF :NEW.POLR_TYPE_PLC_MIN <> :OLD.POLR_TYPE_PLC_MIN THEN
                  v_COLS    := v_COLS||', POLR_TYPE_PLC_MIN';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.POLR_TYPE_PLC_MIN;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.POLR_TYPE_PLC_MIN;
            END IF; 
            IF :NEW.POLR_TYPE_PLC_MAX <> :OLD.POLR_TYPE_PLC_MAX THEN
                  v_COLS    := v_COLS||', POLR_TYPE_PLC_MAX';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.POLR_TYPE_PLC_MAX;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.POLR_TYPE_PLC_MAX;
            END IF; 
            IF :NEW.METER_TYPE <> :OLD.METER_TYPE THEN
                  v_COLS    := v_COLS||', METER_TYPE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.METER_TYPE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.METER_TYPE;
            END IF; 
            IF :NEW.END_DATE <> :OLD.END_DATE THEN
                  v_COLS    := v_COLS||', END_DATE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.END_DATE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.END_DATE;
            END IF;
            IF NOT v_COLS IS NULL THEN
            	-- strip off preceding commas
                v_COLS :=   LTRIM(v_COLS,',');
            	v_OLDVALS := LTRIM(v_OLDVALS,',');
            	v_NEWVALS := LTRIM(v_NEWVALS,',');
				Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,  v_entity_id , SYSDATE, SYSDATE, '?', NULL, NULL, 'RTO_BGE_TARIFF_CODES', v_COLS, SYSDATE, 'UPDATE', NULL, NULL, '?', v_OLDVALS, v_NEWVALS);
			END IF;
   ELSIF DELETING THEN
       v_type:= 'Delete';
       Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id, 
                                     v_entity_id ,
                                     :OLD.EFFECTIVE_DATE, 
                                     :OLD.END_DATE, 
                                     '?', 
                                     NULL,
                                     NULL, 
                                     'RTO_BGE_TARIFF_CODES', 
                                     '*', 
                                     SYSDATE, 
                                     'DELETE',
                                     v_OSUSER, 
                                     NULL, 
                                     '?', 
                                      SUBSTR(:OLD.SOS ||'_'||   
                                             :OLD.DELIVERY_SERVICE ||'_'|| 
                                             :OLD.HOURLY_SERVICE  ||'_'|| 
                                             :OLD.DESCRIPTION  ||'_'|| 
                                             :OLD.ALM_TYPE   ||'_'|| 
                                             :OLD.SPECIAL_NOTATION  ||'_'|| 
                                             :OLD.PROFILE   ||'_'|| 
                                             :OLD.REPORTED_SEGMENT  ||'_'|| 
                                             :OLD.VOLTAGE_CLASS ||'_'|| 
                                             :OLD.POLR_TYPE  ||'_'|| 
                                             :OLD.EFFECTIVE_DATE    ||'_'|| 
                                             :OLD.POLR_TYPE_PLC_MIN ||'_'|| 
                                             :OLD.POLR_TYPE_PLC_MAX  ||'_'|| 
                                             :OLD.METER_TYPE      ||'_'|| 
                                             :OLD.PROCESS_DATE  ||'_'|| 
                                             :OLD.END_DATE
                                             ,1,4000)
                                     , NULL);
   v_oldvals:=    :OLD.SOS ||','||   
                  :OLD.DELIVERY_SERVICE ||','|| 
                  :OLD.HOURLY_SERVICE  ||','|| 
                  :OLD.DESCRIPTION  ||','|| 
                  :OLD.ALM_TYPE   ||','|| 
                  :OLD.SPECIAL_NOTATION  ||','|| 
                  :OLD.PROFILE   ||','|| 
                  :OLD.REPORTED_SEGMENT  ||','|| 
                  :OLD.VOLTAGE_CLASS ||','|| 
                  :OLD.POLR_TYPE  ||','|| 
                  :OLD.EFFECTIVE_DATE    ||','|| 
                  :OLD.POLR_TYPE_PLC_MIN ||','|| 
                  :OLD.POLR_TYPE_PLC_MAX  ||','|| 
                  :OLD.METER_TYPE      ||','|| 
                  :OLD.PROCESS_DATE  ||','|| 
                  :OLD.END_DATE;
    
  END IF;
  
 
 
 INSERT INTO RTO_BGE_TARIFF_CODES_AUDIT
 (
   user_name,
   ddl_date,
   ddl_type,
   object_type,
   owner,
   os_user,
   terminal,
   CHANGED_COLUMNS,
   OLD_VALUES,
   NEW_VALUES
 )
 VALUES
 (
   v_USERNAME,
   SYSDATE,
   v_type,
   'RTO TARIFF Table',
   ora_login_user,
   v_OSUSER,
   v_TERMINAL,
   v_COLS,
   v_oldvals,
   v_newvals --ora_dict_obj_name
   
 );
*/

END;
/
