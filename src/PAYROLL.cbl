IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMPIN ASSIGN TO EMPIN
               ORGANIZATION IS SEQUENTIAL.
           SELECT PAYOUT ASSIGN TO PAYOUT
               ORGANIZATION IS SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  EMPIN
           RECORD CONTAINS 100 CHARACTERS.
       01  EMPIN-RECORD.
           05  EMP-ID              PIC X(10).
           05  EMP-NAME            PIC X(30).
           05  EMP-DEPT            PIC X(10).
           05  EMP-SALARY          PIC 9(9)V99.
           05  EMP-HIRE-DATE       PIC X(10).
           05  FILLER              PIC X(29).

       FD  PAYOUT
           RECORD CONTAINS 120 CHARACTERS.
       01  PAYOUT-RECORD.
           05  PAY-EMP-ID          PIC X(10).
           05  PAY-EMP-NAME        PIC X(30).
           05  PAY-GROSS           PIC 9(9)V99.
           05  PAY-DEDUCTIONS      PIC 9(7)V99.
           05  PAY-NET             PIC 9(9)V99.
           05  PAY-DATE            PIC X(10).
           05  FILLER              PIC X(43).

       WORKING-STORAGE SECTION.
       01  WS-EOF-FLAG             PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           OPEN INPUT EMPIN
                OUTPUT PAYOUT.

           PERFORM UNTIL WS-EOF