cd ../Common
python makedrop.py BuildObjects.sql drop_Common_objects.sql

cd ../CAISO
python ../Common/makedrop.py CAISO_OASIS_Objects.sql
python ../Common/makedrop.py CAISO_Objects.sql

cd ../ERCOT
python ../Common/makedrop.py MEX_ERCOT_Objects.sql drop_objects.sql

cd ../ISONE
python ../Common/makedrop.py isone_objects.sql drop_objects.sql

cd ../MISO
python ../Common/makedrop.py MISO_Objects.sql drop_objects.sql

cd ../NY-ISO
python ../Common/makedrop.py nyiso_objects.sql drop_objects.sql

cd ../OASIS
python ../Common/makedrop.py MEX_OASIS_Objects.sql drop_objects.sql

cd ../Other
python ../Common/makedrop.py PI_Objects.sql drop_PI_Objects.sql

cd ../PJM
python ../Common/makedrop.py PJM_EES_Objects.sql
python ../Common/makedrop.py PJM_EMKT_Objects.sql
python ../Common/makedrop.py PJM_Objects.sql

pause

