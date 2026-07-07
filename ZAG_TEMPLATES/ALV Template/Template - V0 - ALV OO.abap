*&---------------------------------------------------------------------*
*& Include          ZAG_INCLUDE
*&---------------------------------------------------------------------*
**********************************************************************
***************************  README   ********************************

"Mandatory Activities
*--------------------------------------------------------------------*
*) EACH CALLL SCREEN MUST BE CALLED IN THE FOLLOWING WAY, OTHERWISE THE TEMPLATE WILL NOT WORK!
"     PERFORM call_screen USING screen_number

*) "TEMPLATE-DDIC
"   Adapt the marked points with your own DDIC

*) "TEMPLATE-PF_TITLE
"  Create PF-STATUS called ZPF_GENERIC already set as default for dynpro into the template
"  Create PF-STATUS and TITLEBAR for your dynpro into the marked points if you want specific commands

*) "TEMPLATE-PAI_COMMAND
"   Adapt PAI user command module of each created dynpro
"   If you are using ZPF_GENERIC, use module USER_COMMAND_GENERIC with GV_GENERIC_COMM variable to handle command


"Optional Activities
*--------------------------------------------------------------------*
*) "TEMPLATE-FIELDCAT
"   Set Fieldcat, if you need, into marked points

*) "TEMPLATE-LAYOUT
"   Set the layout, if you need, into marked points

*) "TEMPLATE-SORT
"   Set the Sort-Options and Sub-Totals, if you need, into marked points

*) "TEMPLATE-VARIANT
"   Set user variant, if you need, into marked points

*) "TEMPLATE-PRINT_PARAMS
"   Set Print-Params, if you need, into marked points

*) "TEMPLATE-HANDLER
"   Set your handler, if you need, into the marked points

*) "TEMPLATE-EVENT_METHOD
"   Set the handlers method implementation into the marked points

*) "TEMPLATE-CELL_COLOR
"   Set the routine for color of single cell

*) "TEMPLATE-CELL_STYLE
"   Set the routine for style of single cell

*) "TEMPLATE-TOOLBAR_EXCLUDING
"   Set the routine to exclude some buttons, if you need, into the marked points

**********************************************************************
**********************************************************************

"TOP
"--ALV

INCLUDE <cl_alv_control>.

"Types
"-------------------------------------------------
CLASS lcl_alv_event DEFINITION DEFERRED.

TYPES:
  tref_alv_grid      TYPE REF TO cl_gui_alv_grid,
  tref_container     TYPE REF TO cl_gui_custom_container,
  tref_doc_container TYPE REF TO cl_gui_docking_container,
  tref_alv_event     TYPE REF TO lcl_alv_event.

"Technical Type table used to stack the dynpro called
TYPES:
  BEGIN OF ts_stacktrace_dynnr,
    dynnr        TYPE sy-dynnr,
    dynnr_parent TYPE sy-dynnr,
    alv_grid     TYPE tref_alv_grid,
  END OF ts_stacktrace_dynnr,
  tt_stacktrace_dynnr TYPE TABLE OF ts_stacktrace_dynnr WITH DEFAULT KEY.


"Data
"-------------------------------------------------
DATA:
  go_current_alv_grid TYPE tref_alv_grid,
  go_event_handler    TYPE tref_alv_event,

  gt_stacktrace_dynnr TYPE TABLE OF ts_stacktrace_dynnr WITH DEFAULT KEY,
  gt_changed_data     TYPE lvc_t_modi,
  gt_deleted_data     TYPE lvc_t_moce,
  gt_inserted_data    TYPE lvc_t_moce,
  gt_toolbar          TYPE ttb_button,
  gv_generic_comm     TYPE sy-ucomm,
  gv_tmp_comm         TYPE sy-ucomm.

CONSTANTS:
  c_yes VALUE '1',
  c_no  VALUE '0'.

CONSTANTS:
  BEGIN OF tc_icon,
    green TYPE icon_d   VALUE '@5B@',
    red   TYPE icon_d   VALUE '@5C@',
    yell  TYPE icon_d   VALUE '@5D@',
    info  TYPE icon_d   VALUE '@0S@',
    miss  TYPE icon_d   VALUE '@D7@',
    exec  TYPE icon_d   VALUE '@15@',
    refr  TYPE icon_d   VALUE '@42@',
    save  TYPE icon_d   VALUE '@2L@',
  END OF tc_icon,

  BEGIN OF tc_cell_col,
    green TYPE lvc_col  VALUE '5',
    yell  TYPE lvc_col  VALUE '3',
    red   TYPE lvc_col  VALUE '6',
    oran  TYPE lvc_col  VALUE '7',
    null  TYPE lvc_col  VALUE '2',
  END OF tc_cell_col.

*--------------------------------------------------------------------*


"ALV SCREEN 100
*--------------------------------------------------------------------*
"Structure ALV screen 100 + Type Table
*--------------------------------------------------------------------*
TYPES: BEGIN OF ts_alv_0100.
         INCLUDE STRUCTURE t001. "TEMPLATE-DDIC
         TYPES: icon  TYPE icon_d,
         msg   TYPE bapi_msg,
         c_col TYPE lvc_t_scol,
         c_sty TYPE lvc_t_styl.
TYPES: END OF ts_alv_0100,
tt_alv_0100 TYPE TABLE OF ts_alv_0100 WITH DEFAULT KEY.

DATA:
  gt_alv_0100           TYPE tt_alv_0100,
  gv_ok_0100            TYPE sy-ucomm,
  go_container_0100     TYPE tref_container,
  go_alv_0100           TYPE tref_alv_grid,
  go_doc_container_0100 TYPE tref_doc_container.

CONSTANTS:
  c_container_0100 TYPE scrfname      VALUE 'CONTAINER_0100',
  c_alv_st_0100    TYPE dd02l-tabname VALUE 'T001', "TEMPLATE-DDIC
  c_dynnr_0100     TYPE sy-dynnr      VALUE '0100'.
*--------------------------------------------------------------------*


"ALV SCREEN 200
*--------------------------------------------------------------------*
"Structure ALV screen 200 + Type Table
*--------------------------------------------------------------------*
TYPES: BEGIN OF ts_alv_0200.
         INCLUDE STRUCTURE lfa1. "TEMPLATE-DDIC
         TYPES: icon TYPE icon_d,
         msg  TYPE bapi_msg.
TYPES: END OF ts_alv_0200,
tt_alv_0200 TYPE TABLE OF ts_alv_0200 WITH DEFAULT KEY.

DATA:
  gt_alv_0200           TYPE tt_alv_0200,
  gv_ok_0200            TYPE sy-ucomm,
  go_container_0200     TYPE tref_container,
  go_alv_0200           TYPE tref_alv_grid,
  go_doc_container_0200 TYPE tref_doc_container.

CONSTANTS:
  c_container_0200 TYPE scrfname      VALUE 'CONTAINER_0200',
  c_alv_st_0200    TYPE dd02l-tabname VALUE 'LFA1', "TEMPLATE-DDIC
  c_dynnr_0200     TYPE sy-dynnr      VALUE '0200'.
*--------------------------------------------------------------------*


"ALV SCREEN 300
*--------------------------------------------------------------------*
"Structure ALV screen 300 + Type Table
*--------------------------------------------------------------------*
TYPES: BEGIN OF ts_alv_0300.
         INCLUDE STRUCTURE kna1. "TEMPLATE-DDIC
         TYPES: icon TYPE icon_d,
         msg  TYPE bapi_msg.
TYPES: END OF ts_alv_0300,
tt_alv_0300 TYPE TABLE OF ts_alv_0300 WITH DEFAULT KEY.

DATA: gt_alv_0300           TYPE tt_alv_0300,
      gv_ok_0300            TYPE sy-ucomm,
      go_container_0300     TYPE tref_container,
      go_alv_0300           TYPE tref_alv_grid,
      go_doc_container_0300 TYPE tref_doc_container.

CONSTANTS:
  c_container_0300 TYPE scrfname      VALUE 'CONTAINER_0300',
  c_alv_st_0300    TYPE dd02l-tabname VALUE 'KNA1', "TEMPLATE-DDIC
  c_dynnr_0300     TYPE sy-dynnr      VALUE '0300'.
*--------------------------------------------------------------------*


"CLS
*----------------------------------------------------------------------
* CLASS cl_event_toolbar DEFINITION
*----------------------------------------------------------------------
CLASS lcl_alv_event DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object
                  e_interactive,

      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id
                  e_column_id
                  es_row_no,

      handle_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING
          er_data_changed.

ENDCLASS.                    "lcl_event_toolbar DEFINITION
*----------------------------------------------------------------------*
*       CLASS lcl_event_toolbar IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_alv_event IMPLEMENTATION.
  METHOD handle_toolbar.

    "TEMPLATE-EVENT_METHOD
    PERFORM handle_toolbar CHANGING e_object
                                    e_interactive.

  ENDMETHOD.                    "handle_toolbar
  METHOD handle_user_command.

    "TEMPLATE-EVENT_METHOD
    PERFORM handle_user_command USING e_ucomm.

  ENDMETHOD.                    "handle_user_command
  METHOD handle_hotspot_click.

    "TEMPLATE-EVENT_METHOD
    PERFORM handle_hotspot_click USING e_row_id
                                       e_column_id
                                       es_row_no.

  ENDMETHOD.                    "handle_hotspot_click
  METHOD handle_data_changed.

    "TEMPLATE-EVENT_METHOD
    PERFORM handle_data_changed CHANGING er_data_changed.

  ENDMETHOD.                    "handle_data_changed

ENDCLASS.                    "lcl_event_toolbar IMPLEMENTATION


*--------------------------------------------------------------------*
*--------------------------------------------------------------------*
"ALV BUILDING IMPLEMENTATION

*--------------------------------------------------------------------*
"CALL SCREEN
*--------------------------------------------------------------------*
FORM call_screen USING xv_dynnr TYPE sy-dynnr.

  ASSIGN gt_stacktrace_dynnr[ dynnr        = xv_dynnr
                              dynnr_parent = sy-dynnr ]
                            TO FIELD-SYMBOL(<stacktrace>).
  IF sy-subrc <> 0.
    APPEND VALUE #( dynnr        = xv_dynnr
                    dynnr_parent = sy-dynnr
      ) TO gt_stacktrace_dynnr.

  ENDIF.

  CALL SCREEN xv_dynnr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form UPDATE_STACKTRACE
*&---------------------------------------------------------------------*
FORM update_stacktrace  USING xv_parent_dynnr  TYPE sy-dynnr
                              xv_calling_dynnr TYPE sy-dynnr.

  FIELD-SYMBOLS: <stacktrace> LIKE LINE OF gt_stacktrace_dynnr.

  UNASSIGN <stacktrace>.
  IF NOT line_exists( gt_stacktrace_dynnr[ dynnr        = xv_calling_dynnr
                                           dynnr_parent = xv_parent_dynnr ] ).
    APPEND VALUE #(
        dynnr        = xv_calling_dynnr
        dynnr_parent = xv_parent_dynnr
      ) TO gt_stacktrace_dynnr.

  ENDIF.

ENDFORM.                    "update_stacktrace
*&---------------------------------------------------------------------*
*&      Form  PRINT_ALV
*&---------------------------------------------------------------------*
FORM print_alv USING    xv_cont_name     TYPE scrfname
                        xv_structure     TYPE dd02l-tabname
               CHANGING yt_table         TYPE STANDARD TABLE
                        yo_container     TYPE tref_container
                        yo_alv_ref       TYPE tref_alv_grid
                        yo_doc_container TYPE tref_doc_container.

  DATA:
    lt_fcat              TYPE lvc_t_fcat,
    ls_layout            TYPE lvc_s_layo,
    lt_sort              TYPE lvc_t_sort,
    ls_variant           TYPE disvariant,
    ls_print             TYPE lvc_s_prnt,
    lt_toolbar_excluding TYPE ui_functions.


  PERFORM init_container           USING    xv_cont_name
                                   CHANGING yo_container
                                            yo_alv_ref
                                            yo_doc_container.

  PERFORM init_fieldcat            USING    xv_structure
                                   CHANGING lt_fcat[].

  PERFORM init_layout              USING    yt_table
                                   CHANGING ls_layout.

  PERFORM init_sort                CHANGING lt_sort[].
  PERFORM init_variant             CHANGING ls_variant.
  PERFORM init_print_params        CHANGING ls_print.
  PERFORM init_toolbar_excluding   CHANGING lt_toolbar_excluding.

  ASSIGN gt_stacktrace_dynnr[ dynnr = sy-dynnr ] TO FIELD-SYMBOL(<stacktrace>).
  IF sy-subrc EQ 0.
    <stacktrace>-alv_grid = yo_alv_ref.
    go_current_alv_grid   = yo_alv_ref.
  ENDIF.

  PERFORM init_handlers CHANGING yo_alv_ref.

  yo_alv_ref->set_table_for_first_display(
    EXPORTING
      i_buffer_active               = 'X'
      i_bypassing_buffer            = 'X'
      i_save                        = 'A'
      is_layout                     = ls_layout
      is_variant                    = ls_variant
      is_print                      = ls_print
      it_toolbar_excluding          = lt_toolbar_excluding
    CHANGING
      it_outtab                     = yt_table[] "<dyn_table>
      it_fieldcatalog               = lt_fcat[]
      it_sort                       = lt_sort[]
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4
  ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                    " PRINT_ALV
*&---------------------------------------------------------------------*
*&      Form  REFRESH_TABLE
*&---------------------------------------------------------------------*
FORM refresh_table CHANGING yo_ref_alv TYPE tref_alv_grid.

  DATA ls_stable TYPE lvc_s_stbl.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.

  yo_ref_alv->refresh_table_display(  is_stable      = ls_stable
                                      i_soft_refresh = 'X'
  ).

ENDFORM.                    " REFRESH_TABLE
*&---------------------------------------------------------------------*
*&      Form  INIT_CONTAINER
*&---------------------------------------------------------------------*
FORM init_container  USING    xv_cont_name     TYPE scrfname
                     CHANGING yo_container     TYPE tref_container
                              yo_alv_ref       TYPE tref_alv_grid
                              yo_doc_container TYPE tref_doc_container.


  IF yo_container IS INITIAL.
    IF cl_gui_alv_grid=>offline( ) IS INITIAL.

      yo_container = NEW cl_gui_custom_container( container_name =  xv_cont_name ).
      yo_alv_ref   = NEW cl_gui_alv_grid( i_parent = yo_container ).

    ELSE.

      "If it is in background:
      yo_alv_ref   = NEW cl_gui_alv_grid( i_parent = yo_doc_container ).

    ENDIF.

  ELSE.

    PERFORM refresh_table CHANGING yo_alv_ref.

  ENDIF.

ENDFORM.                    " INIT_CONTAINER
*&---------------------------------------------------------------------*
*&      Form  INIT_FIELDCAT
*&---------------------------------------------------------------------*
FORM init_fieldcat USING    xv_structure TYPE dd02l-tabname
                   CHANGING yt_fcat      TYPE lvc_t_fcat.

  DATA: ls_fcat TYPE lvc_s_fcat.

  FIELD-SYMBOLS: <fcat> LIKE LINE OF yt_fcat.


  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = xv_structure
    CHANGING
      ct_fieldcat            = yt_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  ls_fcat-col_opt = 'X'.
  MODIFY yt_fcat FROM ls_fcat TRANSPORTING col_opt
                                     WHERE fieldname NE 'ICON'.

  "TEMPLATE-FIELDCAT
  "TO add new fields manually
  CASE sy-dynnr.
    WHEN c_dynnr_0100.

*      UNASSIGN <fcat>.
*      APPEND INITIAL LINE TO yt_fcat ASSIGNING <fcat>.
*      <fcat>-col_pos   = '0' .
*      <fcat>-fieldname = 'ICON' .
*      <fcat>-seltext   = 'Stato' .
*      <fcat>-scrtext_l = 'Stato' .
*      <fcat>-scrtext_m = 'Stato' .
*      <fcat>-scrtext_s = 'Stato' .
*      <fcat>-key       = ' ' .
*      <fcat>-outputlen = 4.
*      <fcat>-just      = 'C'.

*      UNASSIGN <fcat>.
*      APPEND INITIAL LINE TO yt_fcat ASSIGNING <fcat>.
*      <fcat>-col_pos   = '0' .
*      <fcat>-fieldname = 'MSG' .
*      <fcat>-seltext   = 'Esito Elaborazione' .
*      <fcat>-scrtext_l = 'Esito Elaborazione' .
*      <fcat>-scrtext_m = 'Esito Elab.' .
*      <fcat>-scrtext_s = 'Esito' .
*      <fcat>-key       = ' ' .
*      <fcat>-outputlen = 40.

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

    WHEN OTHERS.
  ENDCASE.

  "TEMPLATE-FIELDCAT
  "Change properties of existing fcat fields
  LOOP AT yt_fcat ASSIGNING <fcat>.
    CASE sy-dynnr.
      WHEN c_dynnr_0100.

      WHEN c_dynnr_0200.

      WHEN c_dynnr_0300.

      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

ENDFORM.                    " INIT_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  INIT_LAYOUT
*&---------------------------------------------------------------------*
FORM init_layout  USING    xt_table  TYPE STANDARD TABLE
                  CHANGING ys_layout TYPE lvc_s_layo.

  "TEMPLATE-LAYOUT

  FIELD-SYMBOLS: <row>       TYPE any,
                 <component> TYPE any.


  ys_layout-sel_mode = 'A'.
  ys_layout-zebra    = 'X'.

  ASSIGN xt_table[ 1 ] TO <row>.
  CHECK sy-subrc EQ 0.

  ASSIGN COMPONENT 'C_COL' OF STRUCTURE <row> TO FIELD-SYMBOL(<component_color>).
  IF sy-subrc EQ 0.
    ys_layout-ctab_fname = 'C_COL'.
  ENDIF.

  ASSIGN COMPONENT 'C_STY' OF STRUCTURE <row> TO FIELD-SYMBOL(<component_style>).
  IF sy-subrc EQ 0.
    ys_layout-stylefname = 'C_STY'.
  ENDIF.

ENDFORM.                    " INIT_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  INIT_SORT
*&---------------------------------------------------------------------*
FORM init_sort  CHANGING yt_sort     TYPE lvc_t_sort.

  "TEMPLATE-SORT

  FIELD-SYMBOLS: <sort> LIKE LINE OF yt_sort.


  REFRESH yt_sort.

  CASE sy-dynnr.
    WHEN c_dynnr_0100.

*      UNASSIGN <sort>.
*      APPEND INITIAL LINE TO yt_sort ASSIGNING <sort>.
*      <sort>-spos      = 1.
*      <sort>-fieldname = 'MY_FIELD1'.
*      <sort>-subtot    = 'X'.
*
*      UNASSIGN <sort>.
*      APPEND INITIAL LINE TO yt_sort ASSIGNING <sort>.
*      <sort>-spos      = 2.
*      <sort>-fieldname = 'MY_FIELD2'.
*      <sort>-subtot    = 'X'.

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " INIT_SORT
*&---------------------------------------------------------------------*
*&      Form  INIT_VARIANT
*&---------------------------------------------------------------------*
FORM init_variant  CHANGING ys_variant TYPE disvariant.

  "TEMPLATE-VARIANT

  CLEAR ys_variant.

  CASE sy-dynnr.
    WHEN c_dynnr_0100.
      ys_variant-report   = sy-repid.
      ys_variant-username = sy-uname.

*      ys_variant-variant  = p_var.

*      IF p_var IS INITIAL.
*        ys_variant-variant = '/DEFAULT'.
*      ENDIF.

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

  ENDCASE.

ENDFORM.                    " INIT_VARIANT
*&---------------------------------------------------------------------*
*&      Form  INIT_PRINT_PARAMS
*&---------------------------------------------------------------------*
FORM init_print_params CHANGING ys_print TYPE lvc_s_prnt.

  "TEMPLATE-PRINT_PARAMS

  CLEAR ys_print.

  CASE sy-dynnr.
    WHEN c_dynnr_0100.

    WHEN c_dynnr_0200.

      IF sy-batch EQ space.
        ys_print-print = 'X'.
      ENDIF.

    WHEN c_dynnr_0300.

  ENDCASE.

ENDFORM.                    " INIT_PRINT_PARAMS
*&---------------------------------------------------------------------*
*& Form INIT_TOOLBAR_EXCLUDING
*&---------------------------------------------------------------------*
FORM init_toolbar_excluding  USING yt_toolbar_excluding TYPE ui_functions.

  "TEMPLATE-TOOLBAR_EXCLUDING

  DATA ls_exclude TYPE ui_func.

  CLEAR yt_toolbar_excluding[].

  CASE sy-dynnr.
    WHEN c_dynnr_0100.

      yt_toolbar_excluding = VALUE #(
        ( cl_gui_alv_grid=>mc_fc_loc_insert_row )
        ( cl_gui_alv_grid=>mc_fc_loc_delete_row )
        ( cl_gui_alv_grid=>mc_fc_loc_copy_row )
        ( cl_gui_alv_grid=>mc_fc_loc_paste )
        ( cl_gui_alv_grid=>mc_fc_loc_paste_new_row )
        ( cl_gui_alv_grid=>mc_fc_loc_cut )
        ( cl_gui_alv_grid=>mc_fc_loc_copy )
        ( cl_gui_alv_grid=>mc_fc_loc_copy_row )
        ( cl_gui_alv_grid=>mc_fc_loc_append_row )
        ( cl_gui_alv_grid=>mc_fc_loc_undo )
      ).

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INIT_HANDLERS
*&---------------------------------------------------------------------*
FORM init_handlers  CHANGING yo_alv_ref TYPE tref_alv_grid.

  IF sy-batch EQ space.
    IF go_current_alv_grid IS NOT INITIAL.

      "TEMPLATE-HANDLER

      yo_alv_ref->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).

      yo_alv_ref->register_edit_event(
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_modified
        EXCEPTIONS
          error      = 1
          OTHERS     = 2
      ).

      yo_alv_ref->set_ready_for_input(
        i_ready_for_input = 1
      ).

      yo_alv_ref->check_changed_data( ).

      CREATE OBJECT go_event_handler.
      SET HANDLER go_event_handler->handle_user_command    FOR yo_alv_ref.
      SET HANDLER go_event_handler->handle_toolbar         FOR yo_alv_ref.
      SET HANDLER go_event_handler->handle_hotspot_click   FOR yo_alv_ref.
      SET HANDLER go_event_handler->handle_data_changed    FOR yo_alv_ref.

    ENDIF.
  ENDIF.

ENDFORM.                    " INIT_HANDLERS
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_GENERIC  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_generic INPUT.

  DATA: lv_answer,
        lv_cur_field(20),
        lv_cur_val(100).


  gv_tmp_comm = gv_generic_comm.
  CLEAR gv_generic_comm.

  CASE gv_tmp_comm.
    WHEN '&F03'
      OR 'BACK'.

      PERFORM check_if_not_saved_data CHANGING lv_answer.
      CHECK lv_answer EQ space
         OR lv_answer EQ c_yes.

      ASSIGN gt_stacktrace_dynnr[ dynnr = sy-dynnr ] TO FIELD-SYMBOL(<stacktrace>).
      IF sy-subrc EQ 0.

        ASSIGN gt_stacktrace_dynnr[ dynnr = <stacktrace>-dynnr_parent ] TO FIELD-SYMBOL(<parent>).
        IF sy-subrc EQ 0.

          go_current_alv_grid = <parent>-alv_grid.

        ENDIF.
      ENDIF.

      LEAVE TO SCREEN 0.

    WHEN '&F12'
      OR '&F15'
      OR 'CANC'
      OR 'EXIT'.
      LEAVE PROGRAM.

    WHEN 'PICK'.

  ENDCASE.

ENDMODULE.                    "user_command_generic INPUT
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  "TEMPLATE-PF_TITLE

*  SET PF-STATUS 'ZPF_0100'.
  SET PF-STATUS 'ZPF_GENERIC'.
  SET TITLEBAR 'ZTIT_0100'.

  PERFORM print_alv USING c_container_0100
                          c_alv_st_0100
                 CHANGING gt_alv_0100[]
                          go_container_0100
                          go_alv_0100
                          go_doc_container_0100 .

ENDMODULE.                    "handle_hotspot_click
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  "TEMPLATE-PF_TITLE

*  SET PF-STATUS 'ZPF_0200'.
  SET PF-STATUS 'ZPF_GENERIC'.
  SET TITLEBAR 'ZTIT_0200'.

  PERFORM print_alv USING c_container_0200
                          c_alv_st_0200
                 CHANGING gt_alv_0200[]
                          go_container_0200
                          go_alv_0200
                          go_doc_container_0200 .

ENDMODULE.                    "handle_hotspot_click
*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.

  "TEMPLATE-PF_TITLE

*  SET PF-STATUS 'ZPF_0300'.
  SET PF-STATUS 'ZPF_GENERIC'.
  SET TITLEBAR 'ZTIT_0300'.

  PERFORM print_alv USING c_container_0300
                          c_alv_st_0300
                 CHANGING gt_alv_0300[]
                          go_container_0300
                          go_alv_0300
                          go_doc_container_0300 .

ENDMODULE.                    "handle_hotspot_click
*----------------------------------------------------------------------*


*----------------------------------------------------------------------*
"CLASS FUNCTIONS IMPMLEMENTATION
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form CHECK_IF_NOT_SAVED_DATA
*&---------------------------------------------------------------------*
FORM check_if_not_saved_data  CHANGING yv_answer.

  CLEAR yv_answer.

  IF gt_changed_data[] IS NOT INITIAL
   OR gt_deleted_data[] IS NOT INITIAL
   OR gt_inserted_data[] IS NOT INITIAL.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question  = 'Dati non salvati. Procedere comunque?'
      IMPORTING
        answer         = yv_answer
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.
  ENDIF.

  CHECK yv_answer EQ c_yes.

  "Clear changed data if exit without save (YES)
  CLEAR gt_changed_data[].
  CLEAR gt_deleted_data[].
  CLEAR gt_inserted_data[].

ENDFORM.                    "check_if_not_Saved_data
*&---------------------------------------------------------------------*
*&      Form  HANDLE_HOTSPOT_CLICK
*&---------------------------------------------------------------------*
FORM handle_hotspot_click USING xs_row_id    TYPE lvc_s_row
                                xs_column_id TYPE lvc_s_col
                                xs_row_no    TYPE lvc_s_roid.


  CASE sy-dynnr.
    WHEN c_dynnr_0100.

      ASSIGN gt_alv_0100[ xs_row_no-row_id ] TO FIELD-SYMBOL(<alv_0100>).
      CHECK sy-subrc EQ 0.
      CASE xs_column_id-fieldname.

        WHEN 'ANLAGE'.
*      CHECK <alv_0100>-anlage IS NOT INITIAL.
*      SET PARAMETER ID 'ANL'
*                 FIELD <alv_0100>-anlage.
*      CALL TRANSACTION 'ES32' AND SKIP FIRST SCREEN.


      ENDCASE.

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

  ENDCASE.


ENDFORM.                    " HANDLE_HOTSPOT_CLICK
*&---------------------------------------------------------------------*
*&      Form  HANDLE_TOOLBAR
*&---------------------------------------------------------------------*
FORM handle_toolbar  CHANGING yo_object      TYPE REF TO cl_alv_event_toolbar_set
                              yv_interactive TYPE  char01.

  CASE sy-dynnr.
    WHEN c_dynnr_0100.

      yo_object->mt_toolbar = VALUE #(
        (
          icon      = tc_icon-exec
          butn_type = '3'
        )

        (
          function  = '&FUNC1'
          icon      = tc_icon-exec
          butn_type = '0'
          text      = 'Function 1'
          quickinfo = 'Function 1'
        )

        (
          function  = '&SCREEN200'
          icon      = tc_icon-exec
          butn_type = '0'
          text      = 'Screen 200'
          quickinfo = 'Screen 200'
        )

      ).


    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

    WHEN OTHERS.
  ENDCASE.


ENDFORM.                    " HANDLE_TOOLBAR
*&---------------------------------------------------------------------*
*&      Form  HANDLE_USER_COMMAND
*&---------------------------------------------------------------------*
FORM handle_user_command  USING xv_ucomm TYPE sy-ucomm.

  DATA: lt_selected_rows   TYPE lvc_t_row.

  FIELD-SYMBOLS: <sel_rows> LIKE LINE OF lt_selected_rows.

  CLEAR lt_selected_rows[].
  go_current_alv_grid->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected_rows
  ).
  IF lt_selected_rows[] IS NOT INITIAL.

  ELSE.
*     MESSAGE s000(db) WITH 'Select at least one row'
*                         DISPLAY LIKE c_e.
*     EXIT.
  ENDIF.

  CASE xv_ucomm.

    WHEN '&FUNC1'.
*       PERFORM PERFORM command_save_data_0100 USING gt_changed_data[].

    WHEN '&SCREEN200'.
      PERFORM call_screen USING c_dynnr_0200.

  ENDCASE.

  PERFORM refresh_table USING go_current_alv_grid.

ENDFORM.                    " HANDLE_USER_COMMAND
*&---------------------------------------------------------------------*
*&      Form  HANDLE_DATA_CHANGED
*&---------------------------------------------------------------------*
FORM handle_data_changed  CHANGING yr_data_changed  TYPE REF TO cl_alv_changed_data_protocol.

  IF yr_data_changed->mt_good_cells[] IS NOT INITIAL.
    APPEND LINES OF yr_data_changed->mt_good_cells[] TO gt_changed_data[].
  ENDIF.

  IF yr_data_changed->mt_deleted_rows[] IS NOT INITIAL.
    APPEND LINES OF yr_data_changed->mt_deleted_rows[] TO gt_deleted_data[].
  ENDIF.

  IF yr_data_changed->mt_inserted_rows[] IS NOT INITIAL.
    APPEND LINES OF yr_data_changed->mt_inserted_rows[] TO gt_inserted_data[].
  ENDIF.


  "CL_ALV_CHANGED_DATA_PROTOCOL
  "quando il valore non è corretto la cella ti diventa rossa, appare il messaggio di errore e ti rimette in automatico il vecchio valore
  DATA(lv_error_protocol) = abap_false.
  LOOP AT yr_data_changed->mt_good_cells ASSIGNING FIELD-SYMBOL(<good_cell>).

    yr_data_changed->add_protocol_entry( i_msgid     = 'DB'
                                         i_msgno     = '646'
                                         i_msgty     = 'E'
                                         i_fieldname = <good_cell>-fieldname
    ).

    lv_error_protocol = abap_true.

  ENDLOOP.


  CHECK lv_error_protocol EQ abap_true.
  yr_data_changed->display_protocol( ).


ENDFORM.                    " HANDLE_DATA_CHANGED
*&---------------------------------------------------------------------*
*& Form COMMAND_SAVE_DATA_0100
*&---------------------------------------------------------------------*
FORM command_save_data_0100  USING xt_changed_data TYPE lvc_t_modi.

  LOOP AT xt_changed_data ASSIGNING FIELD-SYMBOL(<chng>).
    ASSIGN gt_alv_0100[ <chng>-row_id ] TO FIELD-SYMBOL(<alv_0100>).
    CHECK sy-subrc EQ 0.

    ASSIGN COMPONENT <chng>-fieldname OF STRUCTURE <alv_0100> TO FIELD-SYMBOL(<value>).
    CHECK sy-subrc EQ 0.

    <value> = <chng>-value.

  ENDLOOP.

  CLEAR gt_changed_data[].
  CLEAR gt_deleted_data[].
  CLEAR gt_inserted_data[].
  MESSAGE s000(db) WITH TEXT-s00.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_CELL_COLORS
*&---------------------------------------------------------------------*
FORM fill_cell_colors  USING    xv_fieldname TYPE tabname
                                xv_struct    TYPE tabname
                       CHANGING yv_struct    TYPE any.

  "TEMPLATE-CELL_COLOR

  DATA: ls_scol TYPE lvc_s_scol.

  FIELD-SYMBOLS: <alv_0100> LIKE LINE OF gt_alv_0100,
                 <alv_0200> LIKE LINE OF gt_alv_0200,
                 <alv_0300> LIKE LINE OF gt_alv_0300.

  FIELD-SYMBOLS: <value> TYPE any.

  UNASSIGN: <value>,
            <alv_0100>, <alv_0200>, <alv_0300>.

  CASE xv_struct.
    WHEN c_alv_st_0100.

      ASSIGN yv_struct TO <alv_0100>.
      CHECK sy-subrc EQ 0.

      DELETE <alv_0100>-c_col[] WHERE fname EQ xv_fieldname.

      ASSIGN COMPONENT xv_fieldname OF STRUCTURE yv_struct TO <value>.
      CHECK sy-subrc EQ 0.

      CLEAR ls_scol.
      ls_scol-fname     = xv_fieldname.
      ls_scol-color-col = tc_cell_col-green.
      INSERT ls_scol INTO TABLE <alv_0100>-c_col[] .

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_CELL_STYLE
*&---------------------------------------------------------------------*
FORM fill_cell_style  USING    xv_fieldname TYPE tabname
                               xv_struct    TYPE tabname
                      CHANGING yv_struct    TYPE any.

  "TEMPLATE-CELL_STYLE

  DATA: ls_styl TYPE lvc_s_styl.

  FIELD-SYMBOLS: <value>   TYPE any,
                 <t_style> TYPE lvc_t_styl.

  UNASSIGN: <value>.

  CASE xv_struct.
    WHEN c_alv_st_0100.

      ASSIGN COMPONENT 'C_STY' OF STRUCTURE yv_struct TO <t_style>.
      CHECK sy-subrc EQ 0.

      DELETE <t_style> WHERE fieldname EQ xv_fieldname.

      ASSIGN COMPONENT xv_fieldname OF STRUCTURE yv_struct TO <value>.
      CHECK sy-subrc EQ 0.

      CLEAR ls_styl.
      ls_styl-fieldname = xv_fieldname.
      ls_styl-style     = cl_gui_alv_grid=>mc_style_enabled.
      INSERT ls_styl INTO TABLE <t_style>[].

    WHEN c_dynnr_0200.

    WHEN c_dynnr_0300.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.