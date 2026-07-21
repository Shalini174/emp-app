      *----------------------------------------------------------------*
      * COPYBOOK: EMPCOPY                                              *
      * DESCRIPTION: EMPLOYEE INPUT RECORD LAYOUT                      *
      *----------------------------------------------------------------*
       01  EMP-RECORD.
           05  EMP-ID                  PIC X(05).
           05  EMP-NAME                PIC X(20).
           05  EMP-HOURS-WORKED        PIC S9(03)V99 COMP-3.
           05  EMP-HOURLY-RATE         PIC S9(03)V99 COMP-3.
           05  EMP-TAX-RATE            PIC S9(01)V99 COMP-3.
           05  EMP-STATUS              PIC X(01).
               88  STATUS-ACTIVE       VALUE 'A'.
               88  STATUS-INACTIVE     VALUE 'I'.
           05  FILLER                  PIC X(10).