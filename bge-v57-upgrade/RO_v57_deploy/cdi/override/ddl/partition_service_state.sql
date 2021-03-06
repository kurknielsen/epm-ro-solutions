BEGIN CDI_DROP_OBJECT('SERVICE_STATE','TABLE'); END;
/

CREATE TABLE SERVICE_STATE
(
  SERVICE_ID            NUMBER(9)               NOT NULL,
  SERVICE_CODE          CHAR(1 BYTE)            NOT NULL,
  SERVICE_DATE          DATE                    NOT NULL,
  BASIS_AS_OF_DATE      DATE,
  IS_UFE_PARTICIPANT    NUMBER(1),
  SERVICE_ACCOUNTS      NUMBER(8),
  METER_TYPE            CHAR(1 BYTE),
  IS_EXTERNAL_FORECAST  NUMBER(1),
  IS_AGGREGATE_ACCOUNT  NUMBER(1),
  IS_AGGREGATE_POOL     NUMBER(1),
  PROFILE_TYPE          CHAR(1 BYTE),
  PROFILE_SOURCE_DATE   DATE,
  PROFILE_ZERO_COUNT    NUMBER(3),
  USAGE_FACTOR          NUMBER(14,6),
  SERVICE_INTERVALS     NUMBER(3),
  PROXY_DAY_METHOD_ID   NUMBER(9),
  HAS_DETAILS           NUMBER(1)
) TABLESPACE SERVICE_LOAD
PARTITION BY RANGE (SERVICE_DATE)
SUBPARTITION BY LIST (SERVICE_CODE)
SUBPARTITION TEMPLATE (SUBPARTITION B VALUES ('B') TABLESPACE "SERVICE_LOAD", SUBPARTITION A VALUES ('A') TABLESPACE "SERVICE_LOAD")
(  
PARTITION PRIOR_PERIOD VALUES LESS THAN (TO_DATE(' 2019-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS')) TABLESPACE "SERVICE_LOAD" (SUBPARTITION PRIOR_PERIOD_B VALUES('B') TABLESPACE "SERVICE_LOAD", SUBPARTITION PRIOR_PERIOD_A VALUES ('A') TABLESPACE "SERVICE_LOAD")
);

CREATE UNIQUE INDEX PK_SERVICE_STATE ON SERVICE_STATE(SERVICE_ID, SERVICE_CODE, SERVICE_DATE) TABLESPACE NERO_LARGE_INDEX LOCAL
(  
PARTITION PRIOR_PERIOD TABLESPACE NERO_LARGE_INDEX (SUBPARTITION PRIOR_PERIOD_B TABLESPACE NERO_LARGE_INDEX, SUBPARTITION PRIOR_PERIOD_A TABLESPACE NERO_LARGE_INDEX)
);

ALTER TABLE SERVICE_STATE ADD (CONSTRAINT PK_SERVICE_STATE PRIMARY KEY (SERVICE_ID, SERVICE_CODE, SERVICE_DATE) USING INDEX LOCAL ENABLE VALIDATE);

CREATE OR REPLACE TRIGGER SERVICE_STATE_DELETE
	AFTER DELETE ON SERVICE_STATE FOR EACH ROW
DECLARE
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_MODEL_ID NUMBER(9);
BEGIN
	UT.CUT_DATE_RANGE(GA.DEFAULT_MODEL, :old.SERVICE_DATE, LOCAL_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
	IF GA.ENABLE_EXTERNAL_CAST_DELETE THEN
		DELETE SERVICE_LOAD
		WHERE SERVICE_ID = :old.SERVICE_ID
			AND SERVICE_CODE = :old.SERVICE_CODE
			AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;
	ELSE
		DELETE SERVICE_LOAD
		WHERE SERVICE_ID = :old.SERVICE_ID
			AND SERVICE_CODE = :old.SERVICE_CODE
			AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
			AND LOAD_CODE <> GA.EXTERNAL;
	END IF;
END SERVICE_STATE_DELETE;
/
