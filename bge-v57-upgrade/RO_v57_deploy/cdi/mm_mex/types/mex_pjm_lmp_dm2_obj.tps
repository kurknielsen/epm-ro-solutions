BEGIN CDI_DROP_OBJECT('MEX_PJM_LMP_DM2_OBJ_TBL','TYPE'); END;
/
BEGIN CDI_DROP_OBJECT('MEX_PJM_LMP_DM2_OBJ','TYPE'); END;
/
CREATE OR REPLACE TYPE MEX_PJM_LMP_DM2_OBJ AS OBJECT
(
       datetime_beginning_utc date,
       datetime_beginning_ept date,
       pnode_id               varchar2(32),
       pnode_name             varchar2(64),
       voltage                VARCHAR2(32),
       equipment              VARCHAR2(32),
       type                   VARCHAR2(32),
       zone                   VARCHAR2(32),
       system_energy_price    number,
       total_lmp              number,
       congestion_price       number,
       marginal_loss_price    number,
       row_is_current         varchar2(5),
       version_nbr            number
);
/
CREATE OR REPLACE TYPE MEX_PJM_LMP_DM2_OBJ_TBL AS TABLE OF MEX_PJM_LMP_DM2_OBJ;
/
