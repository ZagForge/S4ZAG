*&---------------------------------------------------------------------*
*& Report ZAG_ALV_SPLITTER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zag_alv_splitter.

*  MODULE status_0100.
*  MODULE object_creation.
*  MODULE event_registration.
*  MODULE processing_output.

"TOP
"-- ALV

TYPES: BEGIN OF ty_fcode_list,
         fcode TYPE sy-ucomm,
         fname TYPE tabname,
       END OF ty_fcode_list.

DATA: gt_fcode_list TYPE TABLE OF ty_fcode_list,
      ok_code       TYPE sy-ucomm.

DATA: ref_split TYPE REF TO cl_gui_splitter_container,
      ref_cust  TYPE REF TO cl_gui_custom_container,
      ref_alv1  TYPE REF TO cl_gui_alv_grid,
      ref_alv2  TYPE REF TO cl_gui_alv_grid,
      ref_cont1 TYPE REF TO cl_gui_container,
      ref_cont2 TYPE REF TO cl_gui_container,
      ref_tree  TYPE REF TO cl_simple_tree_model.


CONSTANTS: c_x              VALUE 'X',
           c_e              VALUE 'E',
           c_yes            VALUE '1',
           c_no             VALUE '0',
           c_icon_green     TYPE icon_d   VALUE '@5B@',
           c_icon_red       TYPE icon_d   VALUE '@5C@',
           c_icon_yell      TYPE icon_d   VALUE '@5D@',
           c_icon_info      TYPE icon_d   VALUE '@0S@',
           c_icon_miss      TYPE icon_d   VALUE '@D7@',
           c_icon_exec      TYPE icon_d   VALUE '@15@',
           c_icon_refr      TYPE icon_d   VALUE '@42@',
           c_icon_save      TYPE icon_d   VALUE '@2L@',
           c_cell_col_green TYPE lvc_col  VALUE '5',
           c_cell_col_yell  TYPE lvc_col  VALUE '3',
           c_cell_col_red   TYPE lvc_col  VALUE '6',
           c_cell_col_oran  TYPE lvc_col  VALUE '7',
           c_cell_col_null  TYPE lvc_col  VALUE '2'.

"CLASS
*----------------------------------------------------------------------
* CLASS cl_event_toolbar DEFINITION
*----------------------------------------------------------------------
CLASS lcl_event_toolbar DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object
                  e_interactive,

      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.

ENDCLASS.                    "lcl_event_toolbar DEFINITION

CLASS lcl_event_toolbar IMPLEMENTATION.

  METHOD handle_toolbar.

    DATA: lw_toolbar TYPE stb_button.

    "BTN
    CLEAR lw_toolbar.
    lw_toolbar-function  = '&FCODE1'.
    lw_toolbar-icon      = c_icon_exec.
    lw_toolbar-butn_type = '0'.
    lw_toolbar-text      = 'FCODE1'.
    lw_toolbar-quickinfo = 'FCODE1'.
    APPEND lw_toolbar TO e_object->mt_toolbar.

    CLEAR lw_toolbar.
    lw_toolbar-function  = '&FCODE2'.
    lw_toolbar-icon      = c_icon_exec.
    lw_toolbar-butn_type = '0'.
    lw_toolbar-text      = 'FCODE2'.
    lw_toolbar-quickinfo = 'FCODE2'.
    APPEND lw_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.                    "handle_toolbar
  METHOD handle_user_command.

    DATA: lt_selected_rows TYPE lvc_t_row.

    REFRESH lt_selected_rows.
    CALL METHOD ref_alv2->get_selected_rows
      IMPORTING
        et_index_rows = lt_selected_rows.
    IF lt_selected_rows[] IS INITIAL.

      MESSAGE s000(db) WITH 'Selezionare almeno una riga'
                                  DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    CASE e_ucomm.
      WHEN '&FCODE1'.

      WHEN '&FCODE2'.

      WHEN OTHERS.
    ENDCASE.

    CALL METHOD ref_alv2->refresh_table_display.

  ENDMETHOD.                    "handle_user_command

ENDCLASS.                    "lcl_event_toolbar IMPLEMENTATION

DATA: alv_handler   TYPE REF TO lcl_event_toolbar.

CLASS lcl_event_handler DEFINITION.

  PUBLIC SECTION.

    METHODS: node_dc FOR EVENT node_double_click OF cl_simple_tree_model
      IMPORTING node_key sender.

ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD: node_dc.

    DATA: lt_children TYPE tm_nodekey,
          v_so        TYPE vbeln,
          v_item      TYPE posnr.

    DATA: ls_layout TYPE lvc_s_layo.

    CALL METHOD sender->node_get_last_child
      EXPORTING
        node_key       = node_key
      IMPORTING
        child_node_key = lt_children.

    CASE node_key.
      WHEN '&NODE1'.

        SELECT * UP TO 5 ROWS FROM anla INTO TABLE @DATA(lt_anla).
        ls_layout-grid_title = TEXT-002.
        ls_layout-zebra      = 'X'.
        ls_layout-smalltitle = ''.
        ls_layout-cwidth_opt = 'X'.

        CREATE OBJECT alv_handler.
        SET HANDLER alv_handler->handle_user_command    FOR ref_alv2.
        SET HANDLER alv_handler->handle_toolbar         FOR ref_alv2.

        CALL METHOD ref_alv2->set_table_for_first_display
          EXPORTING
            i_structure_name = 'ANLA'
            is_layout        = ls_layout
          CHANGING
            it_outtab        = lt_anla.

        CALL METHOD ref_alv2->refresh_table_display.

      WHEN '&NODE2'.

        SELECT * UP TO 5 ROWS FROM sflight INTO TABLE @DATA(lt_sflight).

        ls_layout-grid_title = TEXT-002.
        ls_layout-zebra      = 'X'.
        ls_layout-smalltitle = ''.
        ls_layout-cwidth_opt = 'X'.


        CALL METHOD ref_alv2->set_table_for_first_display
          EXPORTING
            i_structure_name = 'SFLIGHT'
            is_layout        = ls_layout
          CHANGING
            it_outtab        = lt_sflight.

        CALL METHOD ref_alv2->refresh_table_display.

      WHEN '&NODE3'.

      WHEN '&NODE4'.

      WHEN '&NODE5'.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       Default PBO module
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZPF_GENERIC'.
* SET TITLEBAR 'xxx'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  OBJECT_CREATION  OUTPUT
*&---------------------------------------------------------------------*
*       Object Creation for Classes
*----------------------------------------------------------------------*
MODULE object_creation OUTPUT.

  CREATE OBJECT ref_cust
    EXPORTING
      container_name = 'SPLIT_CONT'.

  CREATE OBJECT ref_split
    EXPORTING
      parent  = ref_cust
      rows    = 1
      columns = 2.

  CALL METHOD ref_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = ref_cont1.

  CALL METHOD ref_split->set_column_width
    EXPORTING
      id    = 1
      width = 22.


  CALL METHOD ref_split->get_container
    EXPORTING
      row       = 1
      column    = 2
    RECEIVING
      container = ref_cont2.

  CREATE OBJECT ref_tree
    EXPORTING
      node_selection_mode = cl_simple_tree_model=>node_sel_mode_single.

  CALL METHOD ref_tree->create_tree_control
    EXPORTING
      parent = ref_cont1.


  CREATE OBJECT ref_alv2
    EXPORTING
      i_parent = ref_cont2.

ENDMODULE.                 " OBJECT_CREATION  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  EVENT_REGISTRATION  OUTPUT
*&---------------------------------------------------------------------*
*       Double Click Event Registration
*----------------------------------------------------------------------*
MODULE event_registration OUTPUT.
  DATA: lt_events TYPE cntl_simple_events,
        ls_event  TYPE cntl_simple_event.

  DATA: event_handler TYPE REF TO lcl_event_handler.

  CALL METHOD ref_tree->get_registered_events
    IMPORTING
      events = lt_events.

  ls_event-eventid = cl_simple_tree_model=>eventid_node_double_click.
  APPEND ls_event TO lt_events.

  CALL METHOD ref_tree->set_registered_events
    EXPORTING
      events = lt_events.

  CREATE OBJECT event_handler.
  SET HANDLER event_handler->node_dc FOR ref_tree.

ENDMODULE.                 " EVENT_REGISTRATION  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PROCESSING_OUTPUT  OUTPUT
*&---------------------------------------------------------------------*
*       Processing Output of the Table
*----------------------------------------------------------------------*
MODULE processing_output OUTPUT.

  DATA: ls_node TYPE treemsnodt.

  CALL METHOD ref_tree->add_node
    EXPORTING
      node_key = 'ROOT'
      isfolder = 'X'
      text     = 'Main'
      expander = 'X'.

  LOOP AT gt_fcode_list ASSIGNING FIELD-SYMBOL(<fcode>).

    ls_node-node_key = <fcode>-fcode.
    ls_node-text     = <fcode>-fname.

    CALL METHOD ref_tree->add_node
      EXPORTING
        node_key          = ls_node-node_key
        relative_node_key = 'ROOT'
        relationship      = cl_simple_tree_model=>relat_last_child
        isfolder          = 'X'
        text              = ls_node-text.
*        expander          = 'X'.

  ENDLOOP.

ENDMODULE.                 " PROCESSING_OUTPUT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN '&F03'
      OR 'BACK'.

      LEAVE TO SCREEN 0.

    WHEN '&F12'
      OR '&F15'
      OR 'CANC'
      OR 'EXIT'.
      LEAVE PROGRAM.

    WHEN 'PICK'.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT




*&---------------------------------------------------------------------*
*&                   Selection Screen
*&---------------------------------------------------------------------*
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
*SELECT-OPTIONS: s_vbeln FOR vbak-vbeln, "Document Number
*                s_audat FOR vbak-audat, "Document Date
*                s_ernam FOR vbak-ernam. "Name who Created the Object
SELECTION-SCREEN: END OF BLOCK b1.
*&---------------------------------------------------------------------*
*&                   Start Of Selection
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  DATA: ls_fcode_list TYPE ty_fcode_list.
  REFRESH gt_fcode_list[].

  ls_fcode_list-fcode = '&NODE1'.
  ls_fcode_list-fname = 'Nodo 1'.
  APPEND ls_fcode_list TO gt_fcode_list.

  ls_fcode_list-fcode = '&NODE2'.
  ls_fcode_list-fname = 'Nodo 2'.
  APPEND ls_fcode_list TO gt_fcode_list.

  ls_fcode_list-fcode = '&NODE3'.
  ls_fcode_list-fname = 'Nodo 3'.
  APPEND ls_fcode_list TO gt_fcode_list.

  ls_fcode_list-fcode = '&NODE4'.
  ls_fcode_list-fname = 'Nodo 4'.
  APPEND ls_fcode_list TO gt_fcode_list.

  ls_fcode_list-fcode = '&NODE5'.
  ls_fcode_list-fname = 'Nodo 5'.
  APPEND ls_fcode_list TO gt_fcode_list.


  CALL SCREEN 0100.
