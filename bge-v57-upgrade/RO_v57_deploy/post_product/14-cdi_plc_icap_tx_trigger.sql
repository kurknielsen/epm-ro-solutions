CREATE OR REPLACE TRIGGER CDI_PLC_ICAP_TX_TRG
AFTER DELETE OR INSERT OR UPDATE
ON CDI_PLC_ICAP_TX REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
      v_USERNAME      VARCHAR2(400);
      v_OSUSER        VARCHAR2(400);
      v_TERMINAL      VARCHAR2(400);
      v_type          VARCHAR2(10);
      v_PLC_TYPE      VARCHAR2(64);
      v_ICAP          VARCHAR2(64):='ICAP';
      v_TRANS         VARCHAR2(64):='TRANS';
      v_SEGMENT       VARCHAR2(4) :='N/A';
      v_BILL_ACCOUNT  NUMBER;
      v_SERVICE_POINT NUMBER;
--      v_PLC_CREATE    PLC_CREATE_TABLE;
      v_STATUS        NUMBER;
      v_MESSAGE       VARCHAR2(4000);


      v_entity_id   ENTITY_DOMAIN.entity_domain_id%TYPE;
      v_COLS VARCHAR2(512) := '';
      v_OLDVALS VARCHAR2(4000) := '';
      v_NEWVALS VARCHAR2(4000) := '';
BEGIN
   SELECT NVL(USERNAME, 'NA'),
          NVL(OSUSER, 'NA'),
          NVL(TERMINAL, 'NA')
   INTO
         v_USERNAME,
         v_OSUSER,
         v_TERMINAL
   FROM  V$SESSION
   WHERE AUDSID = USERENV('SESSIONID') AND ROWNUM=1;
  SELECT entity_domain_id
  INTO   v_entity_id
  FROM   ENTITY_DOMAIN a
  WHERE  a.ENTITY_DOMAIN_ALIAS = 'CDI_PLC_ICAP_TX_TRG';
   IF INSERTING   THEN
      v_BILL_ACCOUNT  := :NEW.bill_account;
      v_SERVICE_POINT := :new.service_point;
   ELSIF UPDATING THEN
      v_BILL_ACCOUNT  := :NEW.bill_account;
      v_SERVICE_POINT := :new.service_point;
   ELSIF DELETING THEN
      v_BILL_ACCOUNT  := :OLD.bill_account;
      v_SERVICE_POINT := :OLD.service_point;
   END IF;

   BEGIN
   SELECT rate_class
   INTO   v_SEGMENT
   FROM   bge_master_account bge
   WHERE  bge.bill_account  = v_BILL_ACCOUNT
   AND    bge.service_point = v_SERVICE_POINT
   AND    effective_date = (SELECT MAX(effective_date)
                             FROM   bge_master_account MAIN
                             WHERE  main.bill_account  = bge.bill_account
                             AND    main.SERVICE_POINT = bge.SERVICE_POINT
                             AND    main.bill_account  = v_BILL_ACCOUNT
                             AND    main.service_point = v_SERVICE_POINT
                            );
   EXCEPTION
   WHEN OTHERS THEN
        v_SEGMENT:= 'N/A';
   END;
   IF INSERTING THEN
      IF :new.tag_id LIKE '%T' THEN
         v_plc_type := v_TRANS;
      ELSE
         v_plc_type := V_ICAP;
      END IF;
       v_type:= 'Insert';

       INSERT INTO cdi_plc_audit
       (
       BILL_ACCOUNT,
       SERVICE_POINT,
       SEGMENT,
       PLC_YEAR,
       PLC_VALUE,
       PLC_TYPE,
       DML_INDICATOR,
       CREATE_USER,
       CREATE_DATE
       )
       VALUES
       (
        :NEW.bill_account,
        :new.service_point,
        v_SEGMENT,
        SUBSTR(:new.tag_id,1,4),
        :new.tag_val,
        v_PLC_TYPE,
        'I',
        v_OSUSER,
        SYSTIMESTAMP
       );
         v_type:= 'Insert';
--Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,v_entity_id,:NEW.BEGIN_DATE,:NEW.END_DATE,'?',NULL,NULL,'CDI_PLC_ICAP_TX','*',SYSDATE,'INSERT',v_OSUSER,NULL,'?',NULL,SUBSTR(:NEW.BILL_ACCOUNT ||'_'||:NEW.SERVICE_POINT||'_'||:NEW.PREMISE_NUMBER ||'_'||:NEW.TAG_ID ||'_'||:NEW.BEGIN_DATE ||'_'||:NEW.END_DATE  ||'_'||:NEW.TAG_VAL,1,4000));

          v_newvals:= :NEW.BILL_ACCOUNT ||'_'||
                      :NEW.SERVICE_POINT||'_'||
                      :NEW.PREMISE_NUMBER ||'_'||
                      :NEW.TAG_ID ||'_'||
                      :NEW.BEGIN_DATE ||'_'||
                      :NEW.END_DATE  ||'_'||
                      :NEW.TAG_VAL;
          v_COLS  :='*';

   ELSIF UPDATING THEN
       v_type:= 'Update';
      IF :new.tag_id LIKE '%T' THEN
         v_plc_type := v_TRANS;
      ELSE
         v_plc_type := v_ICAP;
      END IF;
       INSERT INTO cdi_plc_audit
       (
       BILL_ACCOUNT,
       SERVICE_POINT,
       SEGMENT,
       PLC_YEAR,
       PLC_VALUE,
       PLC_TYPE,
       DML_INDICATOR,
       CREATE_USER,
       CREATE_DATE
       )
       VALUES
       (
        :NEW.bill_account,
        :new.service_point,
        v_SEGMENT,
        SUBSTR(:new.tag_id,1,4),
        :new.tag_val,
        v_PLC_TYPE,
        'U',
        v_OSUSER,
        SYSDATE
       );

        v_type:= 'Update';
            IF :NEW.BILL_ACCOUNT <> :OLD.BILL_ACCOUNT THEN
                 v_COLS    := v_COLS||', BILL_ACCOUNT';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.BILL_ACCOUNT;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.BILL_ACCOUNT;
            END IF;
            IF :NEW.SERVICE_POINT <> :OLD.SERVICE_POINT THEN
                 v_COLS    := v_COLS||', SERVICE_POINT';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.SERVICE_POINT;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.SERVICE_POINT;
            END IF;
            IF :NEW.PREMISE_NUMBER <> :OLD.PREMISE_NUMBER THEN
                 v_COLS    := v_COLS||', PREMISE_NUMBER';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.PREMISE_NUMBER;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.PREMISE_NUMBER;
            END IF;

            IF :NEW.TAG_ID <> :OLD.TAG_ID THEN
                 v_COLS    := v_COLS||', TAG_ID';
                 v_OLDVALS := v_OLDVALS||', '||:OLD.TAG_ID;
                 v_NEWVALS := v_NEWVALS||', '||:NEW.TAG_ID;
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
            IF :NEW.TAG_VAL <>      :OLD.TAG_VAL THEN
                  v_COLS    := v_COLS||', TAG_VAL';
                  v_OLDVALS := v_OLDVALS||', '||:OLD.TAG_VAL;
                  v_NEWVALS := v_NEWVALS||', '||:NEW.TAG_VAL;
            END IF;

            IF NOT v_COLS IS NULL THEN
                v_COLS :=   LTRIM(v_COLS,',');
                v_OLDVALS := LTRIM(v_OLDVALS,',');
                v_NEWVALS := LTRIM(v_NEWVALS,',');
--                Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,  v_entity_id , SYSDATE, SYSDATE, '?', NULL, NULL, 'CDI_PLC_ICAP_TX', v_COLS, SYSDATE, 'UPDATE', NULL, NULL, '?', v_OLDVALS, v_NEWVALS);
            END IF;

   ELSIF DELETING THEN
       v_type:= 'Delete';
      IF :old.tag_id LIKE '%T' THEN
         v_plc_type := v_TRANS;
      ELSE
         v_plc_type := V_ICAP;
      END IF;
       INSERT INTO cdi_plc_audit
       (
       BILL_ACCOUNT,
       SERVICE_POINT,
       SEGMENT,
       PLC_YEAR,
       PLC_VALUE,
       PLC_TYPE,
       DML_INDICATOR,
       CREATE_USER,
       CREATE_DATE
       )
       VALUES
       (
        :old.bill_account,
        :old.service_point,
        v_SEGMENT,
        SUBSTR(:new.tag_id,1,4),
        :OLD.tag_val,
        v_PLC_TYPE,
        'D',
        v_OSUSER,
        SYSDATE
       );

        v_type:= 'Delete';
--Au.POST_TO_ENTITY_AUDIT_TRAIL(v_entity_id,v_entity_id ,:OLD.BEGIN_DATE,:OLD.END_DATE,'?',NULL,NULL,'CDI_PLC_ICAP_TX ','*',SYSDATE,'DELETE',v_OSUSER,NULL,'?',SUBSTR(:OLD.BILL_ACCOUNT   ||'_'||:OLD.SERVICE_POINT  ||'_'||:OLD.PREMISE_NUMBER ||'_'||:OLD.TAG_ID         ||'_'||:OLD.BEGIN_DATE     ||'_'||:OLD.END_DATE       ||'_'||:OLD.TAG_VAL,1,4000), NULL);
   v_oldvals:=   :OLD.BILL_ACCOUNT   ||'_'||
                 :OLD.SERVICE_POINT  ||'_'||
                 :OLD.PREMISE_NUMBER ||'_'||
                 :OLD.TAG_ID         ||'_'||
                 :OLD.BEGIN_DATE     ||'_'||
                 :OLD.END_DATE       ||'_'||
                 :OLD.TAG_VAL;

  END IF;
  IF v_PLC_TYPE = V_ICAP THEN
    INSERT INTO cdi_reband_plc_accounts (bill_account,service_point)
      VALUES    (v_BILL_ACCOUNT,v_SERVICE_POINT);
  END IF;
END;
/
