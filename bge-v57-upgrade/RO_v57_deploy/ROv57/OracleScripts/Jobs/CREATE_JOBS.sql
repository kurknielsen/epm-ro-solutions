DECLARE
	-- Set this BOOLEAN to TRUE if you want to drop and recreate existing objects.
	-- Set it to FALSE to only create new objects.
	c_CLEAN CONSTANT BOOLEAN := TRUE;

	-- Cached state (enabled vs. disabled) of existing jobs and programs so we can re-create them
	-- in the same state (in case they already existed in the schema)
	TYPE t_CACHE IS TABLE OF NUMBER(1) INDEX BY VARCHAR2(30);
	v_PROGRAM_CACHE t_CACHE;
	v_JOB_CACHE	t_CACHE;
	-- Cached job parameter values
	TYPE t_PARM_VALS IS TABLE OF ANYDATA INDEX BY VARCHAR2(30);
	TYPE t_JOB_PARM_VALS IS TABLE OF t_PARM_VALS INDEX BY VARCHAR2(30);
	v_JOB_PARMS t_JOB_PARM_VALS;
	---------------------------------------------------------------------------------------------------
	PROCEDURE CACHE_JOB_AND_PROGRAM_STATES AS
	BEGIN
		-- Programs first
		FOR v_PROGRAM IN (SELECT PROGRAM_NAME as NAME,
								CASE ENABLED WHEN 'TRUE' THEN 1 WHEN 'FALSE' THEN 0 ELSE NULL END AS STATE
							FROM USER_SCHEDULER_PROGRAMS) LOOP
			IF v_PROGRAM.STATE IS NOT NULL THEN
				v_PROGRAM_CACHE(v_PROGRAM.NAME) := v_PROGRAM.STATE;
			END IF;
		END LOOP;
		-- Then Jobs
		FOR v_JOB IN (SELECT JOB_NAME as NAME,
								CASE ENABLED WHEN 'TRUE' THEN 1 WHEN 'FALSE' THEN 0 ELSE NULL END AS STATE
							FROM USER_SCHEDULER_JOBS) LOOP
			IF v_JOB.STATE IS NOT NULL THEN
				v_JOB_CACHE(v_JOB.NAME) := v_JOB.STATE;
			END IF;
			-- Also cache job argument values
			FOR v_PARM IN (SELECT NVL(ARGUMENT_NAME, 'ARG' || ARGUMENT_POSITION) as NAME, ANYDATA_VALUE as VALUE
							FROM USER_SCHEDULER_JOB_ARGS
							WHERE JOB_NAME = v_JOB.NAME) LOOP
				v_JOB_PARMS(v_JOB.NAME)(v_PARM.NAME) := v_PARM.VALUE;
			END LOOP;
		END LOOP;
	END CACHE_JOB_AND_PROGRAM_STATES;
	---------------------------------------------------------------------------------------------------
	-- Loop through all procs defined in the JOB_PROGRAMS package, and define a Job Program for them.
	PROCEDURE CREATE_ALL_JOB_PROGRAMS AS
		CURSOR c_PROCS IS
			SELECT PROCEDURE_NAME 
			FROM USER_PROCEDURES
			WHERE OBJECT_NAME = 'JOB_PROGRAMS'
				AND PROCEDURE_NAME LIKE '%_PRG';

		v_PARAM_TABLE STORED_PROC_PARAMETER_TABLE;
		v_PARAM STORED_PROC_PARAMETER_TYPE;
		v_NUM_PARAMS BINARY_INTEGER;
		v_COUNT BINARY_INTEGER;
	BEGIN
		FOR v_PROC IN c_PROCS LOOP
			--Get the list of parameters.
			UT.GET_STORED_PROC_PARAMETERS('JOB_PROGRAMS', v_PROC.PROCEDURE_NAME, 0, v_PARAM_TABLE);
			v_NUM_PARAMS := v_PARAM_TABLE.COUNT;

			-- Drop the old program if it exists.
			SELECT COUNT(1) INTO v_COUNT
			FROM USER_SCHEDULER_PROGRAMS
			WHERE PROGRAM_NAME = v_PROC.PROCEDURE_NAME;
			IF v_COUNT > 0 AND c_CLEAN THEN
				DBMS_SCHEDULER.DROP_PROGRAM(v_PROC.PROCEDURE_NAME, TRUE);
			END IF;
			
			IF v_COUNT = 0 OR c_CLEAN THEN
				-- Re-create the program as disabled.  (It cannot be enabled until its parameters are added.)
				DBMS_SCHEDULER.CREATE_PROGRAM(v_PROC.PROCEDURE_NAME, 'STORED_PROCEDURE', 'JOB_PROGRAMS.'||v_PROC.PROCEDURE_NAME, v_NUM_PARAMS, FALSE);

				-- Add any parameters
				FOR i IN 1 .. v_NUM_PARAMS LOOP
					v_PARAM := v_PARAM_TABLE(i);
					
					-- USER_ARGUMENTS has a column called DEFAULT_VALUE, but it is "for future use" and always returns null.
					--   so, we just always set the default value as null.
					DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT(v_PROC.PROCEDURE_NAME, v_PARAM.POSITION, v_PARAM.PARAMETER_NAME, v_PARAM.PARAMETER_TYPE, TO_CHAR(NULL));
				END LOOP;

				-- Enable the Program if it is new or if it was enabled before we re-created it
				IF NOT (v_PROGRAM_CACHE.EXISTS(v_PROC.PROCEDURE_NAME) AND v_PROGRAM_CACHE(v_PROC.PROCEDURE_NAME) = 0) THEN
					DBMS_SCHEDULER.ENABLE(v_PROC.PROCEDURE_NAME);
				END IF;
			END IF;
		END LOOP;
	END CREATE_ALL_JOB_PROGRAMS;
	---------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_JOB_SCHEDULE
		(
		p_SCHEDULE_NAME IN VARCHAR2,
		p_REPEAT_INTERVAL IN VARCHAR2,
		p_COMMENTS IN VARCHAR2
		) AS
		v_COUNT BINARY_INTEGER;
	BEGIN
		-- Recreate Schedule
		SELECT COUNT(1) INTO v_COUNT
		FROM USER_SCHEDULER_SCHEDULES
		WHERE SCHEDULE_NAME = p_SCHEDULE_NAME;

		IF v_COUNT > 0 AND c_CLEAN THEN
			DBMS_SCHEDULER.DROP_SCHEDULE(p_SCHEDULE_NAME, TRUE);
		END IF;

		IF v_COUNT = 0 OR c_CLEAN THEN
			DBMS_SCHEDULER.CREATE_SCHEDULE(p_SCHEDULE_NAME, SYSDATE, p_REPEAT_INTERVAL, NULL, p_COMMENTS);
		END IF;

	END CREATE_JOB_SCHEDULE;
	---------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_JOB
		(
		p_USER_ID IN NUMBER,
		p_JOB_NAME IN VARCHAR2,
		p_PROCEDURE_NAME IN VARCHAR2,
		p_SCHEDULE_NAME IN VARCHAR2,
		p_COMMENTS IN VARCHAR2
		) AS
		v_COUNT BINARY_INTEGER;
		v_JOB_CLASS USER_SCHEDULER_JOBS.JOB_CLASS%TYPE;
	BEGIN

		SELECT COUNT(1)
		INTO v_COUNT
		FROM USER_SCHEDULER_JOBS
		WHERE UPPER(JOB_NAME) = UPPER(p_JOB_NAME);

		IF v_COUNT > 0 AND c_CLEAN THEN
			DBMS_SCHEDULER.DROP_JOB(p_JOB_NAME);
		END IF;

		IF v_COUNT = 0 OR c_CLEAN THEN
			v_JOB_CLASS := NVL(GET_DICTIONARY_VALUE('Job Class', 0, 'System', p_PROCEDURE_NAME), 'DEFAULT_JOB_CLASS');
			--Create the job as disabled.
			DBMS_SCHEDULER.CREATE_JOB(p_JOB_NAME, p_PROCEDURE_NAME, p_SCHEDULE_NAME, v_JOB_CLASS, FALSE, TRUE, p_COMMENTS);
			
			-- Attempt to restore job argument values
			IF v_JOB_PARMS.EXISTS(p_JOB_NAME) THEN
				FOR v_PRG_PARM IN (SELECT NVL(ARGUMENT_NAME, 'ARG' || ARGUMENT_POSITION) as NAME
									FROM USER_SCHEDULER_PROGRAM_ARGS
									WHERE PROGRAM_NAME = p_PROCEDURE_NAME) LOOP
					IF v_JOB_PARMS(p_JOB_NAME).EXISTS(v_PRG_PARM.NAME) THEN
						DBMS_SCHEDULER.SET_JOB_ANYDATA_VALUE(p_JOB_NAME, v_PRG_PARM.NAME, v_JOB_PARMS(p_JOB_NAME)(v_PRG_PARM.NAME));
					END IF;
				END LOOP;
			END IF;
			
			-- Remove any previous JOB_DATA
			DELETE FROM JOB_DATA D WHERE D.JOB_NAME = p_JOB_NAME;
			
			IF SQL%ROWCOUNT > 0 THEN
				LOGS.LOG_WARN('Deleted JOB_DATA for JOB_NAME = ' || p_JOB_NAME);
			END IF;
			
			--Insert the new JOB_DATA
			INSERT INTO JOB_DATA
			   (JOB_NAME, USER_ID, JOB_THREAD_ID, ACTION_CHAIN_NAME, ACTION_DISPLAY_NAME, NOTIFICATION_EMAIL_ADDRESS)
			VALUES
			   (p_JOB_NAME, p_USER_ID, NULL, 'System Job', NULL, NULL);
			
			-- Enable the job if it was previously enabled.
			-- Otherwise, a user must go to Background Job Status screen to enable it.
			IF v_JOB_CACHE.EXISTS(p_JOB_NAME) AND v_JOB_CACHE(p_JOB_NAME) <> 0 THEN
				BEGIN
					DBMS_SCHEDULER.ENABLE(p_JOB_NAME);
				EXCEPTION
					WHEN OTHERS THEN
						ERRS.LOG_AND_CONTINUE('Job: '||p_JOB_NAME||' was previously enabled but could not be re-enabled after being updated.');
				END;
			END IF;
		END IF;
	END CREATE_JOB;
	
BEGIN
	CACHE_JOB_AND_PROGRAM_STATES;

	-- Create a program for each procedure in the Job_Programs package.
	CREATE_ALL_JOB_PROGRAMS;

	-- Create a set of Schedules.
	CREATE_JOB_SCHEDULE('EVERY_MINUTE', 'FREQ=MINUTELY;INTERVAL=1;BYSECOND=0', 'Runs every minute, on the minute');
	CREATE_JOB_SCHEDULE('EVERY_5_MINUTES', 'FREQ=MINUTELY;INTERVAL=5;BYSECOND=30', 'Runs every 5 minutes, 30 seconds past the minute');
	CREATE_JOB_SCHEDULE('WEEKLY', 'FREQ=WEEKLY;BYHOUR=2;BYMINUTE=12;BYSECOND=15', 'Runs once a week (at 2:12am)');
	CREATE_JOB_SCHEDULE('EVERY_DAY_AT_4AM', 'FREQ=DAILY;BYHOUR=4;BYMINUTE=0;BYSECOND=45', 'Runs every day at 4:00am');
	CREATE_JOB_SCHEDULE('EVERY_HOUR', 'FREQ=HOURLY;BYMINUTE=3;BYSECOND=15', 'Runs every hour at 3 minutes after the top of the hour');

	-- Create the default Jobs
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'PROCESS_EVENT_CLEANUP_JOB', 'CLEANUP_PROCESS_EVENTS_PRG', 'EVERY_DAY_AT_4AM', 'Runs the CLEANUP_PROCESS_EVENTS_JOB to process any expired events.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'LOB_STAGING_CLEANUP_JOB', 'CLEANUP_LOB_STAGING_PRG', 'WEEKLY', 'Clean up anything in the LOB_STAGING tables over 30 days old.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_MAIL_MONITOR, 'MAIL_MONITOR_JOB', 'PROCESS_QUEUED_EMAILS_PRG', 'EVERY_5_MINUTES', 'Monitor e-mail log to periodically send queued e-mails');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_PS_QUEUES_MONITOR, 'PROCESS_QUEUES_MONITOR_JOB', 'PROCESS_QUEUES_MONITOR_PRG', 'EVERY_5_MINUTES', 'Runs the Process Queues Monitor to process any new Job Queue Items.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_REACTOR, 'REACTOR_JOB', 'REACTOR_PRG', 'EVERY_MINUTE', 'Runs the Reactor to process any new data changes.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'REBUILD_CUSTOM_REALMS_JOB', 'REBUILD_CUSTOM_REALMS_PRG', 'EVERY_HOUR', 'Updates custom System Realms to synch with possible changes made to related tables.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'APPLY_AUTO_DATA_LOCKS_JOB', 'APPLY_AUTO_DATA_LOCKS_PRG', 'EVERY_5_MINUTES', 'Applies any Automatic Data Lock Groups.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'SEND_APPROVED_INVOICES_JOB', 'SEND_APPROVED_INVOICES_PRG', 'EVERY_DAY_AT_4AM', 'Send all approved invoices through email.');
	CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'EC_CERT_EXPIR_ALERT_JOB', 'EC_CERT_EXPIR_ALERT_PRG', 'EVERY_DAY_AT_4AM', 'Email all external credential certificates that will expire in the next 30 days.');
    CREATE_JOB(SECURITY_CONTROLS.c_SUSER_ID_SYSTEM, 'OADR_POLL_JOB', 'OADR_POLL_PRG', 'EVERY_DAY_AT_4AM', 'Poll OpenADR for UpdateReports.');

    COMMIT;

END;
/
