*&---------------------------------------------------------------------*
*& Include          ZAG_INCLUDE_DYNAMIC
*&---------------------------------------------------------------------*

CLASS lcl_alv_event_dynamic DEFINITION DEFERRED.

*--------------------------------------------------------------------*
* TYPES
*--------------------------------------------------------------------*
TYPES: BEGIN OF ts_alv_config,
         dynnr          TYPE sy-dynnr,
         container_name TYPE scrfname,
         structure_name TYPE dd02l-tabname,
         data_table_ref TYPE REF TO data,
         alv_grid_ref   TYPE REF TO cl_gui_alv_grid,
         container_ref  TYPE REF TO cl_gui_custom_container,
         title_key      TYPE string,
         pf_status      TYPE string,
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
        IMPORTING e_row_id e_column_id es_row_no.
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
      register_alv
        IMPORTING iv_dynnr     TYPE sy-dynnr
                  iv_container TYPE scrfname
                  iv_structure TYPE dd02l-tabname
                  iv_title     TYPE string OPTIONAL
                  iv_pf_status TYPE string OPTIONAL,

      add_field_config
        IMPORTING is_field_config TYPE ts_field_config,

      get_alv_config
        IMPORTING iv_dynnr         TYPE sy-dynnr
        RETURNING VALUE(rs_config) TYPE ts_alv_config,

      get_alv_ref
        IMPORTING iv_dynnr       TYPE sy-dynnr
        RETURNING VALUE(ro_alv)  TYPE REF TO cl_gui_alv_grid,

      set_screen_properties.
ENDCLASS.

*--------------------------------------------------------------------*
* IMPLEMENTATIONS
*--------------------------------------------------------------------*

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

  METHOD get_alv_config.
    READ TABLE gt_alv_config INTO rs_config WITH KEY dynnr = iv_dynnr.
  ENDMETHOD.

  METHOD get_alv_ref.
    READ TABLE gt_alv_config INTO DATA(ls_config) WITH KEY dynnr = iv_dynnr.
    CHECK sy-subrc EQ 0.
    ro_alv = ls_config-alv_grid_ref.
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


CLASS lcl_alv_factory IMPLEMENTATION.

  METHOD create_alv.
    DATA(ls_config) = lcl_config_manager=>get_alv_config( iv_dynnr ).

    " Crea container
    DATA(lo_container) = NEW cl_gui_custom_container(
      container_name = ls_config-container_name
    ).

    " Crea ALV
    ro_alv = NEW cl_gui_alv_grid( i_parent = lo_container ).

    " Fieldcat e layout
    DATA(lt_fcat)   = build_fieldcat( iv_dynnr     = iv_dynnr
                                      iv_structure = ls_config-structure_name ).
    DATA(ls_layout) = setup_layout( ls_config-data_table_ref ).

    FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE.
    ASSIGN ls_config-data_table_ref->* TO <lt_table>.

    ro_alv->set_table_for_first_display(
      EXPORTING
        i_buffer_active = 'X'
        i_save          = 'A'
        is_layout       = ls_layout
      CHANGING
        it_outtab       = <lt_table>
        it_fieldcatalog = lt_fcat
    ).

    " Salva le reference nella config
    ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<cfg>).
    IF sy-subrc EQ 0.
      <cfg>-alv_grid_ref  = ro_alv.
      <cfg>-container_ref = lo_container.
    ENDIF.

    " Aggiorna il puntatore globale e registra eventi
    go_current_alv = ro_alv.
    register_events( ro_alv ).

  ENDMETHOD.

  METHOD build_fieldcat.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name = iv_structure
      CHANGING
        ct_fieldcat      = rt_fcat.

    apply_field_config( EXPORTING iv_dynnr = iv_dynnr
                        CHANGING  ct_fcat  = rt_fcat ).
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
    ENDLOOP.
  ENDMETHOD.

  METHOD setup_layout.
    rs_layout-zebra      = 'X'.
    rs_layout-sel_mode   = 'A'.
    rs_layout-cwidth_opt = 'X'.

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
  ENDMETHOD.

ENDCLASS.


CLASS lcl_alv_event_dynamic IMPLEMENTATION.

  METHOD handle_user_command.
    CASE e_ucomm.
      WHEN '&REFRESH'.
        CHECK go_current_alv IS BOUND.
        go_current_alv->refresh_table_display( ).
      WHEN OTHERS.
        PERFORM handle_custom_command USING e_ucomm.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_toolbar.
    PERFORM build_dynamic_toolbar CHANGING e_object.
  ENDMETHOD.

  METHOD handle_hotspot_click.
    " Recupera la riga cliccata e chiama il FORM del programma chiamante
    PERFORM handle_dynamic_hotspot USING e_row_id e_column_id es_row_no.
  ENDMETHOD.

ENDCLASS.

*--------------------------------------------------------------------*
* FORMS
*--------------------------------------------------------------------*

FORM initialize_dynamic_alv.
  CLEAR: gt_alv_config, gt_field_config, go_current_alv, go_event_handler.
ENDFORM.

" Prepara la config e apre lo screen.
" La creazione fisica dell'ALV avviene nel PBO tramite lcl_alv_factory=>create_alv.
FORM call_alv_screen USING iv_dynnr    TYPE sy-dynnr
                           ir_data_ref TYPE REF TO data.

  ASSIGN gt_alv_config[ dynnr = iv_dynnr ] TO FIELD-SYMBOL(<config>).
  IF sy-subrc EQ 0.
    <config>-data_table_ref = ir_data_ref.
  ENDIF.

  CALL SCREEN iv_dynnr.
ENDFORM.

" Hook: logica custom per user command (implementa nel programma chiamante)
FORM handle_custom_command USING iv_command TYPE sy-ucomm.
ENDFORM.

" Hook: toolbar custom (implementa nel programma chiamante)
FORM build_dynamic_toolbar CHANGING co_object TYPE REF TO cl_alv_event_toolbar_set.
ENDFORM.

" Hook: hotspot click (implementa nel programma chiamante)
" Usa e_row_id-index per leggere la riga dalla tua tabella dati
FORM handle_dynamic_hotspot USING is_row_id    TYPE lvc_s_row
                                  is_column_id TYPE lvc_s_col
                                  is_row_no    TYPE lvc_s_roid.
ENDFORM.