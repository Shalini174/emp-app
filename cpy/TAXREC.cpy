```cobol
       01  EMP-RECORD.
           05  EMP-ID             PIC X(05).
           05  EMP-NAME           PIC X(25).
           05  EMP-DEPT           PIC X(03).
           05  EMP-SALARY         PIC S9(7)V99 COMP-3.
       01  TAX-RATES.
           05  FED-TAX-RATE       PIC V999 VALUE .055.
           05  LOC-TAX-RATE       PIC V999 VALUE .015.
           05  STATE-TAX-RATE     PIC V999 VALUE .010.
       01  WS-NET-PAY             PIC S9(7)V99 COMP-3.
```