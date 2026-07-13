IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL.
       AUTHOR. MAINFRAME EXPERT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMP-IN-FILE ASSIGN TO EMPIN
               FILE STATUS IS WS-EMP-IN-FILE-STATUS.
           SELECT PAY-OUT-FILE ASSIGN TO PAYOUT
               FILE STATUS IS WS-PAY-OUT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  EMP-IN-FILE
           RECORD CONTAINS 100 CHARACTERS.
       01  EMP-REC-IN.
           05 EMP-ID-IN      PIC X(5).
           05 EMP-NAME-IN    PIC X(25).
           05 EMP-HOURS-IN   PIC 9(3).
           05 EMP-RATE-IN    PIC 9(3)V99.
           05 FILLER         PIC X(62).

       FD  PAY-OUT-FILE
           RECORD CONTAINS 120 CHARACTERS.
       01  PAY-REC-OUT       PIC X(120).

       WORKING-STORAGE SECTION.
       01  WS-FLAGS.
           05 WS-EOF-FLAG    PIC X VALUE 'N'.
              88 EOF               VALUE 'Y'.

       01  WS-EMP-IN-FILE-STATUS  PIC XX.
       01  WS-PAY-OUT-FILE-STATUS PIC XX.

       01  WS-CALCULATIONS.
           05 WS-GROSS-PAY   PIC 9(5)V99 VALUE ZERO.

       01  WS-GRP-VAR.
           05 WS-VAR-DATA    PIC X(4) VALUE 'KEYS'.
           05 WS-VAR-NUM REDEFINES WS-VAR-DATA PIC 9(7) COMP-3.
           05 WS-DUMMY-TOT   PIC 9(7) COMP-3 VALUE ZERO.

       01  WS-DETAIL-LINE.
           05 OUT-EMP-ID     PIC X(5).
           05 FILLER         PIC X(2) VALUE SPACES.
           05 OUT-EMP-NAME   PIC X(25).
           05 FILLER         PIC X(2) VALUE SPACES.
           05 OUT-GROSS-PAY  PIC $$,$$9.99.
           05 FILLER         PIC X(77) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
           PERFORM 1000-INITIALIZE.
           PERFORM 2000-PROCESS-RECORDS UNTIL EOF.
           PERFORM 3000-PROCESS-SUM.
           PERFORM 4000-TERMINATE.
           STOP RUN.

       1000-INITIALIZE.
           OPEN INPUT EMP-IN-FILE
           IF WS-EMP-IN-FILE-STATUS NOT = '00'
               DISPLAY 'EMP-IN-FILE OPEN FAILED - STATUS: '
                       WS-EMP-IN-FILE-STATUS
               STOP RUN
           END-IF
           OPEN OUTPUT PAY-OUT-FILE
           IF WS-PAY-OUT-FILE-STATUS NOT = '00'
               DISPLAY 'PAY-OUT-FILE OPEN FAILED - STATUS: '
                       WS-PAY-OUT-FILE-STATUS
               STOP RUN
           END-IF
           PERFORM 2100-READ-RECORD.

       2000-PROCESS-RECORDS.
           COMPUTE WS-GROSS-PAY = EMP-HOURS-IN * EMP-RATE-IN
               ON SIZE ERROR
                   MOVE ZERO TO WS-GROSS-PAY
           END-COMPUTE
           MOVE EMP-ID-IN TO OUT-EMP-ID
           MOVE EMP-NAME-IN TO OUT-EMP-NAME
           MOVE WS-GROSS-PAY TO OUT-GROSS-PAY
           WRITE PAY-REC-OUT FROM WS-DETAIL-LINE
           IF WS-PAY-OUT-FILE-STATUS NOT = '00'
               DISPLAY 'PAY-OUT-FILE WRITE FAILED - STATUS: '
                       WS-PAY-OUT-FILE-STATUS
               STOP RUN
           END-IF
           PERFORM 2100-READ-RECORD.

       2100-READ-RECORD.
           READ EMP-IN-FILE
               AT END MOVE 'Y' TO WS-EOF-FLAG
           END-READ.
           IF WS-EMP-IN-FILE-STATUS NOT = '00'
           AND WS-EMP-IN-FILE-STATUS NOT = '10'
               DISPLAY 'EMP-IN-FILE READ FAILED - STATUS: '
                       WS-EMP-IN-FILE-STATUS
               STOP RUN
           END-IF.

       3000-PROCESS-SUM.
           INITIALIZE WS-VAR-NUM.
           COMPUTE WS-DUMMY-TOT = WS-VAR-NUM + 100
               ON SIZE ERROR
                   MOVE ZERO TO WS-DUMMY-TOT
           END-COMPUTE.

       4000-TERMINATE.
           CLOSE EMP-IN-FILE
                 PAY-OUT-FILE.
           IF WS-EMP-IN-FILE-STATUS NOT = '00'
               DISPLAY 'EMP-IN-FILE CLOSE FAILED - STATUS: '
                       WS-EMP-IN-FILE-STATUS
           END-IF.
           IF WS-PAY-OUT-FILE-STATUS NOT = '00'
               DISPLAY 'PAY-OUT-FILE CLOSE FAILED - STATUS: '
                       WS-PAY-OUT-FILE-STATUS
           END-IF.