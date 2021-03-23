CREATE OR REPLACE TRIGGER DORMANT_PLC
AFTER DELETE OR INSERT OR UPDATE
ON CDI_PLC_DORMANT_ALLOCATION REFERENCING NEW AS NEW OLD AS OLD
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


  SELECT entity_domain_id
  INTO   v_entity_id
  FROM   ENTITY_DOMAIN a
  WHERE  a.ENTITY_DOMAIN_ALIAS = 'DORMANT_PLC';

SELECT NVL(USERNAME, 'NA'), NVL(OSUSER, 'NA'), NVL(TERMINAL, 'NA')
   INTO
      v_USERNAME,
      v_OSUSER,
      v_TERMINAL
   FROM V$SESSION
   WHERE AUDSID = USERENV('SESSIONID') AND ROWNUM=1;

   IF INSERTING THEN
       v_type:= 'Insert';
      -- Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,v_entity_id,:NEW.BEGIN_DATE,:NEW.END_DATE,'?',NULL,NULL,'CDI_PLC_DORMANT_ALLOCATION','*',SYSDATE,'INSERT',v_OSUSER,NULL,'?',NULL,SUBSTR(:NEW.BEGIN_DATE ||'_'||:NEW.END_DATE ||'_'||:NEW.FROM_POLR_TYPE||'_'||:NEW.TO_POLR_TYPE ||'_'||:NEW.REPORTED_SEGMENT ||'_'||:NEW.ALLOCATION,1,4000));
          v_newvals:= :NEW.BEGIN_DATE ||'_'||
                     :NEW.END_DATE ||'_'||
                     :NEW.FROM_POLR_TYPE||'_'||
                     :NEW.TO_POLR_TYPE ||'_'||
                     :NEW.REPORTED_SEGMENT ||'_'||
                     :NEW.ALLOCATION;
          v_COLS  :='*';

   ELSIF UPDATING THEN

          v_type:= 'Update';
            IF :NEW.TO_POLR_TYPE <> :OLD.TO_POLR_TYPE THEN
                 v_COLS    := v_COLS||', TO_POLR_TYPE ';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.TO_POLR_TYPE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.TO_POLR_TYPE;
            END IF;
            IF :NEW.BEGIN_DATE <> :OLD.BEGIN_DATE THEN
                 v_COLS    := v_COLS||', BEGIN_DATE ';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.BEGIN_DATE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.BEGIN_DATE;
            END IF;
            IF :NEW.END_DATE <> :OLD.END_DATE THEN
                 v_COLS    := v_COLS||', END_DATE ';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.END_DATE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.END_DATE;
            END IF;
            IF :NEW.FROM_POLR_TYPE <> :OLD.FROM_POLR_TYPE THEN
                 v_COLS    := v_COLS||', FROM_POLR_TYPE';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.FROM_POLR_TYPE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.FROM_POLR_TYPE;
            END IF;
            IF :NEW.REPORTED_SEGMENT <> :OLD.REPORTED_SEGMENT THEN
                 v_COLS    := v_COLS||', REPORTED_SEGMENT';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.REPORTED_SEGMENT;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.REPORTED_SEGMENT;
            END IF;
            IF :NEW.ALLOCATION <>      :OLD.ALLOCATION THEN
                  v_COLS    := v_COLS||', ALLOCATION';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.ALLOCATION;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.ALLOCATION;
            END IF;

            IF NOT v_COLS IS NULL THEN
                -- strip off preceding commas
                v_COLS :=   LTRIM(v_COLS,',');
                v_OLDVALS := LTRIM(v_OLDVALS,',');
                v_NEWVALS := LTRIM(v_NEWVALS,',');
--                Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,  v_entity_id , SYSDATE, SYSDATE, '?', NULL, NULL, 'CDI_PLC_DORMANT_ALLOCATION', v_COLS, SYSDATE, 'UPDATE', NULL, NULL, '?', v_OLDVALS, v_NEWVALS);
            END IF;
   ELSIF DELETING THEN
       v_type:= 'Delete';
--Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,v_entity_id ,:OLD.BEGIN_DATE,:OLD.END_DATE,'?',NULL,NULL,'CDI_PLC_DORMANT_ALLOCATION','*',SYSDATE,'DELETE',v_OSUSER,NULL,'?',SUBSTR(:OLD.TO_POLR_TYPE ||'_'||:OLD.BEGIN_DATE ||'_'||:OLD.END_DATE||'_'||:OLD.FROM_POLR_TYPE ||'_'||:OLD.REPORTED_SEGMENT ||'_'||:OLD.ALLOCATION,1,4000), NULL);
   v_oldvals:=   :OLD.TO_POLR_TYPE ||'_'||
                 :OLD.BEGIN_DATE ||'_'||
                 :OLD.END_DATE||'_'||
                 :OLD.FROM_POLR_TYPE ||'_'||
                 :OLD.REPORTED_SEGMENT ||'_'||
                 :OLD.ALLOCATION;

  END IF;


END;
/
