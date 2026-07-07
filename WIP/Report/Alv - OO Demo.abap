*&---------------------------------------------------------------------*
*& Report Z_TEST_ALV_DYNAMIC
*&---------------------------------------------------------------------*
REPORT z_test_alv_dynamic.

INCLUDE zag_include.   " <-- aggiornato

*--------------------------------------------------------------------*
* STRUTTURA DATI
*--------------------------------------------------------------------*
TYPES: BEGIN OF ts_mara_alv.
TYPES: matnr TYPE mara-matnr,
       mtart TYPE mara-mtart,
       mbrsh TYPE mara-mbrsh,
       ferth TYPE mara-ferth.
TYPES: icon  TYPE icon_d,
       c_col TYPE lvc_t_scol,
       c_sty TYPE lvc_t_styl.
TYPES: END OF ts_mara_alv.

*--------------------------------------------------------------------*
* DATI GLOBALI
*--------------------------------------------------------------------*
DATA: gt_mara         TYPE TABLE OF ts_mara_alv,
      gv_command_0100 TYPE sy-ucomm,
      go_alv_0100     TYPE REF TO cl_gui_alv_grid.

CONSTANTS: c_dynnr_0100 TYPE sy-dynnr VALUE '0100'.

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT matnr, mtart, mbrsh, ferth
    FROM mara
    INTO CORRESPONDING FIELDS OF TABLE @gt_mara
    UP TO 100 ROWS.

  " Stili e colori iniziali
  LOOP AT gt_mara ASSIGNING FIELD-SYMBOL(<row>).
    <row>-icon = lcl_alv_utils=>tc_icon-green.

    lcl_alv_utils=>set_cell_editable(
      EXPORTING iv_fieldname = 'MTART'
      CHANGING  ct_sty       = <row>-c_sty ).

    lcl_alv_utils=>set_cell_readonly(
      EXPORTING iv_fieldname = 'MBRSH'
      CHANGING  ct_sty       = <row>-c_sty ).

    IF <row>-mtart = 'FERT'.
      lcl_alv_utils=>set_row_color(
        EXPORTING iv_color = lcl_alv_utils=>tc_cell_col-yell
        CHANGING  ct_col   = <row>-c_col ).
    ENDIF.
  ENDLOOP.

  PERFORM initialize_dynamic_alv.

  lcl_config_manager=>register_alv(
    iv_dynnr     = c_dynnr_0100
    iv_container = 'CONTAINER_0100'
    iv_structure = ''              " struttura custom: fieldcat da runtime
    iv_pf_status = 'ZPF_GENERIC'
    iv_title     = 'ZTIT_0100'
  ).

  " Configurazione campi
  lcl_config_manager=>add_field_config( VALUE #(
    dynnr      = c_dynnr_0100
    fieldname  = 'MATNR'
    hotspot    = abap_true
    scrtext_s  = 'Mat.'
    scrtext_m  = 'Materiale'
    scrtext_l  = 'N. Materiale'
  ) ).
  lcl_config_manager=>add_field_config( VALUE #(
    dynnr      = c_dynnr_0100
    fieldname  = 'ICON'
    icon_field = abap_true
    scrtext_s  = ''
    scrtext_m  = ''
    scrtext_l  = ''
  ) ).
  " Nascondi campi tecnici ALV
  lcl_config_manager=>add_field_config( VALUE #(
    dynnr      = c_dynnr_0100
    fieldname  = 'C_COL'
    hide_field = abap_true
  ) ).
  lcl_config_manager=>add_field_config( VALUE #(
    dynnr      = c_dynnr_0100
    fieldname  = 'C_STY'
    hide_field = abap_true
  ) ).

  " Bottoni toolbar custom — sostituisce FORM build_dynamic_toolbar
  lcl_config_manager=>add_toolbar_button(
    iv_dynnr  = c_dynnr_0100
    is_button = VALUE #( butn_type = '3' )          " separatore
  ).
  lcl_config_manager=>add_toolbar_button(
    iv_dynnr  = c_dynnr_0100
    is_button = VALUE #(
      function  = 'ZSAVE'
      icon      = lcl_alv_utils=>tc_icon-save
      text      = 'Salva'
      quickinfo = 'Salva modifiche'
      butn_type = '0'
    )
  ).
  lcl_config_manager=>add_toolbar_button(
    iv_dynnr  = c_dynnr_0100
    is_button = VALUE #(
      function  = 'ZDETAIL'
      icon      = lcl_alv_utils=>tc_icon-info
      text      = 'Dettaglio'
      quickinfo = 'Mostra dettaglio riga'
      butn_type = '0'
    )
  ).

  " Passa dati e apri screen
  DATA lr_data TYPE REF TO data.
  GET REFERENCE OF gt_mara INTO lr_data.
  PERFORM call_alv_screen USING c_dynnr_0100 lr_data.

*--------------------------------------------------------------------*
* PBO - SCREEN 0100
*--------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  lcl_config_manager=>set_screen_properties( ).
  go_alv_0100 = lcl_alv_factory=>get_or_create_alv( c_dynnr_0100 ).
ENDMODULE.

*--------------------------------------------------------------------*
* PAI - SCREEN 0100
*--------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA lv_command TYPE sy-ucomm.
  lv_command = gv_command_0100.
  CLEAR gv_command_0100.

  CASE lv_command.
    WHEN 'BACK' OR '&F03'.
      CHECK lcl_alv_utils=>confirm_unsaved_changes( c_dynnr_0100 ) = abap_true.
      LEAVE TO SCREEN 0.

    WHEN 'EXIT' OR 'CANC' OR '&F15' OR '&F12'.
      LEAVE PROGRAM.

    WHEN 'ZSAVE'.
      PERFORM save_data.

  ENDCASE.
ENDMODULE.

*--------------------------------------------------------------------*
* HOOK: user command
*--------------------------------------------------------------------*
FORM handle_custom_command
  USING iv_command       TYPE sy-ucomm
        it_selected_rows TYPE lvc_t_row.

  CASE iv_command.
    WHEN 'ZSAVE'.
      PERFORM save_data.
    WHEN 'ZDETAIL'.
      PERFORM show_detail USING it_selected_rows.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.

*--------------------------------------------------------------------*
* HOOK: hotspot click
*--------------------------------------------------------------------*
FORM handle_dynamic_hotspot
  USING is_row_id    TYPE lvc_s_row
        is_column_id TYPE lvc_s_col
        is_row_no    TYPE lvc_s_roid.

  READ TABLE gt_mara INDEX is_row_id-index INTO DATA(ls_mara).
  CHECK sy-subrc EQ 0.

  CASE is_column_id-fieldname.
    WHEN 'MATNR'.
      MESSAGE |Materiale: { ls_mara-matnr } — Tipo: { ls_mara-mtart }| TYPE 'I'.
*     SET PARAMETER ID 'MAT' FIELD ls_mara-matnr.
*     CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.

*--------------------------------------------------------------------*
* HOOK: data changed — validazioni
*--------------------------------------------------------------------*
FORM handle_dynamic_data_changed
  CHANGING yr_data_changed TYPE REF TO cl_alv_changed_data_protocol.

  LOOP AT yr_data_changed->mt_good_cells ASSIGNING FIELD-SYMBOL(<cell>).
    CASE <cell>-fieldname.
      WHEN 'MTART'.
        IF <cell>-value IS INITIAL.
          yr_data_changed->add_protocol_entry(
            i_msgid     = 'M3'
            i_msgno     = '305'
            i_msgty     = 'E'
            i_fieldname = 'MTART'
          ).
        ENDIF.
    ENDCASE.
  ENDLOOP.

ENDFORM.

*--------------------------------------------------------------------*
* SALVATAGGIO
*--------------------------------------------------------------------*
FORM save_data.
  CHECK go_alv_0100 IS BOUND.

  go_alv_0100->check_changed_data( ).

  LOOP AT gt_mara ASSIGNING FIELD-SYMBOL(<row>).
*   UPDATE mara SET mtart = <row>-mtart WHERE matnr = <row>-matnr.
  ENDLOOP.

  lcl_config_manager=>clear_changed_data( c_dynnr_0100 ).
  MESSAGE 'Dati salvati' TYPE 'S'.
ENDFORM.

*--------------------------------------------------------------------*
* DETTAGLIO RIGA
*--------------------------------------------------------------------*
FORM show_detail USING it_selected_rows TYPE lvc_t_row.
  IF it_selected_rows IS INITIAL.
    MESSAGE 'Seleziona almeno una riga' TYPE 'I'.
    RETURN.
  ENDIF.

  READ TABLE gt_mara INDEX it_selected_rows[ 1 ]-index INTO DATA(ls_mara).
  CHECK sy-subrc EQ 0.

  MESSAGE s646(db) WITH 'Riga selezionata'.
ENDFORM.