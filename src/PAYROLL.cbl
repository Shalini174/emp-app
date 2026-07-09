IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMPIN    ASSIGN TO EMPIN.
           SELECT PAYOUT   ASSIGN TO PAYOUT.
       DATA DIVISION.
       FILE SECTION.
       FD  EMPIN
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 100 CHARACTERS
           LABEL RECORDS ARE STANDARD.
       01  EMPIN-REC.
           05  EMP-ID          PIC X(10).
           05  EMP-NAME        PIC X(30).
           05  EMP-DEPT        PIC X(10).
           05  EMP-SALARY      PIC 9(08)V99.
           05  EMP-HOURS       PIC 9(05)V99.
           05  FILLER          PIC X(25).
       FD  PAYOUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 120 CHARACTERS
           LABEL RECORDS ARE STANDARD.
       01  PAYOUT-REC.
           05  OUT-EMP-ID      PIC X(10).
           05  OUT-EMP-NAME    PIC X(30).
           05  OUT-DEPT        PIC X(10).
           05  OUT-GROSS       PIC 9(10)V99.
           05  OUT-TAX         PIC 9(08)V99.
           05  OUT-NET         PIC 9(10)V99.
           05  FILLER          PIC X(36).
       WORKING-STORAGE SECTION.
       01  WS-COUNTERS.
           05  WS-READ-COUNT   PIC 9(05) VALUE ZEROS.
           05  WS-WRITE-COUNT  PIC 9(05) VALUE ZEROS.
       01  WS-FLAGS.
           05  WS-EOF-FLAG     PIC X(01) VALUE 'N'.
       01  WS-CALC.
           05  WS-GROSS        PIC 9(10)V99 VALUE ZEROS.
           05  WS-TAX          PIC 9(08)V99 VALUE ZEROS.
           05  WS-NET          PIC 9(10)V99 VALUE ZEROS.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL WS-EOF-FLAG = 'Y'
           PERFORM 3000-WRAPUP
           STOP RUN.
       1000-INIT.
           OPEN INPUT  EMPIN
           OPEN OUTPUT PAYOUT
           PERFORM 1100-READ-EMPIN.
       1100-READ-EMPIN.
           READ EMPIN INTO EMPIN-REC
               AT END MOVE 'Y' TO WS-EOF-FLAG
           END-READ.
       2000-PROCESS.
           ADD 1 TO WS-READ-COUNT
           COMPUTE WS-GROSS = EMP-SALARY * EMP-HOURS
           COMPUTE WS-TAX   = WS-GROSS * 0.20
           COMPUTE WS-NET   = WS-GROSS - WS-TAX
           MOVE EMP-ID      TO OUT-EMP-ID
           MOVE EMP-NAME    TO OUT-EMP-NAME
           MOVE EMP-DEPT    TO OUT-DEPT
           MOVE WS-GROSS    TO OUT-GROSS
           MOVE WS-TAX      TO OUT-TAX
           MOVE WS-NET      TO OUT-NET
           WRITE PAYOUT-REC
           ADD 1 TO WS-WRITE-COUNT
           PERFORM 1100-READ-EMPIN.
       3000-WRAPUP.
           CLOSE EMPIN
           CLOSE PAYOUT
           DISPLAY 'RECORDS READ:    ' WS-READ-COUNT
           DISPLAY 'RECORDS WRITTEN: ' WS-WRITE-COUNT.