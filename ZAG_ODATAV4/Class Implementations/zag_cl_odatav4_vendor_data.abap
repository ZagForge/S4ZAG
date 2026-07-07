CLASS zag_cl_odatav4_vendor_data DEFINITION
  PUBLIC
  INHERITING FROM /iwbep/cl_v4_abs_data_provider
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "Interfaces
    "---------------------------------------------------------------
    INTERFACES:
      zag_if_odatav4_vendor.


    "Methods
    "---------------------------------------------------------------
    METHODS:
      /iwbep/if_v4_dp_basic~read_entity_list REDEFINITION,
      /iwbep/if_v4_dp_basic~read_entity REDEFINITION,
      /iwbep/if_v4_dp_basic~read_ref_target_key_data_list REDEFINITION,
      /iwbep/if_v4_dp_basic~create_entity REDEFINITION,
      /iwbep/if_v4_dp_advanced~create_entity REDEFINITION,
      /iwbep/if_v4_dp_basic~update_entity REDEFINITION,
      /iwbep/if_v4_dp_basic~delete_entity REDEFINITION.


  PROTECTED SECTION.

  PRIVATE SECTION.

    "Aliases
    "---------------------------------------------------------------
    ALIASES:
          ts_cds_views         FOR zag_if_odatav4_vendor~ts_cds_views,
          ts_deep_vendor       FOR zag_if_odatav4_vendor~ts_deep_struct,
          tt_deep_vendor       FOR zag_if_odatav4_vendor~tt_deep_struct,
          tc_entity_set_names  FOR zag_if_odatav4_vendor~tc_entity_set_names,
          tc_entity_type_names FOR zag_if_odatav4_vendor~tc_entity_type_names,
          tc_nav_prop_names    FOR zag_if_odatav4_vendor~tc_nav_prop_names.


    " Methods - Vendor
    "---------------------------------------------------------------
    METHODS:
      read_list_vendor
        IMPORTING
          io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
          io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
          iv_orderby_string TYPE string
          iv_where_clause   TYPE string
          iv_select_string  TYPE string
          iv_skip           TYPE i
          iv_top            TYPE i
          is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
        RAISING
          /iwbep/cx_gateway,

      read_entity_vendor
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_read
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_read
        RAISING
          /iwbep/cx_gateway,

      read_ref_key_list_vendor
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_ref_l
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_ref_l
        RAISING
          /iwbep/cx_gateway,

      create_entity_vendor
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_create
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_create
        RAISING
          /iwbep/cx_gateway,

      create_entity_vendor_deep
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_adv_create
          io_response TYPE REF TO /iwbep/if_v4_resp_adv_create
        RAISING
          /iwbep/cx_gateway,

      update_entity_vendor
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_update
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_update
        RAISING
          /iwbep/cx_gateway,

      delete_entity_vendor
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_delete
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_delete
        RAISING
          /iwbep/cx_gateway.


    " Methods - Company
    "---------------------------------------------------------------
    METHODS:
      read_list_company
        IMPORTING
          io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
          io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
          iv_orderby_string TYPE string
          iv_where_clause   TYPE string
          iv_select_string  TYPE string
          iv_skip           TYPE i
          iv_top            TYPE i
          is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
        RAISING
          /iwbep/cx_gateway,

      read_entity_company
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_read
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_read
        RAISING
          /iwbep/cx_gateway.


    " Methods - Purch. Org.
    "---------------------------------------------------------------
    METHODS:
      read_list_purchorg
        IMPORTING
          io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
          io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
          iv_orderby_string TYPE string
          iv_where_clause   TYPE string
          iv_select_string  TYPE string
          iv_skip           TYPE i
          iv_top            TYPE i
          is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
        RAISING
          /iwbep/cx_gateway,

      read_entity_purchorg
        IMPORTING
          io_request  TYPE REF TO /iwbep/if_v4_requ_basic_read
          io_response TYPE REF TO /iwbep/if_v4_resp_basic_read
        RAISING
          /iwbep/cx_gateway.

ENDCLASS.

CLASS zag_cl_odatav4_vendor_data IMPLEMENTATION.

  METHOD /iwbep/if_v4_dp_advanced~create_entity.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_adv_create=>ty_s_todo_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    IF ls_todo_list-process-deep_busi_data = abap_true.

      io_request->get_entity_type(
        IMPORTING
          ev_entity_type_name = DATA(lv_entity_type_name)
      ).


      CASE lv_entity_type_name.

        WHEN tc_entity_type_names-internal-vendor.
          create_entity_vendor_deep(
            io_request  = io_request
            io_response = io_response
          ).

        WHEN OTHERS.

      ENDCASE.

    ELSE.

      super->/iwbep/if_v4_dp_advanced~create_entity(
            io_request  = io_request
            io_response = io_response
      ).

    ENDIF.

  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~create_entity.

    io_request->get_entity_type(
        IMPORTING
            ev_entity_type_name = DATA(lv_source_entity_name)
    ).


    CASE lv_source_entity_name.

      WHEN tc_entity_type_names-internal-vendor.

        create_entity_vendor(
            io_request  = io_request
            io_response = io_response
        ).

      WHEN tc_entity_type_names-internal-company.

      WHEN tc_entity_type_names-internal-purchorg.

      WHEN OTHERS.

        super->/iwbep/if_v4_dp_basic~create_entity(
                io_request  = io_request
                io_response = io_response
        ).

    ENDCASE.

  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~delete_entity.

    io_request->get_entity_type(
        IMPORTING
            ev_entity_type_name = DATA(lv_source_entity_name)
    ).


    CASE lv_source_entity_name.

      WHEN tc_entity_type_names-internal-vendor.

        delete_entity_vendor(
            io_request  = io_request
            io_response = io_response
        ).

      WHEN tc_entity_type_names-internal-company.

      WHEN tc_entity_type_names-internal-purchorg.

      WHEN OTHERS.

        super->/iwbep/if_v4_dp_basic~delete_entity(
            io_request  = io_request
            io_response = io_response
        ).

    ENDCASE.


  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~read_entity.

    io_request->get_entity_set(
      IMPORTING
        ev_entity_set_name = DATA(lv_entityset_name)
    ).


    CASE lv_entityset_name.

      WHEN tc_entity_set_names-internal-vendor.

        read_entity_vendor(
            io_request  = io_request
            io_response = io_response
        ).


      WHEN tc_entity_set_names-internal-company.

        read_entity_company(
            io_request  = io_request
            io_response = io_response
        ).


      WHEN tc_entity_set_names-internal-purchorg.

        read_entity_purchorg(
            io_request  = io_request
            io_response = io_response
        ).

    ENDCASE.

  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~read_entity_list.

    DATA: lv_orderby_string TYPE string,
          lv_skip           TYPE i,
          lv_top            TYPE i,
          lv_select_string  TYPE string,
          lv_where_clause   TYPE string.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    "Sort settings
    "---------------------------------------------------------------
    lv_orderby_string = 'PRIMARY KEY'.

    IF ls_todo_list-process-orderby = abap_true.

      io_request->get_orderby(
        IMPORTING
            et_orderby_property = DATA(lt_orderby_property)
      ).

      CLEAR lv_orderby_string.
      LOOP AT lt_orderby_property ASSIGNING FIELD-SYMBOL(<ls_orderby_property>).

        lv_orderby_string = COND #(
            WHEN <ls_orderby_property>-descending EQ abap_false
                THEN |{ lv_orderby_string } { <ls_orderby_property>-name } ASCENDING|

            WHEN <ls_orderby_property>-descending EQ abap_true
                THEN |{ lv_orderby_string } { <ls_orderby_property>-name } DESCENDING|
        ).

      ENDLOOP.

      ls_done_list-orderby = abap_true.

    ENDIF.


    " $skip / $top handling
    "---------------------------------------------------------------
    lv_skip = 0. lv_top = 0.

    IF ls_todo_list-process-skip = abap_true.

      io_request->get_skip( IMPORTING ev_skip = lv_skip ).
      ls_done_list-skip = abap_true.

    ENDIF.

    IF ls_todo_list-process-top = abap_true.

      io_request->get_top( IMPORTING ev_top = lv_top ).
      ls_done_list-top = abap_true.

    ENDIF.


    " $select handling
    "---------------------------------------------------------------
    lv_select_string = '*'.

    IF ls_todo_list-process-select = abap_true.

      io_request->get_selected_properties(
        IMPORTING
            et_selected_property = DATA(lt_selected_property)
      ).

      CONCATENATE LINES OF lt_selected_property INTO lv_select_string SEPARATED BY ','.

      ls_done_list-select = abap_true.

    ENDIF.


    "$ filter handling
    "---------------------------------------------------------------
    lv_where_clause = ''.

    IF ls_todo_list-process-filter = abap_true.

      io_request->get_filter_osql_where_clause(
        IMPORTING
            ev_osql_where_clause = lv_where_clause
      ).
      ls_done_list-filter = abap_true.

    ENDIF.


    "Read List Dispatcher
    "---------------------------------------------------------------
    io_request->get_entity_set(
       IMPORTING
         ev_entity_set_name = DATA(lv_entityset_name)
     ).

    CASE lv_entityset_name.
      WHEN tc_entity_set_names-internal-vendor.

        read_list_vendor(
            io_request        = io_request
            io_response       = io_response
            iv_orderby_string = lv_orderby_string
            iv_select_string  = lv_select_string
            iv_where_clause   = lv_where_clause
            iv_skip           = lv_skip
            iv_top            = lv_top
            is_done_list      = ls_done_list
        ).


      WHEN tc_entity_set_names-internal-company.

        read_list_company(
            io_request        = io_request
            io_response       = io_response
            iv_orderby_string = lv_orderby_string
            iv_select_string  = lv_select_string
            iv_where_clause   = lv_where_clause
            iv_skip           = lv_skip
            iv_top            = lv_top
            is_done_list      = ls_done_list
        ).


      WHEN tc_entity_set_names-internal-purchorg.

        read_list_purchorg(
            io_request        = io_request
            io_response       = io_response
            iv_orderby_string = lv_orderby_string
            iv_select_string  = lv_select_string
            iv_where_clause   = lv_where_clause
            iv_skip           = lv_skip
            iv_top            = lv_top
            is_done_list      = ls_done_list
        ).

      WHEN OTHERS.

        super->/iwbep/if_v4_dp_basic~read_entity_list(
            io_request  = io_request
            io_response = io_response
        ).

    ENDCASE.


  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~read_ref_target_key_data_list.

    io_request->get_source_entity_type(
        IMPORTING
            ev_source_entity_type_name = DATA(lv_source_entity_name)
    ).

    CASE lv_source_entity_name.
      WHEN tc_entity_type_names-internal-vendor.

        read_ref_key_list_vendor(
            io_request  = io_request
            io_response = io_response
        ).

      WHEN OTHERS.

        super->/iwbep/if_v4_dp_basic~read_ref_target_key_data_list(
            io_request  = io_request
            io_response = io_response
        ).

    ENDCASE.

  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~update_entity.

    io_request->get_entity_type(
        IMPORTING
            ev_entity_type_name = DATA(lv_source_entity_name)
    ).

    CASE lv_source_entity_name.

      WHEN tc_entity_type_names-internal-vendor.

        update_entity_vendor(
            io_request  = io_request
            io_response = io_response
        ).

      WHEN tc_entity_type_names-internal-company.

      WHEN tc_entity_type_names-internal-purchorg.

      WHEN OTHERS.

        super->/iwbep/if_v4_dp_basic~update_entity(
            io_request  = io_request
            io_response = io_response
        ).

    ENDCASE.

  ENDMETHOD.


  METHOD create_entity_vendor.

    DATA: ls_cds_lfa1  TYPE ts_cds_views-vendor,
          lv_new_lifnr TYPE ts_cds_views-vendor-lifnr.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_create=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_create=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    IF ls_todo_list-process-busi_data = abap_true.
      io_request->get_busi_data(
        IMPORTING
            es_busi_data = ls_cds_lfa1
      ).
      ls_done_list-busi_data = abap_true. "business data processed
    ENDIF.

    IF ls_todo_list-process-partial_busi_data = abap_true.
      " Check if the mandatory properties have been provided


      "If all mandatory data have been provided
      ls_done_list-partial_busi_data = abap_true.
    ENDIF.



    "CREATE YOUR ENTITY HERE



    IF ls_todo_list-return-busi_data = abap_true.

      " Read data again and set the response.
      CLEAR ls_cds_lfa1.
      SELECT SINGLE * FROM zag_cds_lfa1
        INTO CORRESPONDING FIELDS OF @ls_cds_lfa1
        WHERE lifnr = @lv_new_lifnr.

      io_response->set_busi_data( ls_cds_lfa1 ).

    ENDIF.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD create_entity_vendor_deep.

    DATA:
      ls_deep_vendor       TYPE ts_deep_vendor,
      ls_todo_list_subnode TYPE /iwbep/if_v4_data_desc_node=>ty_s_todo_list,
      ls_done_list_subnode TYPE /iwbep/if_v4_data_desc_node=>ty_s_todo_list.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_adv_create=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_adv_create=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Disabilitato di proposito: mostra come leggere l'espressione $expand
    " per limitare il deep create ai soli nav prop richiesti, ma qui non è
    " necessario perché gestiamo solo _Company/_Purchorg sotto Vendor.
    IF 1 = 2.

      io_request->get_data_description_express(
        IMPORTING
          ev_data_description_express = DATA(ls_data_description_express)
      ).


      CHECK ls_data_description_express CS tc_nav_prop_names-internal-vendor_to_company
         OR ls_data_description_express CS tc_nav_prop_names-internal-vendor_to_purchorg.

    ENDIF.

    ls_done_list-deep_busi_data    = abap_true.
    ls_done_list-partial_busi_data = abap_true.

    io_request->get_busi_data(
      IMPORTING
        es_busi_data = ls_deep_vendor
    ).


    " Partial busi data for subnodes
    io_request->get_data_description_tree_list(
        IMPORTING
            et_data_desc_root_node = DATA(lt_data_descr_tree)
    ).


    LOOP AT lt_data_descr_tree ASSIGNING FIELD-SYMBOL(<lo_data_descr_tree>).

      CLEAR ls_todo_list_subnode.
      <lo_data_descr_tree>->get_todos( IMPORTING es_todo_list = ls_todo_list_subnode ).

      CLEAR ls_done_list_subnode.
      IF ls_todo_list_subnode-partial_busi_data = abap_true.

        ls_done_list_subnode-partial_busi_data = abap_true.

        " Process tree to know what for properties where provided

      ENDIF.

      <lo_data_descr_tree>->set_is_done( ls_done_list_subnode ).

    ENDLOOP.


    IF ls_todo_list-return-busi_data = abap_true.
      ls_done_list-busi_data = abap_true.
      io_response->set_busi_data( is_busi_data = ls_deep_vendor ).
    ENDIF.


    io_response->set_is_done( is_todo_list = ls_done_list ).


  ENDMETHOD.


  METHOD delete_entity_vendor.

    DATA: ls_key_data TYPE ts_cds_views-vendor.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_delete=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_delete=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    io_request->get_key_data(
      IMPORTING
        es_key_data = ls_key_data
    ).
    ls_done_list-key_data = abap_true.


    "DELETE YOUR ENTITY HERE


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_entity_company.

    DATA: ls_key_data TYPE ts_cds_views-company,
          ls_cds_lfb1 TYPE ts_cds_views-company.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Read the key data
    "---------------------------------------------------------------
    io_request->get_key_data(
        IMPORTING
            es_key_data = ls_key_data
    ).
    ls_done_list-key_data = abap_true.


    "Perform the extraction
    "---------------------------------------------------------------
    CLEAR ls_cds_lfb1.
    SELECT *
        FROM zag_cds_lfb1
        INTO @ls_cds_lfb1
        WHERE lifnr EQ @ls_key_data-lifnr
          AND bukrs EQ @ls_key_data-bukrs.
    ENDSELECT.
    IF sy-subrc EQ 0.

      io_response->set_busi_data( is_busi_data = ls_cds_lfb1 ).

    ENDIF.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_entity_purchorg.

    DATA: ls_key_data TYPE ts_cds_views-purchorg,
          ls_cds_lfm1 TYPE ts_cds_views-purchorg.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Read the key data
    "---------------------------------------------------------------
    io_request->get_key_data(
        IMPORTING
            es_key_data = ls_key_data
    ).
    ls_done_list-key_data = abap_true.


    "Perform the extraction
    "---------------------------------------------------------------
    CLEAR ls_cds_lfm1.
    SELECT *
        FROM zag_cds_lfm1
        INTO @ls_cds_lfm1
        WHERE lifnr EQ @ls_key_data-lifnr
          AND ekorg EQ @ls_key_data-ekorg.
    ENDSELECT.
    IF sy-subrc EQ 0.

      io_response->set_busi_data( is_busi_data = ls_cds_lfm1 ).

    ENDIF.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_entity_vendor.

    DATA: ls_key_data TYPE ts_cds_views-vendor,
          ls_cds_lfa1 TYPE ts_cds_views-vendor.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Read the key data
    "---------------------------------------------------------------
    io_request->get_key_data( IMPORTING es_key_data = ls_key_data ).
    ls_done_list-key_data = abap_true.


    "Perform the extraction
    "---------------------------------------------------------------
    CLEAR ls_cds_lfa1.
    SELECT * UP TO 1 ROWS
        FROM zag_cds_lfa1
        INTO @ls_cds_lfa1
        WHERE lifnr EQ @ls_key_data-lifnr.
    ENDSELECT.
    IF sy-subrc EQ 0.

      io_response->set_busi_data( is_busi_data = ls_cds_lfa1 ).

    ENDIF.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_company.

    DATA: lt_key_company TYPE STANDARD TABLE OF ts_cds_views-company,
          lr_key_lifnr   TYPE zag_if_odatav4_vendor=>ts_key_range-lifnr,
          lr_key_bukrs   TYPE zag_if_odatav4_vendor=>ts_key_range-bukrs,
          lv_max_index   TYPE i,
          lt_company     TYPE STANDARD TABLE OF ts_cds_views-company.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Get the request options the application has already handled
    ls_done_list = is_done_list.


    " Build key range
    "---------------------------------------------------------------
    IF ls_todo_list-process-key_data = abap_true.

      io_request->get_key_data(
        IMPORTING
            et_key_data = lt_key_company
      ).


      CLEAR lr_key_lifnr[].
      lr_key_lifnr = VALUE #( FOR <lifnr> IN lt_key_company
        ( sign = 'I' option = 'EQ' low = <lifnr>-lifnr )
      ).
      SORT lr_key_lifnr.
      DELETE ADJACENT DUPLICATES FROM lr_key_lifnr.


      CLEAR lr_key_bukrs[].
      lr_key_bukrs = VALUE #( FOR <company> IN lt_key_company
          ( sign = 'I' option = 'EQ' low = <company>-bukrs )
      ).
      SORT lr_key_bukrs.
      DELETE ADJACENT DUPLICATES FROM lr_key_bukrs.

      ls_done_list-key_data = abap_true.

    ENDIF.


    "Data Extraction
    "---------------------------------------------------------------
    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        " Read data from the CDS view
        " value for max_index must only be calculated if the request also contains a $top
        lv_max_index = COND #(
            WHEN iv_top IS NOT INITIAL THEN iv_top + iv_skip
            ELSE 0
        ).

        CLEAR lt_company[].
        SELECT (iv_select_string) UP TO @lv_max_index ROWS
         FROM zag_cds_lfb1
         INTO CORRESPONDING FIELDS OF TABLE @lt_company
          WHERE (iv_where_clause)
            AND lifnr IN @lr_key_lifnr[]
            AND bukrs IN @lr_key_bukrs[]
        ORDER BY (iv_orderby_string).

        " Skipping entries specified by $skip
        " not needed as of NW751 where OFFSET is supported in Open SQL
        IF iv_skip IS NOT INITIAL.
          DELETE lt_company TO iv_skip.
        ENDIF.

        io_response->set_busi_data( it_busi_data = lt_company ).

      WHEN abap_false.

        " If business data is requested count will be calculated by the framework
        IF ls_todo_list-return-count = abap_true.

          SELECT COUNT( * )
              FROM zag_cds_lfb1
              WHERE (iv_where_clause)
                AND lifnr IN @lr_key_lifnr[]
                AND bukrs IN @lr_key_bukrs[].

          io_response->set_count( sy-dbcnt ).

        ENDIF.

    ENDCASE.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_purchorg.

    DATA: lt_key_purchorg TYPE STANDARD TABLE OF ts_cds_views-purchorg,
          lr_key_lifnr    TYPE zag_if_odatav4_vendor=>ts_key_range-lifnr,
          lr_key_ekorg    TYPE zag_if_odatav4_vendor=>ts_key_range-ekorg,
          lv_max_index    TYPE i,
          lt_purchorg     TYPE STANDARD TABLE OF ts_cds_views-purchorg.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Get the request options the application has already handled
    ls_done_list = is_done_list.


    " Build key range
    "---------------------------------------------------------------
    IF ls_todo_list-process-key_data = abap_true.

      io_request->get_key_data(
        IMPORTING
            et_key_data = lt_key_purchorg
      ).


      CLEAR lr_key_lifnr[].
      lr_key_lifnr = VALUE #( FOR <lifnr> IN lt_key_purchorg
          ( sign = 'I' option = 'EQ' low = <lifnr>-lifnr )
      ).
      SORT lr_key_lifnr.
      DELETE ADJACENT DUPLICATES FROM lr_key_lifnr.


      CLEAR lr_key_ekorg[].
      lr_key_ekorg = VALUE #( FOR <purchorg> IN lt_key_purchorg
          ( sign = 'I' option = 'EQ' low = <purchorg>-ekorg )
      ).
      SORT lr_key_ekorg.
      DELETE ADJACENT DUPLICATES FROM lr_key_ekorg.

      ls_done_list-key_data = abap_true.

    ENDIF.


    "Data Extraction
    "---------------------------------------------------------------
    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        " Read data from the CDS view
        " value for max_index must only be calculated if the request also contains a $top
        lv_max_index = COND #(
            WHEN iv_top IS NOT INITIAL THEN iv_top + iv_skip
            ELSE 0
        ).

        CLEAR lt_purchorg[].
        SELECT (iv_select_string) UP TO @lv_max_index ROWS
         FROM zag_cds_lfm1
         INTO CORRESPONDING FIELDS OF TABLE @lt_purchorg
          WHERE (iv_where_clause)
            AND lifnr IN @lr_key_lifnr[]
            AND ekorg IN @lr_key_ekorg[]
        ORDER BY (iv_orderby_string).

        " Skipping entries specified by $skip
        " not needed as of NW751 where OFFSET is supported in Open SQL
        IF iv_skip IS NOT INITIAL.
          DELETE lt_purchorg TO iv_skip.
        ENDIF.

        io_response->set_busi_data( it_busi_data = lt_purchorg ).

      WHEN abap_false.

        " If business data is requested count will be calculated by the framework
        IF ls_todo_list-return-count = abap_true.

          SELECT COUNT( * )
              FROM zag_cds_lfm1
              WHERE (iv_where_clause)
                AND lifnr IN @lr_key_lifnr[]
                AND ekorg IN @lr_key_ekorg[].

          io_response->set_count( sy-dbcnt ).

        ENDIF.

    ENDCASE.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_vendor.

    DATA: lt_key_vendor TYPE STANDARD TABLE OF ts_cds_views-vendor,
          lr_key_vendor TYPE zag_if_odatav4_vendor=>ts_key_range-lifnr,
          lv_max_index  TYPE i,
          lt_vendor     TYPE STANDARD TABLE OF ts_cds_views-vendor.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " Get the request options the application has already handled
    ls_done_list = is_done_list.


    " Build key range
    "---------------------------------------------------------------
    IF ls_todo_list-process-key_data = abap_true.

      io_request->get_key_data(
        IMPORTING
            et_key_data = lt_key_vendor
      ).

      CLEAR lr_key_vendor[].
      lr_key_vendor = VALUE #( FOR <key> IN lt_key_vendor
          ( sign = 'I' option = 'EQ' low = <key>-lifnr )
      ).
      ls_done_list-key_data = abap_true.

    ENDIF.


    "Data Extraction
    "---------------------------------------------------------------
    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        " Read data from the CDS view
        " value for max_index must only be calculated if the request also contains a $top
        lv_max_index = COND #(
            WHEN iv_top IS NOT INITIAL THEN iv_top + iv_skip
            ELSE 0
        ).

        CLEAR lt_vendor[].
        SELECT (iv_select_string) UP TO @lv_max_index ROWS
         FROM zag_cds_lfa1
         INTO CORRESPONDING FIELDS OF TABLE @lt_vendor
          WHERE (iv_where_clause)
            AND lifnr IN @lr_key_vendor[]
        ORDER BY (iv_orderby_string).

        " Skipping entries specified by $skip
        " not needed as of NW751 where OFFSET is supported in Open SQL
        IF iv_skip IS NOT INITIAL.
          DELETE lt_vendor TO iv_skip.
        ENDIF.

        io_response->set_busi_data( it_busi_data = lt_vendor ).

      WHEN abap_false.

        " If business data is requested count will be calculated by the framework
        IF ls_todo_list-return-count = abap_true.

          SELECT COUNT( * )
              FROM zag_cds_lfa1
              WHERE (iv_where_clause)
                AND lifnr IN @lr_key_vendor[].

          io_response->set_count( sy-dbcnt ).

        ENDIF.

    ENDCASE.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_ref_key_list_vendor.

    DATA: ls_key_data          TYPE ts_cds_views-vendor,
          lt_key_company       TYPE STANDARD TABLE OF ts_cds_views-company,
          lt_key_purchorg      TYPE STANDARD TABLE OF ts_cds_views-purchorg,
          lv_nav_property_name TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name.


    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_ref_l=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_ref_l=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    IF ls_todo_list-process-source_key_data = abap_true.
      io_request->get_source_key_data(
        IMPORTING
            es_source_key_data =  ls_key_data
      ).
      ls_done_list-source_key_data = abap_true.
    ENDIF.


    io_request->get_navigation_prop(
        IMPORTING
            ev_navigation_prop_name = lv_nav_property_name
    ).

    CASE lv_nav_property_name.
      WHEN tc_nav_prop_names-internal-vendor_to_company.

        CLEAR lt_key_company[].
        SELECT lifnr, bukrs
            FROM zag_cds_lfb1
            INTO TABLE @lt_key_company
            WHERE lifnr EQ @ls_key_data-lifnr.

        io_response->set_target_key_data( lt_key_company ).

      WHEN tc_nav_prop_names-internal-vendor_to_purchorg.

        CLEAR lt_key_purchorg[].
        SELECT lifnr, ekorg
            FROM zag_cds_lfm1
            INTO TABLE @lt_key_purchorg
            WHERE lifnr EQ @ls_key_data-lifnr.

        io_response->set_target_key_data( lt_key_purchorg ).

      WHEN OTHERS.

    ENDCASE.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD update_entity_vendor.

    DATA: ls_key_data TYPE ts_cds_views-vendor,
          ls_cds_lfa1 TYPE ts_cds_views-vendor.


    " Get the request options the application should/must handle
    "---------------------------------------------------------------
    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_update=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_update=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    IF ls_todo_list-process-key_data = abap_true.

      io_request->get_key_data( IMPORTING es_key_data = ls_key_data ).
      ls_done_list-key_data = abap_true.

    ENDIF.

    IF ls_todo_list-process-busi_data = abap_true.
      io_request->get_busi_data(
        IMPORTING
            es_busi_data = ls_cds_lfa1
      ).
      ls_done_list-busi_data = abap_true. "business data processed
    ENDIF.


    "UPDATE YOUR ENTITY HERE


    IF ls_todo_list-return-busi_data = abap_true.

      io_response->set_busi_data( ls_cds_lfa1 ).

    ENDIF.


    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.
  
ENDCLASS.
