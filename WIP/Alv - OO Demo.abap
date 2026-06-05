*&---------------------------------------------------------------------*
*& Report Z_TEST_ALV_DYNAMIC
*&---------------------------------------------------------------------*
REPORT z_test_alv_dynamic.

INCLUDE zag_include.

*--------------------------------------------------------------------*
* DATI GLOBALI
*--------------------------------------------------------------------*
DATA: gt_mara         TYPE TABLE OF mara,
      gv_command_0100 TYPE sy-ucomm,
      go_alv_0100     TYPE REF TO cl_gui_alv_grid.

CONSTANTS: c_dynnr_0100 TYPE sy-dynnr VALUE '0100'.

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT * FROM mara INTO TABLE @gt_mara UP TO 100 ROWS.

  " Inizializza il framework
  PERFORM initialize_dynamic_alv.

  " Registra l'ALV per lo screen 0100
  lcl_config_manager=>register_alv(
    iv_dynnr      = c_dynnr_0100
    iv_container  = 'CONTAINER_0100'
    iv_structure  = 'MARA'
    iv_pf_status  = 'ZPF_GENERIC'
    iv_title      = 'ZTIT_0100'
  ).

  " Configura MATNR come hotspot
  lcl_config_manager=>add_field_config( VALUE #(
    dynnr     = c_dynnr_0100
    fieldname = 'MATNR'
    hotspot   = abap_true
    scrtext_s = 'Materiale'
    scrtext_m = 'Materiale'
    scrtext_l = 'Numero Materiale'
  ) ).

  " Passa i dati e apre lo screen
  DATA lr_data TYPE REF TO data.
  GET REFERENCE OF gt_mara INTO lr_data.
  PERFORM call_alv_screen USING c_dynnr_0100 lr_data.

*--------------------------------------------------------------------*
* PBO - SCREEN 0100
*--------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  lcl_config_manager=>set_screen_properties( ).

  " Crea l'ALV solo al primo PBO (quando il container è già attivo)
  go_alv_0100 = lcl_config_manager=>get_alv_ref( c_dynnr_0100 ).
  IF go_alv_0100 IS NOT BOUND.
    go_alv_0100 = lcl_alv_factory=>create_alv( c_dynnr_0100 ).
  ENDIF.
ENDMODULE.

*--------------------------------------------------------------------*
* PAI - SCREEN 0100
*--------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA lv_command TYPE sy-ucomm.
  lv_command = gv_command_0100.
  CLEAR gv_command_0100.

  CASE lv_command.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'
      OR '&F03' OR '&F12' OR '&F15'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM save_data.
  ENDCASE.
ENDMODULE.

*--------------------------------------------------------------------*
* IMPLEMENTAZIONE HOOK: hotspot click
* Viene chiamato dall'include quando l'utente clicca su MATNR
*--------------------------------------------------------------------*
FORM handle_dynamic_hotspot USING is_row_id    TYPE lvc_s_row
                                  is_column_id TYPE lvc_s_col
                                  is_row_no    TYPE lvc_s_roid.

  " is_row_id-index = indice riga nella tabella visualizzata
  DATA lv_index TYPE i.
  lv_index = is_row_id-index.

  " Leggi la riga dalla tabella dati
  READ TABLE gt_mara INDEX lv_index INTO DATA(ls_mara).
  CHECK sy-subrc EQ 0.

  " Mostra campo cliccato e riga
  DATA lv_msg TYPE string.
  lv_msg = |Hotspot su colonna: { is_column_id-fieldname } | &&
           |— Materiale: { ls_mara-matnr } | &&
           |— Tipo: { ls_mara-mtart }|.

  MESSAGE lv_msg TYPE 'I'.

  " Esempio: potresti aprire un dettaglio, navigare a MM03, ecc.
  " CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.

ENDFORM.

*--------------------------------------------------------------------*
* IMPLEMENTAZIONE HOOK: user command custom
*--------------------------------------------------------------------*
FORM handle_custom_command USING iv_command TYPE sy-ucomm.
  " Aggiungi qui la gestione di pulsanti custom della toolbar
  CASE iv_command.
    WHEN 'ZDETAIL'.
      MESSAGE 'Funzione dettaglio non ancora implementata' TYPE 'I'.
  ENDCASE.
ENDFORM.

*--------------------------------------------------------------------*
* IMPLEMENTAZIONE HOOK: toolbar custom
*--------------------------------------------------------------------*
FORM build_dynamic_toolbar CHANGING co_object TYPE REF TO cl_alv_event_toolbar_set.
  " Esempio: aggiunge un pulsante custom alla toolbar
  DATA ls_button TYPE stb_button.

  ls_button-function  = 'ZDETAIL'.
  ls_button-icon      = '@17@'.   " icona dettaglio
  ls_button-quickinfo = 'Dettaglio materiale'.
  ls_button-text      = 'Dettaglio'.
  ls_button-disabled  = space.

  APPEND ls_button TO co_object->mt_toolbar.
ENDFORM.

*--------------------------------------------------------------------*
* SALVATAGGIO DATI
*--------------------------------------------------------------------*
FORM save_data.
  CHECK go_alv_0100 IS BOUND.
  go_alv_0100->check_changed_data( ).
  " ... logica di salvataggio su gt_mara ...
  MESSAGE 'Dati salvati' TYPE 'S'.
  go_alv_0100->refresh_table_display( ).
ENDFORM.

*--------------------------------------------------------------------*
* NOTE PER SE51 - SCREEN 0100
*--------------------------------------------------------------------*
* 1. Crea screen 0100 in SE51
* 2. Aggiungi Custom Container: CONTAINER_0100
* 3. Flow Logic:
*    PROCESS BEFORE OUTPUT.
*      MODULE status_0100.
*    PROCESS AFTER INPUT.
*      MODULE user_command_0100.
* 4. OK_CODE = GV_COMMAND_0100
* 5. PF-STATUS 'ZPF_GENERIC': BACK(F3), EXIT(F15), CANC(F12), SAVE(Ctrl+S)
* 6. TITLEBAR 'ZTIT_0100'
*--------------------------------------------------------------------*