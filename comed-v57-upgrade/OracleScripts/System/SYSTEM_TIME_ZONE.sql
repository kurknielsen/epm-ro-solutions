DELETE FROM SYSTEM_TIME_ZONE;

INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('EST', 'Eastern Standard Time', 0, 'EST', '-05:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('EDT', 'Eastern Daylight Time', 1, 'EST', '-04:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('AST', 'Atlantic Standard Time', 0, 'AST', '-04:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('ADT', 'Atlantic Daylight Time', 1, 'AST', '-03:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('MST', 'Mountain Standard Time', 0, 'MST', '-07:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('MDT', 'Mountain Daylight Time', 1, 'MST', '-06:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('CST', 'Central Standard Time', 0, 'CST', '-06:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('CDT', 'Central Daylight Time', 1, 'CST', '-05:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('PST', 'Pacific Standard Time', 0, 'PST', '-08:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('PDT', 'Pacific Daylight Time', 1, 'PST', '-07:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('GMT', 'Greenwich Mean Time', 0, 'GMT', '-00:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('BST', 'British Summer Time', 1, 'GMT', '+01:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('CET', 'Central European Time', 0, 'CET', '+01:00', 1);
INSERT INTO SYSTEM_TIME_ZONE (TIME_ZONE, TIME_ZONE_DESC, IS_DST_OBSERVANT, STANDARD_TIME_ZONE, STANDARD_TIME_ZONE_OFFSET, ENABLED) VALUES 
	('CES', 'Central European Summer Time ', 1, 'CET', '+02:00', 1);
COMMIT;
