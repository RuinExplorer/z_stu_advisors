/* Formatted on 6/15/2016 4:33:21 PM (QP5 v5.287) */
SELECT *
  FROM gjbprun
 WHERE gjbprun_one_up_no = 19340095;

SELECT *
  FROM glbextr
 WHERE     glbextr_application = 'STUDENT'
       AND glbextr_selection = 'UATS_ADVISOR'
       AND glbextr_creator_id = 'A00304596'
       AND glbextr_user_id = 'A00304596';

SELECT sgradvr_pidm,
       sgradvr_term_code_eff,
       sgradvr_advr_pidm,
       sgradvr_advr_code,
       sgradvr_prim_ind,
       sgradvr_activity_date
  FROM sgradvr
 WHERE sgradvr_pidm = 2727078;

SELECT *
  FROM spriden
 WHERE spriden_pidm = 2338184 AND spriden_change_ind IS NULL;
 
Select * from spriden where spriden_id = 'A01506375'; --2735846
A01109057
A01497623
