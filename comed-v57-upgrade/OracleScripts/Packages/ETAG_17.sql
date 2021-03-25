CREATE OR REPLACE PACKAGE ETAG_17 IS
--Revision $Revision: 1.10 $

FUNCTION WHAT_VERSION RETURN VARCHAR;

  FUNCTION TestHarness RETURN XMLTYPE;

  PROCEDURE EXPORT_ETAG(pTransactionID IN NUMBER);

	FUNCTION GetProfileTable(pTransactionID IN NUMBER,
													 pStartDate     IN DATE,
													 pEndDate       IN DATE) RETURN ProfileRecordTable;
END ETAG_17;
/
CREATE OR REPLACE PACKAGE BODY ETAG_17 IS

  /*----------------------------------------------------------------------------
  Returns the service point ID given its NERC code.
  -----------------------------------------------------------------------------*/
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.10 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
	FUNCTION GetServicePointIDFromNERCCode(pNercCode IN VARCHAR2) RETURN NUMBER IS
		lID NUMBER(9);
	BEGIN
		SELECT PT.SERVICE_POINT_ID
			INTO lID
			FROM SERVICE_POINT PT
		 WHERE PT.SERVICE_POINT_NERC_CODE = pNercCode;
		RETURN lID;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END GetServicePointIDFromNERCCode;

  /*----------------------------------------------------------------------------
  Returns the PSE ID given its NERC code.
  -----------------------------------------------------------------------------*/
	FUNCTION GetPSEIDFromNERCCode(pNercCode IN VARCHAR2) RETURN NUMBER IS
		lID NUMBER(9);
	BEGIN
		SELECT PSE.PSE_ID
			INTO lID
			FROM PSE
		 WHERE PSE.PSE_NERC_CODE = pNercCode;
		RETURN lID;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END GetPSEIDFromNERCCode;

  /*----------------------------------------------------------------------------
  Given an entity ID and domain name, return the ContactInfo complex type.
  -----------------------------------------------------------------------------*/
	FUNCTION GetContactInfo(pEntityID IN NUMBER, pEntityName IN VARCHAR2)
		RETURN XMLTYPE IS
		xmlContact XMLTYPE;
		lContactID NUMBER;
	BEGIN
		SELECT E.CONTACT_ID
			INTO lContactID
			FROM ENTITY_DOMAIN_CONTACT E
		 WHERE E.ENTITY_DOMAIN_ID =
					 (SELECT ED.ENTITY_DOMAIN_ID
							FROM ENTITY_DOMAIN ED
						 WHERE UPPER(ENTITY_DOMAIN_NAME) = UPPER(pEntityName))
			 AND E.OWNER_ENTITY_ID = pEntityID
			 AND E.CATEGORY_ID =
					 (SELECT C.CATEGORY_ID
							FROM CATEGORY C
						 WHERE UPPER(C.CATEGORY_NAME) = 'ETAG');

		SELECT XMLELEMENT("ContactInfo", XMLELEMENT("Contact", CONTACT.CONTACT_NAME),
											XMLELEMENT("Phone", PHONE.PHONE_NUMBER),
											XMLELEMENT("Fax", FAX.PHONE_NUMBER))
			INTO xmlContact
			FROM CONTACT, PHONE_NUMBER PHONE, PHONE_NUMBER FAX
		 WHERE CONTACT.CONTACT_ID = lContactID
			 AND PHONE.CONTACT_ID = CONTACT.CONTACT_ID
			 AND FAX.CONTACT_ID = CONTACT.CONTACT_ID
			 AND UPPER(PHONE.PHONE_TYPE) = 'WORK'
			 AND UPPER(FAX.PHONE_TYPE) = 'FAX';

		RETURN xmlContact;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END GetContactInfo;

	/*----------------------------------------------------------------------------
  Given a transaction ID and start and end dates, return the ProfileRecordTable
  for the transaction's IT_SCHEDULE values over the date range. The returned
  table has fields for schedule date, schedule amount, and duration in hours
  that the value is constant (essentially, we're returning a sparse representaion
  of the IT_SCHEDULE_data).
  18-OCT-2004, jbc: above doc doesn't match what actually happens anymore. Fix it!

  -----------------------------------------------------------------------------*/
	FUNCTION GetProfileTable(pTransactionID IN NUMBER,
													 pStartDate     IN DATE,
													 pEndDate       IN DATE) RETURN ProfileRecordTable IS

		dte            DATE;
		lProfileTable  ProfileRecordTable := ProfileRecordTable();
		lProfileRecord ProfileRecord;

		strDate VARCHAR2(32); -- debugging only

		CURSOR cSchedule IS
			SELECT ITX.SCHEDULE_DATE, ITX.AMOUNT
				FROM IT_SCHEDULE ITX
			 WHERE ITX.SCHEDULE_DATE BETWEEN pStartDate AND pEndDate
				 AND ITX.TRANSACTION_ID = pTransactionID;
	BEGIN
		dte            := TRUNC(pStartDate, 'DD');
		lProfileRecord := ProfileRecord(pStartDate, pStartDate, pStartDate, NULL);
		FOR lRec IN cSchedule LOOP
			strDate := to_char(lRec.Schedule_Date, 'mm/dd/yyyy hh24:mi');

			-- get a new row whenever the date changes (not the time,
			-- just the date) or whenever the amount changes
			IF (lRec.Amount != lProfileRecord.amount) OR
				 (lProfileRecord.amount IS NULL) OR (lRec.Schedule_Date = dte + 1) THEN
				lProfileTable.EXTEND();
				lProfileRecord.stopDate := lRec.SCHEDULE_DATE;
				lProfileTable(lProfileTable.LAST) := lProfileRecord;
				lProfileRecord := ProfileRecord(trunc(lRec.SCHEDULE_DATE, 'DD'),
																				lRec.SCHEDULE_DATE, lRec.SCHEDULE_DATE,
																				lRec.AMOUNT);
				IF lRec.Schedule_Date = dte + 1 THEN
					dte := dte + 1;
				END IF;
			END IF;
		END LOOP;

		-- delete the first record, since it was just in there to get us started
		lProfileTable.DELETE(lProfileTable.FIRST);

		RETURN lProfileTable;
	END GetProfileTable;

	/*----------------------------------------------------------------------------
  Returns the DateTimeList element, populated with the individual days in
  the tag's date range.

  The eTAG spec and the eTAG XSD don't appear to have much relationship to one
  another. Either there's something I'm missing (that could be cleared up with
  a tag example), or there's just no true doc on this point. To make things easy,
  we're going to do it like this: DateTimeList will always have just one
  DateTime: the start day of the transaction. The RelativeBlock list will contain,
  for start and stop time offsets, the number of hours since the start day
  of the transaction.
  -----------------------------------------------------------------------------*/
	FUNCTION GetDateTimeList(pProfileTable IN ProfileRecordTable) RETURN XMLTYPE IS
		xmlDateBlock sys.xmltype;
	BEGIN
		-- get the unique block start dates for the DateTimeList xml fragment
		SELECT XMLELEMENT("DateTimeList",
											XMLAGG(XMLELEMENT("DateTime",
																				 to_char(blockStartDate, 'YYYY-MM-DD') || 'T' ||
																					to_char(blockStartDate, 'HH24:MI:SS'))))
			INTO xmlDateBlock
			FROM (SELECT DISTINCT blockStartDate
							FROM TABLE(CAST(pProfileTable AS ProfileRecordTable)));
	
		RETURN xmlDateBlock;
	END GetDateTimeList;

	/*----------------------------------------------------------------------------
  Returns the RelativeBlockList element given a ProfileTable. See the doc for
  GetDateTimeList above for a little more information, but suffice to say
  here that each TimeOffset element is the number of hours since the start
  day of the transaction. TimeOffset elements have a type of "duration", which
  is a bizarro representation that looks like PnYnMnDTnHnMnS. We are only 
  interested in the hour field, so our durations will look like PTnH.
  -----------------------------------------------------------------------------*/
	FUNCTION GetRelativeBlockList(pProfileTable IN ProfileRecordTable)
		RETURN XMLTYPE IS
		xmlRelativeDateBlock sys.xmltype;
	BEGIN
		-- get the time offsets and mw levels for the RelativeBlockList xml fragment
		SELECT XMLELEMENT("RelativeBlockList",
											XMLAGG(XMLELEMENT("RelativeBlock",
																				 XMLELEMENT("RelativeStart",
																										 XMLELEMENT("TimeOffset",
																																 'PT' ||
																																	to_char(startDate,
																																					'hh24') || 'H')),
																				 XMLELEMENT("MWLevel", amount),
																				 XMLELEMENT("RelativeStop",
																										 XMLELEMENT("TimeOffset",
																																 'PT' ||
																																	to_char(stopDate,
																																					'hh24') || 'H')))))
			INTO xmlRelativeDateBlock
			FROM TABLE(CAST(pProfileTable AS ProfileRecordTable));
		RETURN xmlRelativeDateBlock;
	END GetRelativeBlockList;

	/*----------------------------------------------------------------------------
  Retrieves the ProfileSet element given a ProfileTable (which in turn
  contains the representation of the transaction's schedule data).
  -----------------------------------------------------------------------------*/
	FUNCTION GetProfileSet(pProfileTable IN ProfileRecordTable) RETURN XMLTYPE IS
		xmlProfileSet        xmltype;
		xmlDateBlock         sys.xmltype;
		xmlRelativeDateBlock sys.xmltype;
	BEGIN
		xmlDateBlock         := GetDateTimeList(pProfileTable);
		xmlRelativeDateBlock := GetRelativeBlockList(pProfileTable);

		-- now get the whole profile set, including the DateTimeList and RelativeBlockList fragments
		SELECT XMLELEMENT("ProfileSet",
											XMLELEMENT("BaseProfileList",
																	XMLELEMENT("BaseProfile",
																							XMLELEMENT("ProfileID", 1),
																							XMLELEMENT("RelativeProfileList",
																													XMLELEMENT("RelativeProfile",
																																			xmlDateBlock,
																																			xmlRelativeDateBlock,
																																			XMLELEMENT("ProfileTypeList",
																																									XMLELEMENT("ProfileType",
																																															'MARKETLEVEL')))))))
			INTO xmlProfileSet
			FROM DUAL;

		RETURN xmlProfileSet;
	END GetProfileSet;

	/*----------------------------------------------------------------------------

  -----------------------------------------------------------------------------*/
	FUNCTION GetTransmissionAllocationList(pProfileTable IN ProfileRecordTable)
		RETURN XMLTYPE IS
		xmlDateBlock                  sys.xmltype;
		xmlRelativeDateBlock          sys.xmltype;
		xmlAllocationBaseProfile xmltype;
    xmlTAList xmltype;
		lProfileTable                 ProfileRecordTable;

	BEGIN
		xmlDateBlock         := GetDateTimeList(pProfileTable);
		xmlRelativeDateBlock := GetRelativeBlockList(pProfileTable);

    -- transmission allocation ID: unique ID for this allocation
    -- ParentSegmentRef: segment number of this transmission segment
    -- CurrentCorrectionID: correction ID of the most recent correction applied to this segment
    -- TransProductRef: code for a NERC-registered product (see PRODUCT_REGISTRY.csv)
    -- ContractNumber: ref for service agreement
    -- TransmissionCustomerCode: NERC ID for transmission customer
    /*
    SELECT xmlelement("TransmissionAllocationList",
    xmlagg(xmlelement("TransmissionAllocation",
    xmlelement("TransmissionAllocationID", foo),
    xmlelement("ParentSegmentRef", foo),
    xmlelement("CurrentCorrectionID", 0),
    xmlelement("TransProductRef", 10),
    xmlelement("ContractNumber", 0),
    xmlelement("TransmissionCustomerCode", 0)
    -- ,xmlDateBlock, xmlRelativeDateBlock
    )))
    FROM foo;
    */
		RETURN xmlTAList;
	END GetTransmissionAllocationList;

	/*----------------------------------------------------------------------------
  Retrieves the MarketSegmentList node for a given Market Path.
  -----------------------------------------------------------------------------*/
	FUNCTION GetMarketSegmentList(pMarketPathID IN NUMBER) RETURN XMLTYPE IS
		xmlMktSegList XMLTYPE;
	BEGIN
		SELECT XMLELEMENT("MarketSegmentList",
											XMLAGG(XMLELEMENT("MarketSegment", 
																	XMLELEMENT("MarketSegmentID", MPMS.SEGMENT_ORDER),
																	XMLELEMENT("PSECode", PSE.PSE_NERC_CODE))))
			INTO xmlMktSegList
			FROM MARKET_SEGMENT M, MKT_PATH_MKT_SEG MPMS, PSE
		 WHERE MPMS.MARKET_PATH_ID = pMarketPathID
			 AND M.MARKET_SEGMENT_ID = MPMS.MARKET_SEGMENT_ID
			 AND PSE.PSE_ID = M.PSE_ID
		 ORDER BY MPMS.SEGMENT_ORDER;
		RETURN xmlMktSegList;
	END GetMarketSegmentList;

	/*----------------------------------------------------------------------------
  Retrieves data for a physical segment of type Generation.
  -----------------------------------------------------------------------------*/
	FUNCTION GetGenerationSegment(pServicePointID IN NUMBER) RETURN XMLTYPE IS
		xmlSegment XMLTYPE;
	BEGIN
		SELECT XMLELEMENT("Generation",
											XMLELEMENT("ResourceList",
																	XMLELEMENT("Resource",
																							XMLELEMENT("TaggingPointID",
																													PT.SERVICE_POINT_NERC_CODE),
																							XMLELEMENT("ProfileRef", '1'))))
			INTO xmlSegment
			FROM SERVICE_POINT PT
		 WHERE PT.SERVICE_POINT_ID = pServicePointID;
  	RETURN xmlSegment;
	END GetGenerationSegment;

	/*----------------------------------------------------------------------------
  Retrieves data for a physical segment of type Load.
  -----------------------------------------------------------------------------*/
	FUNCTION GetLoadSegment(pServicePointID IN NUMBER) RETURN XMLTYPE IS
		xmlSegment XMLTYPE;
	BEGIN
		SELECT XMLELEMENT("Load",
											XMLELEMENT("ResourceList",
																	XMLELEMENT("Resource",
																							XMLELEMENT("TaggingPointID",
																													PT.SERVICE_POINT_NERC_CODE),
																							XMLELEMENT("ProfileRef", '1'))))
			INTO xmlSegment
			FROM SERVICE_POINT PT
		 WHERE PT.SERVICE_POINT_ID = pServicePointID;
		RETURN xmlSegment;
	END GetLoadSegment;

	/*----------------------------------------------------------------------------
  Retrieves data for a physical segment of type Transmission.
  -----------------------------------------------------------------------------*/
	FUNCTION GetTransmissionSegment(pPODID IN NUMBER, pPORID IN NUMBER)
		RETURN XMLTYPE IS
		xmlSegment XMLTYPE;
	BEGIN
		SELECT XMLELEMENT("Transmission",
											XMLELEMENT("POR", POR.SERVICE_POINT_NERC_CODE),
											XMLELEMENT("POD", POD.SERVICE_POINT_NERC_CODE),
											XMLELEMENT("TransmissionProfileList",
																	XMLELEMENT("TransmissionProfile",
																							XMLELEMENT("PORProfile",
																													XMLELEMENT("ProfileRef", '1')),
																							XMLELEMENT("PODProfile",
																													XMLELEMENT("ProfileRef", '1')))))
			INTO xmlSegment
			FROM SERVICE_POINT POR, SERVICE_POINT POD
		 WHERE POD.SERVICE_POINT_ID = pPODID
			 AND POR.SERVICE_POINT_ID = pPORID;
		RETURN xmlSegment;
	END GetTransmissionSegment;

	/*----------------------------------------------------------------------------
  Retrieves the physical segments associated with a market segment, and
  returns a PhysicalSegmentList element.
  -----------------------------------------------------------------------------*/
	FUNCTION GetPhysicalSegmentList(pMarketPathID IN NUMBER) RETURN XMLTYPE IS
		xmlPhysSegList XMLTYPE;
		xmlFragment    XMLTYPE;
		CURSOR cSegments IS
			SELECT MPMS.SEGMENT_ORDER AS MKT_SEGMENT_ORDER,
						 MSPS.SEGMENT_ORDER AS PHYS_SEGMENT_ORDER,
						 PS.SEGMENT_TYPE,
						 PS.ORIGIN_ID,
						 PS.DESTINATION_ID
				FROM MKT_PATH_MKT_SEG MPMS, MKT_SEG_PHYS_SEG MSPS, PHYSICAL_SEGMENT PS
			 WHERE MPMS.MARKET_PATH_ID = pMarketPathID
				 AND MPMS.MARKET_SEGMENT_ID = MSPS.MARKET_SEGMENT_ID
				 AND MSPS.PHYSICAL_SEGMENT_ID = PS.PHYSICAL_SEGMENT_ID
			 ORDER BY MKT_SEGMENT_ORDER, PHYS_SEGMENT_ORDER;
	BEGIN
		FOR recSegment IN cSegments LOOP
			-- get the segment gen/load/transmission node
			IF recSegment.SEGMENT_TYPE = 'Generation' THEN
				xmlFragment := GetGenerationSegment(recSegment.ORIGIN_ID);
			ELSIF recSegment.SEGMENT_TYPE = 'Load' THEN
				xmlFragment := GetLoadSegment(recSegment.DESTINATION_ID);
			ELSE
				xmlFragment := GetTransmissionSegment(recSegment.ORIGIN_ID,
																							recSegment.DESTINATION_ID);
			END IF;
		
			-- wrap in the <PhysicalSegment> node, adding ID and
			-- market segment reference
			SELECT XMLELEMENT("PhysicalSegment",
												XMLELEMENT("PhysicalSegmentID",
																		recSegment.PHYS_SEGMENT_ORDER),
												XMLELEMENT("ParentMarketSegmentRef",
																		recSegment.MKT_SEGMENT_ORDER), xmlFragment)
				INTO xmlFragment
				FROM DUAL;
		
			-- concatenate into the segment list
			SELECT XMLCONCAT(xmlPhysSegList, xmlFragment)
				INTO xmlPhysSegList
				FROM DUAL;
		END LOOP;
	
		-- now wrap with the outer tag
		SELECT XMLELEMENT("PhysicalSegmentList", xmlPhysSegList)
			INTO xmlPhysSegList
			FROM DUAL;
		RETURN xmlPhysSegList;
	END GetPhysicalSegmentList;

	/*----------------------------------------------------------------------------
   Given a transaction ID, returns the TagID complex type based on the NERC IDs
   of the source and sink control areas, the NERC ID of the PSE, and the tag
   code of the transaction. The tag code is a unique identitifer for this tag.
  -----------------------------------------------------------------------------*/
	FUNCTION GetTagID(pTransactionID IN NUMBER) RETURN XMLTYPE IS
		xmlTagID XMLTYPE;
	BEGIN
		SELECT XMLELEMENT("TagID", XMLELEMENT("GCACode", GCA.CA_NERC_CODE),
											XMLELEMENT("PSECode", PSE.PSE_NERC_CODE),
											XMLELEMENT("TagCode", ETAG.ETAG_TAG_CODE),
											XMLELEMENT("LCACode", LCA.CA_NERC_CODE))
			INTO xmlTagID
			FROM CONTROL_AREA GCA, CONTROL_AREA LCA, PSE, INTERCHANGE_TRANSACTION ITX, ETAG
		 WHERE ITX.TRANSACTION_ID = pTransactionID
			 AND GCA.CA_ID = (SELECT PT.CA_ID
													FROM SERVICE_POINT PT
												 WHERE PT.SERVICE_POINT_ID = ITX.SOURCE_ID)
			 AND LCA.CA_ID = (SELECT PT.CA_ID
													FROM SERVICE_POINT PT
												 WHERE PT.SERVICE_POINT_ID = ITX.SINK_ID)
			 AND PSE.PSE_ID = ITX.PSE_ID
       AND ETAG.TRANSACTION_ID = pTransactionID;

		RETURN xmlTagID;
	END GetTagID;

	/*----------------------------------------------------------------------------
  Retrieves transaction information into a tag.
  -----------------------------------------------------------------------------*/
	FUNCTION GetTagData(pTransactionID IN number,
                      pMarketPathID IN NUMBER,
											pStartDate     IN DATE,
											pEndDate       IN DATE) RETURN XMLTYPE IS
		lProfileTable ProfileRecordTable;
    xmlTagData    XMLTYPE;
		xmlFragment   XMLTYPE;
	BEGIN

    xmlFragment := GetMarketSegmentList(pMarketPathID);
		SELECT XMLCONCAT(xmlTagData, xmlFragment) INTO xmlTagData FROM DUAL;

		xmlFragment := GetPhysicalSegmentList(pMarketPathID);
		SELECT XMLCONCAT(xmlTagData, xmlFragment) INTO xmlTagData FROM DUAL;

		lProfileTable := GetProfileTable(pTransactionID, pStartDate, pEndDate);
		xmlFragment   := GetProfileSet(lProfileTable);
		SELECT XMLCONCAT(xmlTagData, xmlFragment) INTO xmlTagData FROM DUAL;

		xmlFragment := GetTransmissionAllocationList(lProfileTable);
		SELECT XMLCONCAT(xmlTagData, xmlFragment) INTO xmlTagData FROM DUAL;

    SELECT XMLELEMENT("TagData", xmlTagData) INTO xmlTagData FROM DUAL;
		RETURN xmlTagData;
	END GetTagData;

	/*----------------------------------------------------------------------------
  Given a string of the format 'PnYnMnDTnHnMnS' (the duration datatype defined
  in the XML Schema Recommendation at
  http://www.w3.org/TR/2001/REC-xmlschema-2-20010502/#duration), return the
  number of hours represented by this duration. Note that there are 2 M characters
  representing either months or days; T may only be eliminated if there are no
  time elements. So the M occuring after the T always represents the minutes field.

  TODO: IMPLEMENT!!!!
  -----------------------------------------------------------------------------*/
  FUNCTION GetHoursFromDuration(pDuration IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN 0;
  END GetHoursFromDuration;

	/*----------------------------------------------------------------------------
  Returns the TagID of the eTAG.
  -----------------------------------------------------------------------------*/
	FUNCTION GetTagCodeFromTag(xmlTag IN XMLTYPE) RETURN VARCHAR2 IS
		lTagID VARCHAR2(32);
	BEGIN
		SELECT EXTRACTVALUE(VALUE(TAG), '//TagCode') "TAG_CODE"
			INTO lTagID
			FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag, '/descendant::Tag[1]/TagID'))) TAG;
		RETURN lTagID;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END GetTagCodeFromTag;

	/*----------------------------------------------------------------------------
  Pulls the start date of the tag from the first DateTime element and the first
  RelativeStart/TimeOffset element in the first RelativeProfile of the tag.
  -----------------------------------------------------------------------------*/
  FUNCTION GetTagStartDateFromTag(xmlTag IN XMLTYPE) RETURN DATE IS
    dte DATE;
    strDuration VARCHAR2(32);
  BEGIN
  	SELECT TO_DATE(EXTRACTVALUE(VALUE(TAG), '/DateTimeList/DateTime[1]'),
  								 'CCYY-MM-DD') "XN_DATE",
  				 EXTRACTVALUE(VALUE(TAG),
  											'/RelativeBlockList/RelativeBlock[1]/RelativeStart/TimeOffset') "DURATION"
  		INTO dte, strDuration
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
  																	 '/descendant::/Tag[1]/TagData/ProfileSet/BaseProfileList/' ||
  																		'/BaseProfile[1]/RelativeProfileList/RelativeProfile[1]'))) TAG;
  	RETURN dte + GetHoursFromDuration(strDuration) / 24;
  END;

	/*----------------------------------------------------------------------------
  Pulls the stop date of the tag from the last DateTime element and the last
  RelativeStop/TimeOffset element in the first RelativeProfile of the tag.
  -----------------------------------------------------------------------------*/
  FUNCTION GetTagStopDateFromTag(xmlTag IN XMLTYPE) RETURN DATE IS
    dte DATE;
    strDuration VARCHAR2(32);
  BEGIN
  	SELECT TO_DATE(EXTRACTVALUE(VALUE(TAG), '/DateTimeList/DateTime[last()]'),
  								 'CCYY-MM-DD') "XN_DATE",
  				 EXTRACTVALUE(VALUE(TAG),
  											'/RelativeBlockList/RelativeBlock[last()]/RelativeStop/TimeOffset') "DURATION"
  		INTO dte, strDuration
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
  																	 '/descendant::/Tag[1]/TagData/ProfileSet/BaseProfileList/' ||
  																		'/BaseProfile[1]/RelativeProfileList/RelativeProfile[1]'))) TAG;
  	RETURN dte + GetHoursFromDuration(strDuration) / 24;
  END;

	/*----------------------------------------------------------------------------
  Creates an interchange transaction based on the contents of the eTAG.
  -----------------------------------------------------------------------------*/
  FUNCTION CreateTransaction(xmlTag IN XMLTYPE) RETURN NUMBER IS
  	lXNData     Interchange_Transaction%ROWTYPE;
  	lNERCCode   service_point.service_point_nerc_code%TYPE;
  	dte         DATE;
  	strDuration VARCHAR2(32);
  BEGIN
  	-- these are all "hardwired" defaults
  	lXNData.Transaction_Interval := 'Hour';
  	lXNData.External_Interval    := 'Hour';
  	lXNData.Transaction_Desc     := 'RetailOffice generated schedule. Check settings.';
  	lXNData.Is_Firm              := 1;
  	lXNData.Model_Id             := GA.ELECTRIC_MODEL;

  	-- get the Energy commodity ID
  	SELECT C.COMMODITY_ID
  		INTO lXNData.Commodity_Id
  		FROM IT_COMMODITY C
  	 WHERE UPPER(C.COMMODITY_NAME) = 'ENERGY';

  	-- get the ETAG name
    lXNData.Transaction_Name := GetTagCodeFromTag(xmlTag);

  	-- get the PSE ID
  	SELECT EXTRACTVALUE(VALUE(TAG), '//PSECode') "NERC_CODE"
  		INTO lNERCCode
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag, '/descendant::Tag[1]/TagID'))) TAG;
  	SELECT PSE.PSE_ID
  		INTO lXNData.Pse_Id
  		FROM PSE
  	 WHERE PSE.PSE_NERC_CODE = lNERCCode;

  	-- get the ID for source and POR
  	SELECT EXTRACTVALUE(VALUE(TAG), '//TaggingPointID') "NERC_CODE"
  		INTO lNERCCode
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
  																	 '/descendant::Tag[1]/TagData/PhysicalSegmentList/' ||
  																		'PhysicalSegment[1]/Generation/ResourceList/Resource'))) TAG;
  	SELECT PT.SERVICE_POINT_ID
  		INTO lXNData.Source_Id
  		FROM SERVICE_POINT PT
  	 WHERE PT.SERVICE_POINT_NERC_CODE = lNERCCode;
  	lXNData.Por_Id := lXNData.Source_Id;

  	-- get the ID for sink and POD
  	SELECT EXTRACTVALUE(VALUE(TAG), '//TaggingPointID') "NERC_CODE"
  		INTO lNERCCode
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
  																	 '/descendant::Tag[1]/TagData/PhysicalSegmentList/' ||
  																		'PhysicalSegment[1]/Load/ResourceList/Resource'))) TAG;
  	SELECT PT.SERVICE_POINT_ID
  		INTO lXNData.Sink_ID
  		FROM SERVICE_POINT PT
  	 WHERE PT.SERVICE_POINT_NERC_CODE = lNERCCode;
  	lXNData.Pod_Id := lXNData.Sink_ID;

  	-- get the ID of the purchaser
  	SELECT EXTRACTVALUE(VALUE(TAG), '//PSECode') "NERC_CODE"
  		INTO lNERCCode
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
  																	 '/descendant::Tag[1]/TagData/MarketSegmentList/MarketSegment[1]'))) TAG;
  	SELECT PSE.PSE_ID
  		INTO lXNData.Purchaser_Id
  		FROM PSE
  	 WHERE PSE.PSE_NERC_CODE = lNERCCode;

  	-- get the ID of the seller
  	SELECT EXTRACTVALUE(VALUE(TAG), '//PSECode') "NERC_CODE"
  		INTO lNERCCode
  		FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
  																	 '/descendant::Tag[1]/TagData/MarketSegmentList/MarketSegment[last()]'))) TAG;
  	SELECT PSE.PSE_ID
  		INTO lXNData.Seller_Id
  		FROM PSE
  	 WHERE PSE.PSE_NERC_CODE = lNERCCode;

  	-- get the begin date for the transaction
    lXNData.Begin_Date := GetTagStartDateFromTag(xmlTag);

  	-- get the end date for the transaction
    lXNData.End_Date := GetTagStopDateFromTag(xmlTag);

  	em.PUT_TRANSACTION(o_OID => lXNData.Transaction_Id,
  										 p_TRANSACTION_NAME => lXNData.Transaction_Name,
  										 p_TRANSACTION_ALIAS => lXNData.Transaction_Name,
  										 p_TRANSACTION_DESC => lXNData.Transaction_Desc,
  										 p_TRANSACTION_ID => 0, p_TRANSACTION_STATUS => NULL,
  										 p_TRANSACTION_TYPE => NULL, p_TRANSACTION_CODE => NULL,
  										 p_TRANSACTION_IDENTIFIER => lXNData.Transaction_Name,
  										 p_IS_FIRM => lXNData.Is_Firm, p_IS_IMPORT_SCHEDULE => NULL,
  										 p_IS_EXPORT_SCHEDULE => NULL,
  										 p_IS_BALANCE_TRANSACTION => NULL, p_IS_BID_OFFER => NULL,
  										 p_IS_EXCLUDE_FROM_POSITION => NULL,
  										 p_IS_IMPORT_EXPORT => NULL,
										 p_IS_DISPATCHABLE => 0,
  										 p_TRANSACTION_INTERVAL => lXNData.Transaction_Interval,
  										 p_EXTERNAL_INTERVAL => lXNData.External_Interval,
  										 p_ETAG_CODE => NULL, p_BEGIN_DATE => lXNData.Begin_Date,
  										 p_END_DATE => lXNData.End_Date,
  										 p_PURCHASER_ID => lXNData.Purchaser_Id,
  										 p_SELLER_ID => lXNData.Seller_Id, p_CONTRACT_ID => NULL,
  										 p_SC_ID => NULL, p_POR_ID => lXNData.Por_Id,
  										 p_POD_ID => lXNData.Pod_Id, p_SCHEDULER_ID => NULL,
  										 p_COMMODITY_ID => NULL, p_SERVICE_TYPE_ID => NULL,
  										 p_TX_TRANSACTION_ID => NULL, p_PATH_ID => NULL,
  										 p_LINK_TRANSACTION_ID => NULL, p_EDC_ID => NULL,
  										 p_PSE_ID => lXNData.Pse_Id, p_ESP_ID => NULL,
  										 p_POOL_ID => NULL, p_SCHEDULE_GROUP_ID => NULL,
  										 p_MARKET_PRICE_ID => NULL, p_ZOR_ID => NULL,
  										 p_ZOD_ID => NULL, p_SOURCE_ID => lXNData.Source_Id,
  										 p_SINK_ID => lXNData.Sink_Id,
  										 p_RESOURCE_ID => lXNData.Resource_Id,
  										 p_AGREEMENT_TYPE => NULL, p_APPROVAL_TYPE => NULL,
  										 p_LOSS_OPTION => NULL, p_TRAIT_CATEGORY => NULL,
  										 p_MODEL_ID => lXNData.Model_Id);
  	RETURN lXNData.Transaction_Id;
  END CreateTransaction;

	/*----------------------------------------------------------------------------
  Creates a MarketPath entity, named with the eTAG name plus '_MP'.
  -----------------------------------------------------------------------------*/
	FUNCTION CreateMarketPath(xmlTag IN XMLTYPE) RETURN NUMBER IS
		lPathName MARKET_PATH.MARKET_PATH_NAME%TYPE;
		lPathOID  MARKET_PATH.MARKET_PATH_ID%TYPE;
	BEGIN
		lPathName := GetTagCodeFromTag(xmlTag) || '_MP';
		IO.PUT_MARKET_PATH(o_OID => lPathOID, p_MARKET_PATH_NAME => lPathName,
											 p_MARKET_PATH_ALIAS => '?', p_MARKET_PATH_DESC => '?',
											 p_MARKET_PATH_ID => 0);
		RETURN lPathOID;
	END CreateMarketPath;

	/*----------------------------------------------------------------------------
  Creates all the physical segments in a market segment, given their
  OID in the database, the parent market segment, and the tag data itself.
  Physical segments are named <etag code>_MS_<market segment order>_PS_<phys seg order>.
  -----------------------------------------------------------------------------*/
	PROCEDURE CreatePhysicalSegments(xmlTag                    IN XMLTYPE,
																	 pMarketSegmentID          IN NUMBER,
																	 pParentMarketSegmentOrder IN NUMBER,
																	 pTagCode                  IN VARCHAR2) IS
		CURSOR cSegments IS
			SELECT EXTRACTVALUE(VALUE(SEGS), '//PhysicalSegmentID') "SEGMENT_ORDER",
						 EXTRACTVALUE(VALUE(SEGS), '//TaggingPointID') "RESOURCE_NERC_CODE",
						 EXTRACTVALUE(VALUE(SEGS), '//POR') "POR_NERC_CODE",
						 EXTRACTVALUE(VALUE(SEGS), '//POD') "POD_NERC_CODE"
				FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
																			 '/descendant::PhysicalSegmentList[1]//PhysicalSegment[/ParentMarketSegmentRef="' ||
																				pParentMarketSegmentOrder || '"]'))) SEGS;
		lOID           PHYSICAL_SEGMENT.PHYSICAL_SEGMENT_ID%TYPE;
		lOriginID      PHYSICAL_SEGMENT.ORIGIN_ID%TYPE;
		lDestinationID PHYSICAL_SEGMENT.DESTINATION_ID%TYPE;
    lSegmentType PHYSICAL_SEGMENT.SEGMENT_TYPE%TYPE;
	BEGIN
		FOR lSegment IN cSegments LOOP
      IF lSegment.SEGMENT_ORDER = 1 THEN
        lSegmentType := 'Generation';
        lOriginID := GetServicePointIDFromNERCCode(lSegment.RESOURCE_NERC_CODE);
        lDestinationID := NULL;
      ELSIF lSegment.POR_NERC_CODE IS NULL THEN
        lSegmentType := 'Load';
        lOriginID := NULL;
        lDestinationID := GetServicePointIDFromNERCCode(lSegment.RESOURCE_NERC_CODE);
      ELSE
        lSegmentType := 'Transmission';
        lOriginID := GetServicePointIDFromNERCCode(lSegment.POD_NERC_CODE);
        lDestinationID := GetServicePointIDFromNERCCode(lSegment.POR_NERC_CODE);
      END IF;
      IO.PUT_PHYSICAL_SEGMENT(o_OID => lOID,
															p_PHYSICAL_SEGMENT_NAME => pTagCode || '_MS_' ||
																													pParentMarketSegmentOrder ||
																													'_PS_' ||
																													lSegment.SEGMENT_ORDER,
															p_PHYSICAL_SEGMENT_ALIAS => '?',
															p_PHYSICAL_SEGMENT_DESC => '?',
															p_PHYSICAL_SEGMENT_ID => 0,
															p_SEGMENT_TYPE => lSegmentType, p_ORIGIN_ID => lOriginID,
															p_DESTINATION_ID => lDestinationID);
    END LOOP;
	END CreatePhysicalSegments;

	/*----------------------------------------------------------------------------
  Given a tag and a path ID, creates all the market and physical segments
  in this path.
  -----------------------------------------------------------------------------*/
	PROCEDURE CreateSegments(xmlTag XMLTYPE, pMarketPathID IN NUMBER) IS
		CURSOR cSegments IS
			SELECT EXTRACTVALUE(VALUE(SEGS), '//MarketSegmentID') "SEGMENT_ID",
						 EXTRACTVALUE(VALUE(SEGS), '//PSECode') "PSE_NERC_CODE"
				FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag,
																			 '/descendant::MarketSegmentList[1]//MarketSegment'))) SEGS;
		lOID     MARKET_SEGMENT.MARKET_SEGMENT_ID%TYPE;
		lTagCode VARCHAR2(32);
	BEGIN
		lTagCode := GetTagCodeFromTag(xmlTag);

		FOR lSegment IN cSegments LOOP
			IO.PUT_MARKET_SEGMENT(o_OID => lOID,
														p_MARKET_SEGMENT_NAME => lTagCode || '_MS_' ||
																											lSegment.SEGMENT_ID,
														p_MARKET_SEGMENT_ALIAS => '?',
														p_MARKET_SEGMENT_DESC => '?',
														p_MARKET_SEGMENT_ID => 0, p_PSE_ID => GetPSEIDFromNERCCode(lSegment.PSE_NERC_CODE));
			-- create the physical segments for this market segment
      CreatePhysicalSegments(xmlTag, lOID, lSegment.SEGMENT_ID, lTagCode);
		END LOOP;

	END CreateSegments;

	/*----------------------------------------------------------------------------
  Adds a row into the ETAG table based on the transaction ID, the market path ID,
  the tag code, and the tag start and end dates.
  -----------------------------------------------------------------------------*/
	PROCEDURE CreateETagDetails(xmlTag         IN XMLTYPE,
															pTransactionID IN NUMBER,
															pMarketPathID  IN NUMBER) IS
		lStartDate DATE;
		lEndDate   DATE;
	BEGIN
		lStartDate := GetTagStartDateFromTag(xmlTag);
		lEndDate   := GetTagStopDateFromTag(xmlTag);
		INSERT INTO ETAG
			(TRANSACTION_ID,
			 MARKET_PATH_ID,
			 ETAG_START_DATE,
			 ETAG_END_DATE)
		VALUES
			(pTransactionID, pMarketPathID, lStartDate, lEndDate);
	END CreateETagDetails;

	/*----------------------------------------------------------------------------
  This routine actually handles inserting or updating the IT_SCHEDULE record.
  -----------------------------------------------------------------------------*/
  PROCEDURE PutScheduleValues(pTransactionID IN NUMBER,
  														pStartDate     IN DATE,
  														pStopDate      IN DATE,
  														pAmount        IN NUMBER) AS

  	lAsOfDate DATE := LOW_DATE; --ASSUME WE ARE NOT VERSIONING.
  	dte       DATE := pStartDate;
  BEGIN
  	LOOP
  		UPDATE IT_SCHEDULE
  			 SET AMOUNT = NVL(pAmount, AMOUNT)
  		 WHERE TRANSACTION_ID = pTransactionID
  			 AND SCHEDULE_TYPE = 1
  			 AND SCHEDULE_STATE = 2
  			 AND SCHEDULE_DATE = dte
  			 AND AS_OF_DATE = lAsOfDate;
  		IF SQL%NOTFOUND THEN
  			INSERT INTO IT_SCHEDULE
  				(TRANSACTION_ID,
  				 SCHEDULE_TYPE,
  				 SCHEDULE_STATE,
  				 SCHEDULE_DATE,
  				 AS_OF_DATE,
  				 AMOUNT,
  				 PRICE)
  			VALUES
  				(pTransactionID,
  				 1,
  				 2,
  				 dte,
  				 lAsOfDate,
  				 pAmount,
  				 NULL);
  		END IF;
  		dte := dte + 1 / 24;
  		EXIT WHEN dte > pStopDate;
  	END LOOP;
  END PutScheduleValues;

	/*----------------------------------------------------------------------------
  Given an XML representation of an eTAG and a transaction ID, this routine
  creates the corresponding IT_SCHEDULE data.
  -----------------------------------------------------------------------------*/
	PROCEDURE CreateSchedule(xmlTag IN XMLTYPE, pTransactionID IN NUMBER) IS
		lBaseDate DATE;
		CURSOR cSchedule IS
			SELECT EXTRACTVALUE(VALUE(PROFILE), '//RelativeStart//TimeOffset') "START_DATE",
						 EXTRACTVALUE(VALUE(PROFILE), '//RelativeStop//TimeOffset') "STOP_DATE",
						 EXTRACTVALUE(VALUE(PROFILE), '//MWLevel') "AMOUNT"
				FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag, '/descendant::RelativeProfile[1]'))) PROFILE;
	BEGIN
		SELECT TO_DATE(EXTRACTVALUE(VALUE(PROFILE), '/descendant::DateTime[1]'),
									 'CCYY-MM-DD')
			INTO lBaseDate
			FROM TABLE(XMLSEQUENCE(EXTRACT(xmlTag, '/descendant::RelativeProfile[1]'))) PROFILE;

		FOR lScheduleRecord IN cSchedule LOOP
			PutScheduleValues(pTransactionID,
												lBaseDate +
												 GetHoursFromDuration(lScheduleRecord.START_DATE) / 24,
												lBaseDate +
												 GetHoursFromDuration(lScheduleRecord.STOP_DATE) / 24,
												lScheduleRecord.AMOUNT);
		END LOOP;

	END CreateSchedule;

	/*----------------------------------------------------------------------------

  -----------------------------------------------------------------------------*/
  PROCEDURE IMPORT_ETAG(p_RECORD_DELIMITER IN CHAR,
  											p_RECORDS          IN VARCHAR,
  											p_FILE_PATH        IN VARCHAR,
  											p_LAST_TIME        IN NUMBER,
  											p_STATUS           OUT NUMBER,
  											p_MESSAGE          OUT VARCHAR) AS
  	v_CLOB_LOC  CLOB;
  	xmlTag       XMLTYPE;
    lTransactionID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    lMarketPathID MARKET_PATH.MARKET_PATH_ID%TYPE;
  BEGIN
  	p_STATUS := GA.SUCCESS;
/*
  	MM_UTIL.APPEND_UNTIL_FINISHED_CLOB(p_RECORD_DELIMITER, p_RECORDS, p_FILE_PATH,
  																		 p_LAST_TIME, v_CLOB_LOC);
*/
  	IF NOT v_CLOB_LOC IS NULL THEN
      xmlTag := XMLTYPE(v_CLOB_LOC);
      lTransactionID := CreateTransaction(xmlTag);
      lMarketPathID := CreateMarketPath(xmlTag);
      CreateETagDetails(xmlTag, lTransactionID, lMarketPathID);
      CreateSchedule(xmlTag, lTransactionID);
      CreateSegments(xmlTag, lMarketPathID);
/*
  		MM_UTIL.PURGE_CLOB_STAGING_TABLE;
*/  	END IF;

  	IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
  		DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
  	END IF;

  	COMMIT;

  EXCEPTION
  	WHEN OTHERS THEN
  		p_STATUS  := SQLCODE;
  		p_MESSAGE := SQLERRM;
  		ROLLBACK;
  		IF NOT v_CLOB_LOC IS NULL THEN
  			IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
  				DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
  			END IF;
  		END IF;
/*
  		MM_UTIL.PURGE_CLOB_STAGING_TABLE;
*/
  END IMPORT_ETAG;
  
	/*----------------------------------------------------------------------------
   export etag information in eTAG schema format
  -----------------------------------------------------------------------------*/
	PROCEDURE EXPORT_ETAG(pTransactionID IN NUMBER) IS
		lMarketPathID MARKET_PATH.MARKET_PATH_ID%TYPE;
		lStartDate    DATE;
		lEndDate      DATE;
		xmlTagID      XMLTYPE;
		xmlTagData    XMLTYPE;
		xmlTagContact    XMLTYPE;
		xmlTag        XMLTYPE;
	BEGIN
		SELECT E.MARKET_PATH_ID, E.ETAG_START_DATE, E.ETAG_END_DATE
			INTO lMarketPathID, lStartDate, lEndDate
			FROM ETAG E
		 WHERE E.TRANSACTION_ID = pTransactionID;
	
		xmlTagID   := GetTagID(pTransactionID);
		xmlTagData := GetTagData(pTransactionID, lMarketPathID, lStartDate, lEndDate);
	  xmlTagContact := GetContactInfo(pTransactionID, 'Interchange Transaction');
    
		SELECT XMLELEMENT("Tag", xmlTagID, xmlTagData, xmlTagContact,
											XMLELEMENT("WSCCPreScheduleFlag", 'false'),
											XMLELEMENT("TestFlag", 'false'),
											XMLELEMENT("TransactionType", 'NORMAL'),
											XMLELEMENT("Notes", 'Generated from Retail Office'))
			INTO xmlTag
			FROM DUAL;
	  
    --INSERT INTO ETAG_DETAILS(ETAG_DETAILS, ENTRY_DATE) VALUES (xmlTag, SYSDATE());
    --COMMIT;
	END EXPORT_ETAG;

	/*----------------------------------------------------------------------------
   just a generic function so I don't have to make everything public
  -----------------------------------------------------------------------------*/
	FUNCTION TestHarness RETURN xmltype IS
		xmlData   XMLTYPE;
		startDate DATE := to_date('10-07-2004', 'mm-dd-yyyy');
		endDate   DATE := to_date('10-09-2004', 'mm-dd-yyyy');

		profileTable ProfileRecordTable;
		rec          profilerecord;
	BEGIN
		-- test GetContactInfo with service point ANOTHER TEST
		-- xmldata := GetContactInfo(1760, 'Service Point');

    -- test GetTagID with transaction xmission test
    xmlData := GetTagID(1929);
    RETURN xmlData;

		-- test GetTagData with transaction xmission test
		--xmlData := GetTagData(1929, startDate, endDate);
		--RETURN xmlData;

		/*
    -- test GetProfileTable with transaction xmission test
    profileTable := GetProfileTable(1929, startDAte, endDAte);
    FOR i IN profileTable.FIRST .. profileTable.LAST LOOP
      rec := profileTable(i);
      dbms_output.put_line(to_char(rec.blockStartDate, 'mm/dd/yyyy hh24:mi') || ': ' ||
                           to_char(rec.startDate, 'mm/dd/yyyy hh24:mi') ||
                           ' - ' ||
                           to_char(rec.stopDate, 'mm/dd/yyyy hh24:mi') || ': ' ||
                           rec.amount || ' mw');
    END LOOP;
    RETURN NULL;
    */
	END TestHarness;

END ETAG_17;
/
