CLASS zag_cl_converter DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    " Types
    "-------------------------------------------------
    TYPES:
      BEGIN OF ts_conversions_errors,
        row_num     TYPE i,
        field       TYPE fieldname,
        field_descr TYPE string,
        value       TYPE string,
        error       TYPE string,
      END OF ts_conversions_errors.

    TYPES:
      tt_conversions_errors TYPE TABLE OF ts_conversions_errors WITH DEFAULT KEY.


    " Constants
    "-------------------------------------------------
    CONSTANTS:
      BEGIN OF tc_separator,
        horizontal_tab TYPE abap_char1 VALUE %_horizontal_tab ##NO_TEXT,
        semicolon      TYPE char1      VALUE ';'              ##NO_TEXT,
        cr_lf          TYPE abap_cr_lf VALUE %_cr_lf          ##NO_TEXT,
        slash          TYPE char1      VALUE '/'              ##NO_TEXT,
      END OF tc_separator.

    CONSTANTS:
      c_initial_data    TYPE datum VALUE '00000000' ##NO_TEXT,
      c_initial_time    TYPE time  VALUE 000000     ##NO_TEXT,
      c_max_data        TYPE datum VALUE '99991231' ##NO_TEXT,
      c_max_data_number TYPE int4 VALUE 2958465.


    " Methods
    "-------------------------------------------------
    METHODS:
      constructor,

      conv_data_to_ext
        IMPORTING
          !xv_data_int       TYPE string
          !xv_separator      TYPE abap_char1 DEFAULT tc_separator-slash
        RETURNING
          VALUE(yv_data_ext) TYPE string,

      conv_data_to_int
        IMPORTING
          !xv_data_ext       TYPE string
        RETURNING
          VALUE(yv_data_int) TYPE dats
        EXCEPTIONS
          format_error
          plausibility_error,

      conv_numb_to_ext
        IMPORTING
          !xv_numb_int       TYPE string
        RETURNING
          VALUE(yv_numb_ext) TYPE string,

      conv_numb_to_int
        IMPORTING
          !xv_numb_ext       TYPE string
        RETURNING
          VALUE(yv_numb_int) TYPE string
        EXCEPTIONS
          format_error
          plausibility_error,

      conv_time_to_ext
        IMPORTING
          !xv_time_int       TYPE string
        RETURNING
          VALUE(yv_time_ext) TYPE string,

      conv_time_to_int
        IMPORTING
          !xv_time_ext       TYPE string
        RETURNING
          VALUE(yv_time_int) TYPE uzeit
        EXCEPTIONS
          format_error
          plausibility_error,

      conv_tsap_to_ext
        IMPORTING
          !xt_tsap_int       TYPE table
          !xv_header         TYPE abap_bool DEFAULT abap_true
          !xv_separator      TYPE char1 DEFAULT tc_separator-semicolon
        RETURNING
          VALUE(yt_tsap_ext) TYPE string_table,

      conv_tsap_to_int
        IMPORTING
          !xt_tsap_ext           TYPE string_table
          !xv_header             TYPE abap_bool DEFAULT abap_true
          !xv_separator          TYPE abap_char1 DEFAULT tc_separator-semicolon
        CHANGING
          !yt_tsap_int           TYPE table
          !yt_conversions_errors TYPE tt_conversions_errors,

      conv_tstring_to_string
        IMPORTING
          !xt_string_table TYPE string_table
        RETURNING
          VALUE(yv_string) TYPE string,

      conv_string_to_tstring
        IMPORTING
          !xv_string             TYPE string
        RETURNING
          VALUE(yt_string_table) TYPE string_table,

      remove_special_char
        CHANGING
          !yv_text TYPE string.

    CLASS-METHODS:
      get_fieldcat_from_data
        IMPORTING
          !xs_sap_line    TYPE any OPTIONAL
          !xt_sap_table   TYPE table OPTIONAL
        EXPORTING
          !yo_structdescr TYPE REF TO cl_abap_structdescr
          !yt_fcat        TYPE lvc_t_fcat
        RAISING
          cx_ai_system_fault,

      get_header_from_data
        IMPORTING
          !xt_fcat             TYPE lvc_t_fcat
          !xv_separator        TYPE abap_char1 DEFAULT tc_separator-semicolon
        RETURNING
          VALUE(yv_str_header) TYPE string.


  PROTECTED SECTION.

    " Constants
    "-------------------------------------------------
    CONSTANTS:
      BEGIN OF tc_symbols,
        lect_upper   TYPE string VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'   ##NO_TEXT,
        lect_lower   TYPE string VALUE 'abcdefghijklmnopqrstuvwxyz'   ##NO_TEXT,
        digit        TYPE string VALUE '0123456789'                   ##NO_TEXT,
        symb         TYPE string VALUE '!"%/=?;,.:-_@&+*()[]{}<>€$£'  ##NO_TEXT,
        lect_acc     TYPE string VALUE 'èéàáòóùúÉÈÁÀÓÒÚÙ'             ##NO_TEXT,
        exp_notation TYPE string VALUE '0123456789.,+-E'              ##NO_TEXT,
      END OF tc_symbols,

      BEGIN OF tc_exception_msg,
        unable_read_file   TYPE string VALUE 'Unable read file'                   ##NO_TEXT,
        unable_def_struct  TYPE string VALUE 'Unable define Structure Descriptor' ##NO_TEXT,
        input_error        TYPE string VALUE 'Input error'                        ##NO_TEXT,
        internal_error     TYPE string VALUE 'Internal error occurred'            ##NO_TEXT,
        not_implemented    TYPE string VALUE 'Exit method not implemented'        ##NO_TEXT,
        not_supported_file TYPE string VALUE 'File not supported'                 ##NO_TEXT,
        file_empty         TYPE string VALUE 'File empty'                         ##NO_TEXT,
      END OF tc_exception_msg,

      BEGIN OF tc_conversion_msg,
        unmanaged_dtype TYPE string VALUE 'Unmanaged data type' ##NO_TEXT,
        format_number   TYPE string VALUE 'Wrong number format' ##NO_TEXT,
        format_data     TYPE string VALUE 'Wrong data format'   ##NO_TEXT,
        format_time     TYPE string VALUE 'Wrong time format'   ##NO_TEXT,
        implaus_number  TYPE string VALUE 'Implausible number'  ##NO_TEXT,
        implaus_data    TYPE string VALUE 'Implausible data'    ##NO_TEXT,
        implaus_time    TYPE string VALUE 'Implausible time'    ##NO_TEXT,
      END OF tc_conversion_msg.


    "Methods
    "-------------------------------------------------
    METHODS:
      pre_struct_to_ext
        IMPORTING
          xs_fcat            TYPE lvc_s_fcat
          xs_sap_data        TYPE any
          xv_value_pre_conv  TYPE any
        CHANGING
          yv_value_post_conv TYPE string,

      post_struct_to_ext
        IMPORTING
          xs_fcat            TYPE lvc_s_fcat
          xs_sap_data        TYPE any
          xv_value_pre_conv  TYPE any
        CHANGING
          yv_value_post_conv TYPE string,

      pre_struct_to_int
        IMPORTING
          xs_fcat           TYPE lvc_s_fcat
        CHANGING
          yv_value_pre_conv TYPE string,

      post_struct_to_int
        IMPORTING
          xs_fcat            TYPE lvc_s_fcat
          xv_value_pre_conv  TYPE string
        CHANGING
          yv_value_post_conv TYPE string.


  PRIVATE SECTION.
    CONSTANTS:
      c_mandt TYPE fieldname VALUE 'MANDT' ##NO_TEXT.


    " Data
    "-------------------------------------------------
    DATA:
      gr_typekind_charlike TYPE RANGE OF abap_typekind,
      gr_typekind_date     TYPE RANGE OF abap_typekind,
      gr_typekind_numbers  TYPE RANGE OF abap_typekind,
      gr_typekind_time     TYPE RANGE OF abap_typekind.


    " Methods
    "-------------------------------------------------
    METHODS:
      init_managed_ranges,

      conv_standard_exit_input
        IMPORTING
          !xv_conv_name TYPE string
        CHANGING
          !yv_tmp_data  TYPE string,

      conv_standard_exit_output
        IMPORTING
          !xv_conv_name TYPE string
        CHANGING
          !yv_tmp_data  TYPE string.

ENDCLASS.



CLASS zag_cl_converter IMPLEMENTATION.

  METHOD constructor.

    me->init_managed_ranges( ).

  ENDMETHOD.


  METHOD conv_data_to_ext.

*    Data conversion from SAP to External
*    From
*        -> 20241231
*    To
*        -> 31/12/2024

    DATA(lv_data_ext) = xv_data_int.

    lv_data_ext = COND #(
      WHEN lv_data_ext NE c_initial_data
        THEN |{ lv_data_ext+6(2) }{ xv_separator }{ lv_data_ext+4(2) }{ xv_separator }{ lv_data_ext(4) }|

      ELSE ''
    ).

    CONDENSE yv_data_ext NO-GAPS.
    yv_data_ext = lv_data_ext.

  ENDMETHOD.


  METHOD conv_data_to_int.

  *    Data conversion exit from External to SAP
  *    From
  *        -> 25/12/2024
  *        -> 2024/12/31
  *        -> 20241231
  *        -> 45710  (Excel serial date)
  *    To
  *        -> 20241231
  
      CONSTANTS: c_initial_system_data TYPE dats VALUE '18991231'.
  
      yv_data_int = c_initial_data.
  
      CHECK xv_data_ext IS NOT INITIAL.
  
      DATA(lv_data_int) = xv_data_ext.
      CONDENSE lv_data_int NO-GAPS.
  
  
      CASE strlen( lv_data_int ).
        WHEN 8.
          "Format like 20231225
  
          "Already in SAP Format
          "Nothing to do
  
        WHEN 10.
  
          "Data format managed
          "25-12-2023
          "2023-12-25
  
          IF lv_data_int+2(1) CA tc_symbols-digit.
            "Format like 2023-12-25
            lv_data_int = |{ lv_data_int(4) }{ lv_data_int+5(2) }{ lv_data_int+8(2) }|.
  
          ELSEIF lv_data_int+2(1) NA tc_symbols-digit.
            "Format like 25-12-2023
            lv_data_int = |{ lv_data_int+6(4) }{ lv_data_int+3(2) }{ lv_data_int(2) }|.
  
          ELSE.
            RAISE format_error.
  
          ENDIF.
  
        WHEN OTHERS.
  
          "Data format managed
          " 45658 -> 01/01/2025 ( Serial Excel )
          IF lv_data_int CO tc_symbols-digit.
            DATA: lv_tmp_dats TYPE sy-datum.
            
            IF lv_data_int EQ c_max_data_number.
              lv_tmp_dats = c_max_data.
            ELSE.
              "For Excel 01/01/1900 is a leap year but is a bug, so, -1 is required
              lv_tmp_dats = c_initial_system_data + ( lv_data_int - 1 ).
            ENDIF.
            lv_data_int = lv_tmp_dats.
  
          ELSE.
            RAISE format_error.
  
          ENDIF.
  
      ENDCASE.
  
  
      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date                      = CONV sy-datum( lv_data_int )
        EXCEPTIONS
          plausibility_check_failed = 1
          OTHERS                    = 2.
      IF sy-subrc <> 0.
        RAISE plausibility_error.
      ENDIF.
  
      CONDENSE lv_data_int NO-GAPS.
      yv_data_int = lv_data_int.
  
  ENDMETHOD.


  METHOD conv_numb_to_ext.

*    Number conversion exit from SAP to External
*    From
*        -> 1000.25
*        -> 1000.25-
*    To
*        -> 1000,25
*        -> -1000,25

    yv_numb_ext       = 0.
    DATA(lv_numb_ext) = xv_numb_int.


    REPLACE '.' IN lv_numb_ext WITH ','.

    FIND '-' IN lv_numb_ext.
    IF sy-subrc EQ 0.
      REPLACE '-' IN lv_numb_ext WITH ''.
      lv_numb_ext = |-{ lv_numb_ext }|.
    ENDIF.


    CONDENSE lv_numb_ext NO-GAPS.
    yv_numb_ext = lv_numb_ext.

  ENDMETHOD.


  METHOD conv_numb_to_int.

*    Number conversion exit from External to SAP
*    From
*        -> Dot / Comma separator for decimal
*        -> Dot / Comma separator for thousands
*        -> Exp notation
*    To
*        -> 1000.25
*        -> 1000.25-
*
*    WARNING
*    In case of a number like 100,257
*    It's not possible to define if comma is the separator of decimal values or thousnds
*    So, in this case, the number will be converted in SAP Format -> 100.257

    DATA: lv_count TYPE i,
          lv_sign.

    "---------------------------------------------------------------


    yv_numb_int       = 0.

    CHECK xv_numb_ext IS NOT INITIAL.

    DATA(lv_numb_int) = xv_numb_ext.

    CONDENSE lv_numb_int NO-GAPS.
    TRANSLATE lv_numb_int TO UPPER CASE.


    "Find special chars occurrences
    "-------------------------------------------------
    DATA(lv_counter_dot) = 0.
    FIND ALL OCCURRENCES OF '.' IN lv_numb_int MATCH COUNT lv_counter_dot.

    DATA(lv_counter_comma) = 0.
    FIND ALL OCCURRENCES OF ',' IN lv_numb_int MATCH COUNT lv_counter_comma.

    DATA(lv_counter_plus) = 0.
    FIND ALL OCCURRENCES OF '+' IN lv_numb_int MATCH COUNT lv_counter_plus.

    DATA(lv_counter_minus) = 0.
    FIND ALL OCCURRENCES OF '-' IN lv_numb_int MATCH COUNT lv_counter_minus.

    DATA(lv_counter_exp) = 0.
    FIND ALL OCCURRENCES OF 'E' IN lv_numb_int MATCH COUNT lv_counter_exp.


    "Plausibility Pre-Check
    "---------------------------------------------------------------
    IF lv_numb_int CN tc_symbols-exp_notation.
      RAISE plausibility_error.
    ENDIF.

    IF lv_counter_plus    GT 1
      OR lv_counter_minus GT 2 "Allowed double '-' in Exp notation
      OR lv_counter_exp   GT 1.
      RAISE plausibility_error.
    ENDIF.


    "Exponential notation management
    "-------------------------------------------------
    CASE lv_counter_exp.

      WHEN 0. "Normal Notation detected

        IF lv_counter_plus EQ 1.
          REPLACE '+' IN lv_numb_int WITH ''.
        ENDIF.

        IF lv_counter_minus EQ 1.
          REPLACE ALL OCCURRENCES OF '-' IN lv_numb_int WITH ''.
          lv_numb_int = |{ lv_numb_int }-|.
        ENDIF.

      WHEN 1. "Exponential Notation Detected

        "Mandatory '+' or '-' with exp notation
        IF lv_counter_plus     EQ 0
          AND lv_counter_minus EQ 0.
          RAISE format_error.
        ENDIF.


        "Mandatory 'E+' if positive
        IF lv_counter_plus EQ 1.

          IF lv_numb_int NS 'E+'.
            RAISE format_error.
          ENDIF.

        ENDIF.


        "Mandatory 'E-' if negative
        CASE lv_counter_minus.
          WHEN 1.
            IF lv_numb_int NS 'E-'.
              RAISE format_error.
            ENDIF.

          WHEN 2.
            IF lv_numb_int NS 'E-' OR lv_numb_int(1) NE '-'.
              RAISE format_error.
            ENDIF.

        ENDCASE.

    ENDCASE.


    "Convert Real number into SAP Number
    "-------------------------------------------------

    IF lv_counter_comma GT 0
      AND lv_counter_dot EQ 0.
      "100,257 / 1000,25 / 1,000,000,000

      IF lv_counter_comma EQ 1.
        "100,257 / 1000,25

        "WARNING
        "Unable to define if comma is the separator of decimal values or integer parts of number
        "So -> It will be use like decimal separator
        REPLACE ',' IN lv_numb_int WITH '.'.

      ELSE.
        "1,000,000,000
        REPLACE ALL OCCURRENCES OF ',' IN lv_numb_int WITH ''.

      ENDIF.


    ELSEIF lv_counter_comma EQ 0
      AND lv_counter_dot GT 0.
      "100.257 / 100.25 / 1.000.000.000

      IF lv_counter_dot EQ 1.
        "100.257 / 100.25

        "WARNING
        "Unable to define if comma is the separator of decimal values or integer parts of number
        "So -> It will be use like decimal separator
        "Nothing to do

      ELSE.
        "1.000.000.000
        REPLACE ALL OCCURRENCES OF '.' IN lv_numb_int WITH ''.

      ENDIF.

    ELSEIF lv_counter_comma GT 0
       AND lv_counter_dot   GT 0.

      IF lv_counter_comma EQ lv_counter_dot.
        "1,000.25 / 1.000,25

        DATA(lv_offset_comma) = 0.
        FIND FIRST OCCURRENCE OF ',' IN lv_numb_int MATCH OFFSET lv_offset_comma.

        DATA(lv_offset_dot) = 0.
        FIND FIRST OCCURRENCE OF '.' IN lv_numb_int MATCH OFFSET lv_offset_dot.

        IF lv_offset_comma LT lv_offset_dot.
          "1,000.25

          REPLACE ALL OCCURRENCES OF ',' IN lv_numb_int WITH ''.

          FIND ALL OCCURRENCES OF '.' IN lv_numb_int MATCH COUNT lv_count.
          IF lv_count GT 1.
            RAISE format_error.
          ENDIF.

        ELSEIF lv_offset_dot LT lv_offset_comma.
          "1.000,25

          REPLACE ALL OCCURRENCES OF '.' IN lv_numb_int WITH ''.

          FIND ALL OCCURRENCES OF ',' IN lv_numb_int MATCH COUNT lv_count.
          IF lv_count GT 1.
            RAISE format_error.
          ENDIF.

          REPLACE ',' IN lv_numb_int WITH '.'.

        ENDIF.

      ELSEIF lv_counter_comma GT lv_counter_dot.
        "1,000,000.25

        REPLACE ALL OCCURRENCES OF ',' IN lv_numb_int WITH ''.

        FIND ALL OCCURRENCES OF '.' IN lv_numb_int MATCH COUNT lv_count.
        IF lv_count GT 1.
          RAISE format_error.
        ENDIF.

      ELSEIF lv_counter_dot GT lv_counter_comma.
        "1.000.000,25

        REPLACE ALL OCCURRENCES OF '.' IN lv_numb_int WITH ''.

        FIND ALL OCCURRENCES OF ',' IN lv_numb_int MATCH COUNT lv_count.
        IF lv_count GT 1.
          RAISE format_error.
        ENDIF.

        REPLACE ',' IN lv_numb_int WITH '.'.

      ENDIF.

    ENDIF.

    "-------------------------------------------------

    CONDENSE lv_numb_int NO-GAPS.
    yv_numb_int = lv_numb_int.

  ENDMETHOD.


  METHOD conv_time_to_ext.

*    Time conversion exit from SAP to External
*    From
*        -> 235959
*    To
*        -> 23:59:59

    yv_time_ext       = ''.
    DATA(lv_time_int) = xv_time_int.

    lv_time_int = COND #(
      WHEN lv_time_int NE c_initial_time
        THEN |{ lv_time_int(2) }:{ lv_time_int+2(2) }:{ lv_time_int+4(2) }|

      ELSE ''
    ).

    CONDENSE lv_time_int NO-GAPS.
    yv_time_ext = lv_time_int.

  ENDMETHOD.


  METHOD conv_time_to_int.

*    Time conversion exit from External to SAP
*    From
*        -> 23:59:59
*        -> 235959
*    To
*        -> 235959

    yv_time_int = c_initial_time.

    CHECK xv_time_ext IS NOT INITIAL.

    DATA(lv_time_int) = xv_time_ext.
    CONDENSE lv_time_int NO-GAPS.

    CHECK lv_time_int IS NOT INITIAL.


    IF strlen( lv_time_int ) NE 8
      AND strlen( lv_time_int ) NE 6.
      RAISE format_error.
    ENDIF.

    lv_time_int = COND #(
        WHEN strlen( lv_time_int ) EQ 6 THEN lv_time_int
        WHEN strlen( lv_time_int ) EQ 8 THEN |{ lv_time_int(2) }{ lv_time_int+3(2) }{ lv_time_int+6(2) }|
   ).

    CALL FUNCTION 'TIME_CHECK_PLAUSIBILITY'
      EXPORTING
        time                      = CONV sy-uzeit( lv_time_int )
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      RAISE plausibility_error.
    ENDIF.

    CONDENSE lv_time_int NO-GAPS.
    yv_time_int = lv_time_int.

  ENDMETHOD.


  METHOD conv_tsap_to_ext.

    DATA:
      lref_tsap_int TYPE REF TO data,
      lv_cx_msg     TYPE string.

    FIELD-SYMBOLS:
      <lt_tsap_int> TYPE STANDARD TABLE.


    CLEAR: yt_tsap_ext[].


    "Create Local data
    "-------------------------------------------------
    CREATE DATA lref_tsap_int LIKE xt_tsap_int.
    ASSIGN lref_tsap_int->* TO <lt_tsap_int>.

    <lt_tsap_int> = xt_tsap_int[].


    "Get Fieldcat / Header for Dynamic Assignment
    "-------------------------------------------------
    TRY.
        me->get_fieldcat_from_data(
          EXPORTING
            xt_sap_table   = <lt_tsap_int>
          IMPORTING
            yo_structdescr = DATA(lo_structdescr)
            yt_fcat        = DATA(lt_fcat)
        ).

      CATCH cx_ai_system_fault INTO DATA(lx_ai_system_fault). " Application Integration: Technical Error
        lv_cx_msg = lx_ai_system_fault->get_text( ).
    ENDTRY.

    IF xv_header EQ abap_true.
      DATA(lv_str_header) = me->get_header_from_data(
          xt_fcat       = lt_fcat
          xv_separator  = xv_separator
      ).
      APPEND lv_str_header TO yt_tsap_ext.
    ENDIF.


    "String Building
    "-------------------------------------------------
    LOOP AT xt_tsap_int ASSIGNING FIELD-SYMBOL(<struct_int>).

      APPEND INITIAL LINE TO yt_tsap_ext ASSIGNING FIELD-SYMBOL(<struct_ext>).

      LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fcat>).
        CHECK <fcat>-fieldname NE c_mandt.

        ASSIGN lo_structdescr->components[ name = <fcat>-fieldname ] TO FIELD-SYMBOL(<component>).
        CHECK sy-subrc EQ 0.

        IF NOT ( <component>-type_kind IN me->gr_typekind_numbers[]
              OR <component>-type_kind IN me->gr_typekind_date[]
              OR <component>-type_kind IN me->gr_typekind_time[]
              OR <component>-type_kind IN me->gr_typekind_charlike[] ).

          <struct_ext> = COND #(
              WHEN <struct_ext> EQ '' THEN xv_separator
              WHEN <struct_ext> NE '' THEN |{ <struct_ext> }{ xv_separator }|
          ).

          CONTINUE.
        ENDIF.

        ASSIGN COMPONENT <component>-name OF STRUCTURE <struct_int> TO FIELD-SYMBOL(<value_int>).
        DATA(lv_value_ext) = CONV string( <value_int> ).


        "User exit
        "---------------------------------------------------------------
        me->pre_struct_to_ext(
          EXPORTING
            xs_fcat            = <fcat>
            xs_sap_data        = <struct_int>
            xv_value_pre_conv  = <value_int>
          CHANGING
            yv_value_post_conv = lv_value_ext
        ).


        "Numbers
        "---------------------------------------------------------------
        IF <component>-type_kind IN gr_typekind_numbers[].
          IF <fcat>-edit_mask CS 'TSTLC'.
            "If the fields is a timestamp ( detected like numbers ),
            "it mustn't be converted to ext format like normal numbers
            "it must be converted from conv_exit_output routine

          ELSE.

            IF <fcat>-edit_mask CS 'EXCRT'
              OR <fcat>-edit_mask CS 'EXCRX'.

              IF lv_value_ext CS '123456789'.

                CALL FUNCTION 'CONVERSION_EXIT_EXCRT_OUTPUT'
                  EXPORTING
                    input  = lv_value_ext
                  IMPORTING
                    output = lv_value_ext.

              ENDIF.

            ENDIF.

            lv_value_ext = conv_numb_to_ext( lv_value_ext ).

          ENDIF.
        ENDIF.


        "Date
        "---------------------------------------------------------------
        IF <component>-type_kind IN gr_typekind_date[].

          lv_value_ext = conv_data_to_ext( xv_data_int  = lv_value_ext
                                           xv_separator = tc_separator-slash ).

        ENDIF.


        "Time
        "---------------------------------------------------------------
        IF <component>-type_kind IN gr_typekind_time[].

          lv_value_ext = conv_time_to_ext( lv_value_ext ).

        ENDIF.


        "Charlike
        "---------------------------------------------------------------
        IF <component>-type_kind IN gr_typekind_charlike[].

          "Normal Text -> Nothing To Do

        ENDIF.


        "Conversion exit
        "---------------------------------------------------------------
        IF <fcat>-edit_mask IS NOT INITIAL.

          DATA(lv_conv_name)    = <fcat>-edit_mask+2.

          conv_standard_exit_output(
            EXPORTING
              xv_conv_name = CONV #( lv_conv_name )
            CHANGING
              yv_tmp_data  = lv_value_ext
          ).

        ENDIF.


        "User exit
        "---------------------------------------------------------------
        me->post_struct_to_ext(
          EXPORTING
            xs_fcat            = <fcat>
            xs_sap_data        = <struct_int>
            xv_value_pre_conv  = <value_int>
          CHANGING
            yv_value_post_conv = lv_value_ext
        ).


        <struct_ext> = COND #(
          WHEN <struct_ext> EQ '' THEN lv_value_ext
          WHEN <struct_ext> NE '' THEN |{ <struct_ext> }{ xv_separator }{ lv_value_ext }|
        ).


      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD conv_tsap_to_int.

    DATA:
      lref_struct_int      TYPE REF TO data,
      ls_conversion_errors TYPE ts_conversions_errors,
      lv_cx_msg            TYPE string.

    FIELD-SYMBOLS:
      <struct_int>  TYPE any.

    "-------------------------------------------------

    CLEAR: yt_tsap_int[], yt_conversions_errors[].


    "Create Local data
    "-------------------------------------------------
    CREATE DATA lref_struct_int LIKE LINE OF yt_tsap_int.
    ASSIGN lref_struct_int->* TO <struct_int>.


    "Get Fieldcat for dynamic assignment
    "-------------------------------------------------
    TRY.
        me->get_fieldcat_from_data(
          EXPORTING
            xs_sap_line    = <struct_int>
          IMPORTING
            yo_structdescr = DATA(lo_structdescr)
            yt_fcat        = DATA(lt_fcat)
        ).


        "Build SAP Table
        "-------------------------------------------------
        LOOP AT xt_tsap_ext ASSIGNING FIELD-SYMBOL(<struct_ext>).
          DATA(lv_row_num) = sy-tabix.

          IF xv_header EQ abap_true
            AND lv_row_num EQ 1.
            CONTINUE.
          ENDIF.

          DATA(lv_struct_ext) = <struct_ext>.

          CLEAR <struct_int>.

          LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fcat>).
            CHECK <fcat>-fieldname NE c_mandt.

            CLEAR ls_conversion_errors.
            ls_conversion_errors-row_num = lv_row_num.

            ASSIGN lo_structdescr->components[ name = <fcat>-fieldname ] TO FIELD-SYMBOL(<component>).

            ASSIGN COMPONENT <component>-name OF STRUCTURE <struct_int> TO FIELD-SYMBOL(<value_int>).
            ls_conversion_errors-field       = <fcat>-fieldname.
            ls_conversion_errors-field_descr = <fcat>-reptext.

            IF <component>-type_kind NOT IN me->gr_typekind_numbers[]
              AND <component>-type_kind NOT IN me->gr_typekind_date[]
              AND <component>-type_kind NOT IN me->gr_typekind_time[]
              AND <component>-type_kind NOT IN me->gr_typekind_charlike[].

              APPEND VALUE #( BASE ls_conversion_errors
                  error = tc_conversion_msg-unmanaged_dtype
                ) TO yt_conversions_errors.
              CONTINUE.

            ENDIF.


            SPLIT lv_struct_ext AT xv_separator
              INTO DATA(lv_current_value)
                   lv_struct_ext.

            DATA(lv_preconv_value) = lv_current_value.


            "User Exit
            "---------------------------------------------------------------
            me->pre_struct_to_int(
              EXPORTING
                xs_fcat           = <fcat>
              CHANGING
                yv_value_pre_conv = lv_current_value
            ).


            "Deletion special chars
            "-------------------------------------------------
            IF 1 = 2.
              remove_special_char(
                CHANGING
                  yv_text = lv_current_value
              ).
            ENDIF.


            "Conversion Exit
            "---------------------------------------------------------------
            IF <fcat>-edit_mask IS NOT INITIAL.

              DATA(lv_conv_name) = <fcat>-edit_mask+2.

              conv_standard_exit_input(
                EXPORTING
                  xv_conv_name = CONV #( lv_conv_name )
                CHANGING
                  yv_tmp_data  = lv_current_value
              ).

            ENDIF.


            "Numbers
            "---------------------------------------------------------------
            IF <component>-type_kind IN gr_typekind_numbers[].

              conv_numb_to_int(
                EXPORTING
                  xv_numb_ext         = lv_current_value
                RECEIVING
                  yv_numb_int         = DATA(lv_tmp_num)
                EXCEPTIONS
                  format_error       = 1
                  plausibility_error = 2
                  OTHERS             = 3
              ).
              CASE sy-subrc.
                WHEN 0.
                  lv_current_value = lv_tmp_num.

                WHEN 1.
                  APPEND VALUE #( BASE ls_conversion_errors
                      error = tc_conversion_msg-format_number
                      value = lv_current_value
                    ) TO yt_conversions_errors.
                  EXIT.

                WHEN 2.
                  APPEND VALUE #( BASE ls_conversion_errors
                      error = tc_conversion_msg-implaus_number
                      value = lv_current_value
                    ) TO yt_conversions_errors.
                  EXIT.

              ENDCASE.


              IF <fcat>-edit_mask CS 'EXCRT'
               OR <fcat>-edit_mask CS 'EXCRX'.

                IF lv_tmp_num NE 0.

                  CALL FUNCTION 'CONVERSION_EXIT_EXCRT_INPUT'
                    EXPORTING
                      input  = lv_tmp_num
                    IMPORTING
                      output = lv_tmp_num.

                ENDIF.

              ENDIF.

            ENDIF.


            "Date
            "---------------------------------------------------------------
            IF <component>-type_kind IN gr_typekind_date[].

              conv_data_to_int(
                EXPORTING
                  xv_data_ext         = lv_current_value
                RECEIVING
                  yv_data_int         = DATA(lv_tmp_dats)
                EXCEPTIONS
                  format_error       = 1
                  plausibility_error = 2
                  OTHERS             = 3
              ).
              CASE sy-subrc.
                WHEN 0.
                  lv_current_value = lv_tmp_dats.

                WHEN 1.
                  APPEND VALUE #( BASE ls_conversion_errors
                      error = tc_conversion_msg-format_data
                      value = lv_current_value
                    ) TO yt_conversions_errors.
                  EXIT.

                WHEN 2.
                  APPEND VALUE #( BASE ls_conversion_errors
                      error = tc_conversion_msg-implaus_data
                      value = lv_current_value
                    ) TO yt_conversions_errors.
                  EXIT.

              ENDCASE.

            ENDIF.


            "Time
            "---------------------------------------------------------------
            IF <component>-type_kind IN gr_typekind_time[].

              conv_time_to_int(
                EXPORTING
                  xv_time_ext         = lv_current_value
                RECEIVING
                  yv_time_int         = DATA(lv_tmp_time)
                EXCEPTIONS
                  format_error       = 1
                  plausibility_error = 2
                  OTHERS             = 3
              ).
              CASE sy-subrc.
                WHEN 0.
                  lv_current_value = lv_tmp_time.

                WHEN 1.
                  APPEND VALUE #( BASE ls_conversion_errors
                      error = tc_conversion_msg-format_time
                      value = lv_current_value
                    ) TO yt_conversions_errors.
                  EXIT.

                WHEN 2.
                  APPEND VALUE #( BASE ls_conversion_errors
                      error = tc_conversion_msg-implaus_time
                      value = lv_current_value
                    ) TO yt_conversions_errors.
                  EXIT.

              ENDCASE.
            ENDIF.


            "Charlike
            "---------------------------------------------------------------
            IF <component>-type_kind IN gr_typekind_charlike[].

              "Normal Data -> Nothing To Do

            ENDIF.


            "User Exit
            "---------------------------------------------------------------
            me->post_struct_to_int(
              EXPORTING
                xs_fcat            = <fcat>
                xv_value_pre_conv  = lv_preconv_value
              CHANGING
                yv_value_post_conv = lv_current_value
            ).


            <value_int>   = lv_current_value.

          ENDLOOP.

          APPEND <struct_int> TO yt_tsap_int.

        ENDLOOP.


      CATCH cx_ai_system_fault INTO DATA(lx_ai_system_fault). " Application Integration: Technical Error
        lv_cx_msg = lx_ai_system_fault->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD conv_tstring_to_string.

    yv_string = REDUCE #(
      INIT lv_str TYPE string

      FOR <str> IN xt_string_table
        NEXT lv_str = COND #( WHEN lv_str EQ '' THEN <str>
                              WHEN lv_str NE '' THEN |{ lv_str }{ tc_separator-horizontal_tab }{ <str> }| )
    ).

  ENDMETHOD.


  METHOD conv_string_to_tstring.

    DATA:
      lv_current TYPE string,
      lv_next    TYPE string.


    CLEAR yt_string_table[].

    lv_next = xv_string.
    WHILE lv_next IS NOT INITIAL.

      SPLIT lv_next AT tc_separator-horizontal_tab
        INTO lv_current
             lv_next.

      APPEND lv_current TO yt_string_table.

    ENDWHILE.

  ENDMETHOD.


  METHOD remove_special_char.

    DATA:
      lv_text    TYPE string,
      lv_new_str TYPE string VALUE IS INITIAL.

    "Old version - Check Char by Char
    DATA(lv_length) = strlen( yv_text ).
    lv_text = yv_text.

    DO lv_length TIMES.
      DATA(lv_index)     = sy-index - 1.
      DATA(lv_curr_char) = lv_text+lv_index(1).

      CHECK lv_curr_char CA tc_symbols-lect_upper
         OR lv_curr_char CA tc_symbols-lect_lower
         OR lv_curr_char CA tc_symbols-digit
         OR lv_curr_char CA tc_symbols-symb
         OR lv_curr_char CA tc_symbols-lect_acc
         OR lv_curr_char EQ space.

      IF lv_new_str IS INITIAL.
        lv_new_str = lv_curr_char.
      ELSE.
        lv_new_str = |{ lv_new_str }{ lv_curr_char }|.
      ENDIF.

    ENDDO.

    yv_text = lv_new_str.


    "New Version - Check with regex - TODO Work in Progress Regex

*    CONSTANTS: c_regex_lect_upper TYPE string VALUE 'A-Z',
*               c_regex_lect_lower TYPE string VALUE 'a-z',
*               c_regex_digit      TYPE string VALUE '0-9',
*               c_regex_symb       TYPE string VALUE '!"%/=?;,.:-_@&+*()[]{}<>€$£',
*               c_regex_lect_acc   TYPE string VALUE 'èéàáòóùúÉÈÁÀÓÒÚÙ'.
*
*    lv_new_str = y_text.
*
*    lv_regex = ''.
*    lv_regex = |{ lv_regex }[{ c_regex_lect_upper }][{ c_regex_lect_lower }]|.
*    lv_regex = |{ lv_regex }[{ c_regex_digit }]|.
*    lv_regex = |{ lv_regex }[{ c_regex_symb }][{ c_regex_lect_acc }]|.
*
*    lv_regex = |[^{ lv_regex }]|.
*
*    REPLACE ALL OCCURRENCES OF REGEX lv_regex IN lv_new_str WITH ''.

  ENDMETHOD.


  METHOD get_fieldcat_from_data.

    DATA:
      lref_sap_struct TYPE REF TO data,
      lref_sap_table  TYPE REF TO data,

      lv_except_msg   TYPE string.

    FIELD-SYMBOLS:
      <sap_struct> TYPE any,
      <sap_table>  TYPE STANDARD TABLE.

    "-------------------------------------------------

    FREE yo_structdescr.
    CLEAR yt_fcat[].

    IF xs_sap_line IS SUPPLIED.
      CREATE DATA lref_sap_struct LIKE xs_sap_line.
      ASSIGN lref_sap_struct->* TO <sap_struct>.

      CREATE DATA lref_sap_table LIKE TABLE OF xs_sap_line.
      ASSIGN lref_sap_table->* TO <sap_table>.

    ELSEIF xt_sap_table IS SUPPLIED.
      CREATE DATA lref_sap_struct LIKE LINE OF xt_sap_table.
      ASSIGN lref_sap_struct->* TO <sap_struct>.

      CREATE DATA lref_sap_table LIKE xt_sap_table.
      ASSIGN lref_sap_table->* TO <sap_table>.

    ELSE.
      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-input_error.

    ENDIF.

    "-------------------------------------------------

    yo_structdescr ?= cl_abap_typedescr=>describe_by_data( <sap_struct> ).


    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = DATA(lt_salv_table)
          CHANGING
            t_table      = <sap_table>
        ).

        yt_fcat = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
          r_columns      = lt_salv_table->get_columns( ) " ALV Filter
          r_aggregations = lt_salv_table->get_aggregations( ) " ALV Aggregations
        ).

      CATCH cx_ai_system_fault INTO DATA(lx_ai_system_fault).
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING
            errortext = tc_exception_msg-unable_def_struct.

      CATCH cx_salv_msg  INTO DATA(lx_salv_msg).
        lv_except_msg = lx_salv_msg->get_text( ).
        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING
            errortext = tc_exception_msg-unable_def_struct.

    ENDTRY.

  ENDMETHOD.


  METHOD get_header_from_data.

    yv_str_header = ''.

    LOOP AT xt_fcat ASSIGNING FIELD-SYMBOL(<fcat>).
      CHECK <fcat>-fieldname NE c_mandt.

      yv_str_header = COND #(
        WHEN yv_str_header EQ '' THEN <fcat>-reptext
        WHEN yv_str_header NE '' THEN |{ yv_str_header }{ xv_separator }{ <fcat>-reptext }|
      ).

    ENDLOOP.

  ENDMETHOD.


  METHOD pre_struct_to_ext.

    "Redefine this method for custom logic

  ENDMETHOD.


  METHOD post_struct_to_ext.

    "Redefine this method for custom logic

  ENDMETHOD.


  METHOD pre_struct_to_int.

    "Redefine this method for custom logic

  ENDMETHOD.


  METHOD post_struct_to_int.

    "Redefine this method for custom logic

  ENDMETHOD.


  METHOD init_managed_ranges.

    "Init range for managed abap typekind
    "---------------------------------------------------------------
    CLEAR:
      gr_typekind_numbers[] ,
      gr_typekind_date[]    ,
      gr_typekind_time[]    ,
      gr_typekind_charlike[].


    gr_typekind_numbers = VALUE #(
      sign = 'I' option = 'EQ'
      ( low = cl_abap_typedescr=>typekind_float )
      ( low = cl_abap_typedescr=>typekind_decfloat )
      ( low = cl_abap_typedescr=>typekind_decfloat16 )
      ( low = cl_abap_typedescr=>typekind_decfloat34 )
      ( low = cl_abap_typedescr=>typekind_int )
      ( low = cl_abap_typedescr=>typekind_int1 )
      ( low = cl_abap_typedescr=>typekind_int2 )
      ( low = cl_abap_typedescr=>typekind_int8 )
      ( low = cl_abap_typedescr=>typekind_intf )
      ( low = cl_abap_typedescr=>typekind_num )
      ( low = cl_abap_typedescr=>typekind_numeric )
      ( low = cl_abap_typedescr=>typekind_packed )
    ).

    gr_typekind_date = VALUE #(
      sign = 'I' option = 'EQ'
      ( low = cl_abap_typedescr=>typekind_date )
    ).

    gr_typekind_time = VALUE #(
      sign = 'I' option = 'EQ'
      ( low = cl_abap_typedescr=>typekind_time )
    ).

    gr_typekind_charlike = VALUE #(
      sign = 'I' option = 'EQ'
      ( low = cl_abap_typedescr=>typekind_char )
      ( low = cl_abap_typedescr=>typekind_clike )
      ( low = cl_abap_typedescr=>typekind_csequence )
      ( low = cl_abap_typedescr=>typekind_string )
    ).

  ENDMETHOD.


  METHOD conv_standard_exit_input.

    DATA(lv_fm_conv_exit) = |CONVERSION_EXIT_{ xv_conv_name }_INPUT|.

    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = CONV rs38l-name( lv_fm_conv_exit )
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.

      CASE xv_conv_name.

        WHEN 'EXCRT'
          OR 'EXCRX'.

          " Rate numbers mustn't be converted from standard flow
          " If needed, it will be use the user-exit

        WHEN OTHERS.

          CALL FUNCTION lv_fm_conv_exit
            EXPORTING
              input  = yv_tmp_data
            IMPORTING
              output = yv_tmp_data
            EXCEPTIONS
              OTHERS = 1.

      ENDCASE.

    ENDIF.

  ENDMETHOD.


  METHOD conv_standard_exit_output.

    DATA(lv_fm_conv_exit) = |CONVERSION_EXIT_{ xv_conv_name }_OUTPUT|.

    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = CONV rs38l-name( lv_fm_conv_exit )
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.

      CASE xv_conv_name.
        WHEN 'EXCRT'
          OR 'EXCRX'.

        WHEN OTHERS.

          CALL FUNCTION lv_fm_conv_exit
            EXPORTING
              input  = yv_tmp_data
            IMPORTING
              output = yv_tmp_data
            EXCEPTIONS
              OTHERS = 1.

      ENDCASE.

    ENDIF.


  ENDMETHOD.

ENDCLASS.