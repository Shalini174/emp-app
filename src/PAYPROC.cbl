       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PAYPROC.
       AUTHOR.        MAINFRAME-EXPERT.
      *----------------------------------------------------------------*
      * PROGRAM: PAYPROC                                               *
      * PURPOSE: PROCESS EMPLOYEE PAYROLL RECORDS, CALCULATE NET PAY,  *
      *          AND ACCUMULATE BATCH TOTALS USING PACKED DECIMAL.     *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMP-FILE ASSIGN TO "INPUT.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-EMP-STATUS.

           SELECT RPT-FILE ASSIGN TO "OUTPUT.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  EMP-FILE.
           COPY EMPCOPY.

       FD  RPT-FILE.
       01  RPT-RECORD                 PIC X(80).

       WORKING-STORAGE SECTION.
      *--- FILE STATUS & CONTROL SWITCHES ---
       01  WS-FILE-STATUSES.
           05  WS-EMP-STATUS          PIC X(02) VALUE '00'.
               88  EMP-SUCCESS        VALUE '00'.
               88  EMP-EOF            VALUE '10'.
           05  WS-RPT-STATUS          PIC XX.

      *--- WORK FIELDS FOR INTERMEDIATE CALCULATIONS (COMP-3) ---
       01  WS-CALCULATIONS.
           05  WS-GROSS-PAY           PIC S9(05)V99 COMP-3 VALUE ZERO.
           05  WS-TAX-AMOUNT          PIC S9(05)V99 COMP-3 VALUE ZERO.
           05  WS-NET-PAY             PIC S9(05)V99 COMP-3 VALUE ZERO.
           05  WS-HOURLY-RATE         PIC S9(03)V99 COMP-3 VALUE 45.50.
           05  WS-TAX-RATE            PIC S9(01)V99 COMP-3 VALUE 0.15.

      *--- INCLUDE SUMMARY TOTALS COPYBOOK ---
           COPY WSCOPY.

      *--- REPORT FORMATTING STRUCTURES ---
       01  DETAIL-LINE.
           05  DET-EMP-ID             PIC X(05).
           05  FILLER                 PIC X(02) VALUE SPACES.
           05  DET-EMP-NAME           PIC X(20).
           05  FILLER                 PIC X(02) VALUE SPACES.
           05  DET-GROSS-PAY          PIC $$$,$$9.99.
           05  FILLER                 PIC X(02) VALUE SPACES.
           05  DET-NET-PAY            PIC $$$,$$9.99.

       01  SUMMARY-HEADER.
           05  FILLER                 PIC X(40) 
               VALUE '========================================'.

       01  SUMMARY-LINE-1.
           05  FILLER                 PIC X(22) 
               VALUE 'TOTAL EMPLOYEES   : '.
           05  SUM-TOTAL-EMPS         PIC ZZZ,ZZ9.

       01  SUMMARY-LINE-2.
           05  FILLER                 PIC X(22) 
               VALUE 'TOTAL NET PAYOUT  : '.
           05  SUM-TOTAL-NET          PIC $$,$$$,$$9.99.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-FILE UNTIL EMP-EOF
           PERFORM 3000-PRINT-SUMMARY
           PERFORM 9000-TERMINATE
           GOBACK.

       1000-INITIALIZE.
           OPEN INPUT EMP-FILE
           IF WS-EMP-STATUS NOT = '00'
               DISPLAY 'EMP-FILE OPEN FAILED - STATUS: ' WS-EMP-STATUS
               STOP RUN
           END-IF
           OPEN OUTPUT RPT-FILE
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPT-FILE OPEN FAILED - STATUS: ' WS-RPT-STATUS
               STOP RUN
           END-IF
           PERFORM 1100-READ-EMP-FILE.

       1100-READ-EMP-FILE.
           READ EMP-FILE
               AT END
                   SET EMP-EOF TO TRUE
           END-READ
           IF WS-EMP-STATUS NOT = '00' AND WS-EMP-STATUS NOT = '10'
               DISPLAY 'EMP-FILE READ FAILED - STATUS: ' WS-EMP-STATUS
               STOP RUN
           END-IF.

       2000-PROCESS-FILE.
           IF STATUS-ACTIVE
               PERFORM 2100-CALCULATE-PAYROLL
               PERFORM 2200-FORMAT-AND-WRITE-DETAIL
               ADD 1 TO WS-TOTAL-EMPLOYEES
           END-IF
           PERFORM 1100-READ-EMP-FILE.

       2100-CALCULATE-PAYROLL.
           IF EMP-HOURS-WORKED IS NUMERIC
               COMPUTE WS-GROSS-PAY ROUNDED =
                   EMP-HOURS-WORKED * WS-HOURLY-RATE
                   ON SIZE ERROR
                       DISPLAY 'SIZE ERROR ON WS-GROSS-PAY COMPUTE'
                       MOVE ZERO TO WS-GROSS-PAY
               END-COMPUTE
           ELSE
               MOVE ZERO TO WS-GROSS-PAY
           END-IF

           COMPUTE WS-TAX-AMOUNT ROUNDED =
               WS-GROSS-PAY * WS-TAX-RATE
               ON SIZE ERROR
                   DISPLAY 'SIZE ERROR ON WS-TAX-AMOUNT COMPUTE'
                   MOVE ZERO TO WS-TAX-AMOUNT
           END-COMPUTE

           SUBTRACT WS-TAX-AMOUNT FROM WS-GROSS-PAY
               GIVING WS-NET-PAY
               ON SIZE ERROR
                   DISPLAY 'SIZE ERROR ON WS-NET-PAY SUBTRACT'
                   MOVE ZERO TO WS-NET-PAY
           END-SUBTRACT

           ADD WS-GROSS-PAY    TO WS-TOTAL-GROSS-PAY
               ON SIZE ERROR
                   DISPLAY 'SIZE ERROR ON WS-TOTAL-GROSS-PAY ADD'
           END-ADD
           ADD WS-TAX-AMOUNT   TO WS-TOTAL-TAX-DEDUCTED
               ON SIZE ERROR
                   DISPLAY 'SIZE ERROR ON WS-TOTAL-TAX-DEDUCTED ADD'
           END-ADD
           ADD WS-NET-PAY      TO WS-TOTAL-NET-PAY
               ON SIZE ERROR
                   DISPLAY 'SIZE ERROR ON WS-TOTAL-NET-PAY ADD'
           END-ADD.

       2200-FORMAT-AND-WRITE-DETAIL.
           MOVE SPACES          TO DETAIL-LINE
           MOVE EMP-ID          TO DET-EMP-ID
           MOVE EMP-NAME        TO DET-EMP-NAME
           MOVE WS-GROSS-PAY    TO DET-GROSS-PAY
           MOVE WS-NET-PAY      TO DET-NET-PAY
           WRITE RPT-RECORD FROM DETAIL-LINE
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPT-FILE WRITE FAILED - STATUS: ' WS-RPT-STATUS
               STOP RUN
           END-IF.

       3000-PRINT-SUMMARY.
           WRITE RPT-RECORD FROM SUMMARY-HEADER
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPT-FILE WRITE FAILED - STATUS: ' WS-RPT-STATUS
               STOP RUN
           END-IF
           MOVE WS-TOTAL-EMPLOYEES TO SUM-TOTAL-EMPS
           WRITE RPT-RECORD FROM SUMMARY-LINE-1
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPT-FILE WRITE FAILED - STATUS: ' WS-RPT-STATUS
               STOP RUN
           END-IF
           MOVE WS-TOTAL-NET-PAY   TO SUM-TOTAL-NET
           WRITE RPT-RECORD FROM SUMMARY-LINE-2
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPT-FILE WRITE FAILED - STATUS: ' WS-RPT-STATUS
               STOP RUN
           END-IF.

       9000-TERMINATE.
           CLOSE EMP-FILE
                 RPT-FILE
           IF WS-EMP-STATUS NOT = '00'
               DISPLAY 'EMP-FILE CLOSE FAILED - STATUS: ' WS-EMP-STATUS
           END-IF
           IF WS-RPT-STATUS NOT = '00'
               DISPLAY 'RPT-FILE CLOSE FAILED - STATUS: ' WS-RPT-STATUS
           END-IF.