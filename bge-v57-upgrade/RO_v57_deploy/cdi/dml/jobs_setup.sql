DECLARE
c_INSTALL CONSTANT BOOLEAN := TRUE;
v_COUNT PLS_INTEGER;
   PROCEDURE REGISTER_SCHEDULE(p_SCHEDULE_NAME IN VARCHAR2, p_SCHEDULE_DESC IN VARCHAR2, p_SCHEDULE_SPEC IN VARCHAR2) AS
   v_TIMESTAMP TIMESTAMP WITH TIME ZONE := TIMESTAMP '2011-01-01 00:00:00 US/Eastern';
   BEGIN
      SELECT COUNT(*) INTO v_COUNT FROM USER_SCHEDULER_SCHEDULES WHERE SCHEDULE_NAME = p_SCHEDULE_NAME;
      IF v_COUNT > 0 THEN
         DBMS_OUTPUT.PUT_LINE('Drop Schedule: ' || p_SCHEDULE_NAME);
         DBMS_SCHEDULER.DROP_SCHEDULE(p_SCHEDULE_NAME, TRUE);
      END IF;
      IF c_INSTALL THEN
         DBMS_OUTPUT.PUT_LINE('Create Schedule: ' || p_SCHEDULE_NAME);
         DBMS_SCHEDULER.CREATE_SCHEDULE(p_SCHEDULE_NAME, v_TIMESTAMP, p_SCHEDULE_SPEC, NULL, p_SCHEDULE_DESC);
      END IF;
   END REGISTER_SCHEDULE;
   PROCEDURE REGISTER_PROGRAM(p_PROGRAM_NAME IN VARCHAR2, p_STORED_PROCEDURE_NAME IN VARCHAR2) AS
   BEGIN
      SELECT COUNT(*) INTO v_COUNT FROM USER_SCHEDULER_PROGRAMS WHERE PROGRAM_NAME = p_PROGRAM_NAME;
      IF v_COUNT > 0 THEN
         DBMS_OUTPUT.PUT_LINE('Drop Program: ' || p_PROGRAM_NAME);
         DBMS_SCHEDULER.DROP_PROGRAM(p_PROGRAM_NAME, TRUE);
      END IF;
      IF c_INSTALL THEN
         DBMS_OUTPUT.PUT_LINE('Create Program: ' || p_PROGRAM_NAME);
         DBMS_SCHEDULER.CREATE_PROGRAM(p_PROGRAM_NAME, 'STORED_PROCEDURE', p_STORED_PROCEDURE_NAME, 0, TRUE);
      END IF;
   END REGISTER_PROGRAM;
   PROCEDURE REGISTER_JOB(p_JOB_NAME IN VARCHAR2, p_JOB_DESC IN VARCHAR2, p_PROGRAM_NAME IN VARCHAR2, p_SCHEDULE_NAME IN VARCHAR2) AS
   BEGIN
      SELECT COUNT(*) INTO v_COUNT FROM USER_SCHEDULER_JOBS WHERE JOB_NAME = SUBSTR(p_JOB_NAME, INSTR(p_JOB_NAME,'.') + 1);
      IF v_COUNT > 0 THEN
         DBMS_OUTPUT.PUT_LINE('Drop Job: ' || p_JOB_NAME);
         DBMS_SCHEDULER.DROP_JOB(p_JOB_NAME);
         DELETE JOB_DATA WHERE JOB_NAME = p_JOB_NAME;
         COMMIT;
      END IF;
      IF c_INSTALL THEN
         DBMS_OUTPUT.PUT_LINE('Create Job: ' || p_JOB_NAME);
         DBMS_SCHEDULER.CREATE_JOB(p_JOB_NAME, p_PROGRAM_NAME, p_SCHEDULE_NAME, 'DEFAULT_JOB_CLASS', FALSE, TRUE, p_JOB_DESC);
         INSERT INTO JOB_DATA(JOB_NAME, USER_ID, JOB_THREAD_ID, ACTION_CHAIN_NAME, ACTION_DISPLAY_NAME, NOTIFICATION_EMAIL_ADDRESS)
         VALUES (p_JOB_NAME, SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, NULL, 'System Job', NULL, NULL);
         COMMIT;
      END IF;
   END REGISTER_JOB;
BEGIN
-- Register Schedules Used By Jobs--
   REGISTER_SCHEDULE('EVERY_DAY_1AM',  'Daily At 1AM',  'FREQ=DAILY;BYHOUR=1;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_2AM',  'Daily At 2AM',  'FREQ=DAILY;BYHOUR=2;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_3AM',  'Daily At 3AM',  'FREQ=DAILY;BYHOUR=3;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_4PM',  'Daily At 4PM',  'FREQ=DAILY;BYHOUR=4;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_5AM',  'Daily At 5AM',  'FREQ=DAILY;BYHOUR=5;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_6AM',  'Daily At 6AM',  'FREQ=DAILY;BYHOUR=6;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_7AM',  'Daily At 7AM',  'FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_8AM',  'Daily At 8AM',  'FREQ=DAILY;BYHOUR=8;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_9AM',  'Daily At 9AM',  'FREQ=DAILY;BYHOUR=8;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_10AM', 'Daily At 10AM', 'FREQ=DAILY;BYHOUR=10;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_11AM', 'Daily At 11AM', 'FREQ=DAILY;BYHOUR=11;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_12PM', 'Daily At 12PM', 'FREQ=DAILY;BYHOUR=12;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_1PM',  'Daily At 1PM',  'FREQ=DAILY;BYHOUR=13;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_2PM',  'Daily At 2PM',  'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_3PM',  'Daily At 3PM',  'FREQ=DAILY;BYHOUR=15;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_4PM',  'Daily At 4PM',  'FREQ=DAILY;BYHOUR=16;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_5PM',  'Daily At 5PM',  'FREQ=DAILY;BYHOUR=17;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_6PM',  'Daily At 6PM',  'FREQ=DAILY;BYHOUR=18;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_7PM',  'Daily At 7PM',  'FREQ=DAILY;BYHOUR=19;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_8PM',  'Daily At 8PM',  'FREQ=DAILY;BYHOUR=20;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_9PM',  'Daily At 9PM',  'FREQ=DAILY;BYHOUR=21;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_10PM', 'Daily At 10PM', 'FREQ=DAILY;BYHOUR=22;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_11PM', 'Daily At 11PM', 'FREQ=DAILY;BYHOUR=23;BYMINUTE=0;BYSECOND=0');
   REGISTER_SCHEDULE('EVERY_DAY_12AM', 'Daily At 12AM', 'FREQ=DAILY;BYHOUR=0;BYMINUTE=0;BYSECOND=0');
-- Register The Programs -- 
   REGISTER_PROGRAM('ACCOUNT_DATA_SYNC_PRG',      'CDI_TASK.ACCOUNT_DATA_SYNC'); 
   REGISTER_PROGRAM('WEATHER_DATA_IMPORT_PRG',    'CDI_TASK.WEATHER_DATA_IMPORT'); 
   REGISTER_PROGRAM('PERIOD_USAGE_IMPORT_PRG',    'CDI_TASK.PERIOD_USAGE_IMPORT'); 
   REGISTER_PROGRAM('INTERVAL_USAGE_IMPORT_PRG',  'CDI_TASK.USAGE_USAGE_IMPORT'); 
   REGISTER_PROGRAM('CUSTOMER_DATA_IMPORT_PRG',   'CDI_TASK.CUSTOMER_DATA_IMPORT'); 
   REGISTER_PROGRAM('INITIAL_BID_BLOCK_SIZE_PRG', 'CDI_TASK.INITIAL_BID_BLOCK_SIZE'); 
-- Register The Jobs -- 
   REGISTER_JOB('ACCOUNT_DATA_SYNC_JOB',     'Synchronize The Retail Operations Data Model From Pre-Staged Content', 'ACCOUNT_DATA_SYNC_PRG', 'EVERY_DAY_4AM'); 
   REGISTER_JOB('WEATHER_DATA_IMPORT_JOB',   'Import Weather Data From Pre-Staged Content', 'WEATHER_DATA_IMPORT_PRG', 'EVERY_DAY_5AM'); 
   REGISTER_JOB('PERIOD_USAGE_IMPORT_JOB',   'Import Period Usage Data From Pre-Staged-Content', 'PERIOD_USAGE_IMPORT_PRG', 'EVERY_DAY_10PM'); 
   REGISTER_JOB('INTERVAL_USAGE_IMPORT_JOB', 'Import Interval Usage Data From Pre-Staged-Content', 'INTERVAL_USAGE_IMPORT_PRG', 'EVERY_DAY_5AM'); 
   REGISTER_JOB('CUSTOMER_DATA_IMPORT_JOB',  'Import Customer Data From Pre-Staged-Content', 'CUSTOMER_DATA_IMPORT_PRG',  'EVERY_DAY_8PM'); 
   REGISTER_JOB('INITIAL_BID_BLOCK_SIZE',    'Set The Initial Bid Block Size', 'INITIAL_BID_BLOCK_SIZE_PRG',  'EVERY_DAY_6AM'); 
END;
/
