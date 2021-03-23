CREATE OR REPLACE TRIGGER ALM_TRIGGER
AFTER DELETE OR INSERT OR UPDATE
ON BGE_ALM_INPUT REFERENCING NEW AS NEW OLD AS OLD
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
  WHERE  a.ENTITY_DOMAIN_ALIAS = 'ALM_CODE';

SELECT NVL(USERNAME, 'NA'), NVL(OSUSER, 'NA'), NVL(TERMINAL, 'NA')
   INTO
      v_USERNAME,
      v_OSUSER,
      v_TERMINAL
   FROM V$SESSION
   WHERE AUDSID = USERENV('SESSIONID') AND ROWNUM=1;

   IF INSERTING THEN
       v_type:= 'Insert';
      --AU.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,v_entity_id,:NEW.BEGIN_DATE,:NEW.END_DATE,'?',NULL,NULL,'BGE_ALM_INPUT','*',SYSDATE,'INSERT',v_OSUSER,NULL,'?',NULL,SUBSTR(:NEW.PROGRAM ||'_'||:NEW.BEGIN_DATE ||'_'||:NEW.END_DATE  ||'_'||:NEW.EVENT_TYPE,1,4000));
          v_newvals:= :NEW.PROGRAM ||'_'||
                      :NEW.BEGIN_DATE ||'_'||
                      :NEW.END_DATE  ||'_'||
                      :NEW.EVENT_TYPE;
          v_COLS  :='*';

   ELSIF UPDATING THEN

          v_type:= 'Update';
            IF :NEW.PROGRAM <> :OLD.PROGRAM THEN
                 v_COLS    := v_COLS||', PROGRAM';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.PROGRAM;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.PROGRAM;
            END IF;
            IF :NEW.BEGIN_DATE <> :OLD.BEGIN_DATE THEN
                 v_COLS    := v_COLS||', BEGIN_DATE';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.BEGIN_DATE;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.BEGIN_DATE;
            END IF;
            IF :NEW.END_DATE <>   :OLD.END_DATE THEN
                  v_COLS    := v_COLS||', END_DATE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.END_DATE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.END_DATE;
            END IF;
            IF :NEW.EVENT_TYPE <>      :OLD.EVENT_TYPE THEN
                  v_COLS    := v_COLS||', EVENT_TYPE';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.EVENT_TYPE;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.EVENT_TYPE;
            END IF;

            IF NOT v_COLS IS NULL THEN
                -- strip off preceding commas
                v_COLS :=   LTRIM(v_COLS,',');
                v_OLDVALS := LTRIM(v_OLDVALS,',');
                v_NEWVALS := LTRIM(v_NEWVALS,',');
--                Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,  v_entity_id , SYSDATE, SYSDATE, '?', NULL, NULL, 'BGE_ALM_INPUT', v_COLS, SYSDATE, 'UPDATE', NULL, NULL, '?', v_OLDVALS, v_NEWVALS);
            END IF;
   ELSIF DELETING THEN
       v_type:= 'Delete';
--       Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,v_entity_id ,:OLD.BEGIN_DATE,:OLD.END_DATE,'?',NULL,NULL,'BGE_ALM_INPUT ','*',SYSDATE,'DELETE',v_OSUSER,NULL,'?',SUBSTR(:OLD.PROGRAM ||'_'||:OLD.BEGIN_DATE ||'_'||:OLD.END_DATE  ||'_'||:OLD.EVENT_TYPE,1,4000), NULL);
   v_oldvals:=    :OLD.PROGRAM ||','||
                  :OLD.BEGIN_DATE ||','||
                  :OLD.END_DATE  ||','||
                  :OLD.EVENT_TYPE;

  END IF;


END;
/
