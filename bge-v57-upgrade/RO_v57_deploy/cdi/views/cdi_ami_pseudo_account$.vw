CREATE OR REPLACE VIEW CDI_AMI_PSEUDO_ACCOUNT$ AS
   SELECT
      'AMI ' || TRIM(SUPPLIER) || '_' || TRIM(RTO_POOL_ID)  AS ACCOUNT_EXTERNAL_IDENTIFIER,
      'AMI ' || TRIM(SUPPLIER) || '_' || TRIM(RTO_POOL_ID)  AS ACCOUNT_NAME,
      VOLTAGE_LEVEL                                         AS VOLTAGE_LEVEL,
      'Interval'                                            AS ACCOUNT_METER_TYPE,
      NULL                                                  AS ACCOUNT_DUNS_NUMBER,
      'AMI'                                                 AS ACCOUNT_SIC_CODE,
      NULL                                                  AS ACCOUNT_METER_EXT_IDENTIFIER,
      'BGE'                                                 AS EDC_EXTERNAL_IDENTIFIER,
      'BWI'                                                 AS SERVICE_LOCATION_IDENTIFIER,
      RTO_POOL_ID                                           AS ACCOUNT_POOL_IDENTIFIER,
      MIN(BEGIN_DATE)                                       AS BEGIN_DATE,
      MAX(END_DATE)                                         AS END_DATE,
      COUNT(*)                                              AS ENTRY_COUNT
   FROM CDI_INDIVIDUAL_ACCOUNT_NEW
   WHERE IDR_STATUS <> 'Y'
      AND METER_TYPE <> 'I'
   GROUP BY SUPPLIER, RTO_POOL_ID, VOLTAGE_LEVEL;
