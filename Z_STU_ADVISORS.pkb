CREATE OR REPLACE PACKAGE BODY BANINST1.z_stu_advisors
AS
   /******************************************************************************
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      beta       20140423    Carl Ellsworth   Created P_STUDENT_ADVISOR_UPDATE
                                                as a stand alone procedure
      1.0        20150527    Carl Ellsworth   Created this package, heavily
                                                modified P_STUDENT_ADVISOR_UPDATE
                                                to generalize and work with POPSEL
                                              Added f_get_existing_term and
                                                P_INSERT_ADVISOR_RECORD
      1.0.1      20150528    Carl Ellsworth   Added ZSPADVR to allow call from
                                                JOBSUB
      1.0.2      20150529    Carl Ellsworth   Corrected bug with primary indicator
      1.1        20151023    Carl Ellsworth   Added P_STUDENT_ADVISOR_SWAP and
                                                ZSPSWP, expanded functionality in
                                                P_INSERT_ADVISOR_RECORD to force
                                                primary indicator
      1.1.1      20151026    Carl Ellsworth   Added logging to p_student_advisor_swap
      1.2.0      20160527    Carl Ellsworth   Added p_purge_advisor_records and
                                                added parameter to ZSPADVR
      1.2.1      20160627    Carl Ellsworth   Added logic to add advisors in purge
                                                mode even if previously assigned.
                                                Updated record count to include
                                                all inserts of advisor
      1.3.0      20181011    Carl Ellsworth   Correded a sequencing problem that would
                                                mark new advisors as primary when
                                                rolling forward existing advisors

   ******************************************************************************/



   FUNCTION f_get_existing_term (p_pidm NUMBER, p_term_code VARCHAR)
      RETURN VARCHAR2
   AS
      /******************************************************************************
         This function finds if there are advisor assignments in an existing term
         and if so - returns that term, if not - returns the current term.
      ******************************************************************************/
      v_existing_term_code   VARCHAR2 (6) := NULL;
   BEGIN
      SELECT MAX (sgradvr_term_code_eff)
        INTO v_existing_term_code
        FROM sgradvr
       WHERE sgradvr_pidm = p_pidm AND sgradvr_term_code_eff <= p_term_code;

      IF v_existing_term_code IS NULL
      THEN
         RETURN p_term_code;
      END IF;

      RETURN v_existing_term_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN p_term_code;
   END;

   PROCEDURE P_INSERT_ADVISOR_RECORD (
      p_pidm_student     NUMBER,
      p_term_code        VARCHAR2,
      p_pidm_advisor     VARCHAR2,
      p_advr_code        VARCHAR2,
      p_activity_date    DATE,
      p_prim_override    VARCHAR2 DEFAULT 'N')
   AS
      /******************************************************************************
         This procedure does the advisor assignment into banner.
      ******************************************************************************/
      v_flag   VARCHAR2 (1) := NULL;
   BEGIN
      --need to check to see if an advisor with already exists as a primary
      SELECT MAX ('X')
        INTO v_flag
        FROM sgradvr
       WHERE     sgradvr_pidm = p_pidm_student
             AND sgradvr_term_code_eff = p_term_code
             --AND sgradvr_advr_code = p_advr_code
             AND sgradvr_prim_ind = 'Y';

      IF v_flag IS NULL
      THEN
         --load advisor as primary if a primary doesn't exist
         INSERT INTO sgradvr (sgradvr_pidm,
                              sgradvr_term_code_eff,
                              sgradvr_advr_pidm,
                              sgradvr_advr_code,
                              sgradvr_prim_ind,
                              sgradvr_activity_date)
              VALUES (p_pidm_student,
                      p_term_code,
                      p_pidm_advisor,
                      p_advr_code,
                      'Y',
                      p_activity_date);
      ELSIF p_prim_override = 'Y'
      THEN
         --remove primary indicator from existing record
         UPDATE sgradvr
            SET sgradvr_prim_ind = 'N'
          WHERE     sgradvr_pidm = p_pidm_student
                AND sgradvr_term_code_eff = p_term_code
                AND sgradvr_prim_ind = 'Y';

         --load advisor as primary
         INSERT INTO sgradvr (sgradvr_pidm,
                              sgradvr_term_code_eff,
                              sgradvr_advr_pidm,
                              sgradvr_advr_code,
                              sgradvr_prim_ind,
                              sgradvr_activity_date)
              VALUES (p_pidm_student,
                      p_term_code,
                      p_pidm_advisor,
                      p_advr_code,
                      'Y',
                      p_activity_date);
      ELSE
         --load without primary indicator if a primary already exists
         INSERT INTO sgradvr (sgradvr_pidm,
                              sgradvr_term_code_eff,
                              sgradvr_advr_pidm,
                              sgradvr_advr_code,
                              sgradvr_prim_ind,
                              sgradvr_activity_date)
              VALUES (p_pidm_student,
                      p_term_code,
                      p_pidm_advisor,
                      p_advr_code,
                      'N',
                      p_activity_date);
      END IF;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         DBMS_OUTPUT.PUT_LINE (
               'EXCEPTION: Advisor '
            || p_pidm_advisor
            || ' already assigned to student '
            || p_pidm_student);
   END;

   PROCEDURE P_DELETE_ADVISOR_RECORD (p_pidm_student    NUMBER,
                                      p_term_code       VARCHAR2,
                                      p_pidm_advisor    VARCHAR2)
   AS
   /******************************************************************************
      This procedure removes specific advisor assignments in banner.
   ******************************************************************************/
   BEGIN
      DELETE FROM sgradvr
            WHERE     sgradvr_pidm = p_pidm_student
                  AND sgradvr_term_code_eff = p_term_code
                  AND sgradvr_advr_pidm = p_pidm_advisor;
   END;

   PROCEDURE P_PURGE_ADVISOR_RECORDS (p_pidm_student    NUMBER,
                                      p_term_code       VARCHAR2)
   AS
   /******************************************************************************
      This procedure removes all advisor assignments from the term code parameter
      forward. This is inteded to be run prior to an advisor assignment for a
      clean slate.
   ******************************************************************************/
   BEGIN
      DELETE FROM sgradvr
            WHERE     sgradvr_pidm = p_pidm_student
                  AND sgradvr_term_code_eff >= p_term_code;
   END;

   PROCEDURE P_STUDENT_ADVISOR_UPDATE (
      p_term_code       VARCHAR2,
      p_advisor_id      VARCHAR2,
      p_advisor_code    VARCHAR2,
      p_application     VARCHAR2,
      p_selection       VARCHAR2,
      p_creator_id      VARCHAR2,
      p_user_id         VARCHAR2,
      p_purge           VARCHAR2 DEFAULT NULL)
   AS
      /******************************************************************************
         This procedure does batch advisor assignments from a POPSEL.
         If assignments exist prior to the specified term, this are rolled forward
         and created along with the new advisor assignment in the specified term.
         If there are advisor assignments in the future, the new advisor assignment
         is also added as part of that effective term.
      ******************************************************************************/
      CURSOR student_c (
         p_application    VARCHAR2,
         p_selection      VARCHAR2,
         p_creator_id     VARCHAR2,
         p_user_id        VARCHAR2)
      IS
         SELECT glbextr_key pidm
           FROM glbextr
          WHERE     glbextr_application = UPPER (p_application)
                AND glbextr_selection = UPPER (p_selection)
                AND glbextr_creator_id = UPPER (p_creator_id)
                AND glbextr_user_id = UPPER (p_user_id);

      CURSOR existing_attributes_c (p_pidm IN NUMBER, p_term IN VARCHAR2)
      IS
         SELECT sgradvr_pidm,
                sgradvr_term_code_eff,
                sgradvr_advr_pidm,
                sgradvr_advr_code,
                sgradvr_prim_ind,
                sgradvr_activity_date
           FROM sgradvr
          WHERE sgradvr_pidm = p_pidm AND sgradvr_term_code_eff = p_term;

      CURSOR future_terms_c (p_pidm IN NUMBER)
      IS
         SELECT DISTINCT sgradvr_term_code_eff
           FROM sgradvr
          WHERE sgradvr_pidm = p_pidm AND sgradvr_term_code_eff > p_term_code;

      v_activity_date        DATE := SYSDATE;
      v_advisor_pidm         NUMBER (8) := NULL;
      v_existing_term_code   VARCHAR2 (6) := NULL;
      v_count                NUMBER (5) := 0;
      v_error_found          VARCHAR2 (1) := 'N';
      v_existing_attribute   NUMBER (3) := 0;
   BEGIN
      --get the advisor pidm
      SELECT spriden_pidm
        INTO v_advisor_pidm
        FROM spriden
       WHERE spriden_change_ind IS NULL AND spriden_id = p_advisor_id;

      FOR student_rec IN student_c (p_application,
                                    p_selection,
                                    p_creator_id,
                                    p_user_id)
      LOOP
         IF (p_purge = 'Y')
         THEN
            --purge all current and future advisor records if purge is set
            p_purge_advisor_records (student_rec.pidm, p_term_code);
            COMMIT;

            --add back advisor for the term regardless if previously assigned
            P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                     p_term_code,
                                     v_advisor_pidm,
                                     p_advisor_code,
                                     v_activity_date);

            v_count := v_count + 1;
         END IF;

         --reset variables
         v_existing_term_code := NULL;

         --get existing term_code
         v_existing_term_code :=
            f_get_existing_term (student_rec.pidm, p_term_code);

         --this verifies that the record we are trying to insert doesn't already exist
         SELECT COUNT (sgradvr_pidm)
           INTO v_existing_attribute
           FROM sgradvr
          WHERE     sgradvr_pidm = student_rec.pidm
                AND sgradvr_term_code_eff = v_existing_term_code
                AND sgradvr_advr_code = p_advisor_code
                AND sgradvr_advr_pidm = v_advisor_pidm;

         IF v_existing_attribute = 0 AND v_existing_term_code = p_term_code
         --either no existing attributes for any term or attributes exist in current term
         THEN
            --insert attributes
            P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                     p_term_code,
                                     v_advisor_pidm,
                                     p_advisor_code,
                                     v_activity_date);

            v_count := v_count + 1;
         ELSIF v_existing_attribute = 0
         --attributes exist in a prior term, need to insert the new and roll the old forward
         THEN
            --roll previously existing attributes forward to new term
            --iff p_purge is null
            IF (p_purge IS NULL)
            THEN
               FOR existing_rec
                  IN existing_attributes_c (student_rec.pidm,
                                            v_existing_term_code)
               LOOP
                  P_INSERT_ADVISOR_RECORD (
                     student_rec.pidm,
                     p_term_code,
                     existing_rec.sgradvr_advr_pidm,
                     existing_rec.sgradvr_advr_code,
                     existing_rec.sgradvr_activity_date);
               /*
                  INSERT INTO sgradvr (sgradvr_pidm,
                                       sgradvr_term_code_eff,
                                       sgradvr_advr_pidm,
                                       sgradvr_advr_code,
                                       sgradvr_prim_ind,
                                       sgradvr_activity_date)
                       VALUES (student_rec.pidm,
                               p_term_code,
                               existing_rec.sgradvr_advr_pidm,
                               existing_rec.sgradvr_advr_code,
                               existing_rec.sgradvr_prim_ind,
                               existing_rec.sgradvr_activity_date);
               */
               END LOOP;
            END IF;
            
            --insert new attribute
            P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                     p_term_code,
                                     v_advisor_pidm,
                                     p_advisor_code,
                                     v_activity_date);

            v_count := v_count + 1;

         END IF;

         --insert attributes for future terms
         FOR future_rec IN future_terms_c (student_rec.pidm)
         LOOP
            --this verifies that the record we are trying to insert doesn't already exist
            SELECT COUNT (sgradvr_pidm)
              INTO v_existing_attribute
              FROM sgradvr
             WHERE     sgradvr_pidm = student_rec.pidm
                   AND sgradvr_term_code_eff =
                          future_rec.sgradvr_term_code_eff
                   AND sgradvr_advr_code = p_advisor_code
                   AND sgradvr_advr_pidm = v_advisor_pidm;

            IF v_existing_attribute = 0
            THEN
               --insert new attribute
               P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                        future_rec.sgradvr_term_code_eff,
                                        v_advisor_pidm,
                                        p_advisor_code,
                                        v_activity_date);
            END IF;
         END LOOP;

      END LOOP;

      DBMS_OUTPUT.put_line ('COMPLETION: ' || v_count || ' records loaded.');

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line (
            'EXCEPTION: Cannot find record in Banner for ID ' || p_advisor_id);
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('EXCEPTION: ' || SQLERRM);
   END;

   PROCEDURE ZSPADVR (one_up_no IN NUMBER)
   AS
      /******************************************************************************
         this procedure is just a wrapper to allow the P_STUDENT_ADVISOR_UPDATE
         procedure to gather parameters from the JOBSUB entries
      ******************************************************************************/

      v_application    VARCHAR2 (32);
      v_selection      VARCHAR2 (32);
      v_creator_id     VARCHAR2 (32);
      v_user_id        VARCHAR2 (32);
      v_term_code      VARCHAR2 (32);
      v_advisor_id     VARCHAR2 (32);
      v_advisor_code   VARCHAR2 (32);
      v_purge          VARCHAR2 (32);
   BEGIN
      BEGIN
         SELECT gjbprun_value
           INTO v_application
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '01';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_application := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_selection
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '02';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_creator_id := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_creator_id
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '03';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_creator_id := NULL;
      END;


      BEGIN
         SELECT gjbprun_value
           INTO v_user_id
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '04';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_user_id := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_term_code
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '05';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_term_code := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_advisor_id
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '06';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_advisor_id := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_advisor_code
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '07';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_advisor_code := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_purge
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPADVR'
                AND gjbprun_number = '08';

         --check formatting for call
         IF (v_purge IN ('Y',
                         'y',
                         'YES',
                         'yes',
                         'Yes'))
         THEN
            v_purge := 'Y';
         ELSE
            v_purge := NULL;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_purge := NULL;
      END;

      P_STUDENT_ADVISOR_UPDATE (v_term_code,
                                v_advisor_id,
                                v_advisor_code,
                                v_application,
                                v_selection,
                                v_creator_id,
                                v_user_id,
                                v_purge);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('EXCEPTION: ' || SQLERRM);
   END;

   PROCEDURE P_STUDENT_ADVISOR_SWAP (
      p_term_code         VARCHAR2,
      p_old_advisor_id    VARCHAR2,
      p_new_advisor_id    VARCHAR2,
      p_advisor_code      VARCHAR2,
      p_prim_override     VARCHAR2 DEFAULT 'N')
   AS
      /******************************************************************************
         This procedure swaps one advisor assignment for another in batch.
         If other assignments exist prior to the specified term, these are rolled forward
         and created along with the new advisor assignment in the specified term.
         If there are other advisor assignments in the future, the new advisor assignment
         is also added as part of that effective term and the old advisor removed.
      ******************************************************************************/
      CURSOR student_c (
         p_advr_pidm   IN NUMBER)
      IS
         SELECT sgradvr_pidm pidm,
                spriden_id aNum,
                sgradvr_term_code_eff term_code,
                sgradvr_advr_pidm,
                sgradvr_advr_code,
                sgradvr_prim_ind,
                sgradvr_activity_date
           FROM sgradvr alpha
                JOIN spriden
                   ON     spriden_pidm = sgradvr_pidm
                      AND spriden_change_ind IS NULL
          WHERE     sgradvr_advr_pidm = p_advr_pidm
                AND sgradvr_term_code_eff =
                       (SELECT MAX (bravo.sgradvr_term_code_eff)
                          FROM sgradvr bravo
                         WHERE     bravo.sgradvr_pidm = alpha.sgradvr_pidm
                               AND bravo.sgradvr_term_code_eff <= p_term_code);

      CURSOR existing_attributes_c (
         p_pidm               IN NUMBER,
         p_term               IN VARCHAR2,
         p_old_advisor_pidm   IN NUMBER)
      IS
         --this criteria prevents the old advisor from being rollerd forward
         SELECT sgradvr_pidm,
                sgradvr_term_code_eff,
                sgradvr_advr_pidm,
                sgradvr_advr_code,
                sgradvr_prim_ind,
                sgradvr_activity_date
           FROM sgradvr
          WHERE     sgradvr_pidm = p_pidm
                AND sgradvr_term_code_eff = p_term
                AND sgradvr_advr_pidm <> p_old_advisor_pidm;

      CURSOR future_terms_c (p_pidm IN NUMBER)
      IS
         SELECT DISTINCT sgradvr_term_code_eff
           FROM sgradvr
          WHERE sgradvr_pidm = p_pidm AND sgradvr_term_code_eff > p_term_code;

      v_flag                 VARCHAR2 (1) := NULL;
      v_activity_date        DATE := SYSDATE;
      v_old_advisor_pidm     NUMBER (8) := NULL;
      v_new_advisor_pidm     NUMBER (8) := NULL;
      v_existing_term_code   VARCHAR2 (6) := NULL;
      v_count                NUMBER (5) := 0;
      v_error_found          VARCHAR2 (1) := 'N';
      v_existing_attribute   NUMBER (3) := 0;

      ERROR_PARAMETERS       EXCEPTION;
   BEGIN
      BEGIN
         --get the old advisor pidm
         SELECT spriden_pidm
           INTO v_old_advisor_pidm
           FROM spriden
          WHERE spriden_change_ind IS NULL AND spriden_id = p_old_advisor_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            DBMS_OUTPUT.put_line (
                  'EXCEPTION: Cannot find record in Banner for ID '
               || p_old_advisor_id);
            RAISE ERROR_PARAMETERS;
      END;

      BEGIN
         --get the new advisor pidm
         SELECT spriden_pidm
           INTO v_new_advisor_pidm
           FROM spriden
          WHERE spriden_change_ind IS NULL AND spriden_id = p_new_advisor_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            DBMS_OUTPUT.put_line (
                  'EXCEPTION: Cannot find record in Banner for ID '
               || p_new_advisor_id);
            RAISE ERROR_PARAMETERS;
      END;

      BEGIN
         --verify that the advisor code is valid
         SELECT 'X'
           INTO v_flag
           FROM stvadvr
          WHERE stvadvr_code = p_advisor_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            DBMS_OUTPUT.put_line (
                  'EXCEPTION: Cannot find advisor type '
               || p_advisor_code
               || ' in Banner.');
            RAISE ERROR_PARAMETERS;
      END;

      FOR student_rec IN student_c (v_old_advisor_pidm)
      LOOP
         --reset variables
         v_existing_term_code := student_rec.term_code;

         --this verifies that the record we are trying to insert doesn't already exist
         SELECT COUNT (sgradvr_pidm)
           INTO v_existing_attribute
           FROM sgradvr
          WHERE     sgradvr_pidm = student_rec.pidm
                AND sgradvr_term_code_eff = v_existing_term_code
                AND sgradvr_advr_code = p_advisor_code
                AND sgradvr_advr_pidm = v_new_advisor_pidm;

         IF v_existing_attribute = 0 AND v_existing_term_code = p_term_code
         --either no existing attributes for any term or attributes exist in current term
         THEN
            --remove old advisor
            P_DELETE_ADVISOR_RECORD (student_rec.pidm,
                                     p_term_code,
                                     v_old_advisor_pidm);

            --insert attributes
            P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                     p_term_code,
                                     v_new_advisor_pidm,
                                     p_advisor_code,
                                     v_activity_date,
                                     p_prim_override);

            DBMS_OUTPUT.put_line ('Updated Student ' || student_rec.aNum);
         ELSIF v_existing_attribute = 0
         --attributes exist in a prior term, need to insert the new and roll the old forward
         THEN
            --insert new attribute
            P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                     p_term_code,
                                     v_new_advisor_pidm,
                                     p_advisor_code,
                                     v_activity_date,
                                     p_prim_override);

            --roll previously existing attributes forward to new term
            FOR existing_rec
               IN existing_attributes_c (student_rec.pidm,
                                         v_existing_term_code,
                                         v_old_advisor_pidm)
            LOOP
               P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                        p_term_code,
                                        existing_rec.sgradvr_advr_pidm,
                                        existing_rec.sgradvr_advr_code,
                                        existing_rec.sgradvr_activity_date);
            END LOOP;

            DBMS_OUTPUT.put_line (
                  'updated Student '
               || student_rec.aNum
               || ' and rolled previous records forward.');
         ELSE
            --attribute already exists
            v_count := v_count - 1;
         END IF;

         --insert attributes for future terms
         FOR future_rec IN future_terms_c (student_rec.pidm)
         LOOP
            --this verifies that the record we are trying to insert doesn't already exist
            SELECT COUNT (sgradvr_pidm)
              INTO v_existing_attribute
              FROM sgradvr
             WHERE     sgradvr_pidm = student_rec.pidm
                   AND sgradvr_term_code_eff =
                          future_rec.sgradvr_term_code_eff
                   AND sgradvr_advr_code = p_advisor_code
                   AND sgradvr_advr_pidm = v_new_advisor_pidm;

            IF v_existing_attribute = 0
            THEN
               --remove old advisor
               P_DELETE_ADVISOR_RECORD (student_rec.pidm,
                                        future_rec.sgradvr_term_code_eff,
                                        v_old_advisor_pidm);
               --insert new attribute
               P_INSERT_ADVISOR_RECORD (student_rec.pidm,
                                        future_rec.sgradvr_term_code_eff,
                                        v_new_advisor_pidm,
                                        p_advisor_code,
                                        v_activity_date,
                                        p_prim_override);
            END IF;
         END LOOP;

         v_count := v_count + 1;
      END LOOP;

      DBMS_OUTPUT.put_line ('COMPLETION: ' || v_count || ' records loaded.');

      COMMIT;
   EXCEPTION
      WHEN ERROR_PARAMETERS
      THEN
         DBMS_OUTPUT.put_line ('EXCEPTION: Check parameters and try again.');
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('EXCEPTION: ' || SQLERRM);
   END;

   PROCEDURE ZSPSWAP (one_up_no IN NUMBER)
   AS
      /******************************************************************************
         this porocedure is just a wrapper to allow the P_STUDENT_ADVISOR_SWAP
         procedure to gather parameters from the JOBSUB entries
      ******************************************************************************/

      v_term_code          VARCHAR (32);
      v_old_advisor_id     VARCHAR2 (32);
      v_new_advisor_id     VARCHAR2 (32);
      v_advisor_code       VARCHAR2 (32);
      v_primary_override   VARCHAR2 (3);
   BEGIN
      BEGIN
         SELECT gjbprun_value
           INTO v_term_code
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPSWAP'
                AND gjbprun_number = '01';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_term_code := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_old_advisor_id
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPSWAP'
                AND gjbprun_number = '02';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_old_advisor_id := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_new_advisor_id
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPSWAP'
                AND gjbprun_number = '03';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_new_advisor_id := NULL;
      END;


      BEGIN
         SELECT gjbprun_value
           INTO v_advisor_code
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPSWAP'
                AND gjbprun_number = '04';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_advisor_code := NULL;
      END;

      BEGIN
         SELECT gjbprun_value
           INTO v_primary_override
           FROM gjbprun
          WHERE     gjbprun_one_up_no = one_up_no
                AND gjbprun_job = 'ZSPSWAP'
                AND gjbprun_number = '05';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_primary_override := NULL;
      END;


      P_STUDENT_ADVISOR_SWAP (v_term_code,
                              v_old_advisor_id,
                              v_new_advisor_id,
                              v_advisor_code,
                              v_primary_override);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('EXCEPTION: ' || SQLERRM);
   END;
END z_stu_advisors;
/