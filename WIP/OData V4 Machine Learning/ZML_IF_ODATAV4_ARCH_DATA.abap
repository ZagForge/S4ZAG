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
    ALIASES tc_nav_prop_names    FOR zml_if_odatav4_arch~tc_nav_prop_names .

    ALIASES ts_top_tables        FOR zml_if_odatav4_arch~ts_top_tables .
    ALIASES ts_table_growth      FOR zml_if_odatav4_arch~ts_table_growth .
    ALIASES ts_growth_point      FOR zml_if_odatav4_arch~ts_growth_point .

    METHODS read_list_top_tables
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_top            TYPE i
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    " TableGrowth: solo sintesi, piatta — lo storico si ottiene con
    " $expand=_History (entity separata GrowthPoint).
    METHODS read_list_table_growth
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_top            TYPE i
        !is_filtri         TYPE zml_if_odatav4_arch=>ts_filters
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    " GrowthPoint: raggiunta di norma via $expand=_History da TableGrowth
    " (chiavi risolte da READ_REF_KEY_LIST_TABLE_GROWTH), ma supporta anche
    " accesso diretto filtrando per TableName/SnapshotDate.
    METHODS read_list_growth_point
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !is_filtri         TYPE zml_if_odatav4_arch=>ts_filters
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    " Risolve le chiavi di GrowthPoint (TableName+SnapshotDate) raggiungibili
    " da una data riga TableGrowth via la nav property _History.
    METHODS read_ref_key_list_table_growth
      IMPORTING
        !io_request  TYPE REF TO /iwbep/if_v4_requ_basic_ref_l
        !io_response TYPE REF TO /iwbep/if_v4_resp_basic_ref_l
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

    DATA: lv_top TYPE i.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).


    " $top handling — solo TopTables lo spinge davvero come limite di query.
    "---------------------------------------------------------------
    lv_top = 0.

    IF ls_todo_list-process-top = abap_true.
      io_request->get_top( IMPORTING ev_top = lv_top ).
    ENDIF.


    "$ filter handling
    "---------------------------------------------------------------
    DATA: ls_filtri TYPE zml_if_odatav4_arch=>ts_filters.

    IF ls_todo_list-process-filter = abap_true.

      TRY.
          io_request->get_filter_ranges_for_prop(
            EXPORTING
              iv_property_path = 'TABLE_NAME'    " TableGrowth / GrowthPoint
            IMPORTING
              et_range         = ls_filtri-r_table_name
          ).
        CATCH /iwbep/cx_gateway. " proprietà non presente su questa entity — ignora
      ENDTRY.

      TRY.
          io_request->get_filter_ranges_for_prop(
            EXPORTING
              iv_property_path = 'SNAPSHOT_DATE'    " solo GrowthPoint
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
            io_request   = io_request
            io_response  = io_response
            iv_top       = lv_top
            is_done_list = ls_done_list
        ).

      WHEN tc_entity_set_names-internal-table_growth.

        read_list_table_growth(
            io_request   = io_request
            io_response  = io_response
            iv_top       = lv_top
            is_filtri    = ls_filtri
            is_done_list = ls_done_list
        ).

      WHEN tc_entity_set_names-internal-growth_point.

        read_list_growth_point(
            io_request   = io_request
            io_response  = io_response
            is_filtri    = ls_filtri
            is_done_list = ls_done_list
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
      WHEN tc_entity_type_names-internal-table_growth.

        read_ref_key_list_table_growth(
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


  METHOD read_ref_key_list_table_growth.

    " ─────────────────────────────────────────────────────────────────
    " $expand=_History: data una riga TableGrowth (chiave TableName),
    " risolve le chiavi (TableName, SnapshotDate) di GrowthPoint raggiungibili.
    " ─────────────────────────────────────────────────────────────────

    DATA: ls_key_data TYPE ts_table_growth.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_ref_l=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_ref_l=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).

    IF ls_todo_list-process-source_key_data = abap_true.
      io_request->get_source_key_data(
        IMPORTING
            es_source_key_data = ls_key_data
      ).
      ls_done_list-source_key_data = abap_true.
    ENDIF.

    DATA(lo_growth) = NEW zag_cl_ml_table_growth( ).

    lo_growth->get_table_growth(
      EXPORTING
        xt_table_name      = VALUE #( ( ls_key_data-table_name ) )
        xv_include_history = abap_true
      IMPORTING
        yt_growth          = DATA(lt_growth)
        yt_errors          = DATA(lt_errors)
    ).

    DATA(lt_key_growth_point) = VALUE zml_if_odatav4_arch=>tt_growth_point(
      FOR <g> IN lt_growth
      FOR <h> IN <g>-history
      ( table_name = ls_key_data-table_name snapshot_date = <h>-snapshot_date )
    ).

    io_response->set_target_key_data( lt_key_growth_point ).

    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_growth_point.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).

    ls_done_list = is_done_list.
    ls_done_list-skip = abap_false.
    ls_done_list-top  = abap_false.

    " Chiavi risolte via $expand (TableName+SnapshotDate) — se assenti si
    " tratta di accesso diretto all'entity set, si usa il $filter su TableName.
    DATA lt_key_growth_point TYPE STANDARD TABLE OF ts_growth_point.

    IF ls_todo_list-process-key_data = abap_true.
      io_request->get_key_data( IMPORTING et_key_data = lt_key_growth_point ).
      ls_done_list-key_data = abap_true.
    ENDIF.

    DATA(lt_table_name) = COND zag_cl_ml_table_growth=>tt_tabname(
      WHEN lt_key_growth_point IS NOT INITIAL
      THEN VALUE #( FOR <key> IN lt_key_growth_point ( <key>-table_name ) )
      ELSE get_table_names_from_range( is_filtri-r_table_name )
    ).

    SORT lt_table_name.
    DELETE ADJACENT DUPLICATES FROM lt_table_name.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        DATA(lv_date_from) = VALUE sy-datum( ).
        DATA(lv_date_to)   = VALUE sy-datum( ).
        get_date_bounds(
          EXPORTING
            it_range     = is_filtri-r_snapshot_date
          IMPORTING
            ev_date_from = lv_date_from
            ev_date_to   = lv_date_to
        ).

        DATA(lo_growth) = NEW zag_cl_ml_table_growth( ).

        " Filtro date spinto nella query storica stessa (XV_DATE_FROM/TO),
        " non fatto qui in ABAP dopo aver scaricato tutto.
        lo_growth->get_table_growth(
          EXPORTING
            xt_table_name      = lt_table_name
            xv_include_history = abap_true
            xv_date_from       = lv_date_from
            xv_date_to         = lv_date_to
          IMPORTING
            yt_growth          = DATA(lt_growth)
            yt_errors          = DATA(lt_errors)
        ).

        DATA(lt_points) = VALUE zml_if_odatav4_arch=>tt_growth_point(
          FOR <g> IN lt_growth
          FOR <h> IN <g>-history
          ( table_name    = <g>-table_name
            snapshot_date = <h>-snapshot_date
            record_count  = <h>-record_count
            disk_bytes    = <h>-disk_bytes )
        ).

        io_response->set_busi_data( it_busi_data = lt_points ).
    ENDCASE.

    io_response->set_is_done( ls_done_list ).

  ENDMETHOD.


  METHOD read_list_table_growth.

    DATA: ls_todo_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list         VALUE IS INITIAL,
          ls_done_list TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list VALUE IS INITIAL.

    io_request->get_todos( IMPORTING es_todo_list = ls_todo_list ).

    ls_done_list = is_done_list.
    ls_done_list-skip = abap_false.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        " Elenco tabelle dal $filter; se vuoto GET_TABLE_GROWTH fa da sola
        " il fallback sul top N (rilevante solo in questo caso: se il
        " filtro elenca già le tabelle, $top qui non si applica).
        DATA(lt_table_name) = get_table_names_from_range( is_filtri-r_table_name ).

        ls_done_list-top = COND #(
          WHEN lt_table_name IS INITIAL AND iv_top > 0 THEN abap_true
          ELSE abap_false ).

        DATA(lo_growth) = NEW zag_cl_ml_table_growth( ).

        " Storico non richiesto qui: si ottiene con $expand=_History
        " (entity separata GrowthPoint) — niente query storiche inutili.
        lo_growth->get_table_growth(
          EXPORTING
            xt_table_name      = lt_table_name
            xv_top_n           = COND #( WHEN iv_top > 0 THEN iv_top ELSE 20 )
            xv_include_history = abap_false
          IMPORTING
            yt_growth          = DATA(lt_growth_full)
            yt_errors          = DATA(lt_errors)
        ).

        DATA(lt_growth) = VALUE zml_if_odatav4_arch=>tt_table_growth(
          FOR <g> IN lt_growth_full
          ( table_name  = <g>-table_name
            schema_name = <g>-schema_name
            disk_bytes  = <g>-disk_bytes
            rec_count   = <g>-rec_count )
        ).

        io_response->set_busi_data( it_busi_data = lt_growth ).
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
