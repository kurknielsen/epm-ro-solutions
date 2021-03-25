@echo off

rem // First load the JCE in case it doesn't already exist in the Oracle VM's standard libraries.
rem // Then load our Oracle Stored Procedures jar.

loadjava -user %1 -resolve crystal-exporter.jar


