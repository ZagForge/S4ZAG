CLASS zml_cl_odatav4_arch_data DEFINITION
  PUBLIC
  INHERITING FROM /iwbep/cl_v4_abs_data_provider
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zml_if_odatav4_arch .


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

    ALIASES tc_entity_set_names  FOR zml_if_odatav4_arch~tc_entity_set_names .
    ALIASES tc_entity_type_names FOR zml_if_odatav4_arch~tc_entity_type_names .

    ALIASES ts_table_history     FOR zml_if_odatav4_arch~ts_table_history .
    ALIASES ts_table_size        FOR zml_if_odatav4_arch~ts_table_size .
    ALIASES ts_top_tables        FOR zml_if_odatav4_arch~ts_top_tables .

    METHODS read_list_top_tables
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_orderby_string TYPE string
        !iv_where_clause   TYPE string
        !iv_select_string  TYPE string
        !is_filtri         TYPE zml_if_odatav4_arch=>ts_filters
        !iv_skip           TYPE i
        !iv_top            TYPE i
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    METHODS read_list_table_history
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_orderby_string TYPE string
        !iv_where_clause   TYPE string
        !iv_select_string  TYPE string
        !is_filtri         TYPE zml_if_odatav4_arch=>ts_filters
        !iv_skip           TYPE i
        !iv_top            TYPE i
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    METHODS read_list_table_size
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_orderby_string TYPE string
        !iv_where_clause   TYPE string
        !iv_select_string  TYPE string
        !is_filtri         TYPE zml_if_odatav4_arch=>ts_filters
        !iv_skip           TYPE i
        !iv_top            TYPE i
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    " Estrae i nomi tabella dalle righe EQ del range (ignorate BT/GT/ecc.:
    " il filtro atteso è "TableName eq 'X' or TableName eq 'Y'").
    METHODS get_table_names_from_range
      IMPORTING
        !it_range         TYPE zml_if_odatav4_arch=>tt_tabname_range
      RETURNING
        VALUE(rt_tabname) TYPE zag_cl_ml_table_growth=>tt_tabname.

    " Riduce un range di date a due estremi (from/to), combinando le righe
    " GE/LE/BT/EQ che il framework genera dal $filter su un singolo campo data.
    METHODS get_date_bounds
      IMPORTING
        !it_range     TYPE zml_if_odatav4_arch=>tt_date_range
      EXPORTING
        !ev_date_from TYPE sy-datum
        !ev_date_to   TYPE sy-datum.

    METHODS mock_data_table_history
      IMPORTING
        !is_filtri          TYPE zml_if_odatav4_arch=>ts_filters
      RETURNING
        VALUE(rt_mock_data) TYPE zml_if_odatav4_arch=>tt_table_history.
ENDCLASS.



CLASS ZML_CL_ODATAV4_ARCH_DATA IMPLEMENTATION.


  METHOD /iwbep/if_v4_dp_advanced~create_entity.
  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~create_entity.
  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~delete_entity.
  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~read_entity.
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
    " NB: qui leggiamo solo i valori richiesti dal client. Se e come vengono
    " davvero applicati (done = abap_true) lo decide ogni READ_LIST_* in base
    " a cosa sa effettivamente spingere verso ZAG_CL_ML_TABLE_GROWTH — non li
    " marchiamo "fatti" a priori per non promettere una paginazione che poi
    " non viene onorata.
    lv_skip = 0. lv_top = 0.

    IF ls_todo_list-process-skip = abap_true.
      io_request->get_skip( IMPORTING ev_skip = lv_skip ).
    ENDIF.

    IF ls_todo_list-process-top = abap_true.
      io_request->get_top( IMPORTING ev_top = lv_top ).
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

    DATA: ls_filtri TYPE zml_if_odatav4_arch=>ts_filters.

    IF ls_todo_list-process-filter = abap_true.

      io_request->get_filter_osql_where_clause(
        IMPORTING
            ev_osql_where_clause = lv_where_clause
      ).

      TRY.
          io_request->get_filter_ranges_for_prop(
            EXPORTING
              iv_property_path = 'TABLE_NAME'    " TableHistory / TableSize
            IMPORTING
              et_range         = ls_filtri-r_table_name
          ).
        CATCH /iwbep/cx_gateway. " proprietà non presente su questa entity — ignora
      ENDTRY.

      TRY.
          io_request->get_filter_ranges_for_prop(
            EXPORTING
              iv_property_path = 'SNAPSHOT_DATE'    " solo TableHistory
            IMPORTING
              et_range         = ls_filtri-r_snapshot_date
          ).
        CATCH /iwbep/cx_gateway. " proprietà non presente su questa entity — ignora
      ENDTRY.

      ls_done_list-filter = abap_true.

    ENDIF.


    "Read List Dispatcher
    "---------------------------------------------------------------
    io_request->get_entity_set(
       IMPORTING
         ev_entity_set_name = DATA(lv_entityset_name)
     ).

    CASE lv_entityset_name.
      WHEN tc_entity_set_names-internal-top_tables.

        read_list_top_tables(
            io_request        = io_request
            io_response       = io_response
            iv_orderby_string = lv_orderby_string
            iv_select_string  = lv_select_string
            iv_where_clause   = lv_where_clause
            is_filtri         = ls_filtri
            iv_skip           = lv_skip
            iv_top            = lv_top
            is_done_list      = ls_done_list
        ).

      WHEN tc_entity_set_names-internal-table_history.

        read_list_table_history(
            io_request        = io_request
            io_response       = io_response
            iv_orderby_string = lv_orderby_string
            iv_select_string  = lv_select_string
            iv_where_clause   = lv_where_clause
            is_filtri         = ls_filtri
            iv_skip           = lv_skip
            iv_top            = lv_top
            is_done_list      = ls_done_list
        ).

      WHEN tc_entity_set_names-internal-table_size.

        read_list_table_size(
            io_request        = io_request
            io_response       = io_response
            iv_orderby_string = lv_orderby_string
            iv_select_string  = lv_select_string
            iv_where_clause   = lv_where_clause
            is_filtri         = ls_filtri
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
  ENDMETHOD.


  METHOD /iwbep/if_v4_dp_basic~update_entity.
  ENDMETHOD.


  METHOD get_date_bounds.

    LOOP AT it_range INTO DATA(ls_range).
      CASE ls_range-option.
        WHEN 'BT'.
          ev_date_from = ls_range-low.
          ev_date_to   = ls_range-high.
        WHEN 'GE' OR 'EQ'.
          IF ev_date_from IS INITIAL OR ls_range-low < ev_date_from.
            ev_date_from = ls_range-low.
          ENDIF.
        WHEN 'LE'.
          IF ev_date_to IS INITIAL OR ls_range-low > ev_date_to.
            ev_date_to = ls_range-low.
          ENDIF.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_table_names_from_range.

    LOOP AT it_range INTO DATA(ls_range) WHERE option = 'EQ'.
      APPEND ls_range-low TO rt_tabname.
    ENDLOOP.

  ENDMETHOD.


  METHOD mock_data_table_history.

    " ─────────────────────────────────────────────────────────────────
    " Dati finti per test senza connessione a un sistema con dati reali.
    " Stessa curva di crescita (lineare + stagionalità + rumore) del
    " precedente generatore per DB02, adattata alla forma di TableHistory.
    " ─────────────────────────────────────────────────────────────────

    CONSTANTS: c_num_anni TYPE i VALUE 10,
               c_num_mesi TYPE i VALUE 120.

    TYPES: BEGIN OF ty_table_cfg,
             table_name   TYPE tabname,
             start_gb     TYPE f,
             growth_gb_yr TYPE f,
             bytes_x_rec  TYPE i,
           END OF ty_table_cfg.

    DATA: lt_table_cfg     TYPE TABLE OF ty_table_cfg,
          ls_cfg           TYPE ty_table_cfg,
          lv_year          TYPE i,
          lv_month         TYPE i,
          lv_start_year    TYPE i,
          lv_date_start    TYPE d,
          lv_mm            TYPE string,
          lv_current_gb    TYPE f,
          lv_rec_f         TYPE f,
          lv_base_rec      TYPE i,
          lv_seas_pct      TYPE i,
          lv_noise_pct     TYPE i,
          lv_raw_rec_count TYPE i,
          lv_total_bytes   TYPE int8.

    " ── Configurazione per tabella ────────────────────────────────────────
    " start_gb = peso stimato a inizio serie, growth_gb_yr = GB/anno,
    " bytes_x_rec = dimensione media record
    lt_table_cfg = VALUE #(
      ( table_name = 'VBAK' start_gb = '0.4'  growth_gb_yr = '0.20'  bytes_x_rec = 380 )
      ( table_name = 'VBAP' start_gb = '1.2'  growth_gb_yr = '0.60'  bytes_x_rec = 250 )
      ( table_name = 'MARA' start_gb = '0.3'  growth_gb_yr = '0.02'  bytes_x_rec = 1800 )
      ( table_name = 'MARC' start_gb = '0.7'  growth_gb_yr = '0.05'  bytes_x_rec = 1200 )
      ( table_name = 'MKPF' start_gb = '0.5'  growth_gb_yr = '0.28'  bytes_x_rec = 190 )
      ( table_name = 'MSEG' start_gb = '1.8'  growth_gb_yr = '1.10'  bytes_x_rec = 520 )
    ).

    lv_start_year = sy-datum(4) - c_num_anni + 1.

    DATA(lo_rand_noise) = cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                                        min  = 0
                                                        max  = 100 ).

    LOOP AT lt_table_cfg INTO ls_cfg.

      CHECK ls_cfg-table_name IN is_filtri-r_table_name[].

      DO c_num_mesi TIMES.

        lv_month = ( sy-index - 1 ) MOD 12 + 1.
        lv_year  = lv_start_year + ( sy-index - 1 ) DIV 12.

        lv_mm         = |{ lv_month WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
        lv_date_start = |{ lv_year }{ lv_mm }01|.

        CHECK lv_date_start IN is_filtri-r_snapshot_date[].

        lv_current_gb = ls_cfg-start_gb + ls_cfg-growth_gb_yr * ( sy-index - 1 ) / 12.
        lv_rec_f      = lv_current_gb * 1073741824 / ls_cfg-bytes_x_rec.
        lv_base_rec   = CONV i( lv_rec_f ).

        CASE lv_month.
          WHEN 1 OR 2.       lv_seas_pct = -8.
          WHEN 3 OR 4.       lv_seas_pct = -3.
          WHEN 5 OR 6 OR 7.  lv_seas_pct =  2.
          WHEN 8.            lv_seas_pct =  5.
          WHEN 9 OR 10.      lv_seas_pct =  8.
          WHEN 11 OR 12.     lv_seas_pct = 15.
        ENDCASE.

        lv_noise_pct = lo_rand_noise->get_next( ).

        lv_raw_rec_count = lv_base_rec
                         + lv_base_rec * ( lv_noise_pct - 50 ) / 250
                         + lv_base_rec * lv_seas_pct / 100.
        IF lv_raw_rec_count < 1. lv_raw_rec_count = 1. ENDIF.

        lv_total_bytes = CONV int8( lv_raw_rec_count * ls_cfg-bytes_x_rec ).

        APPEND VALUE #(
          table_name    = ls_cfg-table_name
          snapshot_date = lv_date_start
          record_count  = lv_raw_rec_count
          disk_bytes    = lv_total_bytes
        ) TO rt_mock_data.

      ENDDO.

    ENDLOOP.

  ENDMETHOD.


  METHOD read_list_table_history.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).

    ls_done_list = is_done_list.
    ls_done_list-skip = abap_false.
    ls_done_list-top  = abap_false.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        DATA(lt_table_name) = get_table_names_from_range( is_filtri-r_table_name ).

        DATA(lo_growth) = NEW zag_cl_ml_table_growth( ).

        IF lt_table_name IS INITIAL.
          " Nessun filtro su TableName: fallback sul top N per avere comunque un elenco
          lo_growth->get_top_tables(
            IMPORTING
              yt_tables = DATA(lt_top)
              yt_errors = DATA(lt_top_errors)
          ).
          lt_table_name = VALUE #( FOR <top> IN lt_top ( <top>-table_name ) ).
        ENDIF.

        DATA(lv_date_from) = VALUE sy-datum( ).
        DATA(lv_date_to)   = VALUE sy-datum( ).
        get_date_bounds(
          EXPORTING
            it_range     = is_filtri-r_snapshot_date
          IMPORTING
            ev_date_from = lv_date_from
            ev_date_to   = lv_date_to
        ).

        lo_growth->get_table_history(
          EXPORTING
            xt_table_name = lt_table_name
            xv_date_from  = lv_date_from
            xv_date_to    = lv_date_to
          IMPORTING
            yt_growth     = DATA(lt_growth)
            yt_errors     = DATA(lt_errors)
        ).

        "TODO - simulazione: decommentare per usare dati finti invece del DB reale
*       lt_growth = mock_data_table_history( is_filtri ).

        io_response->set_busi_data( it_busi_data = lt_growth ).
    ENDCASE.

    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_table_size.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).

    ls_done_list = is_done_list.
    ls_done_list-skip = abap_false.
    ls_done_list-top  = abap_false.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        DATA(lt_table_name) = get_table_names_from_range( is_filtri-r_table_name ).

        DATA(lo_growth) = NEW zag_cl_ml_table_growth( ).

        IF lt_table_name IS INITIAL.
          " Nessun filtro su TableName: fallback sul top N per avere comunque un elenco
          lo_growth->get_top_tables(
            IMPORTING
              yt_tables = DATA(lt_top)
              yt_errors = DATA(lt_top_errors)
          ).
          lt_table_name = VALUE #( FOR <top> IN lt_top ( <top>-table_name ) ).
        ENDIF.

        lo_growth->get_table_size(
          EXPORTING
            xt_table_name = lt_table_name
          IMPORTING
            yt_sizes      = DATA(lt_sizes)
            yt_errors     = DATA(lt_errors)
        ).

        io_response->set_busi_data( it_busi_data = lt_sizes ).
    ENDCASE.

    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_top_tables.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).

    ls_done_list = is_done_list.

    " $top: se il client lo richiede lo spingiamo come xv_top_n (limite lato DB
    " sulla query di discovery). $skip non è gestito qui: lo lascia fare il
    " framework sul risultato che restituiamo.
    DATA(lv_top_n) = COND i( WHEN iv_top > 0 THEN iv_top ELSE 9999 ).
    ls_done_list-top  = COND #( WHEN iv_top > 0 THEN abap_true ELSE abap_false ).
    ls_done_list-skip = abap_false.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        DATA(lo_growth) = NEW zag_cl_ml_table_growth( ).

        lo_growth->get_top_tables(
          EXPORTING
            xv_top_n  = lv_top_n
          IMPORTING
            yt_tables = DATA(lt_tables)
            yt_errors = DATA(lt_errors)
        ).

        io_response->set_busi_data( it_busi_data = lt_tables ).
    ENDCASE.

    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.
ENDCLASS.
