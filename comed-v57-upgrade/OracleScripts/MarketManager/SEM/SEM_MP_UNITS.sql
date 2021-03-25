CREATE OR REPLACE VIEW SEM_MP_UNITS AS
SELECT   S.PSE_ID,
		 S.POD_ID,
         TEA.ATTRIBUTE_VAL AS RESOURCE_TYPE,
		 GREATEST(S.BEGIN_DATE,TEA.BEGIN_DATE) as EFFECTIVE_DATE,
		 LEAST(NVL(S.END_DATE,HIGH_DATE), NVL(TEA.END_DATE,HIGH_DATE)) as EXPIRATION_DATE,
		 GREATEST(TEA.ENTRY_DATE, S.ENTRY_DATE) as ENTRY_DATE,
		 (SELECT MAX(T.ATTRIBUTE_VAL)
		 	FROM TEMPORAL_ENTITY_ATTRIBUTE T,
				ENTITY_ATTRIBUTE EA
			WHERE EA.ENTITY_DOMAIN_ID = -160
				and EA.ATTRIBUTE_NAME = 'Jurisdiction'
				and T.ATTRIBUTE_ID = EA.ATTRIBUTE_ID
				AND T.OWNER_ENTITY_ID = S.PSE_ID
				AND T.ATTRIBUTE_ID = EA.ATTRIBUTE_ID) AS JURISDICTION
      FROM SEM_SERVICE_POINT_PSE S,
           TEMPORAL_ENTITY_ATTRIBUTE TEA
      WHERE S.POD_ID = TEA.OWNER_ENTITY_ID
            AND TEA.ATTRIBUTE_NAME = 'Resource Type'
			AND S.BEGIN_DATE <= NVL(TEA.END_DATE, HIGH_DATE)
			AND TEA.BEGIN_DATE <= NVL(S.END_DATE, HIGH_DATE);
