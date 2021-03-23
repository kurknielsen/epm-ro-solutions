create or replace function SYSDATE_AS_CUT return date is
--Revision: $Revision: 1.2 $
begin
  return TO_CUT(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'GMT');
end SYSDATE_AS_CUT;
/
