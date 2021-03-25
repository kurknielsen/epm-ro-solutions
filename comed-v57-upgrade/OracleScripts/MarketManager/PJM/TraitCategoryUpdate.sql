UPDATE TRANSACTION_TRAIT_GROUP SET TRAIT_CATEGORY = 'Unit Data' 
 WHERE trait_group_name LIKE '%PS%' 
 OR trait_group_name IN ('PJM Update MinPumpMW', 'PJM Update MinGenMW');