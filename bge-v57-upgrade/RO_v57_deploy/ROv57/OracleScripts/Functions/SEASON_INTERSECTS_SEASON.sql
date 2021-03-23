CREATE OR REPLACE FUNCTION SEASON_INTERSECTS_SEASON
	(
	p_TARGET_BEGIN_DATE IN DATE,
	p_TARGET_END_DATE IN DATE,
	p_SEASON_BEGIN_DATE IN DATE,
	p_SEASON_END_DATE IN DATE
	) RETURN CHAR IS
--Revision: $Revision: 1.15 $

-- Answer 'Y' if a date falls within the specified season dates; otherwise answer 'N''.
 
v_SEASON_BEGIN_DATE DATE;
v_SEASON_END_DATE DATE;
v_INTERSECTS CHAR(1);
 
BEGIN
 
    --Adjust year of season to that of target, based on begin years  - Note ADD_MONTHS adjusts for Feb 29 in leap year! - wjc 1/8/04
    v_SEASON_BEGIN_DATE := ADD_MONTHS(p_SEASON_BEGIN_DATE, 12*(TO_CHAR(p_TARGET_BEGIN_DATE, 'YYYY') - TO_CHAR(p_SEASON_BEGIN_DATE, 'YYYY') ));
    v_SEASON_END_DATE := ADD_MONTHS(p_SEASON_END_DATE, 12*(TO_CHAR(p_TARGET_BEGIN_DATE, 'YYYY') - TO_CHAR(p_SEASON_BEGIN_DATE, 'YYYY') ));
    --Adjust end year of season that spans years, but is entered as same year - wjc 1/8/04
    IF v_SEASON_END_DATE < v_SEASON_BEGIN_DATE THEN  --End year should come after begin year
        IF p_TARGET_BEGIN_DATE >= v_SEASON_END_DATE THEN  --Extend season_end into next year
            v_SEASON_END_DATE := ADD_MONTHS(v_SEASON_END_DATE,12);
        ELSE  --Extend season_begin into previous year
            v_SEASON_BEGIN_DATE := ADD_MONTHS(v_SEASON_BEGIN_DATE,-12);
        END IF;
    END IF;
    --See if the target overlaps the season
    IF p_TARGET_BEGIN_DATE <= v_SEASON_END_DATE  --Target begins before season ends
      AND p_TARGET_END_DATE >= v_SEASON_BEGIN_DATE  THEN  --and target ends after season begins
        v_INTERSECTS := 'Y';
    ELSE    
        v_INTERSECTS := 'N';
    END IF;
     
    RETURN v_INTERSECTS;

END SEASON_INTERSECTS_SEASON;
/
