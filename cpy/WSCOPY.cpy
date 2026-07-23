*----------------------------------------------------------------*
      * COPYBOOK: WSCOPY                                               *
      * DESCRIPTION: BATCH SUMMARY ACCUMULATOR FIELDS                  *
      *----------------------------------------------------------------*
       01  WS-TOTALS.
           05  WS-TOTAL-EMPLOYEES      PIC S9(05)    COMP-3 VALUE +0.
           05  WS-TOTAL-GROSS-PAY      PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-TOTAL-TAX-DEDUCTED   PIC S9(07)V99 COMP-3 VALUE +0.
           05  WS-TOTAL-NET-PAY        PIC S9(07)V99 COMP-3 VALUE +0.