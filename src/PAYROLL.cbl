IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMPIN  ASSIGN TO EMPIN.
           SELECT PAYOUT ASSIGN TO PAYOUT.
       DATA DIVISION.
       FILE SECTION.
       FD  EMPIN
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 100 CHARACTERS
           LABEL RECORDS ARE STANDARD.
       01  EMPIN-RECORD.
           05  EMP-ID             PIC X(10).
           05  EMP-NAME           PIC X(30).
           05  EMP-DEPT           PIC X(10).
           05  EMP-SALARY         PIC 9(10)V99.
           05  EMP-HOURS          PIC 9(05)V99.
           05  EMP-RATE           PIC 9(05)V99.
           05  EMP-FILLER         PIC X(24).
       FD  PAYOUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 120 CHARACTERS
           LABEL RECORDS ARE STANDARD.
       01  PAYOUT-RECORD.
           05  PAY-EMP-ID         PIC X(10).
           05  PAY-EMP-NAME       PIC X(30).
           05  PAY-DEPT           PIC X(10).
           05  PAY-GROSS          PIC 9(10)V99.
           05  PAY-TAX            PIC 9(08)V99.
           05  PAY-NET            PIC 9(10)V99.
           05  PAY-PERIOD         PIC X(10).
           05  PAY-DATE           PIC X(10).
           05  PAY-FILLER         PIC X(16).
       WORKING-STORAGE SECTION.
       01  WS-EOF-FLAG            PIC X(01) VALUE 'N'.
           88  WS-EOF             VALUE 'Y'.
       01  WS-GROSS-PAY           PIC 9(10)V99 VALUE ZEROS.
       01  WS-TAX-AMOUNT          PIC 9(08)V99 VALUE ZEROS.
       01  WS-NET-PAY             PIC 9(10)V99 VALUE ZEROS.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT  EMPIN
           OPEN OUTPUT PAYOUT
           PERFORM 1000-READ-EMPIN UNTIL WS-EOF
           CLOSE EMPIN
           CLOSE PAYOUT
           STOP RUN.
       1000-READ-EMPIN.
           READ EMPIN INTO EMPIN-RECORD
               AT END MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END PERFORM 2000-PROCESS-RECORD
           END-READ.
       2000-PROCESS-RECORD.
           COMPUTE WS-GROSS-PAY = EMP-HOURS * EMP-RATE
           COMPUTE WS-TAX-AMOUNT = WS-GROSS-PAY * 0.20
           COMPUTE WS-NET-PAY = WS-GROSS-PAY - WS-TAX-AMOUNT
           MOVE EMP-ID          TO PAY-EMP-ID
           MOVE EMP-NAME        TO PAY-EMP-NAME
           MOVE EMP-DEPT        TO PAY-DEPT
           MOVE WS-GROSS-PAY    TO PAY-GROSS
           MOVE WS-TAX-AMOUNT   TO PAY-TAX
           MOVE WS-NET-PAY      TO PAY-NET
           MOVE SPACES          TO PAY-PERIOD
           MOVE SPACES          TO PAY-DATE
           MOVE SPACES          TO PAY-FILLER
           WRITE PAYOUT-RECORD.