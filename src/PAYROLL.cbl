I need to generate a valid COBOL program that matches the DD names (EMPIN, PAYOUT) to FD entries with correct LRECLs, since the provided input is not valid COBOL source code.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL.
       AUTHOR. COBOL-DEVOPS-AGENT.
      *****************************************************************
      * PROGRAM: PAYROLL                                               *
      * DESC:    READS EMPLOYEE INPUT AND WRITES PAYROLL OUTPUT        *
      *****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
       OBJECT-COMPUTER. IBM-MAINFRAME.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMPIN
               ASSIGN TO EMPIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-EMPIN-STATUS.
           SELECT PAYOUT
               ASSIGN TO PAYOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-PAYOUT-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  EMPIN
           RECORDING MODE IS F
           RECORD CONTAINS 100 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           LABEL RECORDS ARE STANDARD.
       01  EMPIN-RECORD.
           05  EMP-ID                  PIC X(10).
           05  EMP-FIRST-NAME          PIC X(15).
           05  EMP-LAST-NAME           PIC X(20).
           05  EMP-DEPARTMENT          PIC X(10).
           05  EMP-JOB-TITLE           PIC X(20).
           05  EMP-SALARY              PIC 9(09)V99.
           05  EMP-HOURS-WORKED        PIC 9(03)V99.
           05  FILLER                  PIC X(09).
       FD  PAYOUT
           RECORDING MODE IS F
           RECORD CONTAINS 120 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           LABEL RECORDS ARE STANDARD.
       01  PAYOUT-RECORD.
           05  OUT-EMP-ID              PIC X(10).
           05  OUT-EMP-FIRST-NAME      PIC X(15).
           05  OUT-EMP-LAST-NAME       PIC X(20).
           05  OUT-DEPARTMENT          PIC X(10).
           05  OUT-JOB-TITLE           PIC X(20).
           05  OUT-GROSS-PAY           PIC 9(09)V99.
           05  OUT-TAX-AMOUNT          PIC 9(07)V99.
           05  OUT-NET-PAY             PIC 9(09)V99.
           05  OUT-PAY-DATE            PIC X(08).
           05  FILLER                  PIC X(07).
       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUSES.
           05  WS-EMPIN-STATUS         PIC XX.
           05  WS-PAYOUT-STATUS        PIC XX.
       01  WS-FLAGS.
           05  WS-EOF-EMPIN            PIC X(01) VALUE 'N'.
               88  EOF-EMPIN           VALUE 'Y'.
       01  WS-COUNTERS.
           05  WS-RECORDS-READ         PIC 9(07) VALUE ZEROS.
           05  WS-RECORDS-WRITTEN      PIC 9(07) VALUE ZEROS.
       01  WS-CALCULATIONS.
           05  WS-GROSS-PAY            PIC 9(09)V99 VALUE ZEROS.
           05  WS-TAX-RATE             PIC V99 VALUE .20.
           05  WS-TAX-AMOUNT           PIC 9(07)V99 VALUE ZEROS.
           05  WS-NET-PAY              PIC 9(09)V99 VALUE ZEROS.
       01  WS-CURRENT-DATE.
           05  WS-CURR-YEAR            PIC 9(04).
           05  WS-CURR-MONTH           PIC 9(02).
           05  WS-CURR-DAY             PIC 9(02).
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL EOF-EMPIN
           PERFORM 3000-TERMINATE
           STOP RUN.
       1000-INIT.
           OPEN INPUT  EMPIN
           OPEN OUTPUT PAYOUT
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURRENT-DATE
           PERFORM 1100-READ-EMPIN.
       1100-READ-EMPIN.
           READ EMPIN INTO EMPIN-RECORD
               AT END MOVE 'Y' TO WS-EOF-EMPIN
           END-READ.
       2000-PROCESS.
           ADD 1 TO WS-RECORDS-READ
           PERFORM 2100-CALC-PAY
           PERFORM 2200-WRITE-PAYOUT
           PERFORM 1100-READ-EMPIN.
       2100-CALC-PAY.
           MULTIPLY EMP-SALARY BY EMP-HOURS-WORKED
               GIVING WS-GROSS-PAY
           MULTIPLY WS-GROSS-PAY BY WS-TAX-RATE
               GIVING WS-TAX-AMOUNT
           SUBTRACT WS-TAX-AMOUNT FROM WS-GROSS-PAY
               GIVING WS-NET-PAY.
       2200-WRITE-PAYOUT.
           MOVE SPACES              TO PAYOUT-RECORD
           MOVE EMP-ID              TO OUT-EMP-ID
           MOVE EMP-FIRST-NAME      TO OUT-EMP-FIRST-NAME
           MOVE EMP-LAST-NAME       TO OUT-EMP-LAST-NAME
           MOVE EMP-DEPARTMENT      TO OUT-DEPARTMENT
           MOVE EMP-JOB-TITLE       TO OUT-JOB-TITLE
           MOVE WS-GROSS-PAY        TO OUT-GROSS-PAY
           MOVE WS-TAX-AMOUNT       TO OUT-TAX-AMOUNT
           MOVE WS-NET-PAY          TO OUT-NET-PAY
           MOVE WS-CURRENT-DATE     TO OUT-PAY-DATE
           WRITE PAYOUT-RECORD
           ADD 1 TO WS-RECORDS-WRITTEN.
       3000-TERMINATE.
           CLOSE EMPIN
           CLOSE PAYOUT.