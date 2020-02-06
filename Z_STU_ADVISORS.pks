/* Formatted on 6/7/2016 1:14:18 PM (QP5 v5.287) */
CREATE OR REPLACE PACKAGE BANINST1.z_stu_advisors
AS
   /******************************************************************************
      NAME:       z_stu_advisors
      PURPOSE:    batch update of advisor assignments based on POPSEL

   ******************************************************************************/



   PROCEDURE P_PURGE_ADVISOR_RECORDS (p_pidm_student    NUMBER,
                                      p_term_code       VARCHAR2);

   PROCEDURE P_STUDENT_ADVISOR_UPDATE (
      p_term_code       VARCHAR2,
      p_advisor_id      VARCHAR2,
      p_advisor_code    VARCHAR2,
      p_application     VARCHAR2,
      p_selection       VARCHAR2,
      p_creator_id      VARCHAR2,
      p_user_id         VARCHAR2,
      p_purge           VARCHAR2 DEFAULT NULL);

   PROCEDURE ZSPADVR (one_up_no IN NUMBER);

   PROCEDURE P_STUDENT_ADVISOR_SWAP (
      p_term_code         VARCHAR2,
      p_old_advisor_id    VARCHAR2,
      p_new_advisor_id    VARCHAR2,
      p_advisor_code      VARCHAR2,
      p_prim_override     VARCHAR2 DEFAULT 'N');

   PROCEDURE ZSPSWAP (one_up_no IN NUMBER);
END z_stu_advisors;
/