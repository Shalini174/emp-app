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
       01  EMPIN-RECORD.
           05  EMP-ID              PIC X(10).
           05  EMP-NAME            PIC X(30).
           05  EMP-DEPT            PIC X(10).
           05  EMP-SALARY          PIC 9(10)V99.
           05  EMP-HOURS           PIC 9(05)V99.
           05  EMP-FILLER          PIC X(31).
       FD  PAYOUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 120 CHARACTERS
           LABEL RECORDS ARE STANDARD.
       01  PAYOUT-RECORD.
           05  PAY-EMP-ID          PIC X(10).
           05  PAY-EMP-NAME        PIC X(30).
           05  PAY-DEPT            PIC X(10).
           05  PAY-GROSS           PIC 9(10)V99.
           05  PAY-TAX             PIC 9(08)V99.
           05  PAY-NET             PIC 9(10)V99.
           05  PAY-DATE            PIC X(08).
           05  PAY-FILLER          PIC X(28).
       WORKING-STORAGE SECTION.
       01  WS-EOF-FLAG             PIC X(01) VALUE 'N'.
           88  WS-EOF              VALUE 'Y'.
       01  WS-GROSS-PAY            PIC 9(10)V99 VALUE ZEROS.
       01  WS-TAX-AMT             PIC 9(08)V99 VALUE ZEROS.
       01  WS-NET-PAY              PIC 9(10)V99 VALUE ZEROS.
       01  WS-TAX-RATE             PIC V99      VALUE .20.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL WS-EOF
           PERFORM 3000-TERM
           STOP RUN.
       1000-INIT.
           OPEN INPUT  EMPIN
           OPEN OUTPUT PAYOUT
           PERFORM 1100-READ-EMPIN.
       1100-READ-EMPIN.
           READ EMPIN
               AT END MOVE 'Y' TO WS-EOF-FLAG
           END-READ.
       2000-PROCESS.
           PERFORM 2100-CALC-PAY
           PERFORM 2200-WRITE-PAY
           PERFORM 1100-READ-EMPIN.
       2100-CALC-PAY.
           COMPUTE WS-GROSS-PAY =
               EMP-SALARY * EMP-HOURS
           COMPUTE WS-TAX-AMT =
               WS-GROSS-PAY * WS-TAX-RATE
           COMPUTE WS-NET-PAY =
               WS-GROSS-PAY - WS-TAX-AMT.
       2200-WRITE-PAY.
           MOVE EMP-ID         TO PAY-EMP-ID
           MOVE EMP-NAME       TO PAY-EMP-NAME
           MOVE EMP-DEPT       TO PAY-DEPT
           MOVE WS-GROSS-PAY   TO PAY-GROSS
           MOVE WS-TAX-AMT     TO PAY-TAX
           MOVE WS-NET-PAY     TO PAY-NET
           MOVE FUNCTION CURRENT-DATE (1:8) TO PAY-DATE
           MOVE SPACES         TO PAY-FILLER
           WRITE PAYOUT-RECORD.
       3000-TERM.
           CLOSE EMPIN
           CLOSE PAYOUT.