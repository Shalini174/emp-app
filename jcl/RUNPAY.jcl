//PAYRUN   JOB (12345),'PAYROLL RUN',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*===================================================================
//* JCL TO EXECUTE PAYROLL COBOL PROGRAM
//*===================================================================
//STEP01   EXEC PGM=PAYROLL
//STEPLIB  DD DSN=USER.PROCLIB.LOAD,DISP=SHR
//*
//* INTENTIONAL LENGTH MISMATCH:
//* COBOL expects 80 characters for EMPIN, but JCL defines LRECL=100.
//* This mismatch usually causes an S013 abend or File Status 39.
//*
//EMPIN    DD DSN=USER.INPUT.PAYROLL,DISP=SHR,
//            DCB=(RECFM=FB,LRECL=100,BLKSIZE=1000)
//*
//PAYOUT   DD DSN=USER.OUTPUT.PAYROLL,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(5,1),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=1200)
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
