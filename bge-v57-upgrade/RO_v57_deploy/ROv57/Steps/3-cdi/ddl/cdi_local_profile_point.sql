BEGIN CDI_DROP_OBJECT('CDI_LOCAL_PROFILE_POINT', 'TABLE'); END;
/

CREATE TABLE CDI_LOCAL_PROFILE_POINT
(
  PROFILE_IDENTIFIER       VARCHAR2(32),
  PROFILE_POINT_DATE       DATE,
  PROFILE_POINT_CUT_DATE   DATE,
  PROFILE_POINT_DAY_NAME   CHAR(3),
  PROFILE_POINT_HOUR       NUMBER(2),
  PROFILE_POINT_VALUE      NUMBER,
  TEMPERATURE              NUMBER(8,2),
  HUMIDITY                 NUMBER(8,2),
  WIND_SPEED               NUMBER(8,2),
  WEATHER_INDEX            NUMBER(8,2),
  PROFILE_POINT_SELECTED   NUMBER(1),
  CONSTRAINT PK_CDI_LOCAL_PROFILE_POINT PRIMARY KEY (PROFILE_IDENTIFIER, PROFILE_POINT_DATE) USING INDEX TABLESPACE &&NERO_INDEX_TABLESPACE
) TABLESPACE &&NERO_DATA_TABLESPACE;