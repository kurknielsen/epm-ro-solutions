begin
    dbms_java.grant_permission( 'RTO', 'SYS:java.security.SecurityPermission', 'putProviderProperty.CryptixCrypto', '' );
    dbms_java.grant_permission( 'RTO', 'SYS:java.security.SecurityPermission', 'insertProvider.CryptixCrypto', '' );
end;
/

