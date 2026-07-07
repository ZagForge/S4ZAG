*&---------------------------------------------------------------------*
*& Report ZAG_ALV_TREE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zag_alv_tree.

CLASS cl_gui_column_tree DEFINITION LOAD.
CLASS cl_gui_cfw         DEFINITION LOAD.
INCLUDE <icon>.

"Types per container e struttura Alv
TYPES: ty_ref_alv           TYPE REF TO cl_gui_alv_grid,
       ty_ref_container     TYPE REF TO cl_gui_custom_container,
       ty_ref_doc_container TYPE REF TO cl_gui_docking_container.

"Technical Type table
"used to stack the dynpro called
TYPES: BEGIN OF ty_stacktrace_dynnr,
         dynnr          TYPE sy-dynnr,
         dynnr_parent   TYPE sy-dynnr,
         event_instance TYPE ty_ref_alv,
       END OF ty_stacktrace_dynnr.

DATA: go_instance_event   TYPE ty_ref_alv,
      gt_stacktrace_dynnr TYPE TABLE OF ty_stacktrace_dynnr,
      gt_changed_data     TYPE lvc_t_modi,
      gt_deleted_data     TYPE lvc_t_moce,
      gt_inserted_data    TYPE lvc_t_moce,
      gt_toolbar          TYPE ttb_button,
      ok_code             TYPE sy-ucomm.

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
*--------------------------------------------------------------------*


"ALV SCREEN 100
*--------------------------------------------------------------------*
"Structure ALV screen 100 + Type Table
*--------------------------------------------------------------------*
TYPES: BEGIN OF ty_alv_0100.
    INCLUDE STRUCTURE t001l. "TODO-DDIC
TYPES: icon TYPE icon_d,
       msg  TYPE bapi_msg.
*       c_col TYPE lvc_t_scol.
TYPES: END OF ty_alv_0100.
TYPES: tt_alv_0100 TYPE TABLE OF ty_alv_0100.

DATA: gt_alv_0100  TYPE TABLE OF ty_alv_0100,
      gt_my_tree TYPE TABLE OF ty_alv_0100,
      gt_alv_det   TYPE TABLE OF ty_alv_0100.

DATA: ok_0100               TYPE sy-ucomm,
      go_container_0100     TYPE ty_ref_container,
      go_alv_0100           TYPE ty_ref_alv,
      go_doc_container_0100 TYPE ty_ref_doc_container.

CONSTANTS: c_container_0100 TYPE scrfname      VALUE 'CONTAINER_0100',
           c_alv_st_0100    TYPE dd02l-tabname VALUE 'T001L', "TODO-DDIC
           c_dynnr_0100     TYPE sy-dynnr      VALUE '0100'.
*--------------------------------------------------------------------*


"ALV SCREEN 200
*--------------------------------------------------------------------*
"Structure ALV screen 200 + Type Table
*--------------------------------------------------------------------*
TYPES: BEGIN OF ty_alv_0200.
    INCLUDE STRUCTURE lfa1. "TODO-DDIC
TYPES: icon TYPE icon_d,
       msg  TYPE bapi_msg.
TYPES: END OF ty_alv_0200.
TYPES: tt_alv_0200 TYPE TABLE OF ty_alv_0200.

DATA: gt_alv_0200 TYPE TABLE OF ty_alv_0200  .

DATA: ok_0200               TYPE sy-ucomm,
      go_container_0200     TYPE ty_ref_container,
      go_alv_0200           TYPE ty_ref_alv,
      go_doc_container_0200 TYPE ty_ref_doc_container.

CONSTANTS: c_container_0200 TYPE scrfname      VALUE 'CONTAINER_0200',
           c_alv_st_0200    TYPE dd02l-tabname VALUE 'LFA1', "TODO-DDIC
           c_dynnr_0200     TYPE sy-dynnr      VALUE '0200'.
*--------------------------------------------------------------------*


"ALV SCREEN 300
*--------------------------------------------------------------------*
"Structure ALV screen 300 + Type Table
*--------------------------------------------------------------------*
TYPES: BEGIN OF ty_alv_0300.
    INCLUDE STRUCTURE kna1. "TODO-DDIC
TYPES: icon TYPE icon_d,
       msg  TYPE bapi_msg.
TYPES: END OF ty_alv_0300.
TYPES: tt_alv_0300 TYPE TABLE OF ty_alv_0300.

DATA: gt_alv_0300 TYPE TABLE OF ty_alv_0300.

DATA: ok_0300               TYPE sy-ucomm,
      go_container_0300     TYPE ty_ref_container,
      go_alv_0300           TYPE ty_ref_alv,
      go_doc_container_0300 TYPE ty_ref_doc_container.

CONSTANTS: c_container_0300 TYPE scrfname      VALUE 'CONTAINER_0300',
           c_alv_st_0300    TYPE dd02l-tabname VALUE 'KNA1', "TODO-DDIC
           c_dynnr_0300     TYPE sy-dynnr      VALUE '0300'.
*--------------------------------------------------------------------*

DATA: my_tree    TYPE REF TO cl_gui_alv_tree,
      mr_toolbar TYPE REF TO cl_gui_toolbar.






START-OF-SELECTION.

  SELECT * FROM t001l INTO TABLE gt_alv_0100.

  CALL SCREEN 100.




CLASS cl_alv_event DEFINITION.

  PUBLIC SECTION.
    METHODS: on_function_selected
                  FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.

ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS lcl_toolbar_event_receiver IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS cl_alv_event IMPLEMENTATION.

  METHOD on_function_selected.

    DATA: lt_selected_node TYPE lvc_t_nkey.
    DATA: ls_alv_0100      TYPE ty_alv_0100.

    CLEAR lt_selected_node[].
    CALL METHOD my_tree->get_selected_nodes
      CHANGING
        ct_selected_nodes = lt_selected_node.

    CALL METHOD cl_gui_cfw=>flush.

    READ TABLE lt_selected_node INTO DATA(l_selected_node) INDEX 1.
    IF lt_selected_node[] IS INITIAL.
*      MESSAGE i227(0h).
*      EXIT.
    ENDIF.

    CLEAR ls_alv_0100.
    CALL METHOD my_tree->get_outtab_line
      EXPORTING
        i_node_key    = l_selected_node
      IMPORTING
        e_outtab_line = ls_alv_0100.

    CASE fcode.
      WHEN 'SHOW_DETAILS'.

        REFRESH gt_alv_det.
        APPEND ls_alv_0100 TO gt_alv_det.

        CALL SCREEN 200.

      WHEN OTHERS.
    ENDCASE.

*   update frontend
    CALL METHOD cl_gui_cfw=>flush( ).
    CALL METHOD my_tree->update_calculations.
    CALL METHOD my_tree->frontend_update.
  ENDMETHOD.

ENDCLASS.

TYPES ty_ref_alv_event TYPE REF TO cl_alv_event.
DATA: go_alv_event     TYPE ty_ref_alv_event.




*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZPF_GENERIC'.
  SET TITLEBAR 'ZTIT_0100'.

  IF my_tree IS INITIAL.
    PERFORM init_tree.
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Form INIT_TREE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_tree .

  DATA: lt_fcat             TYPE lvc_t_fcat,
        ls_hierarchy_header TYPE treev_hhdr,
        lt_list_commentary  TYPE slis_t_listheader,
        ls_logo             TYPE sdydo_value,
        ls_variant          TYPE disvariant.

  DATA: lt_excl TYPE ui_functions,
        ls_excl LIKE LINE OF lt_excl.

*--------------------------------------------------------------------*
* create and init container
  PERFORM init_container.

* create fieldcat
  PERFORM build_fieldcatalog CHANGING lt_fcat.

* create Hierarchy-header
  PERFORM build_hierarchy_header CHANGING ls_hierarchy_header.


* create info-table for html-header
  PERFORM build_comment USING lt_list_commentary
                              ls_logo.

* exclude functions
  PERFORM excl_functions TABLES lt_excl.

* repid for saving variants
  ls_variant-report = sy-repid.

* create emty tree-control
  CALL METHOD my_tree->set_table_for_first_display
    EXPORTING
      is_hierarchy_header  = ls_hierarchy_header
      it_list_commentary   = lt_list_commentary
      i_logo               = ls_logo
      i_background_id      = 'ALV_BACKGROUND'
      i_save               = 'A'
      is_variant           = ls_variant
      it_toolbar_excluding = lt_excl
    CHANGING
      it_outtab            = gt_my_tree "table must be emty !!
      it_fieldcatalog      = lt_fcat.

* create hierarchy
  PERFORM create_hierarchy.

* add own functioncodes to the toolbar
  PERFORM change_toolbar.

* register events
  PERFORM register_events.

* adjust column_width
  CALL METHOD my_tree->column_optimize.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_CONTAINER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_container .

* create container for alv-tree
  IF sy-batch IS INITIAL.
    CREATE OBJECT go_container_0100
      EXPORTING
        container_name              = c_container_0100
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.
    IF sy-subrc <> 0.
      MESSAGE x208(00) WITH 'ERROR'.                        "#EC NOTEXT
    ENDIF.
  ENDIF.

* create tree control
  CREATE OBJECT my_tree
    EXPORTING
      parent                      = go_container_0100
      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_multiple
      item_selection              = space
      no_html_header              = ''
      no_toolbar                  = ''
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      illegal_node_selection_mode = 5
      failed                      = 6
      illegal_column_name         = 7.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.                          "#EC NOTEXT
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_fieldcatalog CHANGING yt_fcat TYPE lvc_t_fcat..

  DATA: ls_fcat TYPE lvc_s_fcat.

  FIELD-SYMBOLS: <fcat> LIKE LINE OF yt_fcat.

*--------------------------------------------------------------------*
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = c_alv_st_0100
    CHANGING
      ct_fieldcat            = yt_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_HIERARCHY_HEADER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- L_HIERARCHY_HEADER
*&---------------------------------------------------------------------*
FORM build_hierarchy_header  CHANGING y_hierarchy_header TYPE treev_hhdr.

  y_hierarchy_header-heading    = 'Hierarchy Header'.
  y_hierarchy_header-tooltip    = 'This is the Hierarchy Header !'.
  y_hierarchy_header-width      = 30.
  y_hierarchy_header-width_pix  = ''.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_COMMENT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_LIST_COMMENTARY
*&      --> L_LOGO
*&---------------------------------------------------------------------*
FORM build_comment  USING yt_list_commentary TYPE slis_t_listheader
                          y_logo             TYPE sdydo_value.

  DATA: ls_line TYPE slis_listheader.

* LIST HEADING LINE: TYPE H
  CLEAR ls_line.
  ls_line-typ  = 'H'.
  ls_line-info = sy-title.
  APPEND ls_line TO yt_list_commentary.

  "STATUS LINE: TYPE S
  CLEAR ls_line.
  ls_line-typ  = 'S'.
  ls_line-key  = 'Data:'.
  WRITE sy-datum TO ls_line-info DD/MM/YYYY.
  APPEND ls_line TO yt_list_commentary.

  ls_line-key  = 'User'.
  ls_line-info = sy-uname.
  APPEND ls_line TO yt_list_commentary.



  y_logo = 'ENJOYSAP_LOGO'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form EXCL_FUNCTIONS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_EXCL
*&---------------------------------------------------------------------*
FORM excl_functions  TABLES yt_excl TYPE ui_functions.

  DATA: ls_excl LIKE LINE OF yt_excl.

  ls_excl = cl_gui_alv_tree=>mc_fc_calculate.
  APPEND ls_excl TO yt_excl.

  ls_excl = cl_gui_alv_tree=>mc_fc_calculate_avg.
  APPEND ls_excl TO yt_excl.

  ls_excl = cl_gui_alv_tree=>mc_fc_calculate_max.
  APPEND ls_excl TO yt_excl.

  ls_excl = cl_gui_alv_tree=>mc_fc_calculate_min.
  APPEND ls_excl TO yt_excl.

  ls_excl = cl_gui_alv_tree=>mc_fc_calculate_sum.
  APPEND ls_excl TO yt_excl.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_HIERARCHY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_hierarchy .

* add data to tree
  DATA: l_root_key TYPE lvc_nkey,
        l_node_key TYPE lvc_nkey,
        l_leaf_key TYPE lvc_nkey,
        l_last_key TYPE lvc_nkey.

  SORT gt_alv_0100.

  LOOP AT gt_alv_0100 ASSIGNING FIELD-SYMBOL(<alv_0100>).

    AT NEW werks.

      CLEAR: l_root_key, l_node_key, l_last_key.

      PERFORM add_root_line USING   <alv_0100>
                                    ''
                           CHANGING l_root_key.

      CONTINUE.
    ENDAT.

    AT END OF werks.

      PERFORM add_node_line USING    <alv_0100>
*                                     l_node_key
                                     l_root_key
                            CHANGING l_node_key.


      CONTINUE.
    ENDAT.


    PERFORM add_leaf_line USING    <alv_0100>
                                   l_root_key
                          CHANGING l_leaf_key.

  ENDLOOP.


* calculate totals
  CALL METHOD my_tree->update_calculations.

* this method must be called to send the data to the frontend
  CALL METHOD my_tree->frontend_update.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ADD_ROOT_LINE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <ALV_0100>
*&      --> P_
*&      <-- L_ROOT_KEY
*&---------------------------------------------------------------------*
FORM add_root_line  USING     x_line_data TYPE ty_alv_0100
                              x_relat_key TYPE lvc_nkey
                     CHANGING y_node_key  TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.


* set item-layout
  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  ls_item_layout-t_image = '@3P@'.
  ls_item_layout-fieldname = my_tree->c_hierarchy_column_name.
  ls_item_layout-style   = cl_gui_column_tree=>style_intensifd_critical.
  APPEND ls_item_layout TO lt_item_layout.

* add node
  CONCATENATE 'Root: '
              x_line_data-werks
              INTO l_node_text SEPARATED BY space.

  DATA: ls_node TYPE lvc_s_layn.
  ls_node-n_image   = space.
  ls_node-exp_image = space.
  ls_node-isfolder  = 'X'.

  CALL METHOD my_tree->add_node
    EXPORTING
      i_relat_node_key = x_relat_key
      i_relationship   = cl_gui_column_tree=>relat_last_child
      i_node_text      = l_node_text
      is_outtab_line   = x_line_data
      is_node_layout   = ls_node
      it_item_layout   = lt_item_layout
    IMPORTING
      e_new_node_key   = y_node_key.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form ADD_NODE_LINE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <ALV_0100>
*&      --> X_NODE_KEY
*&      <-- L_LAST_KEY
*&---------------------------------------------------------------------*
FORM add_node_line  USING     x_line_data TYPE ty_alv_0100
                              x_relat_key TYPE lvc_nkey
                     CHANGING y_node_key  TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.

* set item-layout
  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  ls_item_layout-t_image = '@3Y@'.
  ls_item_layout-style   = cl_gui_column_tree=>style_intensified.
  ls_item_layout-fieldname = my_tree->c_hierarchy_column_name.
  APPEND ls_item_layout TO lt_item_layout.



  CONCATENATE 'Node: '
              x_line_data-lgort
              INTO l_node_text SEPARATED BY space.

  DATA: ls_node TYPE lvc_s_layn.
  ls_node-n_image   = space.
  ls_node-exp_image = space.
  ls_node-isfolder  = 'X'.

  DATA: relat TYPE int4.
  relat = cl_gui_column_tree=>relat_last_child.

  CALL METHOD my_tree->add_node
    EXPORTING
      i_relat_node_key = x_relat_key
      i_relationship   = relat
      i_node_text      = l_node_text
      is_outtab_line   = x_line_data
      is_node_layout   = ls_node
      it_item_layout   = lt_item_layout
    IMPORTING
      e_new_node_key   = y_node_key.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ADD_LEAF_LINE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <ALV_0100>
*&      --> X_NODE_KEY
*&      <-- L_NODE_KEY
*&---------------------------------------------------------------------*
FORM add_leaf_line  USING    x_line_data TYPE ty_alv_0100
                             x_relat_key TYPE lvc_nkey
                    CHANGING y_node_key  TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.

* set item-layout
  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  ls_item_layout-fieldname = my_tree->c_hierarchy_column_name.
*  ls_item_layout-class     = cl_gui_column_tree=>item_class_checkbox.
*  ls_item_layout-editable  = 'X'.
  APPEND ls_item_layout TO lt_item_layout.

*  CLEAR ls_item_layout.
*  ls_item_layout-fieldname = 'PLANETYPE'.
*  ls_item_layout-alignment = cl_gui_column_tree=>align_right.
*  APPEND ls_item_layout TO lt_item_layout.

  CONCATENATE 'Leaf: '
              x_line_data-lgort
              INTO l_node_text SEPARATED BY space.

  DATA: ls_node TYPE lvc_s_layn.
  ls_node-n_image   = space.
  ls_node-exp_image = space.

  CALL METHOD my_tree->add_node
    EXPORTING
      i_relat_node_key = x_relat_key
      i_relationship   = cl_gui_column_tree=>relat_last_child
      is_outtab_line   = x_line_data
      i_node_text      = l_node_text
      is_node_layout   = ls_node
      it_item_layout   = lt_item_layout
    IMPORTING
      e_new_node_key   = y_node_key.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHANGE_TOOLBAR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM change_toolbar .

* get toolbar control
  CALL METHOD my_tree->get_toolbar_object
    IMPORTING
      er_toolbar = mr_toolbar.

  CHECK NOT mr_toolbar IS INITIAL.

* add seperator to toolbar
  CALL METHOD mr_toolbar->add_button
    EXPORTING
      fcode     = ''
      icon      = ''
      butn_type = cntb_btype_sep
      text      = ''
      quickinfo = ''.                    "#EC NOTEXT

* add seperator to toolbar
  CALL METHOD mr_toolbar->add_button
    EXPORTING
      fcode     = ''
      icon      = ''
      butn_type = cntb_btype_sep
      text      = ''
      quickinfo = ''.                    "#EC NOTEXT

  CALL METHOD mr_toolbar->add_button
    EXPORTING
      fcode     = 'SHOW_DETAILS'
      icon      = '@16@'
*     butn_type = cntb_btype_dropdown
      butn_type = cntb_btype_button
      text      = 'Node Details'
      quickinfo = 'Node Details'.

  CREATE OBJECT go_alv_event.
  SET HANDLER go_alv_event->on_function_selected FOR mr_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form REGISTER_EVENTS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM register_events .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_GENERIC  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_generic INPUT.

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

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'ZPF_GENERIC'.
* SET TITLEBAR 'xxx'.

  DATA: l_column    TYPE sy-tabix,
        lp_struct   TYPE REF TO data,
        lp_table    TYPE REF TO data,      " POINTER to dynamic table
        ls_lvc_cat  TYPE lvc_s_fcat,
        lt_lvc_cat  TYPE lvc_t_fcat,       " FIELD catalog
        lt_fcat     TYPE slis_t_fieldcat_alv,  " FIELD catalog
        ls_fieldcat TYPE slis_fieldcat_alv,
        lt_fieldcat TYPE slis_t_fieldcat_alv,  " FIELD catalog
        ls_layout   TYPE slis_layout_alv,
        ls_layo     TYPE lvc_s_layo.


  FIELD-SYMBOLS : <header>       TYPE any,
                  <field_header> TYPE any,
                  <field_qmih>   TYPE any,
                  <lt_data>      TYPE table.         " data to display

  FIELD-SYMBOLS: <fcat> LIKE LINE OF lt_fcat.

  CLEAR: go_container_0200,
         l_column   ,
         lp_struct  ,
         lp_table   ,
         ls_lvc_cat ,
         lt_lvc_cat ,
         lt_fcat    ,
         ls_fieldcat,
         lt_fieldcat,
         ls_layout  ,
         ls_layo    .

*--------------------------------------------------------------------*
  IF go_container_0200 IS INITIAL.
    IF cl_gui_alv_grid=>offline( ) IS INITIAL.
      CREATE OBJECT go_container_0200
        EXPORTING
          container_name = c_container_0200.

      CREATE OBJECT go_alv_0200
        EXPORTING
          i_parent = go_container_0200.
    ELSE.
* If it is in background:
      CREATE OBJECT go_alv_0200
        EXPORTING
          i_parent = go_doc_container_0200.
    ENDIF.

    ls_layo-zebra   = 'X'.
    ls_layo-col_opt = 'X'.

    ls_lvc_cat-fieldname = 'COLUMNTEXT'.
    ls_lvc_cat-ref_table = 'LVC_S_DETA'.
    APPEND ls_lvc_cat TO lt_lvc_cat.

    ls_fieldcat-fieldname = 'COLUMNTEXT'.
    ls_fieldcat-ref_tabname = 'LVC_S_DETA'.
    ls_fieldcat-key  = 'X'.
    APPEND ls_fieldcat TO lt_fieldcat.

    DESCRIBE TABLE gt_alv_det.

    DO sy-tfill TIMES.
*   For each line, a column 'VALUEx' is created in the fieldcatalog

*   Build Fieldcatalog
      WRITE sy-index TO ls_lvc_cat-fieldname LEFT-JUSTIFIED.

      CONCATENATE 'VALUE' ls_lvc_cat-fieldname
             INTO ls_lvc_cat-fieldname.
      ls_lvc_cat-ref_field = 'VALUE'.
      ls_lvc_cat-ref_table = 'LVC_S_DETA'.
      APPEND ls_lvc_cat TO lt_lvc_cat.

*   Build Fieldcatalog
      CLEAR ls_fieldcat.
      ls_fieldcat-fieldname = ls_lvc_cat-fieldname.
      ls_fieldcat-ref_fieldname = 'VALUE'.
      ls_fieldcat-ref_tabname = 'LVC_S_DETA'.
      APPEND ls_fieldcat TO lt_fieldcat.

    ENDDO.

* Create internal table

    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog = lt_lvc_cat
      IMPORTING
        ep_table        = lp_table.

    ASSIGN lp_table->* TO <lt_data>.

* Create structure = structure of the internal table
    CREATE DATA lp_struct LIKE LINE OF <lt_data>.
    ASSIGN lp_struct->* TO <header>.

* Create field catalog from dictionary structure
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = c_alv_st_0100
      CHANGING
        ct_fieldcat            = lt_fcat
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.


    DESCRIBE TABLE lt_fcat.

* Fill the internal to display <lt_data>
    DO sy-tfill TIMES.
      IF sy-index = 1.

        READ TABLE lt_fcat INTO ls_fieldcat INDEX 1.

        IF ls_fieldcat-fieldname = 'MANDT'.
*       If 1st column is MANDT, it's not displayed
          CONTINUE.
        ENDIF.

      ENDIF.

*   For each field of GT_DATA
      ASSIGN COMPONENT 1 OF STRUCTURE <header> TO <field_header>.
      IF sy-subrc NE 0. EXIT .ENDIF.

      READ TABLE lt_fcat INTO ls_fieldcat INDEX sy-index.
*   Fill 1st column

      <field_header> = ls_fieldcat-seltext_m.
      IF <field_header> IS INITIAL.
        <field_header> = ls_fieldcat-fieldname.
      ENDIF.

      LOOP AT gt_alv_det ASSIGNING FIELD-SYMBOL(<alv_det>).
        l_column = sy-tabix + 1.
        ASSIGN COMPONENT sy-index OF STRUCTURE <alv_det> TO <field_qmih>.
        IF sy-subrc NE 0. EXIT .ENDIF.

        ASSIGN COMPONENT l_column OF STRUCTURE <header> TO <field_header>.
        IF sy-subrc NE 0. EXIT .ENDIF.

        WRITE <field_qmih> TO <field_header> LEFT-JUSTIFIED.

      ENDLOOP.

      APPEND <header> TO <lt_data>.
    ENDDO.

    ls_layout-colwidth_optimize = 'X'.
    ls_layout-no_colhead = 'X'.
    ls_layout-zebra = 'X'.

    CALL FUNCTION 'LVC_TRANSFER_FROM_SLIS'
      EXPORTING
        it_fieldcat_alv = lt_fieldcat
      IMPORTING
        et_fieldcat_lvc = lt_lvc_cat
      TABLES
        it_data         = <lt_data>
      EXCEPTIONS
        it_data_missing = 1
        OTHERS          = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    READ TABLE lt_lvc_cat INTO ls_lvc_cat INDEX 1.
    ls_lvc_cat-col_opt = 'X'.
    MODIFY lt_lvc_cat FROM ls_lvc_cat
                      TRANSPORTING col_opt
                      WHERE fieldname NE 'DUMMY'.

    ls_layo-sel_mode   = 'A'.
    ls_layo-zebra      = 'X'.

*    IF sy-batch EQ space.
*      CREATE OBJECT go_event_receiver.
*      SET HANDLER go_event_receiver->handle_toolbar       FOR go_alv_0200.
*      SET HANDLER go_event_receiver->handle_user_command  FOR go_alv_0200.
*    SET HANDLER go_event_receiver->handle_hotspot_click FOR go_alv_0100.
*    ENDIF.

    CALL METHOD go_alv_0200->set_table_for_first_display
      EXPORTING
*       i_save                        = 'A'
        is_layout                     = ls_layo
      CHANGING
        it_outtab                     = <lt_data>
        it_fieldcatalog               = lt_lvc_cat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ELSE.

    PERFORM refresh_table USING go_alv_0200.

  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Form REFRESH_TABLE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GO_ALV_0200
*&---------------------------------------------------------------------*
FORM refresh_table  USING p_ref_alv TYPE ty_ref_alv.

  DATA lt_stable TYPE lvc_s_stbl.

  lt_stable-row = 'X'.
  lt_stable-col = 'X'.

  CALL METHOD p_ref_alv->refresh_table_display
    EXPORTING
      is_stable      = lt_stable
      i_soft_refresh = 'X'.

ENDFORM.
