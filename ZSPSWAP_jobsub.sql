/* Formatted on 10/23/2015 4:12:05 PM (QP5 v5.277) */
--z_secured_procs entry

/*
PROCEDURE ZSPSWAP (one_up_no IN NUMBER)
AS
BEGIN
   verify_access ('ZSPSWAP'); -- call security
   baninst1.z_stu_advisors.ZSPSWAP (one_up_no);
   revoke_access;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
*/

--JOBSUB Entries

--create banner object and set current version

INSERT INTO bansecr.guraobj (GURAOBJ_OBJECT,
                             GURAOBJ_DEFAULT_ROLE,
                             GURAOBJ_CURRENT_VERSION,
                             GURAOBJ_SYSI_CODE,
                             GURAOBJ_ACTIVITY_DATE,
                             GURAOBJ_CHECKSUM,
                             GURAOBJ_USER_ID)
     VALUES ('ZSPSWAP',
             'BAN_DEFAULT_M',
             '8.7',                                                  --version
             'S',                                                     --module
             SYSDATE,
             NULL,
             'Z_CARL_ELLSWORTH');

--create GENERAL object base table entry

INSERT INTO GUBOBJS (GUBOBJS_NAME,
                     GUBOBJS_DESC,
                     GUBOBJS_OBJT_CODE,
                     GUBOBJS_SYSI_CODE,
                     GUBOBJS_USER_ID,
                     GUBOBJS_ACTIVITY_DATE,
                     GUBOBJS_HELP_IND,
                     GUBOBJS_EXTRACT_ENABLED_IND)
     VALUES ('ZSPSWAP',
             'Batch Swap Advisors',
             'JOBS',
             'S',                                                     --module
             'LOCAL',
             SYSDATE,
             'N',
             'B');

--create job definition

INSERT INTO gjbjobs (GJBJOBS_NAME,
                     GJBJOBS_TITLE,
                     GJBJOBS_ACTIVITY_DATE,
                     GJBJOBS_SYSI_CODE,
                     GJBJOBS_JOB_TYPE_IND,
                     GJBJOBS_DESC,
                     GJBJOBS_COMMAND_NAME,
                     GJBJOBS_PRNT_FORM,
                     GJBJOBS_PRNT_CODE,
                     GJBJOBS_LINE_COUNT,
                     GJBJOBS_VALIDATION)
        VALUES (
                  'ZSPSWAP',
                  'Batch Swap Advisors',
                  SYSDATE,
                  'S',                                                --module
                  'P',                                              --job type
                  'Updates student advisor assignments removing a specific old advisor and adding a new in batch.',
                  NULL,
                  NULL,
                  'DATABASE',
                  NULL,
                  NULL);

--create job parameter definition

INSERT INTO gjbpdef (GJBPDEF_JOB,
                     GJBPDEF_NUMBER,
                     GJBPDEF_DESC,
                     GJBPDEF_LENGTH,
                     GJBPDEF_TYPE_IND,
                     GJBPDEF_OPTIONAL_IND,
                     GJBPDEF_SINGLE_IND,
                     GJBPDEF_ACTIVITY_DATE,
                     GJBPDEF_LOW_RANGE,
                     GJBPDEF_HIGH_RANGE,
                     GJBPDEF_HELP_TEXT,
                     GJBPDEF_VALIDATION,
                     GJBPDEF_LIST_VALUES)
        VALUES (
                  'ZSPSWAP',
                  '01',                                     --parameter number
                  'Term Code',                         --parameter description
                  32,                                                 --length
                  'C',                      --Character, Integer, Date, Number
                  'R',                                     --Optional/Required
                  'S',                                       --Single/Multiple
                  SYSDATE,
                  NULL,                                            --low range
                  NULL,                                           --high range
                  'Six digit term code when the advisor assignment becomes effective', --help text
                  NULL,
                  NULL);

INSERT INTO gjbpdef (GJBPDEF_JOB,
                     GJBPDEF_NUMBER,
                     GJBPDEF_DESC,
                     GJBPDEF_LENGTH,
                     GJBPDEF_TYPE_IND,
                     GJBPDEF_OPTIONAL_IND,
                     GJBPDEF_SINGLE_IND,
                     GJBPDEF_ACTIVITY_DATE,
                     GJBPDEF_LOW_RANGE,
                     GJBPDEF_HIGH_RANGE,
                     GJBPDEF_HELP_TEXT,
                     GJBPDEF_VALIDATION,
                     GJBPDEF_LIST_VALUES)
     VALUES ('ZSPSWAP',
             '02',                                          --parameter number
             'Previous Adivsor ID',                    --parameter description
             32,                                                      --length
             'C',                           --Character, Integer, Date, Number
             'R',                                          --Optional/Required
             'S',                                            --Single/Multiple
             SYSDATE,
             NULL,                                                 --low range
             NULL,                                                --high range
             'Banner ID of the advisor to be replaced on students', --help text
             NULL,
             NULL);

INSERT INTO gjbpdef (GJBPDEF_JOB,
                     GJBPDEF_NUMBER,
                     GJBPDEF_DESC,
                     GJBPDEF_LENGTH,
                     GJBPDEF_TYPE_IND,
                     GJBPDEF_OPTIONAL_IND,
                     GJBPDEF_SINGLE_IND,
                     GJBPDEF_ACTIVITY_DATE,
                     GJBPDEF_LOW_RANGE,
                     GJBPDEF_HIGH_RANGE,
                     GJBPDEF_HELP_TEXT,
                     GJBPDEF_VALIDATION,
                     GJBPDEF_LIST_VALUES)
     VALUES ('ZSPSWAP',
             '03',                                          --parameter number
             'New Advisor ID',                         --parameter description
             32,                                                      --length
             'C',                           --Character, Integer, Date, Number
             'R',                                          --Optional/Required
             'S',                                            --Single/Multiple
             SYSDATE,
             NULL,                                                 --low range
             NULL,                                                --high range
             'Banner ID of the advisor to be assigned to students', --help text
             NULL,
             NULL);

INSERT INTO gjbpdef (GJBPDEF_JOB,
                     GJBPDEF_NUMBER,
                     GJBPDEF_DESC,
                     GJBPDEF_LENGTH,
                     GJBPDEF_TYPE_IND,
                     GJBPDEF_OPTIONAL_IND,
                     GJBPDEF_SINGLE_IND,
                     GJBPDEF_ACTIVITY_DATE,
                     GJBPDEF_LOW_RANGE,
                     GJBPDEF_HIGH_RANGE,
                     GJBPDEF_HELP_TEXT,
                     GJBPDEF_VALIDATION,
                     GJBPDEF_LIST_VALUES)
     VALUES ('ZSPSWAP',
             '04',                                          --parameter number
             'Advisor Code',                           --parameter description
             32,                                                      --length
             'C',                           --Character, Integer, Date, Number
             'R',                                          --Optional/Required
             'S',                                            --Single/Multiple
             SYSDATE,
             NULL,                                                 --low range
             NULL,                                                --high range
             'Advisor type code for the new advisor assignment',   --help text
             NULL,
             NULL);

INSERT INTO gjbpdef (GJBPDEF_JOB,
                     GJBPDEF_NUMBER,
                     GJBPDEF_DESC,
                     GJBPDEF_LENGTH,
                     GJBPDEF_TYPE_IND,
                     GJBPDEF_OPTIONAL_IND,
                     GJBPDEF_SINGLE_IND,
                     GJBPDEF_ACTIVITY_DATE,
                     GJBPDEF_LOW_RANGE,
                     GJBPDEF_HIGH_RANGE,
                     GJBPDEF_HELP_TEXT,
                     GJBPDEF_VALIDATION,
                     GJBPDEF_LIST_VALUES)
        VALUES (
                  'ZSPSWAP',
                  '05',                                     --parameter number
                  'Primary Override',                  --parameter description
                  4,                                                  --length
                  'C',                      --Character, Integer, Date, Number
                  'O',                                     --Optional/Required
                  'S',                                       --Single/Multiple
                  SYSDATE,
                  NULL,                                            --low range
                  NULL,                                           --high range
                  'Do you want this advisor to ALWAYS be primary- Y (Yes) or N (No)?', --help text
                  NULL,
                  NULL);

--create default parameter values

INSERT INTO gjbpdft (GJBPDFT_JOB,
                     GJBPDFT_NUMBER,
                     GJBPDFT_ACTIVITY_DATE,
                     GJBPDFT_USER_ID,
                     GJBPDFT_VALUE,
                     GJBPDFT_JPRM_CODE)
     VALUES ('ZSPSWAP',
             '01',
             SYSDATE,
             NULL,
             '',
             NULL);

INSERT INTO gjbpdft (GJBPDFT_JOB,
                     GJBPDFT_NUMBER,
                     GJBPDFT_ACTIVITY_DATE,
                     GJBPDFT_USER_ID,
                     GJBPDFT_VALUE,
                     GJBPDFT_JPRM_CODE)
     VALUES ('ZSPSWAP',
             '02',
             SYSDATE,
             NULL,
             '',
             NULL);

INSERT INTO gjbpdft (GJBPDFT_JOB,
                     GJBPDFT_NUMBER,
                     GJBPDFT_ACTIVITY_DATE,
                     GJBPDFT_USER_ID,
                     GJBPDFT_VALUE,
                     GJBPDFT_JPRM_CODE)
     VALUES ('ZSPSWAP',
             '03',
             SYSDATE,
             NULL,
             '',
             NULL);

INSERT INTO gjbpdft (GJBPDFT_JOB,
                     GJBPDFT_NUMBER,
                     GJBPDFT_ACTIVITY_DATE,
                     GJBPDFT_USER_ID,
                     GJBPDFT_VALUE,
                     GJBPDFT_JPRM_CODE)
     VALUES ('ZSPSWAP',
             '04',
             SYSDATE,
             NULL,
             'MAJR',
             NULL);

INSERT INTO gjbpdft (GJBPDFT_JOB,
                     GJBPDFT_NUMBER,
                     GJBPDFT_ACTIVITY_DATE,
                     GJBPDFT_USER_ID,
                     GJBPDFT_VALUE,
                     GJBPDFT_JPRM_CODE)
     VALUES ('ZSPSWAP',
             '05',
             SYSDATE,
             NULL,
             'N',
             NULL);

--create security grants to specific users

INSERT INTO bansecr.guruobj (GURUOBJ_OBJECT,
                             GURUOBJ_ROLE,
                             GURUOBJ_USERID,
                             GURUOBJ_ACTIVITY_DATE,
                             GURUOBJ_USER_ID,
                             GURUOBJ_COMMENTS,
                             GURUOBJ_DATA_ORIGIN)
     VALUES ('ZSPSWAP',
             'BAN_DEFAULT_M',
             'BAN_STUDENT_C',
             SYSDATE,
             'Z_CARL_ELLSWORTH',
             NULL,
             NULL);


INSERT INTO bansecr.guruobj (GURUOBJ_OBJECT,
                             GURUOBJ_ROLE,
                             GURUOBJ_USERID,
                             GURUOBJ_ACTIVITY_DATE,
                             GURUOBJ_USER_ID,
                             GURUOBJ_COMMENTS,
                             GURUOBJ_DATA_ORIGIN)
     VALUES ('ZSPSWAP',
             'BAN_DEFAULT_M',
             'S_REG_ADMIN_M',
             SYSDATE,
             'Z_CARL_ELLSWORTH',
             NULL,
             NULL);