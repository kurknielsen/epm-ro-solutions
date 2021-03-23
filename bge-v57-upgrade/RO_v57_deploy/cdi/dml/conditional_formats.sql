DECLARE
o_OID NUMBER;
BEGIN
   SECURITY_CONTROLS.SET_CURRENT_USER(SECURITY_CONTROLS.c_SUSER_SYSTEM);
   BEGIN
      IO.PUT_CONDITIONAL_FORMAT(o_OID,'BGE_TXN_COMPARE_DISPLAY',NULL,NULL,0,NULL);
   EXCEPTION WHEN OTHERS THEN NULL; END;
   BEGIN
      EM.PUT_CONDITIONAL_FORMAT_ITEM(o_OID,1,'DELTA_EMPHASIS_CODE=1',-16777216,-3342388,1,0,0,0);  
   EXCEPTION WHEN OTHERS THEN NULL; END;
   BEGIN
      EM.PUT_CONDITIONAL_FORMAT_ITEM(o_OID,2,'DELTA_EMPHASIS_CODE=2',-16777216,-13108,1,0,0,0);  
   EXCEPTION WHEN OTHERS THEN NULL; END;
   COMMIT;  
END;  
/