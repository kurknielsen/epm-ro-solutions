CREATE OR REPLACE FUNCTION DATE_IS_WITHIN_SEASON
--Revision: $Revision: 1.19 $
	(
	p_TARGET_DATE IN DATE,
	p_SEASON_BEGIN_DATE IN DATE,
	p_SEASON_END_DATE IN DATE
	) RETURN CHAR IS

--c	Answer 'Y' if a date falls within the specified season dates; otherwise answer 'N'.

v_BEGIN_MMDD CHAR(4) := TO_CHAR(p_SEASON_BEGIN_DATE,'MMDD');
v_END_MMDD CHAR(4) := TO_CHAR(p_SEASON_END_DATE, 'MMDD');
v_TARGET_MMDD CHAR(4) := TO_CHAR(p_TARGET_DATE, 'MMDD');
BEGIN

	--We want to include 2/29 in February, even if the specified end date is 2/28.
	IF v_END_MMDD = '0228' THEN
	   v_END_MMDD := '0229';
	END IF; 

	IF v_BEGIN_MMDD <= v_END_MMDD THEN
		IF v_TARGET_MMDD BETWEEN v_BEGIN_MMDD AND v_END_MMDD THEN
			RETURN 'Y';
		ELSE
			RETURN 'N';
		END IF;
	ELSE -- Handles case of year-boundary crossing.
		IF v_TARGET_MMDD >= v_BEGIN_MMDD OR v_TARGET_MMDD <= v_END_MMDD THEN
			RETURN 'Y';
		ELSE
			RETURN 'N';
		END IF;
	END IF;

END DATE_IS_WITHIN_SEASON;
/

