Java Stored Procedures
----------------------

After a Database build completes (from the System\build.sql script),
the batch file in this directory should be run to load the Java classes
behind all Java Stored Procedures.

Run the load-java batch file passing it the username, password, and
database to connect to. Ex:

c:\> load-ro-osp.bat josh/password@rodev2

This loads the Oracle Stored Procedures as well as the JCE v1.2.2. If the
Oracle JVM already has the JCE loaded (or has a J2SE 1.4 or higher runtime
environment, which includes JCE) you may want to remove that JAR from
the list of loaded JAR files.

In order for the NTLM method of SMTP Authentication to work, the schema
that will be running this code ("josh" in the example above) must have
certain grants so that the proper encryption libraries can be loaded.

Run the following script from a DBA oracle login to grant the proper
permissions. Replace the string 'JOSH' with the name of the schema that
will need the permissions:

begin
    dbms_java.grant_permission( 'JOSH', 'SYS:java.security.SecurityPermission', 'putProviderProperty.CryptixCrypto', '' );
    dbms_java.grant_permission( 'JOSH', 'SYS:java.security.SecurityPermission', 'insertProvider.CryptixCrypto', '' );
end;

The above is available as a script in a file in this folder named GRANT_JAVA.sql

Crystal Reports Exporter
-----------------------------------------------------------------------

The Crystal Reports Exporter is loaded seperately because it first requires the Crystal Reports SDK to be imported.  
To load the Crystal Reports SDK, execute the following command with the following jar files found in the Crystal Reports Designer
installation:

loadjava -user SCHEMA_NAME/SCHEMA_PASSWORD@DATABASE Concurrent.jar CrystalCharting.jar CrystalCommon.jar 
CrystalContentModels.jar CrystalDatabaseConnectors.jar CrystalExporters.jar CrystalExportingBase.jar CrystalFormulas.jar 
CrystalQueryEngine.jar CrystalReportEngine.jar CrystalReportingCommon.jar icu4j.jar jrcadapter.jar jrcerom.jar 
keycodeDecoder.jar log4j.jar MetafileRenderer.jar rasapp.jar rascore.jar ReportPrinter.jar ReportViewer.jar rpoifs.jar 
Serialization.jar xercesImpl.jar xml-apis.jar -force -genmissing -resolve

Then run the load-crystal-exporter batch file passing it the username, password, and
database to connect to. Ex:

c:\> load-crystal-exporter.bat josh/password@rodev2

The crystal reporter also requires configuration files to run: 

You can upload the log4j.properties file in the JavaStoredProcedures directory (this can be modified to fit your needs):

c:\> loadjava -user josh/password@rodev2 -resolve log4j.properties

Also, in your Crystal Reports installation there should be a CRConfig.xml file (this contains your license key). 
 It should be loaded into the schema as well, with  one major edit: An attribute named "reportlocation" must be commented out: 
	<!--<reportlocation></reportlocation>-->

Then the CFConfig.xml resource should be loaded just like the property file:

c:\> loadjava -user josh/password@rodev2 -resolve CRConfig.xml


Run the following script from a DBA oracle login to grant the proper
permissions. Replace the string 'JOSH' with the name of the schema that
will need the permissions and the string 'TEMP_DIRECTORY' with the name of the directory on the database server 
which will hold the temporary crystal report files:

GRANT JAVASYSPRIV to JOSH;

BEGIN

	DBMS_JAVA.GRANT_PERMISSION('JOSH','SYS:java.io.FilePermission','TEMP_DIRECTORY','read,write');

END;
/

The above is available as a script in a file in this folder named CRYSTAL_GRANTS.sql

Third Party Libraries
---------------------

The Java Stored Procedures included contain one third-party library:

* Cryptix
      This library contains a JCE provider for certain cryptographic
      algorithms including MD4 message digests (needed for NTLM
      authentication). The license for this library is listed below.

The library's original distribution form is available in the folder
called "thirdPartyLibraries". The portions used by the Java Stored
Procedures are all contained in the archive file named "ro-osp.jar"
and include the following:

* cryptix-jce-api.jar
* cryptix-jce-provider.jar

The license for this library follows:

=======================
Cryptix General Licence
=======================
Copyright (C) 1995, 1996, 1997, 1998, 1999, 2000 
The Cryptix Foundation Limited. All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions 
are met:

1. Redistributions of source code must retain the copyright notice, 
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright 
   notice, this list of conditions and the following disclaimer in 
   the documentation and/or other materials provided with the 
   distribution.

THIS SOFTWARE IS PROVIDED BY THE CRYPTIX FOUNDATION LIMITED ``AS IS'' 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR 
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF 
USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
THE POSSIBILITY OF SUCH DAMAGE.
