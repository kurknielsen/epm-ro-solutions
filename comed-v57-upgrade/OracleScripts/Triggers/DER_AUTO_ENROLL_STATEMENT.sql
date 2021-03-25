CREATE OR REPLACE TRIGGER DER_AUTO_ENROLL_STATEMENT
	AFTER INSERT OR UPDATE ON DISTRIBUTED_ENERGY_RESOURCE
DECLARE
	v_COUNT NUMBER;
	v_PROGRAM_IDS NUMBER_COLLECTION;
	v_KEY_NEW UT.STRING_MAP;
	v_KEY_OLD UT.STRING_MAP;
	v_DATA UT.STRING_MAP;
BEGIN
	FOR v_DER_REC IN
		(SELECT DER.*
		FROM DISTRIBUTED_ENERGY_RESOURCE DER, RTO_WORK RW
		WHERE DER.DER_ID = RW.WORK_XID
			AND RW.WORK_ID = CONSTANTS.DER_AUTO_ENROLL_WORK_ID)
	LOOP
		UPDATE DER_PROGRAM DP
		SET DP.BEGIN_DATE = v_DER_REC.BEGIN_DATE
		WHERE DP.DER_ID = v_DER_REC.DER_ID
			AND DP.BEGIN_DATE < v_DER_REC.BEGIN_DATE
			AND NVL(DP.END_DATE, CONSTANTS.HIGH_DATE) >= v_DER_REC.BEGIN_DATE;

		UPDATE DER_PROGRAM DP
		SET DP.END_DATE = v_DER_REC.END_DATE
		WHERE DP.DER_ID = v_DER_REC.DER_ID
			AND DP.BEGIN_DATE <= NVL(v_DER_REC.END_DATE, CONSTANTS.HIGH_DATE)
			AND NVL(DP.END_DATE, CONSTANTS.HIGH_DATE) > NVL(v_DER_REC.END_DATE, CONSTANTS.HIGH_DATE);

		SELECT P.PROGRAM_ID
		BULK COLLECT INTO v_PROGRAM_IDS
		FROM DER_PROGRAM DP, PROGRAM P
		WHERE DP.DER_ID = v_DER_REC.DER_ID
			AND DP.PROGRAM_ID = P.PROGRAM_ID
			AND (NVL(DP.END_DATE, CONSTANTS.HIGH_DATE) < v_DER_REC.BEGIN_DATE
				OR DP.BEGIN_DATE > NVL(v_DER_REC.END_DATE, CONSTANTS.HIGH_DATE));

		IF v_PROGRAM_IDS.COUNT > 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_CANNOT_ORPHAN_ENROLLMENT, 'Cannot limit Resource '||v_DER_REC.DER_NAME||' date range to be outside of its enrollment in the Programs '||TEXT_UTIL.TO_CHAR_ENTITY_LIST(v_PROGRAM_IDS, EC.ED_PROGRAM, FALSE, FALSE));
		END IF;

		FOR v_DP_REC IN
			(SELECT SLP.PROGRAM_ID, GREATEST(SLP.BEGIN_DATE, v_DER_REC.BEGIN_DATE) AS BEGIN_DATE,
				LEAST(NVL(SLP.END_DATE, CONSTANTS.HIGH_DATE), NVL(v_DER_REC.END_DATE, CONSTANTS.HIGH_DATE)) AS END_DATE
			FROM SERVICE_LOCATION_PROGRAM SLP, PROGRAM_DER_TYPE PDT
			WHERE SLP.SERVICE_LOCATION_ID = v_DER_REC.SERVICE_LOCATION_ID
				AND SLP.PROGRAM_ID = PDT.PROGRAM_ID
				AND PDT.DER_TYPE_ID = v_DER_REC.DER_TYPE_ID
				AND SLP.BEGIN_DATE <= NVL(v_DER_REC.END_DATE, CONSTANTS.HIGH_DATE)
				AND NVL(SLP.END_DATE, CONSTANTS.HIGH_DATE) >= v_DER_REC.BEGIN_DATE
				AND SLP.AUTO_ENROLL = 1)
		LOOP
			IF v_DP_REC.END_DATE = CONSTANTS.HIGH_DATE THEN
				v_DP_REC.END_DATE := NULL;
			END IF;

			SELECT COUNT(DP.DER_ID)
			INTO v_COUNT
			FROM DER_PROGRAM DP
			WHERE DP.DER_ID = v_DER_REC.DER_ID
				AND DP.PROGRAM_ID = v_DP_REC.PROGRAM_ID
				AND DP.BEGIN_DATE <= NVL(v_DP_REC.END_DATE, CONSTANTS.HIGH_DATE)
				AND NVL(DP.END_DATE, CONSTANTS.HIGH_DATE) >= v_DP_REC.BEGIN_DATE;

			IF v_COUNT = 0 THEN
				v_KEY_NEW('DER_ID') := UT.GET_LITERAL_FOR_NUMBER(v_DER_REC.DER_ID);
				v_KEY_OLD('DER_ID') := UT.GET_LITERAL_FOR_NUMBER(NULL);
				v_DATA('PROGRAM_ID') := UT.GET_LITERAL_FOR_NUMBER(v_DP_REC.PROGRAM_ID);
				v_DATA('COUNT') := UT.GET_LITERAL_FOR_NUMBER(1);

				UT.PUT_TEMPORAL_DATA_UI('DER_PROGRAM',
										v_DP_REC.BEGIN_DATE,
										v_DP_REC.END_DATE,
										NULL,
										FALSE,
										v_KEY_NEW,
										v_KEY_OLD,
										v_DATA,
										'',
										'',
										'BEGIN_DATE',
										'END_DATE');
			END IF;
		END LOOP;
	END LOOP;

	DELETE FROM RTO_WORK
	WHERE WORK_ID = CONSTANTS.DER_AUTO_ENROLL_WORK_ID;
END DER_AUTO_ENROLL_STATEMENT;
/
