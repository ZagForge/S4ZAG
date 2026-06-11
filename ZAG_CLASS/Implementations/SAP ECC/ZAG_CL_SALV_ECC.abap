CLASS zag_cl_salv DEFINITION.

  PUBLIC SECTION.

    " Types
    "---------------------------------------------------------------
    TYPES:
      BEGIN OF ts_col_settings,
        fieldname TYPE lvc_s_fcat-fieldname,
        label     TYPE string,
        no_out    TYPE flag,
        hotspot   TYPE flag,
      END OF ts_col_settings .

    TYPES:
      tt_col_settings TYPE TABLE OF ts_col_settings WITH DEFAULT KEY,
      tt_fieldname    TYPE TABLE OF lvc_s_fcat-fieldname WITH DEFAULT KEY.

    " Data
    "---------------------------------------------------------------
    DATA:
      gref_output      TYPE REF TO data.


    " Constants
    "---------------------------------------------------------------
    CONSTANTS:
      BEGIN OF tc_icon,
        green TYPE icon_d VALUE '@5B@' ##NO_TEXT,
        red   TYPE icon_d VALUE '@5C@' ##NO_TEXT,
        yell  TYPE icon_d VALUE '@5D@' ##NO_TEXT,
        info  TYPE icon_d VALUE '@0S@' ##NO_TEXT,
        miss  TYPE icon_d VALUE '@D7@' ##NO_TEXT,
        exec  TYPE icon_d VALUE '@15@' ##NO_TEXT,
        refr  TYPE icon_d VALUE '@42@' ##NO_TEXT,
        save  TYPE icon_d VALUE '@2L@' ##NO_TEXT,
      END OF tc_icon,

      BEGIN OF tc_cell_col,
        cyan  TYPE lvc_col VALUE '1' ##NO_TEXT,
        grey  TYPE lvc_col VALUE '2' ##NO_TEXT,
        yell  TYPE lvc_col VALUE '3' ##NO_TEXT,
        blue  TYPE lvc_col VALUE '4' ##NO_TEXT,
        green TYPE lvc_col VALUE '5' ##NO_TEXT,
        red   TYPE lvc_col VALUE '6' ##NO_TEXT,
        oran  TYPE lvc_col VALUE '7' ##NO_TEXT,
      END OF tc_cell_col,

      BEGIN OF tc_event_handler,
        on_link_click   TYPE string VALUE 'ON_LINK_CLICK'   ##NO_TEXT,
        on_double_click TYPE string VALUE 'ON_DOUBLE_CLICK' ##NO_TEXT,
      END OF tc_event_handler.

    CONSTANTS:
      c_col_fieldname TYPE lvc_fname VALUE 'T_COL' ##NO_TEXT.


    " Methods
    "---------------------------------------------------------------
    CLASS-METHODS:
      set_color_cell
        IMPORTING
          !xs_color     TYPE lvc_s_colo
          !xt_fieldname TYPE tt_fieldname
        CHANGING
          !y_row        TYPE any
        RAISING
          cx_ai_system_fault,

      set_color_row
        IMPORTING
          !xs_color TYPE lvc_s_colo
        CHANGING
          !ys_row   TYPE any
        RAISING
          cx_ai_system_fault,

      get_fieldcat_from_data
        IMPORTING
          !xs_sap_line    TYPE any OPTIONAL
          !xt_sap_table   TYPE table OPTIONAL
        EXPORTING
          !yo_structdescr TYPE REF TO cl_abap_structdescr
          !yt_fcat        TYPE lvc_t_fcat
        RAISING
          cx_ai_system_fault.

    METHODS:
      display_generic_alv
        IMPORTING
          !xt_output        TYPE STANDARD TABLE
          !xt_col_settings  TYPE tt_col_settings OPTIONAL
          !xo_event_handler TYPE REF TO object OPTIONAL
          !xv_popup         TYPE boolean OPTIONAL
        RAISING
          cx_salv_msg
          cx_ai_system_fault,

      display_transposed_row
        IMPORTING
          !xv_popup      TYPE flag DEFAULT abap_true
          !xs_row        TYPE any
        EXPORTING
          !yt_transposed TYPE STANDARD TABLE
        RAISING
          cx_salv_msg
          cx_ai_system_fault,

      on_link_click FOR EVENT link_click OF cl_salv_events_table
        IMPORTING
          row
          column,

      on_double_click FOR EVENT double_click OF cl_salv_events_table
        IMPORTING
          row
          column.


  PRIVATE SECTION.

    " Types
    "---------------------------------------------------------------
    TYPES:
      tt_sorted_col_settings TYPE SORTED TABLE OF ts_col_settings WITH NON-UNIQUE KEY fieldname.

    "Constants
    "-------------------------------------------------
    CONSTANTS:
      BEGIN OF tc_exception_msg,
        unable_read_file    TYPE string VALUE 'Unable read file'                   ##NO_TEXT,
        unable_def_struct   TYPE string VALUE 'Unable define Structure Descriptor' ##NO_TEXT,
        input_error         TYPE string VALUE 'Input error'                        ##NO_TEXT,
        internal_error      TYPE string VALUE 'Internal error occurred'            ##NO_TEXT,
        not_implemented     TYPE string VALUE 'Exit method not implemented'        ##NO_TEXT,
        not_supported_file  TYPE string VALUE 'File not supported'                 ##NO_TEXT,
        file_empty          TYPE string VALUE 'File empty'                         ##NO_TEXT,
        col_tab_not_found   TYPE string VALUE 'Color Column T_COL not found'       ##NO_TEXT,
        fieldname_not_found TYPE string VALUE 'Fieldname not found'                ##NO_TEXT,
      END OF tc_exception_msg.


    " Data
    "---------------------------------------------------------------
    DATA:
      go_salv          TYPE REF TO cl_salv_table,
      gt_fcat          TYPE lvc_t_fcat,
      go_structdescr   TYPE REF TO cl_abap_structdescr,
      gt_col_settings  TYPE tt_sorted_col_settings,
      go_event_handler TYPE REF TO object.


    " Methods
    "---------------------------------------------------------------
    METHODS:
      set_display_settings,
      set_layout_settings,
      set_column_settings,
      set_handler_settings.

ENDCLASS.                    "zag_cl_salv DEFINITION



*----------------------------------------------------------------------*
*       CLASS zag_cl_salv IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zag_cl_salv IMPLEMENTATION.


  METHOD display_generic_alv.

    DATA:
      lv_cx_msg TYPE string VALUE IS INITIAL,
      lx_root   TYPE REF TO cx_root.

    FIELD-SYMBOLS:
      <t_output> TYPE STANDARD TABLE.


    "Init. SALV Object
    "-------------------------------------------------
    DATA: lx_salv_msg        TYPE REF TO cx_salv_msg,
          lx_ai_system_fault TYPE REF TO cx_ai_system_fault.
    TRY.
        CLEAR me->gref_output.
        CREATE DATA me->gref_output LIKE xt_output.
        ASSIGN me->gref_output->* TO <t_output>.

        <t_output> = xt_output.

        FREE me->go_salv.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = me->go_salv
          CHANGING
            t_table      = <t_output>[] ).


        get_fieldcat_from_data(
          EXPORTING
            xt_sap_table              = <t_output>
          IMPORTING
            yo_structdescr            = me->go_structdescr
            yt_fcat                   = me->gt_fcat[]
        ).


        "Set Display settings
        "-------------------------------------------------
        set_display_settings( ).


        "Set layout settings
        "-------------------------------------------------
        set_layout_settings( ).


        "Set Columns Settings
        "-------------------------------------------------
        me->gt_col_settings = xt_col_settings[].
        set_column_settings( ).


        "Set handler and functions based on sy-tcode
        "-------------------------------------------------
        me->go_event_handler = xo_event_handler.
        set_handler_settings( ).


        "Print as PopUp
        "-------------------------------------------------
        IF xv_popup EQ abap_true.

          me->go_salv->set_screen_popup(
            start_column = 1
            end_column   = 100
            start_line   = 1
            end_line     = 15
          ).

        ENDIF.


        "PRINT ALV
        "-------------------------------------------------
        me->go_salv->display( ).


      CATCH cx_salv_msg INTO lx_salv_msg.
        RAISE EXCEPTION lx_salv_msg.

      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        RAISE EXCEPTION lx_ai_system_fault.

    ENDTRY.


  ENDMETHOD.                    "display_generic_alv


  METHOD display_transposed_row.

    DATA:
      lref_t_row     TYPE REF TO data,
      lt_fcat        TYPE lvc_t_fcat,
      lref_transp    TYPE REF TO data,

      lo_data_transp TYPE  REF TO data,
      lt_fcat_transp TYPE  lvc_t_fcat.

    FIELD-SYMBOLS:
      <t_table>        TYPE STANDARD TABLE,
      <fcat>           TYPE lvc_s_fcat,
      <lt_transp_data> TYPE table.


    "-------------------------------------------------

    CLEAR: lo_data_transp, lt_fcat_transp[].

    CREATE DATA lref_t_row LIKE TABLE OF xs_row.
    ASSIGN lref_t_row->* TO <t_table>.


    "-> Creazione tabella 'DESCR_CAMPO' + 'VALORE'
    "-> con relativo riferimento <fs>
    "------------------------------------------------
    APPEND INITIAL LINE TO lt_fcat ASSIGNING <fcat>.
    <fcat>-fieldname  = 'COLUMNTEXT'.
    <fcat>-ref_table  = 'LVC_S_DETA'.

    APPEND INITIAL LINE TO lt_fcat ASSIGNING <fcat>.
    <fcat>-fieldname  = 'VALUE'.
    <fcat>-ref_field  = 'VALUE'.
    <fcat>-ref_table  = 'LVC_S_DETA'.

    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog = lt_fcat
      IMPORTING
        ep_table        = lref_transp.

    ASSIGN lref_transp->* TO <lt_transp_data>.


    "-> Estrazione lista campi tabella originale
    "------------------------------------------------
    DATA: lx_salv_msg        TYPE REF TO cx_salv_msg,
          lx_ai_system_fault TYPE REF TO cx_ai_system_fault.

    TRY.
        DATA lo_salv TYPE REF TO cl_salv_table.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_salv
          CHANGING
            t_table      = <t_table>[] ).


        DATA: lr_columns      TYPE REF TO cl_salv_columns_table,
              lt_column_ref   TYPE salv_t_column_ref.

        lr_columns    = lo_salv->get_columns( ).
        lt_column_ref = lr_columns->get( ).


        "-> Trasposizione campi da NxM a MxN
        "------------------------------------------------
        FIELD-SYMBOLS: <column_ref>     LIKE LINE OF lt_column_ref,
                       <original_value> TYPE any,
                       <transp_row>     TYPE any,
                       <transp_coltxt>  TYPE any,
                       <transp_value>   TYPE any.
        LOOP AT lt_column_ref ASSIGNING <column_ref>.

          CHECK <column_ref>-columnname NE 'MANDT'.

          ASSIGN COMPONENT <column_ref>-columnname OF STRUCTURE xs_row TO <original_value>.
          CHECK sy-subrc EQ 0.

          APPEND INITIAL LINE TO <lt_transp_data> ASSIGNING <transp_row>.

          ASSIGN COMPONENT 'COLUMNTEXT' OF STRUCTURE <transp_row> TO <transp_coltxt>.
          ASSIGN COMPONENT 'VALUE'      OF STRUCTURE <transp_row> TO <transp_value>.

          <transp_coltxt> = <column_ref>-r_column->get_long_text( ).
          <transp_value>  = <original_value>.

        ENDLOOP.


        "-> Esportazione tabella trasposta
        "------------------------------------------------
        yt_transposed = <lt_transp_data>.


        "-> Stampa tabella
        "-------------------------------------------------

        display_generic_alv( <lt_transp_data>[] ).

      CATCH cx_salv_msg INTO lx_salv_msg.
        DATA lv_cx_msg TYPE string.
        lv_cx_msg = lx_salv_msg->get_text( ).
        RAISE EXCEPTION lx_salv_msg.

      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        RAISE EXCEPTION lx_ai_system_fault.

    ENDTRY.

  ENDMETHOD.                    "display_transposed_row


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

    DATA: lx_salv_msg        TYPE REF TO cx_salv_msg,
          lx_ai_system_fault TYPE REF TO cx_ai_system_fault.

    TRY.
        DATA lt_salv_table TYPE REF TO cl_salv_table.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lt_salv_table
          CHANGING
            t_table      = <sap_table>
        ).

        yt_fcat = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
          r_columns      = lt_salv_table->get_columns( ) " ALV Filter
          r_aggregations = lt_salv_table->get_aggregations( ) " ALV Aggregations
        ).

      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING
            errortext = tc_exception_msg-unable_def_struct.

      CATCH cx_salv_msg INTO lx_salv_msg.
        lv_except_msg = lx_salv_msg->get_text( ).
        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING
            errortext = tc_exception_msg-unable_def_struct.

    ENDTRY.


  ENDMETHOD.                    "get_fieldcat_from_data


  METHOD set_color_cell.

    DATA:
      ls_scol TYPE lvc_s_scol.

    FIELD-SYMBOLS:
      <t_col> TYPE lvc_t_scol.

    "-------------------------------------------------

    ASSIGN COMPONENT c_col_fieldname OF STRUCTURE y_row TO <t_col>.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-col_tab_not_found.

    ENDIF.

    FIELD-SYMBOLS: <fieldname>   LIKE LINE OF xt_fieldname,
                   <field_check> TYPE any.
    LOOP AT xt_fieldname ASSIGNING <fieldname>.
      ASSIGN COMPONENT <fieldname> OF STRUCTURE y_row TO <field_check>.
      IF sy-subrc <> 0.

        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING
            errortext = tc_exception_msg-fieldname_not_found.

      ENDIF.

      DELETE <t_col> WHERE fname EQ <fieldname>.

      DATA ls_col TYPE lvc_s_scol.
      ls_col-fname     = <fieldname> .
      ls_col-color-col = xs_color-col.
      ls_col-color-int = xs_color-int.
      ls_col-color-inv = xs_color-inv.
      INSERT ls_col INTO TABLE <t_col>.

    ENDLOOP.

  ENDMETHOD.                    "set_color_cell


  METHOD set_color_row.

    DATA:
      ls_scol TYPE lvc_s_scol.

    FIELD-SYMBOLS:
      <t_col> TYPE lvc_t_scol.

    "-------------------------------------------------

    ASSIGN COMPONENT c_col_fieldname OF STRUCTURE ys_row TO <t_col>.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-col_tab_not_found.

    ENDIF.

    DATA lt_fcat TYPE lvc_t_fcat.
    get_fieldcat_from_data(
      EXPORTING
        xs_sap_line = ys_row
      IMPORTING
        yt_fcat     = lt_fcat
    ).


    DATA ls_col TYPE lvc_s_scol.

    FIELD-SYMBOLS: <fcat> LIKE LINE OF lt_fcat.

    LOOP AT lt_fcat ASSIGNING <fcat>.

      DELETE <t_col> WHERE fname EQ <fcat>-fieldname.

      CLEAR ls_col.
      ls_col-fname     = <fcat>-fieldname.
      ls_col-color-col = xs_color-col.
      ls_col-color-int = xs_color-int.
      ls_col-color-inv = xs_color-inv.
      INSERT ls_col INTO TABLE <t_col>.

    ENDLOOP.

  ENDMETHOD.                    "set_color_row


  METHOD set_display_settings.

    FIELD-SYMBOLS:
      <t_output> TYPE STANDARD TABLE.


    ASSIGN me->gref_output->* TO <t_output>.

    DATA: lv_lines TYPE i,
          lv_title TYPE lvc_title.

    lv_lines   = lines( <t_output>[] ).
    lv_title   = |{ sy-title } ( { lv_lines } Record )| ##NO_TEXT.

    DATA lr_display TYPE REF TO cl_salv_display_settings.
    lr_display = me->go_salv->get_display_settings( ).
    lr_display->set_list_header( lv_title ).
    lr_display->set_striped_pattern( cl_salv_display_settings=>true ).

  ENDMETHOD.                    "set_display_settings


  METHOD set_layout_settings.

    DATA:
      ls_key TYPE salv_s_layout_key.


    ls_key-report   = sy-repid.

    DATA lr_layout TYPE REF TO cl_salv_layout.
    lr_layout = me->go_salv->get_layout( ).
    lr_layout->set_key( ls_key ).
    lr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

    DATA lr_selections TYPE REF TO cl_salv_selections.
    lr_selections = me->go_salv->get_selections( ).
    lr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  ENDMETHOD.                    "set_layout_settings


  METHOD set_column_settings.

    DATA:
      lr_column TYPE REF TO cl_salv_column_table.

    FIELD-SYMBOLS:
      <t_output> TYPE STANDARD TABLE.


    "--> Optimize all columns
    "---------------------------------------------------------------
    DATA lr_columns TYPE REF TO cl_salv_columns_table.
    lr_columns = me->go_salv->get_columns( ).
    lr_columns->set_optimize( 'X' ).


    "If T_COL column exists in your table, it will be set as color column reference
    "---------------------------------------------------------------
    DATA lx_salv_data_err TYPE REF TO cx_salv_data_error.
    TRY.
        lr_columns->set_color_column( c_col_fieldname ).
      CATCH cx_salv_data_error INTO lx_salv_data_err.
    ENDTRY.



    " Set Fieldcat settings
    "---------------------------------------------------------------
    DATA: lt_column_ref   TYPE salv_t_column_ref,
          lv_rollname     TYPE rollname,
          ls_ddic_ref     TYPE salv_s_ddic_reference.

    DATA: txt_l TYPE scrtext_l,
          txt_m TYPE scrtext_m,
          txt_s TYPE scrtext_s.

    FIELD-SYMBOLS: <column> LIKE LINE OF lt_column_ref,
                   <col_settings> LIKE LINE OF me->gt_col_settings.

    lt_column_ref = lr_columns->get( ).
    LOOP AT lt_column_ref ASSIGNING <column>.
      lr_column ?= <column>-r_column.

      "Default settings "-------------------------------------------------
      lv_rollname = <column>-r_column->get_ddic_rollname( ).
      CASE lv_rollname.
        WHEN 'MANDT'.
          lr_column->set_visible( if_salv_c_bool_sap=>false ).

        WHEN 'ICON_D'.
          lr_column->set_icon( if_salv_c_bool_sap=>true ).
          lr_column->set_alignment( if_salv_c_alignment=>centered ).

      ENDCASE.

      FIELD-SYMBOLS: <fcat> LIKE LINE OF me->gt_fcat.
      READ TABLE me->gt_fcat WITH KEY fieldname = <column>-columnname ASSIGNING <fcat>.
      IF sy-subrc EQ 0.
        CLEAR ls_ddic_ref.

        ls_ddic_ref-table =  <fcat>-ref_table.
        ls_ddic_ref-field =  <fcat>-ref_field.
        lr_column->set_ddic_reference( ls_ddic_ref ).
      ENDIF.


      "User settings
      "---------------------------------------------------------------
      READ TABLE me->gt_col_settings ASSIGNING <col_settings>
        WITH KEY fieldname = <column>-columnname
        BINARY SEARCH.
      IF sy-subrc EQ 0.

        "Labels
        IF <col_settings>-label IS NOT INITIAL.

          txt_l = <col_settings>-label.
          txt_m = <col_settings>-label.
          txt_s = <col_settings>-label.

          lr_column->set_long_text( txt_l ).
          lr_column->set_medium_text( txt_m ).
          lr_column->set_short_text( txt_s ).

        ENDIF.


        "Hide columns
        IF <col_settings>-no_out EQ 'X'.

          lr_column->set_visible( if_salv_c_bool_sap=>false ).

        ENDIF.


        "Set Hotspot
        IF <col_settings>-hotspot EQ 'X'.

          lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.                    "set_column_settings


  METHOD set_handler_settings.

    DATA:
        lo_event_handler TYPE REF TO object,
        lr_functions    TYPE REF TO cl_salv_functions_list,
        lo_events       TYPE REF TO cl_salv_events_table.


    lr_functions = me->go_salv->get_functions( ).
    lr_functions->set_all( 'X' ).
    lo_events = me->go_salv->get_event( ).


    CHECK me->go_event_handler IS NOT INITIAL.
    SET HANDLER on_link_click   FOR lo_events.
    SET HANDLER on_double_click FOR lo_events.


  ENDMETHOD.                    "set_handler_settings

  METHOD on_link_click.
    DATA lx_illegal_method TYPE REF TO cx_sy_dyn_call_illegal_method.

    TRY.
        CALL METHOD me->go_event_handler->(tc_event_handler-on_link_click)
          EXPORTING
            xv_row    = row
            xv_column = column.

      CATCH cx_sy_dyn_call_illegal_method INTO lx_illegal_method.
        DATA lv_msg TYPE string.
        lv_msg = lx_illegal_method->get_longtext( ).
        MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.

  ENDMETHOD.                    "on_link_click

  METHOD on_double_click.
    DATA lx_illegal_method TYPE REF TO cx_sy_dyn_call_illegal_method.

    TRY.
        CALL METHOD me->go_event_handler->(tc_event_handler-on_double_click)
          EXPORTING
            xv_row    = row
            xv_column = column.

      CATCH cx_sy_dyn_call_illegal_method INTO lx_illegal_method.
        DATA lv_msg TYPE string.
        lv_msg = lx_illegal_method->get_longtext( ).
        MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.

  ENDMETHOD.                    "on_double_click

ENDCLASS.                    "zag_cl_salv IMPLEMENTATION