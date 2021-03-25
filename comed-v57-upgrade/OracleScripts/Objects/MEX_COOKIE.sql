--====================================
--	MEX_COOKIE
--====================================
CREATE OR REPLACE TYPE MEX_COOKIE IS OBJECT (
	NAME     VARCHAR2(256),   -- Cookie name
	VALUE    VARCHAR2(4000),  -- Cookie value
	EXPIRES  VARCHAR2(64),    -- Expiration Date - NULL is cookie should not be persisted
	DOMAIN   VARCHAR2(128),   -- Domain name - for persistent cookies only
	PATH     VARCHAR2(1024),  -- URL path for which the cookie applies
	IS_SECURE NUMBER(1),      -- 1 if cookie should only be used for HTTPS, 0 otherwise
	IS_HIDDEN NUMBER(1)       -- 1 if cookie should be hidden from client apps (non-scriptable), 0 otherwise
);
/

CREATE OR REPLACE TYPE MEX_COOKIE_TBL IS TABLE OF MEX_COOKIE;
/
