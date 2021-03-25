DECLARE
	l_OID NUMBER;
	usa_OID NUMBER;
  	canada_OID NUMBER;
  
	TYPE t_ARRAY IS VARRAY(216) OF VARCHAR2(32);

	l_STATES t_ARRAY;
	i NUMBER;
  l_country CHAR(3);
  	
  PROCEDURE PUT_GEOGRAPHY(p_NAME         IN VARCHAR2,
                          p_PARENT_ID    IN NUMBER,
                          p_DISPLAY_NAME IN VARCHAR2,
                          p_ABBREV       IN VARCHAR2) IS
		l_OID NUMBER;
	BEGIN
		IO.PUT_GEOGRAPHY(o_OID => l_OID, p_GEOGRAPHY_NAME => p_NAME,
                     p_GEOGRAPHY_ALIAS => '?',
                     p_GEOGRAPHY_DESC => '?',
                     p_GEOGRAPHY_ID => 0,
                     p_GEOGRAPHY_TYPE => 'State/Province',
                     p_PARENT_GEOGRAPHY_ID => p_PARENT_ID,
                     p_DISPLAY_NAME => P_DISPLAY_NAME,
		                 p_ABBREVIATION => P_ABBREV);
	
	END PUT_GEOGRAPHY;
    
BEGIN

-- Insert USA and Canada as country entries first

	IO.PUT_GEOGRAPHY(o_OID => usa_OID, p_GEOGRAPHY_NAME => 'USA',
                     p_GEOGRAPHY_ALIAS => '?',
                     p_GEOGRAPHY_DESC => '?',
                     p_GEOGRAPHY_ID => 0,
                     p_GEOGRAPHY_TYPE => 'Country',
                     p_PARENT_GEOGRAPHY_ID => 0,
                     p_DISPLAY_NAME => 'USA',
		                 p_ABBREVIATION => 'USA');

	IO.PUT_GEOGRAPHY(o_OID => canada_OID, p_GEOGRAPHY_NAME => 'CANADA',
                     p_GEOGRAPHY_ALIAS => '?',
                     p_GEOGRAPHY_DESC => '?',
                     p_GEOGRAPHY_ID => 0,
                     p_GEOGRAPHY_TYPE => 'Country',
                     p_PARENT_GEOGRAPHY_ID => 0,
                     p_DISPLAY_NAME => 'CANADA',
		                 p_ABBREVIATION => 'CANADA');
                     
  -- format is name, display name, abbreviation
  
	l_STATES := t_ARRAY(
		'USA, AL', 'ALABAMA', 'AL',
		'USA, AK', 'ALASKA', 'AK',
		'USA, AS', 'AMERICAN SAMOA', 'AS',
		'USA, AZ', 'ARIZONA ', 'AZ',
		'USA, AR', 'ARKANSAS', 'AR',
		'USA, CA', 'CALIFORNIA ', 'CA',
		'USA, CO', 'COLORADO ', 'CO',
		'USA, CT', 'CONNECTICUT', 'CT',
		'USA, DE', 'DELAWARE', 'DE',
		'USA, DC', 'DISTRICT OF COLUMBIA', 'DC',
		'USA, FM', 'FEDERATED STATES OF MICRONESIA', 'FM',
		'USA, FL', 'FLORIDA', 'FL',
		'USA, GA', 'GEORGIA', 'GA',
		'USA, GU', 'GUAM ', 'GU',
		'USA, HI', 'HAWAII', 'HI',
		'USA, ID', 'IDAHO', 'ID',
		'USA, IL', 'ILLINOIS', 'IL',
		'USA, IN', 'INDIANA', 'IN',
		'USA, IA', 'IOWA', 'IA',
		'USA, KS', 'KANSAS', 'KS',
		'USA, KY', 'KENTUCKY', 'KY',
		'USA, LA', 'LOUISIANA', 'LA',
		'USA, ME', 'MAINE', 'ME',
		'USA, MH', 'MARSHALL ISLANDS', 'MH',
		'USA, MD', 'MARYLAND', 'MD',
		'USA, MA', 'MASSACHUSETTS', 'MA',
		'USA, MI', 'MICHIGAN', 'MI',
		'USA, MN', 'MINNESOTA', 'MN',
		'USA, MS', 'MISSISSIPPI', 'MS',
		'USA, MO', 'MISSOURI', 'MO',
		'USA, MT', 'MONTANA', 'MT',
		'USA, NE', 'NEBRASKA', 'NE',
		'USA, NV', 'NEVADA', 'NV',
		'USA, NH', 'NEW HAMPSHIRE', 'NH',
		'USA, NJ', 'NEW JERSEY', 'NJ',
		'USA, NM', 'NEW MEXICO', 'NM',
		'USA, NY', 'NEW YORK', 'NY',
		'USA, NC', 'NORTH CAROLINA', 'NC',
		'USA, ND', 'NORTH DAKOTA', 'ND',
		'USA, MP', 'NORTHERN MARIANA ISLANDS', 'MP',
		'USA, OH', 'OHIO', 'OH',
		'USA, OK', 'OKLAHOMA', 'OK',
		'USA, OR', 'OREGON', 'OR',
		'USA, PW', 'PALAU', 'PW',
		'USA, PA', 'PENNSYLVANIA', 'PA',
		'USA, PR', 'PUERTO RICO', 'PR',
		'USA, RI', 'RHODE ISLAND', 'RI',
		'USA, SC', 'SOUTH CAROLINA', 'SC',
		'USA, SD', 'SOUTH DAKOTA', 'SD',
		'USA, TN', 'TENNESSEE', 'TN',
		'USA, TX', 'TEXAS', 'TX',
		'USA, UT', 'UTAH', 'UT',
		'USA, VT', 'VERMONT', 'VT',
		'USA, VI', 'VIRGIN ISLANDS', 'VI',
		'USA, VA', 'VIRGINIA ', 'VA',
		'USA, WA', 'WASHINGTON', 'WA',
		'USA, WV', 'WEST VIRGINIA', 'WV',
		'USA, WI', 'WISCONSIN', 'WI',
		'USA, WY', 'WYOMING', 'WY',
		'CANADA, AB', 'ALBERTA', 'AB',
		'CANADA, BC', 'BRITISH COLUMBIA', 'BC',
		'CANADA, MB', 'MANITOBA', 'MB',
		'CANADA, NB', 'NEW BRUNSWICK', 'NB',
		'CANADA, NL', 'NEWFOUNDLAND AND LABRADOR', 'NL',
		'CANADA, NT', 'NORTHWEST TERRITORIES', 'NT',
		'CANADA, NS', 'NOVA SCOTIA', 'NS',
		'CANADA, NU', 'NUNAVUT', 'NU',
		'CANADA, ON', 'ONTARIO', 'ON',
		'CANADA, PE', 'PRINCE EDWARD ISLAND', 'PE',
		'CANADA, QC', 'QUEBEC', 'QC',
		'CANADA, SK', 'SASKATCHEWAN', 'SK',
		'CANADA, YT', 'YUKON', 'YT'
		);

	-- Insert the States/Provinces associated with the appropriate country

	i := 1;
	LOOP
    l_country := SUBSTR(l_STATES(i),1,3);
    IF UPPER(l_country) = 'USA' THEN
		  PUT_GEOGRAPHY(l_STATES(i), usa_OID, l_STATES(i + 1), l_STATES(i + 2));
		ELSIF UPPER(l_country) = 'CAN' THEN
      PUT_GEOGRAPHY(l_STATES(i), canada_OID, l_STATES(i + 1), l_STATES(i + 2));
    END IF;
    i := i + 3;
		EXIT WHEN i > l_STATES.COUNT;
	END LOOP;

  COMMIT;
  
EXCEPTION
   WHEN MSGCODES.e_ERR_DUP_ENTRY THEN
	NULL; -- ignore this exception - it means we've already created these objects
END;
/

