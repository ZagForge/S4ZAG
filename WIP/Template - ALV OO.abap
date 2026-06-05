*&---------------------------------------------------------------------*
*& Include          ZAG_INCLUDE_DYNAMIC
*&---------------------------------------------------------------------*
*
*& DESCRIZIONE:
*&   Framework generico per ALV OO su dynpro custom.
*&   Gestisce creazione container, fieldcat, layout, sort, variant,
*&   print_params, toolbar_excluding, toolbar_buttons ed eventi
*&   (toolbar, user command, hotspot, data_changed) tramite hook FORM
*&   nel programma chiamante.
*&
*&---------------------------------------------------------------------*
*& UTILIZZO - PASSI OBBLIGATORI
*&---------------------------------------------------------------------*
*&
*& 1) INCLUDE nel report principale:
*&      INCLUDE zag_include_dynamic.
*&
*& 2) Struttura dati — aggiungi C_COL e C_STY se servono colori/stili:
*&
*&      TYPES: BEGIN OF ts_mia_struttura.
*&               INCLUDE STRUCTURE mara.
*&               TYPES: c_col TYPE lvc_t_scol,   " colori cella
*&                      c_sty TYPE lvc_t_styl.   " stile/editabilità cella
*&      TYPES: END OF ts_mia_struttura.
*&
*& 3) START-OF-SELECTION — inizializza e registra:
*&
*&      PERFORM initialize_dynamic_alv.
*&
*&      lcl_config_manager=>register_alv(
*&        iv_dynnr      = '0100'
*&        iv_container  = 'CONTAINER_0100'
*&        iv_structure  = 'MARA'
*&        iv_pf_status  = 'ZPF_GENERIC'
*&        iv_title      = 'ZTIT_0100'
*&      ).
*&
*& 4) Configurazione campi — opzionale:
*&
*&      lcl_config_manager=>add_field_config( VALUE #(
*&        dynnr      = '0100'
*&        fieldname  = 'MATNR'
*&        hotspot    = abap_true
*&        scrtext_s  = 'Mat.'
*&        scrtext_m  = 'Materiale'
*&        scrtext_l  = 'N. Materiale'
*&      ) ).
*&
*& 5) Sort — opzionale:
*&
*&      lcl_config_manager=>add_sort(
*&        iv_dynnr = '0100'
*&        is_sort  = VALUE #( spos = 1 fieldname = 'MATNR' subtot = 'X' )
*&      ).
*&
*& 6) Variant — opzionale:
*&
*&      lcl_config_manager=>set_variant(
*&        iv_dynnr    = '0100'
*&        iv_report   = sy-repid
*&        iv_username = sy-uname
*&      ).
*&      " Per variante specifica:
*&      " iv_variant = '/DEFAULT'
*&
*& 7) Print params — opzionale:
*&
*&      lcl_config_manager=>set_print_params(
*&        iv_dynnr  = '0100'
*&        is_print  = VALUE #( print = 'X' )
*&      ).
*&
*& 8) Toolbar excluding — opzionale:
*&
*&      lcl_config_manager=>add_toolbar_exclude(
*&        iv_dynnr = '0100'
*&        iv_func  = cl_gui_alv_grid=>mc_fc_loc_insert_row
*&      ).
*&
*& 9) Bottoni toolbar custom — opzionale:
*&
*&      lcl_config_manager=>add_toolbar_button(
*&        iv_dynnr  = '0100'
*&        is_button = VALUE #(
*&          function  = '&MYACTION'
*&          icon      = lcl_alv_utils=>tc_icon-exec
*&          text      = 'Azione'
*&          quickinfo = 'Azione custom'
*&          butn_type = '0'
*&        )
*&      ).
*&
*& 10) Passa i dati e apri lo screen:
*&
*&      DATA lr_data TYPE REF TO data.
*&      GET REFERENCE OF gt_mia_tabella INTO lr_data.
*&      PERFORM call_alv_screen USING '0100' lr_data.
*&
*& 11) PBO dello screen — crea ALV solo al primo PBO:
*&
*&      MODULE status_0100 OUTPUT.
*&        lcl_config_manager=>set_screen_properties( ).
*&        go_alv_0100 = lcl_config_manager=>get_alv_ref( '0100' ).
*&        IF go_alv_0100 IS NOT BOUND.
*&          go_alv_0100 = lcl_alv_factory=>create_alv( '0100' ).
*&        ENDIF.
*&      ENDMODULE.
*&
*& 12) PAI dello screen — gestisci comandi e salvataggio.
*&
*&---------------------------------------------------------------------*
*& HOOK FORM — da implementare nel programma chiamante
*&---------------------------------------------------------------------*
*&
*&   FORM handle_custom_command USING iv_command TYPE sy-ucomm.
*&   ENDFORM.
*&
*&   " is_row_id-index        = indice riga
*&   " is_column_id-fieldname = campo cliccato
*&   FORM handle_dynamic_hotspot
*&     USING is_row_id    TYPE lvc_s_row
*&           is_column_id TYPE lvc_s_col
*&           is_row_no    TYPE lvc_s_roid.
*&   ENDFORM.
*&
*&   " Accumula celle modificate in gt_changed_data, gt_deleted_data, ecc.
*&   FORM handle_dynamic_data_changed
*&     CHANGING yr_data_changed TYPE REF TO cl_alv_changed_data_protocol.
*&   ENDFORM.
*&
*&---------------------------------------------------------------------*
*& NOTE SE51 - SCREEN
*&---------------------------------------------------------------------*
*&
*&   - Custom Container: nome = iv_container passato in register_alv
*&   - Flow Logic:
*&       PROCESS BEFORE OUTPUT.
*&         MODULE status_XXXX.
*&       PROCESS AFTER INPUT.
*&         MODULE user_command_XXXX.
*&   - OK_CODE = variabile TYPE sy-ucomm del programma (es. GV_COMMAND_0100)
*&
*&---------------------------------------------------------------------*

CLASS lcl_alv_event_dynamic DEFINITION DEFERRED.
CLASS lcl_alv_factory       DEFINITION DEFERRED.
CLASS lcl_config_manager    DEFINITION DEFERRED.
CLASS lcl_alv_utils         DEFINITION DEFERRED.

*--------------------------------------------------------------------*
* TYPES
*--------------------------------------------------------------------*
TYPES: BEGIN OF ts_alv_config,
         dynnr           TYPE sy-dynnr,
         container_name  TYPE scrfname,
         structure_name  TYPE dd02l-tabname,
         data_table_ref  TYPE REF TO data,
         alv_grid_ref    TYPE REF TO cl_gui_alv_grid,
         container_ref   TYPE REF TO cl_gui_custom_container,
         title_key       TYPE string,
         pf_status       TYPE string,
         " — dati modificati —
         changed_data    TYPE lvc_t_modi,
         deleted_data    TYPE lvc_t_moce,
         inserted_data   TYPE lvc_t_moce,
         " — configurazione display —
         sort            TYPE lvc_t_sort,
         variant         TYPE disvariant,
         print_params    TYPE lvc_s_prnt,
         toolbar_excl    TYPE ui_functions,
         toolbar_buttons TYPE ttb_button,
       END OF ts_alv_config,
       tt_alv_config TYPE TABLE OF ts_alv_config WITH KEY dynnr.

TYPES: BEGIN OF ts_field_config,
         dynnr      TYPE sy-dynnr,
         fieldname  TYPE fieldname,
         scrtext_s  TYPE scrtext_s,
         scrtext_m  TYPE scrtext_m,
         scrtext_l  TYPE scrtext_l,
         hotspot    TYPE abap_bool,
         icon_field TYPE abap_bool,
         hide_field TYPE abap_bool,
       END OF ts_field_config,
       tt_field_config TYPE TABLE OF ts_field_config WITH KEY dynnr fieldname.

*--------------------------------------------------------------------*
* GLOBAL DATA
*--------------------------------------------------------------------*
DATA: gt_alv_config    TYPE tt_alv_config,
      gt_field_config  TYPE tt_field_config,
      go_current_alv   TYPE REF TO cl_gui_alv_grid,
      go_event_handler TYPE REF TO lcl_alv_event_dynamic.


*--------------------------------------------------------------------*
* EVENT HANDLER CLASS
*--------------------------------------------------------------------*
CLASS lcl_alv_event_dynamic DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id es_row_no,
      handle_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed.
ENDCLASS.


*--------------------------------------------------------------------*
* ALV FACTORY CLASS
*--------------------------------------------------------------------*
CLASS lcl_alv_factory DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      create_alv
        IMPORTING iv_dynnr      TYPE sy-dynnr
        RETURNING VALUE(ro_alv) TYPE REF TO cl_gui_alv_grid,
      build_fieldcat
        IMPORTING iv_dynnr       TYPE sy-dynnr
                  iv_structure   TYPE dd02l-tabname
        RETURNING VALUE(rt_fcat) TYPE lvc_t_fcat,
      setup_layout
        IMPORTING ir_data_table    TYPE REF TO data
        RETURNING VALUE(rs_layout) TYPE lvc_s_layo,
      register_events
        IMPORTING io_alv TYPE REF TO cl_gui_alv_grid.
  PRIVATE SECTION.
    CLASS-METHODS:
      apply_field_config
        IMPORTING iv_dynnr TYPE sy-dynnr
        CHANGING  ct_fcat  TYPE lvc_t_fcat.
ENDCLASS.


*--------------------------------------------------------------------*
* CONFIGURATION MANAGER CLASS
*--------------------------------------------------------------------*
CLASS lcl_config_manager DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      "— Registrazione screen —
      register_alv
        IMPORTING iv_dynnr     TYPE sy-dynnr
                  iv_container TYPE scrfname
                  iv_structure TYPE dd02l-tabname
                  iv_title     TYPE string    OPTIONAL
                  iv_pf_status TYPE string    OPTIONAL,

      "— Campi —
      add_field_config
        IMPORTING is_field_config TYPE ts_field_config,

      "— Sort —
      add_sort
        IMPORTING iv_dynnr TYPE sy-dynnr
                  is_sort  TYPE lvc_s_sort,

      "— Variant —
      set_variant
        IMPORTING iv_dynnr    TYPE sy-dynnr
                  iv_report   TYPE syrepid   OPTIONAL
                  iv_username TYPE syuname   OPTIONAL
                  iv_variant  TYPE variant   OPTIONAL,

      "— Print params —
      set_print_params
        IMPORTING iv_dynnr TYPE sy-dynnr
                  is_print TYPE lvc_s_prnt,

      "— Toolbar excluding —
      add_toolbar_exclude
        IMPORTING iv_dynnr TYPE sy-dynnr
                  iv_func  TYPE ui_func,

      "— Toolbar buttons —
      add_toolbar_button
        IMPORTING iv_dynnr  TYPE sy-dynnr
                  is_button TYPE stb_button,

      "— Getter / utility —
      get_alv_config
        IMPORTING iv_dynnr         TYPE sy-dynnr
        RETURNING VALUE(rs_config) TYPE ts_alv_config,

      get_alv_ref
        IMPORTING iv_dynnr      TYPE sy-dynnr
        RETURNING VALUE(ro_alv) TYPE REF TO cl_gui_alv_grid,

      has_unsaved_changes
        IMPORTING iv_dynnr        TYPE sy-dynnr
        RETURNING VALUE(rv_dirty) TYPE abap_bool,

      clear_changed_data
        IMPORTING iv_dynnr TYPE sy-dynnr,

      set_screen_properties.
ENDCLASS.


*--------------------------------------------------------------------*
* HELPER CLASS
*--------------------------------------------------------------------*
CLASS lcl_alv_utils DEFINITION.
  PUBLIC SECTION.
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

    CLASS-METHODS:

      "— Refresh con stabilizzazione riga/colonna —
      refresh
        IMPORTING io_alv  TYPE REF TO cl_gui_alv_grid
                  iv_soft TYPE abap_bool DEFAULT abap_true,

      "— Abilita cella in editing —
      set_cell_editable
        IMPORTING iv_fieldname TYPE fieldname
        CHANGING  ct_sty       TYPE lvc_t_styl,

      "— Imposta cella read-only —
      set_cell_readonly
        IMPORTING iv_fieldname TYPE fieldname
        CHANGING  ct_sty       TYPE lvc_t_styl,

      "— Colora riga intera —
      set_row_color
        IMPORTING iv_color TYPE lvc_col
                  iv_int   TYPE i DEFAULT 1
        CHANGING  ct_col   TYPE lvc_t_scol,

      "— Colora cella singola —
      set_cell_color
        IMPORTING iv_fieldname TYPE fieldname
                  iv_color     TYPE lvc_col
                  iv_int       TYPE i DEFAULT 1
        CHANGING  ct_col       TYPE lvc_t_scol,

      "— Popup conferma dati non salvati — ritorna abap_true se ok procedere —
      confirm_unsaved_changes
        IMPORTING iv_dynnr          TYPE sy-dynnr
        RETURNING VALUE(rv_proceed) TYPE abap_bool,

      "— Righe selezionate dall'ALV corrente —
      get_selected_rows
        IMPORTING io_alv         TYPE REF TO cl_gui_alv_grid
        RETURNING VALUE(rt_rows) TYPE lvc_t_row,

      "— Applica changed_data alla tabella interna —
      apply_changed_data
        IMPORTING iv_dynnr TYPE sy-dynnr
        CHANGING  ct_table TYPE STANDARD TABLE,

      "— Restituisce fieldcat e descrittore di una generica struttura/tabella —
      get_fieldcat_from_data
        IMPORTING
          !xs_sap_line    TYPE any   OPTIONAL
          !xt_sap_table   TYPE table OPTIONAL
        EXPORTING
          !yo_structdescr TYPE REF TO cl_abap_structdescr
          !yt_fcat        TYPE lvc_t_fcat
        RAISING
          cx_ai_system_fault.

ENDCLASS.


*--------------------------------------------------------------------*
* IMPLEMENTATIONS
*--------------------------------------------------------------------*

CLASS lcl_alv_event_dynamic IMPLEMENTATION.

  METHOD handle_user_command.
    CASE e_ucomm.
      WHEN '&REFRESH'.
        CHECK go_current_alv IS BOUND.
        lcl_alv_utils=>refresh( go_current_alv ).
      WHEN OTHERS.
        PERFORM handle_custom_command USING e_ucomm.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_toolbar.
    "— Inietta i bottoni custom dalla config del dynnr corrente —
    ASSIGN gt_alv_config[ dynnr = sy-dynnr ] TO FIELD-SYMBOL(<cfg>).
    IF sy-subrc EQ 0 AND <cfg>-toolbar_buttons IS NOT INITIAL.
      APPEND LINES OF <cfg>-toolbar_buttons TO e_object->mt_toolbar.
    ENDIF.
  ENDMETHOD.

  METHOD handle_hotspot_click.
    PERFORM handle_dynamic_hotspot USING e_row_id e_column_id es_row_no.
  ENDMETHOD.

  METHOD handle_data_changed.
    "— Accumula nelle config del dynnr corrente —
    ASSIGN gt_alv_config[ dynnr = sy-dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    APPEND LINES OF er_data_changed->mt_good_cells    TO <cfg>-changed_data.
    APPEND LINES OF er_data_changed->mt_deleted_rows  TO <cfg>-deleted_data.
    APPEND LINES OF er_data_changed->mt_inserted_rows TO <cfg>-inserted_data.

    "— Hook nel report per validazioni custom —
    PERFORM handle_dynamic_data_changed CHANGING er_data_changed.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_alv_factory IMPLEMENTATION.

  METHOD create_alv.

    DATA(ls_config) = lcl_config_manager=>get_alv_config( iv_dynnr ).

    FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE.
    ASSIGN ls_config-data_table_ref->* TO <lt_table>.

    DATA(lo_container) = NEW cl_gui_custom_container(
      container_name = ls_config-container_name
    ).

    ro_alv = NEW cl_gui_alv_grid( i_parent = lo_container ).

    DATA(lt_fcat) = build_fieldcat(
      iv_dynnr     = iv_dynnr
      iv_structure = ls_config-structure_name
    ).

    DATA(ls_layout) = setup_layout( ls_config-data_table_ref ).

    ro_alv->set_table_for_first_display(
      EXPORTING
        i_buffer_active      = 'X'
        i_save               = 'A'
        is_layout            = ls_layout
        is_variant           = ls_config-variant
        is_print             = ls_config-print_params
        it_toolbar_excluding = ls_config-toolbar_excl
      CHANGING
        it_outtab            = <lt_table>
        it_fieldcatalog      = lt_fcat
        it_sort              = ls_config-sort
    ).

    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    IF sy-subrc EQ 0.
      <cfg>-alv_grid_ref  = ro_alv.
      <cfg>-container_ref = lo_container.
    ENDIF.

    go_current_alv = ro_alv.
    register_events( ro_alv ).

  ENDMETHOD.

  METHOD build_fieldcat.

    IF iv_structure IS NOT INITIAL.

      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name = iv_structure
        CHANGING
          ct_fieldcat      = rt_fcat.

    ELSE.

      DATA(ls_config) = lcl_config_manager=>get_alv_config( iv_dynnr ).

      FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE.
      ASSIGN ls_config-data_table_ref->* TO <lt_table>.

      TRY.
          lcl_alv_utils=>get_fieldcat_from_data(
            EXPORTING xt_sap_table = <lt_table>
            IMPORTING yt_fcat      = rt_fcat
          ).
        CATCH cx_ai_system_fault INTO DATA(lx_sys_fault).
          DATA(lv_exc) = lx_sys_fault->get_text( ).
      ENDTRY.

    ENDIF.

    apply_field_config(
      EXPORTING iv_dynnr = iv_dynnr
      CHANGING  ct_fcat  = rt_fcat
    ).

  ENDMETHOD.

  METHOD apply_field_config.
    LOOP AT ct_fcat ASSIGNING FIELD-SYMBOL(<ls_fcat>).

      READ TABLE gt_field_config INTO DATA(ls_fc)
        WITH KEY dynnr = iv_dynnr fieldname = <ls_fcat>-fieldname.
      CHECK sy-subrc EQ 0.

      IF ls_fc-scrtext_s IS NOT INITIAL. <ls_fcat>-scrtext_s = ls_fc-scrtext_s. ENDIF.
      IF ls_fc-scrtext_m IS NOT INITIAL. <ls_fcat>-scrtext_m = ls_fc-scrtext_m. ENDIF.
      IF ls_fc-scrtext_l IS NOT INITIAL. <ls_fcat>-scrtext_l = ls_fc-scrtext_l. ENDIF.

      <ls_fcat>-hotspot = ls_fc-hotspot.
      <ls_fcat>-icon    = ls_fc-icon_field.
      <ls_fcat>-no_out  = ls_fc-hide_field.

      IF <ls_fcat>-rollname NE 'ICON_D'.
        <ls_fcat>-col_opt = 'X'.
      ENDIF.

      IF <ls_fcat>-rollname EQ 'MANDT'.
        <ls_fcat>-no_out = 'X'.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD setup_layout.
    rs_layout-zebra    = 'X'.
    rs_layout-sel_mode = 'A'.

    CHECK ir_data_table IS BOUND.

    FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE,
                   <ls_row>   TYPE any.

    ASSIGN ir_data_table->* TO <lt_table>.
    CHECK sy-subrc EQ 0 AND lines( <lt_table> ) > 0.
    ASSIGN <lt_table>[ 1 ] TO <ls_row>.

    ASSIGN COMPONENT 'C_COL' OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<color>).
    IF sy-subrc EQ 0. rs_layout-ctab_fname  = 'C_COL'. ENDIF.

    ASSIGN COMPONENT 'C_STY' OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<style>).
    IF sy-subrc EQ 0. rs_layout-stylefname = 'C_STY'. ENDIF.
  ENDMETHOD.

  METHOD register_events.
    IF go_event_handler IS INITIAL.
      go_event_handler = NEW lcl_alv_event_dynamic( ).
    ENDIF.

    SET HANDLER go_event_handler->handle_toolbar       FOR io_alv.
    SET HANDLER go_event_handler->handle_user_command  FOR io_alv.
    SET HANDLER go_event_handler->handle_hotspot_click FOR io_alv.
    SET HANDLER go_event_handler->handle_data_changed  FOR io_alv.

    io_alv->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
    io_alv->register_edit_event(
      EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_modified
      EXCEPTIONS error = 1 OTHERS = 2
    ).
    io_alv->set_ready_for_input( i_ready_for_input = 1 ).

  ENDMETHOD.

ENDCLASS.


CLASS lcl_config_manager IMPLEMENTATION.

  METHOD register_alv.
    APPEND VALUE ts_alv_config(
      dynnr          = iv_dynnr
      container_name = iv_container
      structure_name = iv_structure
      title_key      = iv_title
      pf_status      = iv_pf_status
    ) TO gt_alv_config.
  ENDMETHOD.

  METHOD add_field_config.
    APPEND is_field_config TO gt_field_config.
  ENDMETHOD.

  METHOD add_sort.
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    APPEND is_sort TO <cfg>-sort.
  ENDMETHOD.

  METHOD set_variant.
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    <cfg>-variant-report   = iv_report.
    <cfg>-variant-username = iv_username.
    <cfg>-variant-variant  = iv_variant.
  ENDMETHOD.

  METHOD set_print_params.
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    <cfg>-print_params = is_print.
  ENDMETHOD.

  METHOD add_toolbar_exclude.
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    APPEND iv_func TO <cfg>-toolbar_excl.
  ENDMETHOD.

  METHOD add_toolbar_button.
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    APPEND is_button TO <cfg>-toolbar_buttons.
  ENDMETHOD.

  METHOD get_alv_config.
    READ TABLE gt_alv_config INTO rs_config WITH KEY dynnr = iv_dynnr.
  ENDMETHOD.

  METHOD get_alv_ref.
    READ TABLE gt_alv_config INTO DATA(ls_config) WITH KEY dynnr = iv_dynnr.
    CHECK sy-subrc EQ 0.
    ro_alv = ls_config-alv_grid_ref.
  ENDMETHOD.

  METHOD has_unsaved_changes.
    READ TABLE gt_alv_config INTO DATA(ls_config) WITH KEY dynnr = iv_dynnr.
    CHECK sy-subrc EQ 0.
    rv_dirty = xsdbool(
      ls_config-changed_data  IS NOT INITIAL OR
      ls_config-deleted_data  IS NOT INITIAL OR
      ls_config-inserted_data IS NOT INITIAL
    ).
  ENDMETHOD.

  METHOD clear_changed_data.
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    CHECK sy-subrc EQ 0.
    CLEAR: <cfg>-changed_data, <cfg>-deleted_data, <cfg>-inserted_data.
  ENDMETHOD.

  METHOD set_screen_properties.
    DATA(ls_config) = lcl_config_manager=>get_alv_config( sy-dynnr ).

    IF ls_config-pf_status IS NOT INITIAL.
      SET PF-STATUS ls_config-pf_status.
    ENDIF.

    IF ls_config-title_key IS NOT INITIAL.
      SET TITLEBAR ls_config-title_key.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_alv_utils IMPLEMENTATION.

  METHOD refresh.
    CHECK io_alv IS BOUND.
    DATA ls_stable TYPE lvc_s_stbl.
    IF iv_soft = abap_true.
      ls_stable-row = 'X'.
      ls_stable-col = 'X'.
      io_alv->refresh_table_display(
        is_stable      = ls_stable
        i_soft_refresh = 'X'
      ).
    ELSE.
      io_alv->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD set_cell_editable.
    DATA ls_styl TYPE lvc_s_styl.
    DELETE ct_sty WHERE fieldname = iv_fieldname.
    ls_styl-fieldname = iv_fieldname.
    ls_styl-style     = cl_gui_alv_grid=>mc_style_enabled.
    INSERT ls_styl INTO TABLE ct_sty.
  ENDMETHOD.

  METHOD set_cell_readonly.
    DATA ls_styl TYPE lvc_s_styl.
    DELETE ct_sty WHERE fieldname = iv_fieldname.
    ls_styl-fieldname = iv_fieldname.
    ls_styl-style     = cl_gui_alv_grid=>mc_style_disabled.
    INSERT ls_styl INTO TABLE ct_sty.
  ENDMETHOD.

  METHOD set_row_color.
    DATA ls_scol TYPE lvc_s_scol.
    CLEAR ct_col[].
    ls_scol-color-col = iv_color.
    ls_scol-color-int = iv_int.
    INSERT ls_scol INTO TABLE ct_col.
  ENDMETHOD.

  METHOD set_cell_color.
    DATA ls_scol TYPE lvc_s_scol.
    DELETE ct_col WHERE fname = iv_fieldname.
    ls_scol-fname     = iv_fieldname.
    ls_scol-color-col = iv_color.
    ls_scol-color-int = iv_int.
    INSERT ls_scol INTO TABLE ct_col.
  ENDMETHOD.

  METHOD confirm_unsaved_changes.
    rv_proceed = abap_true.
    CHECK lcl_config_manager=>has_unsaved_changes( iv_dynnr ) = abap_true.

    DATA lv_answer TYPE c LENGTH 1.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question  = 'Dati non salvati. Uscire comunque?'
      IMPORTING
        answer         = lv_answer
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.

    rv_proceed = xsdbool( lv_answer EQ '1' ).
  ENDMETHOD.

  METHOD get_selected_rows.
    CHECK io_alv IS BOUND.
    io_alv->get_selected_rows(
      IMPORTING et_index_rows = rt_rows
    ).
  ENDMETHOD.

  METHOD apply_changed_data.
    DATA(ls_config) = lcl_config_manager=>get_alv_config( iv_dynnr ).
    CHECK ls_config-changed_data IS NOT INITIAL.

    LOOP AT ls_config-changed_data ASSIGNING FIELD-SYMBOL(<chng>).
      ASSIGN ct_table[ <chng>-row_id ] TO FIELD-SYMBOL(<row>).
      CHECK sy-subrc EQ 0.
      ASSIGN COMPONENT <chng>-fieldname OF STRUCTURE <row> TO FIELD-SYMBOL(<val>).
      CHECK sy-subrc EQ 0.
      <val> = <chng>-value.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_fieldcat_from_data.

    DATA:
      lref_sap_struct TYPE REF TO data,
      lref_sap_table  TYPE REF TO data,
      lv_except_msg   TYPE string.

    FIELD-SYMBOLS:
      <sap_struct> TYPE any,
      <sap_table>  TYPE STANDARD TABLE.

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
        EXPORTING errortext = tc_exception_msg-input_error.
    ENDIF.

    yo_structdescr ?= cl_abap_typedescr=>describe_by_data( <sap_struct> ).

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = DATA(lt_salv_table)
          CHANGING  t_table      = <sap_table>
        ).

        yt_fcat = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
          r_columns      = lt_salv_table->get_columns( )
          r_aggregations = lt_salv_table->get_aggregations( )
        ).

      CATCH cx_ai_system_fault INTO DATA(lx_ai_system_fault).
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING errortext = tc_exception_msg-unable_def_struct.

      CATCH cx_salv_msg INTO DATA(lx_salv_msg).
        lv_except_msg = lx_salv_msg->get_text( ).
        RAISE EXCEPTION TYPE cx_ai_system_fault
          EXPORTING errortext = tc_exception_msg-unable_def_struct.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.


*--------------------------------------------------------------------*
* FORMS
*--------------------------------------------------------------------*

FORM initialize_dynamic_alv.
  CLEAR: gt_alv_config, gt_field_config, go_current_alv, go_event_handler.
ENDFORM.

FORM call_alv_screen USING iv_dynnr    TYPE sy-dynnr
                           ir_data_ref TYPE REF TO data.
  ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<config>).
  IF sy-subrc EQ 0.
    <config>-data_table_ref = ir_data_ref.
  ENDIF.
  CALL SCREEN iv_dynnr.
ENDFORM.

*& Hook: implementa nel programma chiamante
*FORM handle_custom_command USING iv_command TYPE sy-ucomm.
*ENDFORM.
*
*FORM handle_dynamic_hotspot
*  USING is_row_id    TYPE lvc_s_row
*        is_column_id TYPE lvc_s_col
*        is_row_no    TYPE lvc_s_roid.
*ENDFORM.
*
*FORM handle_dynamic_data_changed
*  CHANGING yr_data_changed TYPE REF TO cl_alv_changed_data_protocol.
*ENDFORM.