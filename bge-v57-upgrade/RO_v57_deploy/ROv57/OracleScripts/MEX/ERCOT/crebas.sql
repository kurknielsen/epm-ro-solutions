
--THESE ARE STAGING TABLES MARKET PRICES AND LOAD EXTRACT
CREATE TABLE ERCOT_MARKET_HEADER_WORK (
    WORK_ID                          NUMBER(9)         NOT NULL,
    INTERVAL_DATA_ID                 NUMBER(10)        NOT NULL,
    INTERVAL_ID                      NUMBER(10)        NOT NULL,
    RECORDER                         VARCHAR2(64)       ,
    MARKET_INTERVAL                  NUMBER(5)          ,
    START_TIME                       DATE               ,
    STOP_TIME                        DATE               ,
    SECONDS_PER_INTERVAL             NUMBER(10)         ,
    MEASUREMENT_UNITS_CODE           VARCHAR2(64)       ,
    DSTPARTICIPANT                   CHAR(1)            ,
    TIMEZONE                         NUMBER(5)          ,
    ORIGIN                           CHAR(1)            ,
    EDITED                           CHAR(1)            ,
    INTERNALVALIDATION               CHAR(1)            ,
    EXTERNALVALIDATION               CHAR(1)            ,
    MERGEFLAG                        CHAR(1)            ,
    DELETEFLAG                       CHAR(1)            ,
    VALFLAGE                         CHAR(1)            ,
    VALFLAGI                         CHAR(1)            ,
    VALFLAGO                         CHAR(1)            ,
    VALFLAGN                         CHAR(1)            ,
    TKWRITTENFLAG                    CHAR(1)            ,
    DCFLOW                           CHAR(1)            ,
    ACCEPTREJECTSTATUS               CHAR(2)            ,
    TRANSLATIONTIME                  DATE               ,
    DESCRIPTOR                      VARCHAR2(254)      ,
    TIMESTAMP                       DATE               ,
    COUNT                            NUMBER(10)         ,
    TRANSACTION_DATE                 DATE               
)
TABLESPACE NERO_DATA
  PCTFREE 10
  INITRANS 1
  MAXTRANS 255
  STORAGE
  (
    INITIAL 64K
    MINEXTENTS 1
    MAXEXTENTS UNLIMITED
  );

CREATE INDEX ERCOT_MARKET_HEADER_WORK_IX01 ON ERCOT_MARKET_HEADER_WORK(WORK_ID,INTERVAL_DATA_ID,INTERVAL_ID);

COMMENT ON TABLE ERCOT_MARKET_HEADER_WORK IS 'CONTAINS THE HEADER INFORMATION FOR THE INTERVAL DATA CUTS';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.WORK_ID IS 'KEEP TRACK OF DATA THAT IS APPENDED TO THE TABLE; DATA STORED IN THIS TABLE MIGHT EITHER BE MARKET PRICES OR LOAD EXTRACT';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.INTERVAL_DATA_ID IS 'LINKS THIS TABLE WITH THE MARKET_INTERVAL_DATA TABLE.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.RECORDER IS 'UNIQUE COMBINATION OF DETERMINANT NAME AND OTHER DESCRIPTORS SUCH AS QSE CODE, ZONE NAME  AND GENSITE ETC.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.MARKET_INTERVAL IS 'INDICATES THE SETTLEMENT CHANNEL.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.START_TIME IS 'INDICATES THE DATE AND TIME WHEN THE DATA IN A ROW TAKES EFFECT.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.STOP_TIME IS 'INDICATES THE DATE AND TIME WHEN THE DATA IN A ROW IS NO LONGER IN EFFECT.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.SECONDS_PER_INTERVAL IS 'THE NUMBER OF SECONDS PER INTERVAL (SPI) FOR THE INTERVAL DATA CUT (I.E. 15 MINUTES = 900, 1 HOUR = 3600).';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.MEASUREMENT_UNITS_CODE IS 'LINKS THIS TABLE WITH THE MEASUREMENT_UNITS TABLE.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.DSTPARTICIPANT IS 'INDICATES WHETHER THE INTERVAL DATA CUT PARTICIPATES IN ANY DAYLIGHT SAVINGS TIME (DST) TIME CHANGES (ALWAYS YES).';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.TIMEZONE IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.ORIGIN IS 'A FLAG THAT INDICATES THE ORIGIN OF THE CUT:  M = METERED CUT, P = PROFILED CUT, C = COMPUTER CUT, S =  STATISTIC CUT.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.EDITED IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.INTERNALVALIDATION IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.EXTERNALVALIDATION IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.MERGEFLAG IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.DELETEFLAG IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.VALFLAGE IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.VALFLAGI IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.VALFLAGO IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.VALFLAGN IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.TKWRITTENFLAG IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.DCFLOW IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.ACCEPTREJECTSTATUS IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.TRANSLATIONTIME IS 'NOT IN USE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.DESCRIPTOR IS 'A DESCRIPTION OF THE INTERVAL DATA CUT.';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.TIMESTAMP IS 'BATCH DATE';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.COUNT IS 'INDICATES WHETHER THE RECORD IS INTERVAL DATA (96) OR HOURLY DATA (24).';
COMMENT ON COLUMN ERCOT_MARKET_HEADER_WORK.TRANSACTION_DATE IS 'INDICATES THE DATE AND TIME WHEN A RECORD WAS ADDED';

CREATE TABLE ERCOT_MARKET_DATA_WORK
(
    WORK_ID             NUMBER     NOT NULL,
    INTERVAL_DATA_ID    NUMBER(10) NOT NULL,
    TRANSACTION_DATE	DATE,
    TRADE_DATE   		DATE,
    LOAD_AMOUNT         NUMBER(15,8)
)
TABLESPACE NERO_DATA
  PCTFREE 10
  INITRANS 1
  MAXTRANS 255
  STORAGE
  (
    INITIAL 64K
    MINEXTENTS 1
    MAXEXTENTS UNLIMITED
  );

CREATE INDEX ERCOT_MARKET_DATA_WORK_IX01 ON ERCOT_MARKET_DATA_WORK(WORK_ID,INTERVAL_DATA_ID);

COMMENT ON TABLE ERCOT_MARKET_DATA_WORK IS 'Contains data values for the interval readings that make up the interval data cut.';
COMMENT ON COLUMN ERCOT_MARKET_DATA_WORK.WORK_ID IS 'KEEP TRACK OF DATA THAT IS APPENDED TO THE TABLE; DATA STORED IN THIS TABLE MIGHT EITHER BE MARKET PRICES OR LOAD EXTRACT';
COMMENT ON COLUMN ERCOT_MARKET_DATA_WORK.INTERVAL_DATA_ID IS 'LINKS THIS TABLE WITH THE MARKET_INTERVAL_HEADER TABLE.';
COMMENT ON COLUMN ERCOT_MARKET_DATA_WORK.TRANSACTION_DATE IS 'INDICATES THE DATE AND TIME WHEN A RECORD WAS ADDED';
COMMENT ON COLUMN ERCOT_MARKET_DATA_WORK.TRADE_DATE IS 'THE MARKET TRADE DATE FOR WHICH THE INTERVAL DATA APPLIES.';
COMMENT ON COLUMN ERCOT_MARKET_DATA_WORK.LOAD_AMOUNT IS 'THE VALUE FOR WHICH THE INTERVAL DATA APPLIES.';

--These are the tables for the ESIID Extract
CREATE TABLE EXTRACT_TABLE_COUNTS (
        RECORD_COUNT      	NUMBER(10),
	TABLE_NAME          	VARCHAR2(70)          
);


COMMENT ON TABLE EXTRACT_TABLE_COUNTS IS 'This table contains the record counts and filenames in the compressed file downloaded from ERCOT.';

comment on column EXTRACT_TABLE_COUNTS.RECORD_COUNT is 'The record count for the associated table.';
comment on column EXTRACT_TABLE_COUNTS.TABLE_NAME is 'The ESI ID file level: DUNS Number-Table Name-Run Date.csv. The dimensional file level: Table Name - Run Date.csv';

CREATE TABLE CMZONE (
    CMZONECODE                       VARCHAR2(64)      NOT NULL,
    CMZONENAME                       VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               
);

ALTER TABLE CMZONE
  ADD CONSTRAINT PK_CMZN2_1
  PRIMARY KEY (CMZONECODE);

COMMENT ON TABLE CMZONE IS 'This table describes the ERCOT defined Congestion Management Zones found in ERCOTs territory.';

comment on column CMZONE.CMZONECODE is 'The ERCOT Lodestar code associated to an ERCOT congestion management zone.';
comment on column CMZONE.CMZONENAME is 'The long name for an ERCOT congestion management zone.';
comment on column CMZONE.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column CMZONE.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column CMZONE.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';


CREATE TABLE ESIID (
    UIDESIID                         NUMBER(10)        NOT NULL,
    ESIID                            VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE
);

ALTER TABLE ESIID
  ADD CONSTRAINT PK_SD3_2
  PRIMARY KEY (UIDESIID);

COMMENT ON TABLE ESIID IS 'This table lists ESIIDs and their Start and Stop times of existence.';

comment on column ESIID.UIDESIID is 'The ERCOT Lodestar unique numeric identifier for the ESIID.';
comment on column ESIID.ESIID is 'The Electric Service Industry Identifier (ESIID) as assigned by the TDSP.';
comment on column ESIID.STARTTIME is 'The date and time when the ESIID was created by the TDSP.';
comment on column ESIID.STOPTIME is 'If this field is not null, the date and time represents when the ESIID was retired by the TDSP.';
comment on column ESIID.ADDTIME is 'The date and time when an ESIID record is added or updated in ERCOTs Lodestar system.';


CREATE TABLE ESIIDSERVICEHIST (
    UIDESIID                         NUMBER(10)        NOT NULL,
    SERVICECODE                      VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    REPCODE                          VARCHAR2(64)       ,
    STATIONCODE                      VARCHAR2(64)       ,
    PROFILECODE                      VARCHAR2(64)       ,
    LOSSCODE                         VARCHAR2(64)       ,
    ADDTIME                          DATE               ,
    DISPATCHFL                       CHAR(1)           NOT NULL,
    MRECODE                          VARCHAR2(64)      NOT NULL,
    TDSPCODE                         VARCHAR2(64)      NOT NULL,
    REGIONCODE                       VARCHAR2(64)      NOT NULL,
    DISPATCHASSETCODE                VARCHAR2(14)       ,
    STATUS                           VARCHAR2(64)      NOT NULL,
    ZIP                              VARCHAR2(10)       ,
    PGCCODE                          VARCHAR2(64)       ,
    DISPATCHTYPE                     VARCHAR2(3)        
);

ALTER TABLE ESIIDSERVICEHIST
  ADD CONSTRAINT PK_SDSRVCHST7_3
  PRIMARY KEY (UIDESIID, SERVICECODE, STARTTIME);

COMMENT ON TABLE ESIIDSERVICEHIST IS 'This table identifies the settlement characteristics associated with each ESIID such as the load serving entity, profile code, loss code, TDSP code, etc.';

comment on column ESIIDSERVICEHIST.UIDESIID is 'The ERCOT Lodestar unique numeric identifier for the ESIID.';
comment on column ESIIDSERVICEHIST.SERVICECODE is 'The unique identifier of ELE for electrical service.';
comment on column ESIIDSERVICEHIST.STARTTIME is 'The date and time when the data elements in the row take effect.';
comment on column ESIIDSERVICEHIST.STOPTIME is 'The date and time when the data elements in a row are no longer in effect.';
comment on column ESIIDSERVICEHIST.REPCODE is 'The ERCOT Lodestar code used to identify a load serving entity (LSE).  See values in REP table.';
comment on column ESIIDSERVICEHIST.STATIONCODE is 'The unique character code to identify a substation serving an ESIID as assigned by the TDSP and used in the ERCOT Network Model.  See values in STATION table.  To identify the CM Zone and the UFE Zone, see STATIONSERVICEHIST.';
comment on column ESIIDSERVICEHIST.PROFILECODE is 'The unique character code that identifies the profile type, weather zone, meter data type, weather sensitivity and Time Of Use code as assigned by the TDSP.  See values in the PROFILECLASS table.';
comment on column ESIIDSERVICEHIST.LOSSCODE is 'The unique character code that identifies a distribution loss factor code as assigned by the TDSP.  LOSSCODEs are defined in ERCOT Protocols (A, B, C, D, E, T).';
comment on column ESIIDSERVICEHIST.ADDTIME is 'The date and time when an ESIIDSERVICEHIST record is added or updated in ERCOTs Lodestar system.';
comment on column ESIIDSERVICEHIST.DISPATCHFL is 'A flag indicating if the ESIID is registered as a load resource.';
comment on column ESIIDSERVICEHIST.MRECODE is 'The ERCOT Lodestar code identifying the Meter Reading Entity.  MRECODE defaults to the submitting TDSP, unless otherwise assigned by ERCOT.  See values in the MRE table.';
comment on column ESIIDSERVICEHIST.TDSPCODE is 'The ERCOT Lodestar code identifying the Transmission and Distribution Service Provider.  See values in TDSP table.';
comment on column ESIIDSERVICEHIST.REGIONCODE is 'The unique character code identifying the power region the ESIID is electrically connected in as assigned by the TDSP (ERCOT, SPP, SERC, WSCC). If REGIONCODE is not ERCOT, the STATIONCODE, PROFILECODE, LOSSCODE should be null. See values in REGION table.';
comment on column ESIIDSERVICEHIST.DISPATCHASSETCODE is 'The unique character code assigned by ERCOT Operations to a registered load resource.';
comment on column ESIIDSERVICEHIST.STATUS is 'The status of the ESIIDSERVICEHIST row identified as A (Active-ESIID affiliated with LSE), D (De-Energized-ESIID not affiliated with any LSE), or I (Inactive-ESIID Retired).';
comment on column ESIIDSERVICEHIST.ZIP is 'Service Address ZIP Code as assigned by the TDSP.';
comment on column ESIIDSERVICEHIST.PGCCODE is 'The ERCOT Lodestar code assigned to a Power Generation Company (PGC), if the ESIID is registered as a load resource. See values in PGC table.';
comment on column ESIIDSERVICEHIST.DISPATCHTYPE is 'The code identifying the type of load resource as assigned by ERCOT Operations.';


CREATE TABLE ESIIDSERVICEHIST_DELETE (
    UIDESIID                         NUMBER(10)        NOT NULL,
    SERVICECODE                      VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    D_TIMESTAMP                      DATE,
    SRC_ADDTIME                      DATE              NOT NULL
);

ALTER TABLE ESIIDSERVICEHIST_DELETE
  ADD CONSTRAINT PK_SDSRVCHST11_4
  PRIMARY KEY (UIDESIID, SERVICECODE, STARTTIME, SRC_ADDTIME);

COMMENT ON TABLE ESIIDSERVICEHIST_DELETE IS 'Records that appear in this table have been deleted in ERCOTs system.  The keys sRecords that appear in this table have been deleted in ERCOTs system.  The keys should be used to delete the corresponding records from ESIIDSERVICEHIST.hould be used to delete the corresponding records from ESIIDSERVICEHIST.';

comment on column ESIIDSERVICEHIST_DELETE.UIDESIID is 'The ERCOT Lodestar unique numeric identifier for the ESIID.';
comment on column ESIIDSERVICEHIST_DELETE.SERVICECODE is 'The unique identifier of ELE for electrical service.';
comment on column ESIIDSERVICEHIST_DELETE.STARTTIME is 'The date and time when the data elements in the row take effect.';
comment on column ESIIDSERVICEHIST_DELETE.D_TIMESTAMP is 'This timestamp represents the date and time when a record in ESIIDSERVICEHIST has been deleted';
comment on column ESIIDSERVICEHIST_DELETE.SRC_ADDTIME is 'This timestamp represents the ADDTIME of the record in ESIIDSERVICEHIST that was deleted';


CREATE TABLE ESIIDUSAGE (
    UIDESIID                         NUMBER(10)        NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE              NOT NULL,
    BILLMONTH                        NUMBER(5)          ,
    METERTYPE                        VARCHAR2(2)       NOT NULL,
    TOTAL                            NUMBER             ,
    READSTATUS                       VARCHAR2(64)       ,
    AVGDAILYUSG                      NUMBER             ,
    ONPK                             NUMBER             ,
    OFFPK                            NUMBER             ,
    MDPK                             NUMBER             ,
    SPK                              NUMBER             ,
    ONPKADU                          NUMBER             ,
    OFFPKADU                         NUMBER             ,
    MDPKADU                          NUMBER             ,
    SPKADU                           NUMBER             ,
    ADDTIME                          DATE               ,
    GLOBPROCID                       VARCHAR2(128)      ,
    TIMESTAMP                        DATE               
);

ALTER TABLE ESIIDUSAGE
  ADD CONSTRAINT PK_SDSG6_5
  PRIMARY KEY (UIDESIID, STARTTIME, METERTYPE);

COMMENT ON TABLE ESIIDUSAGE IS 'This table contains Non-IDR usage records submitted by the Meter Reading Entity (typically the TSDP)that have passed ERCOT validation and loaded into Lodestar.  For those ESIIDs that are demand metered, there will a separate record for the demand value.';

comment on column ESIIDUSAGE.UIDESIID is 'The ERCOT Lodestar unique numeric identifier for the ESIID.';
comment on column ESIIDUSAGE.STARTTIME is 'The start time of the meter read.';
comment on column ESIIDUSAGE.STOPTIME is 'The stop time of the meter read.';
comment on column ESIIDUSAGE.BILLMONTH is 'The ERCOT Lodestar assigned month and year associated to the meter read to be used only to identify Non-IDR profiled ESIIDs subject to the IDR Requirement.  This field is NOT used for usage month determination for the Load Profile assignment.';
comment on column ESIIDUSAGE.METERTYPE is 'The unit of measure of the meter data as defined by Texas SET.';
comment on column ESIIDUSAGE.TOTAL is 'The total energy or maximum demand for the record submitted by the Meter Reading Entity (typically the TDSP).';
comment on column ESIIDUSAGE.READSTATUS is 'The code submitted by the Meter Reading Entity (typically the TDSP) representing whether the meter read is actual (A) or estimated (E).';
comment on column ESIIDUSAGE.AVGDAILYUSG is '(No longer used in ERCOT settlement calculations.)  The ERCOT Lodestar calculated Total Average Daily Usage, which represents the ESIIDUSAGE.TOTAL divided by the number of days in the meter read record.';
comment on column ESIIDUSAGE.ONPK is 'On Peak value is the total on-peak energy for the record submitted by the Meter Reading Entity (typically the TDSP).  This field is only required to be populated when the ESIID has a Time Of Use assignment in the ESIIDSERVICEHIST.PROFILECODE.';
comment on column ESIIDUSAGE.OFFPK is 'Off Peak value is the total off-peak energy for the record submitted by the Meter Reading Entity (typically the TDSP).  This field is only required to be populated when the ESIID has a Time Of Use assignment in the ESIIDSERVICEHIST.PROFILECODE.';
comment on column ESIIDUSAGE.MDPK is 'Mid Peak value is the total mid-peak energy for the record submitted by the Meter Reading Entity (typically the TDSP).  This field is only required to be populated when the ESIID has a Time Of Use assignment in the ESIIDSERVICEHIST.PROFILECODE.';
comment on column ESIIDUSAGE.SPK is 'Super Peak value is the total super-peak energy for the record submitted by the Meter Reading Entity (typically the TDSP).  This field is only required to be populated when the ESIID has a Time Of Use assignment in the ESIIDSERVICEHIST.PROFILECODE.';
comment on column ESIIDUSAGE.ONPKADU is '(No longer used in ERCOT settlement calculations.)  The ERCOT Lodestar calculated on-peak Average Daily Usage, which represents the ESIIDUSAGE.ONPK divided by the number of days in the meter read record.';
comment on column ESIIDUSAGE.OFFPKADU is '(No longer used in ERCOT settlement calculations.)  The ERCOT Lodestar calculated off-peak Average Daily Usage, which represents the ESIIDUSAGE.OFFPK divided by the number of days in the meter read record.';
comment on column ESIIDUSAGE.MDPKADU is '(No longer used in ERCOT settlement calculations.)  The ERCOT Lodestar calculated mid-peak Average Daily Usage, which represents the ESIIDUSAGE.MDPK divided by the number of days in the meter read record.';
comment on column ESIIDUSAGE.SPKADU is '(No longer used in ERCOT settlement calculations.)  The ERCOT Lodestar calculated super-peak Average Daily Usage, which represents the ESIIDUSAGE.SPK divided by the number of days in the meter read record.';
comment on column ESIIDUSAGE.ADDTIME is 'The batch processing date when an ESIIDUSAGE record is added in ERCOTs Lodestar system.  This timestamp is not an indication of Non-IDR data being available for settlements.';
comment on column ESIIDUSAGE.GLOBPROCID is 'The ERCOT system generated unique transaction number.';
comment on column ESIIDUSAGE.TIMESTAMP is 'The date and time when an ESIIDUSAGE record is added or updated in ERCOTs Lodestar system.';


CREATE TABLE ESIIDUSAGE_DELETE (
    UIDESIID                         NUMBER(10)        NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    METERTYPE                        VARCHAR2(2)       NOT NULL,
    D_TIMESTAMP                      DATE,
    SRC_TIMESTAMP                    DATE              NOT NULL
);

ALTER TABLE ESIIDUSAGE_DELETE
  ADD CONSTRAINT PK_SDSGDLT10_6
  PRIMARY KEY (UIDESIID, STARTTIME, METERTYPE, SRC_TIMESTAMP);

COMMENT ON TABLE ESIIDUSAGE_DELETE IS 'Records that appear in this table have been deleted in ERCOTs system.  The keys should be used to delete the corresponding records from ESIIDUSAGE.';

comment on column ESIIDUSAGE_DELETE.UIDESIID is 'The ERCOT Lodestar unique numeric identifier for the ESIID.';
comment on column ESIIDUSAGE_DELETE.STARTTIME is 'The start time of the meter read.';
comment on column ESIIDUSAGE_DELETE.METERTYPE is 'The unit of measure of the meter data as defined by Texas SET.';
comment on column ESIIDUSAGE_DELETE.D_TIMESTAMP is 'This timestamp represents the date and time when a record in ESIIDUSAGE has been deleted.';
comment on column ESIIDUSAGE_DELETE.SRC_TIMESTAMP is 'This timestamp represents the TIMESTAMP of the record in ESIIDUSAGE that was deleted';


CREATE TABLE LSCHANNELCUTDATA (
    UIDCHANNELCUT                    NUMBER(10)        NOT NULL,
    ADDTIME                          DATE               ,
    TRADE_DATE                       DATE              NOT NULL,
    INT001                           NUMBER             ,
    INT002                           NUMBER             ,
    INT003                           NUMBER             ,
    INT004                           NUMBER             ,
    INT005                           NUMBER             ,
    INT006                           NUMBER             ,
    INT007                           NUMBER             ,
    INT008                           NUMBER             ,
    INT009                           NUMBER             ,
    INT010                           NUMBER             ,
    INT011                           NUMBER             ,
    INT012                           NUMBER             ,
    INT013                           NUMBER             ,
    INT014                           NUMBER             ,
    INT015                           NUMBER             ,
    INT016                           NUMBER             ,
    INT017                           NUMBER             ,
    INT018                           NUMBER             ,
    INT019                           NUMBER             ,
    INT020                           NUMBER             ,
    INT021                           NUMBER             ,
    INT022                           NUMBER             ,
    INT023                           NUMBER             ,
    INT024                           NUMBER             ,
    INT025                           NUMBER             ,
    INT026                           NUMBER             ,
    INT027                           NUMBER             ,
    INT028                           NUMBER             ,
    INT029                           NUMBER             ,
    INT030                           NUMBER             ,
    INT031                           NUMBER             ,
    INT032                           NUMBER             ,
    INT033                           NUMBER             ,
    INT034                           NUMBER             ,
    INT035                           NUMBER             ,
    INT036                           NUMBER             ,
    INT037                           NUMBER             ,
    INT038                           NUMBER             ,
    INT039                           NUMBER             ,
    INT040                           NUMBER             ,
    INT041                           NUMBER             ,
    INT042                           NUMBER             ,
    INT043                           NUMBER             ,
    INT044                           NUMBER             ,
    INT045                           NUMBER             ,
    INT046                           NUMBER             ,
    INT047                           NUMBER             ,
    INT048                           NUMBER             ,
    INT049                           NUMBER             ,
    INT050                           NUMBER             ,
    INT051                           NUMBER             ,
    INT052                           NUMBER             ,
    INT053                           NUMBER             ,
    INT054                           NUMBER             ,
    INT055                           NUMBER             ,
    INT056                           NUMBER             ,
    INT057                           NUMBER             ,
    INT058                           NUMBER             ,
    INT059                           NUMBER             ,
    INT060                           NUMBER             ,
    INT061                           NUMBER             ,
    INT062                           NUMBER             ,
    INT063                           NUMBER             ,
    INT064                           NUMBER             ,
    INT065                           NUMBER             ,
    INT066                           NUMBER             ,
    INT067                           NUMBER             ,
    INT068                           NUMBER             ,
    INT069                           NUMBER             ,
    INT070                           NUMBER             ,
    INT071                           NUMBER             ,
    INT072                           NUMBER             ,
    INT073                           NUMBER             ,
    INT074                           NUMBER             ,
    INT075                           NUMBER             ,
    INT076                           NUMBER             ,
    INT077                           NUMBER             ,
    INT078                           NUMBER             ,
    INT079                           NUMBER             ,
    INT080                           NUMBER             ,
    INT081                           NUMBER             ,
    INT082                           NUMBER             ,
    INT083                           NUMBER             ,
    INT084                           NUMBER             ,
    INT085                           NUMBER             ,
    INT086                           NUMBER             ,
    INT087                           NUMBER             ,
    INT088                           NUMBER             ,
    INT089                           NUMBER             ,
    INT090                           NUMBER             ,
    INT091                           NUMBER             ,
    INT092                           NUMBER             ,
    INT093                           NUMBER             ,
    INT094                           NUMBER             ,
    INT095                           NUMBER             ,
    INT096                           NUMBER             ,
    INT097                           NUMBER             ,
    INT098                           NUMBER             ,
    INT099                           NUMBER             ,
    INT100                           NUMBER             
);

ALTER TABLE LSCHANNELCUTDATA
  ADD CONSTRAINT PK_LSCHNNLCT5_8
  PRIMARY KEY (UIDCHANNELCUT, TRADE_DATE);

COMMENT ON TABLE LSCHANNELCUTDATA IS 'This table contains IDR usage records submitted by the Meter Reading Entity (typically the TSDP) that have passed ERCOT validation and loaded into Lodestar.  Records in this table are joined to the LSCHANNELCUTHEADER table by the UIDCHANNELCUT variable.';

comment on column LSCHANNELCUTDATA.UIDCHANNELCUT is 'Variable used to join the LSCHANNELCUTDATA table to the LSCHANNELCUTHEADER table.';
comment on column LSCHANNELCUTDATA.ADDTIME is 'The date and time when an IDR usage record is added or updated in ERCOTs Lodestar system.  This timestamp indicates that IDR data is available for settlements.';
comment on column LSCHANNELCUTDATA.TRADE_DATE is 'The ERCOT Lodestar market trade date for which the interval data applies.';
comment on column LSCHANNELCUTDATA.INT001 is 'The total energy for the interval record submitted by the Meter Reading Entity (typically the TDSP).  This comment applies to LSCHANNELCUTDATA.INT001 through LSCHANNELCUTDATA.INT100.';

CREATE TABLE LSCHANNELCUTHEADER (
    UIDCHANNELCUT                    NUMBER(10)        NOT NULL,
    UIDCHANNEL                       NUMBER(10)        NOT NULL,
    RECORDER                         VARCHAR2(64)       ,
    CHANNEL                          NUMBER(5)          ,
    STARTTIME                        DATE               ,
    STOPTIME                         DATE               ,
    SPI                              NUMBER(10)         ,
    UOMCODE                          VARCHAR2(64)       ,
    DSTPARTICIPANT                   CHAR(1)            ,
    TIMEZONE                         NUMBER(5)          ,
    ORIGIN                           CHAR(1)            ,
    STARTREADING                     NUMBER             ,
    STOPREADING                      NUMBER             ,
    METERMULTIPLIER                  NUMBER             ,
    METEROFFSET                      NUMBER             ,
    PULSEMULTIPLIER                  NUMBER             ,
    PULSEOFFSET                      NUMBER             ,
    EDITED                           CHAR(1)            ,
    INTERNALVALIDATION               CHAR(1)            ,
    EXTERNALVALIDATION               CHAR(1)            ,
    MERGEFLAG                        CHAR(1)            ,
    DELETEFLAG                       CHAR(1)            ,
    VALFLAGE                         CHAR(1)            ,
    VALFLAGI                         CHAR(1)            ,
    VALFLAGO                         CHAR(1)            ,
    VALFLAGN                         CHAR(1)            ,
    TKWRITTENFLAG                    CHAR(1)            ,
    DCFLOW                           CHAR(1)            ,
    ACCEPTREJECTSTATUS               CHAR(2)            ,
    TRANSLATIONTIME                  DATE               ,
    DESCRIPTOR                       VARCHAR2(254)      ,
    ADDTIME                          DATE               ,
    INTERVALCOUNT                    NUMBER(10)         ,
    CHNLCUTTIMESTAMP                 DATE               
);

ALTER TABLE LSCHANNELCUTHEADER
  ADD CONSTRAINT PK_LSCHNNLCT6_9
  PRIMARY KEY (UIDCHANNELCUT);

COMMENT ON TABLE LSCHANNELCUTHEADER IS 'This table contains the header data for IDR usage records submitted by the Meter Reading Entity (typically the TSDP) that have passed ERCOT validation and loaded into Lodestar. Records in this table are joined to the LSCHANNELCUTDATA table by the UIDCHANNELCUT variable.';

comment on column LSCHANNELCUTHEADER.UIDCHANNELCUT is 'Variable used to join the LSCHANNELCUTHEADER table to the LSCHANNELCUTDATA.';
comment on column LSCHANNELCUTHEADER.UIDCHANNEL is 'Lodestar variable not used by ERCOT.';
comment on column LSCHANNELCUTHEADER.RECORDER is 'The Electric Service Industry Identifier (ESIID) as assigned by the TDSP or the Resource ID for TDSP submitted distributed generation.';
comment on column LSCHANNELCUTHEADER.CHANNEL is 'The Lodestar channel ERCOT uses for interval data storage (1=generation kWh, 3=load kVARh, 4=load kWh).';
comment on column LSCHANNELCUTHEADER.STARTTIME is 'The start time of the interval meter read.';
comment on column LSCHANNELCUTHEADER.STOPTIME is 'The stop time of the interval meter read.';
comment on column LSCHANNELCUTHEADER.SPI is 'The number of seconds per interval (SPI) for the interval data cut (I.E. 15 MINUTES = 900, 1 HOUR = 3600).';
comment on column LSCHANNELCUTHEADER.UOMCODE is 'The Lodestar defined numerical code to indicate the Unit Of Measure of the interval data (01=kWh, 03=kVARh).';
comment on column LSCHANNELCUTHEADER.DSTPARTICIPANT is 'This flag indicates if the data participates in DST adjustments (always = Y).';
comment on column LSCHANNELCUTHEADER.TIMEZONE is 'Not in use';
comment on column LSCHANNELCUTHEADER.ORIGIN is 'A variable that represents the origin of the interval cut: M = TDSP submitted, C = ERCOT computed or EPS data.';
comment on column LSCHANNELCUTHEADER.STARTREADING is 'Not in use';
comment on column LSCHANNELCUTHEADER.STOPREADING is 'Not in use';
comment on column LSCHANNELCUTHEADER.METERMULTIPLIER is 'The determined meter multiplier for this data record.  It is defaulted to 1.';
comment on column LSCHANNELCUTHEADER.METEROFFSET is 'The determined meter off set value for this data record.  It is defaulted to 1.';
comment on column LSCHANNELCUTHEADER.PULSEMULTIPLIER is 'The determined pulse multiplier for this data record.  It is defaulted to 1.';
comment on column LSCHANNELCUTHEADER.PULSEOFFSET is 'The determined pulse off set value for this data record.  It is defaulted to 1.';
comment on column LSCHANNELCUTHEADER.EDITED is 'Not in use';
comment on column LSCHANNELCUTHEADER.INTERNALVALIDATION is 'Not in use';
comment on column LSCHANNELCUTHEADER.EXTERNALVALIDATION is 'Not in use';
comment on column LSCHANNELCUTHEADER.MERGEFLAG is 'Not in use';
comment on column LSCHANNELCUTHEADER.DELETEFLAG is 'Not in use';
comment on column LSCHANNELCUTHEADER.VALFLAGE is 'Not in use';
comment on column LSCHANNELCUTHEADER.VALFLAGI is 'Not in use';
comment on column LSCHANNELCUTHEADER.VALFLAGO is 'Not in use';
comment on column LSCHANNELCUTHEADER.VALFLAGN is 'Not in use';
comment on column LSCHANNELCUTHEADER.TKWRITTENFLAG is 'Not in use';
comment on column LSCHANNELCUTHEADER.DCFLOW is 'Not in use';
comment on column LSCHANNELCUTHEADER.ACCEPTREJECTSTATUS is 'Not in use';
comment on column LSCHANNELCUTHEADER.TRANSLATIONTIME is 'Not in use';
comment on column LSCHANNELCUTHEADER.DESCRIPTOR is 'This is a comment field.  If data is loaded via EDI transaction, ERCOT populates this field with the GLOBAL Processing ID.';
comment on column LSCHANNELCUTHEADER.ADDTIME is 'The batch processing date when an IDR record is added in ERCOTs Lodestar system.  This timestamp is not an indication of IDR data being available for settlements.';
comment on column LSCHANNELCUTHEADER.INTERVALCOUNT is 'Count of intervals within the LSCHANNELCUTHEADER.STARTTIME and LSCHANNELCUTHEADER.STOPTIME.';
comment on column LSCHANNELCUTHEADER.CHNLCUTTIMESTAMP is 'The date when the EDI transaction translates into XML, which is then translated into LSE to be validated and loaded into Lodestar.  This timestamp is not an indication of IDR data being available for settlements.';


CREATE TABLE LSCHANNELCUTHEADER_DELETE (
    UIDCHANNELCUT                    NUMBER(10)        NOT NULL,
    D_TIMESTAMP                      DATE,
    SRC_CHNLCUTTIMESTAMP             DATE              NOT NULL
);

ALTER TABLE LSCHANNELCUTHEADER_DELETE
  ADD CONSTRAINT PK_LSCHNNLCT10_10
  PRIMARY KEY (UIDCHANNELCUT, SRC_CHNLCUTTIMESTAMP);

COMMENT ON TABLE LSCHANNELCUTHEADER_DELETE IS 'Records that appear in this table have been deleted in ERCOTs system.  The keys should be used to delete the corresponding records from LSCHANNELCUTHEADER.';

comment on column LSCHANNELCUTHEADER_DELETE.UIDCHANNELCUT is 'Variable used to join the LSCHANNELCUTHEADER table to the LSCHANNELCUTDATA.';
comment on column LSCHANNELCUTHEADER_DELETE.D_TIMESTAMP is 'This timestamp represents the date and time when a record in LSCHANNELCUTHEADER has been deleted.';
comment on column LSCHANNELCUTHEADER_DELETE.SRC_CHNLCUTTIMESTAMP is 'This timestamp represents the CHNLCUTTIMESTAMP of the record in LSCHANNELCUTHEADER that was deleted';


CREATE TABLE MRE (
    MRECODE                          VARCHAR2(64)      NOT NULL,
    MRENAME                          VARCHAR2(64)      NOT NULL,
    STARTTIIME                       DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               ,
    DUNSNUMBER                       VARCHAR2(64)      NOT NULL
);

ALTER TABLE MRE
  ADD CONSTRAINT PK_MR1_12
  PRIMARY KEY (MRECODE);

COMMENT ON TABLE MRE IS 'This table lists Meter Reading Entities (MRE) and DUNS numbers.';

comment on column MRE.MRECODE is 'The ERCOT Lodestar code identifying the Meter Reading Entity.  MRECODE defaults to the submitting TDSP, unless otherwise assigned by ERCOT.';
comment on column MRE.MRENAME is 'The long name identifying a meter reading entity.';
comment on column MRE.STARTTIIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column MRE.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column MRE.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';
comment on column MRE.DUNSNUMBER is 'This code uniquely identifies the market participant as registered at ERCOT.';


CREATE TABLE PGC (
    PGCCODE                          VARCHAR2(64)      NOT NULL,
    PGCNAME                          VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               ,
    DUNSNUMBER                       VARCHAR2(64)      NOT NULL
);

ALTER TABLE PGC
  ADD CONSTRAINT PK_PGC0_13
  PRIMARY KEY (PGCCODE);

COMMENT ON TABLE PGC IS 'This table record the ownership percentage in a generator by a power generating company (PGC).';

comment on column PGC.PGCCODE is 'The ERCOT Lodestar code assigned to a Power Generation Company (PGC), if the ESIID is registered as a load resource.';
comment on column PGC.PGCNAME is 'The long name of a power generation company as registered at ERCOT.';
comment on column PGC.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column PGC.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column PGC.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';
comment on column PGC.DUNSNUMBER is 'This code uniquely identifies the market participant as registered at ERCOT.';


CREATE TABLE PROFILECLASS (
    PROFILECODE                      VARCHAR2(64)      NOT NULL,
    WEATHERSENSITIVITY               VARCHAR2(3)       NOT NULL,
    METERTYPE                        VARCHAR2(4)       NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               ,
    TOUTYPE                          VARCHAR2(64)      NOT NULL,
    PROFILECUTCODE                   VARCHAR2(64)      NOT NULL
);

ALTER TABLE PROFILECLASS
  ADD CONSTRAINT PK_PRFLCLSS4_14
  PRIMARY KEY (PROFILECODE);

COMMENT ON TABLE PROFILECLASS IS 'The PROFILECLASS table identifies the components of profile codes, including weather zone, meter type, weather sensitivity and time of use code.  Refer to the Profile Decision Tree on the ERCOT website for additional details.';

comment on column PROFILECLASS.PROFILECODE is 'The unique character code that identifies the profile type, weather zone, meter data type, weather sensitivity and Time Of Use code as assigned by the TDSP.';
comment on column PROFILECLASS.WEATHERSENSITIVITY is 'This code identifies if the ESIID is weather sensitive.';
comment on column PROFILECLASS.METERTYPE is 'Defines the type of meter (IDR or NIDR).';
comment on column PROFILECLASS.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column PROFILECLASS.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column PROFILECLASS.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';
comment on column PROFILECLASS.TOUTYPE is 'Time of use schedule assigned to the ESIID by the TDSP.';
comment on column PROFILECLASS.PROFILECUTCODE is 'The unique character code that identifies the unique combinations of profile types and weather zones.';


CREATE TABLE REP (
    REPCODE                          VARCHAR2(64)      NOT NULL,
    REPNAME                          VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               ,
    DUNSNUMBER                       VARCHAR2(64)      NOT NULL
);

ALTER TABLE REP
  ADD CONSTRAINT PK_RP1_15
  PRIMARY KEY (REPCODE);

COMMENT ON TABLE REP IS 'This table lists Load Serving Entities (LSE) and DUNS number.';

comment on column REP.REPCODE is 'The ERCOT Lodestar code used to identify a load serving entity (LSE).';
comment on column REP.REPNAME is 'The company name used by the load serving entity as registered at ERCOT.';
comment on column REP.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column REP.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column REP.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';
comment on column REP.DUNSNUMBER is 'This code uniquely identifies the market participant as registered at ERCOT.';


CREATE TABLE STATION (
    STATIONCODE                      VARCHAR2(64)      NOT NULL,
    STATIONNAME                      VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               
);

ALTER TABLE STATION
  ADD CONSTRAINT PK_STTN3_16
  PRIMARY KEY (STATIONCODE);

COMMENT ON TABLE STATION IS 'A physical electric substation location that exists in the ERCOT Network Model and is used to associate load (ESIID) and generation (resources) to CM zones and UFE zones.';

comment on column STATION.STATIONCODE is 'The unique character code to identify a substation serving an ESIID as assigned by the TDSP and used in the ERCOT Network Model.';
comment on column STATION.STATIONNAME is 'The long name to identify a substation used in the ERCOT Network Model.';
comment on column STATION.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column STATION.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column STATION.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';


CREATE TABLE STATIONSERVICEHIST (
    STATIONCODE                      VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    UFEZONECODE                      VARCHAR2(64)      NOT NULL,
    CMZONECODE                       VARCHAR2(64)      NOT NULL,
    ADDTIME                          DATE               ,
    SUBUFECODE                       VARCHAR2(64)      NOT NULL
);

ALTER TABLE STATIONSERVICEHIST
  ADD CONSTRAINT PK_STTNSRVCH7_17
  PRIMARY KEY (STATIONCODE, STARTTIME);

COMMENT ON TABLE STATIONSERVICEHIST IS 'Historical changes in STATION table.';

comment on column STATIONSERVICEHIST.STATIONCODE is 'The unique character code to identify a substation serving an ESIID as assigned by the TDSP and used in the ERCOT Network Model.';
comment on column STATIONSERVICEHIST.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column STATIONSERVICEHIST.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column STATIONSERVICEHIST.UFEZONECODE is 'The ERCOT Lodestar code identifying an electrically connected area where the total generation is compared to the total load and variences attributed to Unaccounted For Energy (UFE).  The STATIONSERVICEHIST.UFEZONECODE is U1.';
comment on column STATIONSERVICEHIST.CMZONECODE is 'The ERCOT Lodestar code associated to an ERCOT congestion management zone.  See CMZONE table.';
comment on column STATIONSERVICEHIST.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';
comment on column STATIONSERVICEHIST.SUBUFECODE is 'The ERCOT Lodestar code identifying an analysis subzone of electerically connected area where the total generation is compared to the total load and variences attributed to Unaccounted For Energy (UFE).';


CREATE TABLE TDSP (
    TDSPCODE                         VARCHAR2(64)      NOT NULL,
    TDSPNAME                         VARCHAR2(64)      NOT NULL,
    STARTTIME                        DATE              NOT NULL,
    STOPTIME                         DATE               ,
    ADDTIME                          DATE               ,
    DUNSNUMBER                       VARCHAR2(64)      NOT NULL,
    NOIECODE                         VARCHAR2(64)       
);

ALTER TABLE TDSP
  ADD CONSTRAINT PK_TDSP0_18
  PRIMARY KEY (TDSPCODE);

COMMENT ON TABLE TDSP IS 'Any entity under the jurisdiction of the PUCT and registered with ERCOT that owns and maintains a transmission or distribution system for the delivery of energy to and from the grid including a municipal or coop.';

comment on column TDSP.TDSPCODE is 'The ERCOT Lodestar code identifying the Transmission and Distribution Service Provider.';
comment on column TDSP.TDSPNAME is 'The long name identifying the Transmission and Distribution Service Provider.';
comment on column TDSP.STARTTIME is 'This timestamp represents the date and time when the data in a row takes effect.';
comment on column TDSP.STOPTIME is 'This timestamp represents the date and time when the data in a row is no longer in effect.';
comment on column TDSP.ADDTIME is 'This timestamp represents the date and time when a new row is added or a column value in an existing row is updated.';
comment on column TDSP.DUNSNUMBER is 'This code uniquely identifies the market participant as registered at ERCOT.';
comment on column TDSP.NOIECODE is 'The ERCOT Lodestar unique code associated to TDSPs that are registered with ERCOT as a non opt-in entity (NOIE).';