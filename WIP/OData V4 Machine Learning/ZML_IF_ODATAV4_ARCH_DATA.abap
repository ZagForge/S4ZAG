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

    ALIASES ts_db02_disk_size    FOR zml_if_odatav4_arch~ts_db02_disk_size .
    ALIASES ts_db02_ram_size     FOR zml_if_odatav4_arch~ts_db02_ram_size .

    METHODS read_list_db02_ram_size
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_orderby_string TYPE string
        !iv_where_clause   TYPE string
        !iv_select_string  TYPE string
        !is_filtri         TYPE zml_cl_bsn_logic=>ts_filters
        !iv_skip           TYPE i
        !iv_top            TYPE i
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .
    METHODS read_list_db02_disk_size
      IMPORTING
        !io_request        TYPE REF TO /iwbep/if_v4_requ_basic_list
        !io_response       TYPE REF TO /iwbep/if_v4_resp_basic_list
        !iv_orderby_string TYPE string
        !iv_where_clause   TYPE string
        !iv_select_string  TYPE string
        !is_filtri         TYPE zml_cl_bsn_logic=>ts_filters
        !iv_skip           TYPE i
        !iv_top            TYPE i
        !is_done_list      TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list
      RAISING
        /iwbep/cx_gateway .

    METHODS mock_data_ram_size
      IMPORTING
        !is_filtri          TYPE zml_cl_bsn_logic=>ts_filters
      RETURNING
        VALUE(yt_mock_data) TYPE zml_if_odatav4_arch=>tt_db02_ram_size
      RAISING
        /iwbep/cx_gateway .
ENDCLASS.



CLASS ZML_CL_ODATAV4_ARCH_DATA IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_ADVANCED~CREATE_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_ADV_CREATE
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_ADV_CREATE
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_dp_advanced~create_entity.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_V4_DP_ADVANCED~CREATE_ENTITY
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
** CATCH /iwbep/cx_gateway .
**ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_BASIC~CREATE_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_CREATE
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_CREATE
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_dp_basic~create_entity.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_V4_DP_BASIC~CREATE_ENTITY
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
** CATCH /iwbep/cx_gateway .
**ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_BASIC~DELETE_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_DELETE
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_DELETE
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_dp_basic~delete_entity.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_V4_DP_BASIC~DELETE_ENTITY
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
** CATCH /iwbep/cx_gateway .
**ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_BASIC~READ_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_READ
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_READ
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_dp_basic~read_entity.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_V4_DP_BASIC~READ_ENTITY
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
** CATCH /iwbep/cx_gateway .
**ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_BASIC~READ_ENTITY_LIST
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_LIST
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_LIST
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
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

    DATA: ls_filtri TYPE zml_cl_bsn_logic=>ts_filters.

    IF ls_todo_list-process-filter = abap_true.

      io_request->get_filter_osql_where_clause(
        IMPORTING
            ev_osql_where_clause = lv_where_clause
      ).

      TRY.
          io_request->get_filter_ranges_for_prop(
            EXPORTING
              iv_property_path = 'TABLE_NAME'    " "-" separated property Path (e.g. COMPL_PROP1-FIELD2)
            IMPORTING
              et_range         = ls_filtri-r_table_name                  " Range table - must be typed for the property's ABAP type
          ).
        CATCH /iwbep/cx_gateway. " SAP Gateway Exception
      ENDTRY.

      TRY.
          io_request->get_filter_ranges_for_prop(
            EXPORTING
              iv_property_path = 'CREATE_TIME'    " "-" separated property Path (e.g. COMPL_PROP1-FIELD2)
            IMPORTING
              et_range         = ls_filtri-r_create_time                  " Range table - must be typed for the property's ABAP type
          ).
        CATCH /iwbep/cx_gateway. " SAP Gateway Exception
      ENDTRY.

      TRY.
          io_request->get_filter_ranges_for_prop(
           EXPORTING
             iv_property_path = 'START_DATE'    " "-" separated property Path (e.g. COMPL_PROP1-FIELD2)
           IMPORTING
             et_range         = ls_filtri-r_start_date                  " Range table - must be typed for the property's ABAP type
         ).
        CATCH /iwbep/cx_gateway. " SAP Gateway Exception
      ENDTRY.

      TRY.
          io_request->get_filter_ranges_for_prop(
           EXPORTING
             iv_property_path = 'END_DATE'    " "-" separated property Path (e.g. COMPL_PROP1-FIELD2)
           IMPORTING
             et_range         = ls_filtri-r_end_date                  " Range table - must be typed for the property's ABAP type
         ).
        CATCH /iwbep/cx_gateway. " SAP Gateway Exception
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
      WHEN tc_entity_set_names-internal-db02_ram_size.

        read_list_db02_ram_size(
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
      WHEN tc_entity_set_names-internal-db02_disk_size.

        read_list_db02_disk_size(
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


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_BASIC~READ_REF_TARGET_KEY_DATA_LIST
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_REF_L
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_REF_L
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_dp_basic~read_ref_target_key_data_list.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_V4_DP_BASIC~READ_REF_TARGET_KEY_DATA_LIST
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
** CATCH /iwbep/cx_gateway .
**ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_DATA->/IWBEP/IF_V4_DP_BASIC~UPDATE_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_UPDATE
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_UPDATE
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_dp_basic~update_entity.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_V4_DP_BASIC~UPDATE_ENTITY
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
** CATCH /iwbep/cx_gateway .
**ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_ODATAV4_ARCH_DATA->MOCK_DATA_RAM_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_FILTRI                      TYPE        ZML_CL_BSN_LOGIC=>TS_FILTERS
* | [<-()] YT_MOCK_DATA                   TYPE        ZML_IF_ODATAV4_ARCH=>TT_DB02_RAM_SIZE
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD mock_data_ram_size.

    CONSTANTS: c_num_anni TYPE i VALUE 10,
               c_num_mesi TYPE i VALUE 120.

    TYPES: BEGIN OF ty_table_cfg,
             table_name   TYPE string,
             start_gb     TYPE f,
             growth_gb_yr TYPE f,
             bytes_x_rec  TYPE i,
           END OF ty_table_cfg.

    DATA: lt_table_cfg      TYPE TABLE OF ty_table_cfg,
          ls_cfg            TYPE ty_table_cfg,
          lv_year           TYPE i,
          lv_next_year      TYPE i,
          lv_month          TYPE i,
          lv_next_month     TYPE i,
          lv_start_year     TYPE i,
          lv_date_start     TYPE d,
          lv_date_end       TYPE d,
          lv_start          TYPE string,
          lv_end            TYPE string,
          lv_base_rec       TYPE i,
          lv_base_size      TYPE i,
          lv_raw_rec_count  TYPE i,
          lv_seas_pct       TYPE i,
          lv_noise_rec_pct  TYPE i,
          lv_noise_size_pct TYPE i,
          lv_mm             TYPE string,
          lv_mm_next        TYPE string,
          lv_current_gb     TYPE f,
          lv_rec_f          TYPE f.

    " ── Configurazione per tabella ────────────────────────────────────────────
    " table_name   | start_gb | growth_gb_yr | bytes_x_rec
    " start_gb     = peso stimato tabella ad inizio serie
    " growth_gb_yr = GB aggiunti ogni anno (esprime la velocità di crescita)
    " bytes_x_rec  = dimensione media record (caratteristica tecnica della tabella)

    lt_table_cfg = VALUE #(
      " ── Ordini di vendita ─────────────────────────────────────────────────────
      ( table_name = `VBAK` start_gb = '0.4'  growth_gb_yr = '0.20'  bytes_x_rec = 380 )
      " Testate OdV: 1 record per ordine, cresce con il business. Record medio
      " (header fields): ~380 byte. Crescita moderata e costante.

      ( table_name = `VBAP` start_gb = '1.2'  growth_gb_yr = '0.60'  bytes_x_rec = 250 )
      " Posizioni OdV: mediamente 4-5 righe per testata → 5x i record di VBAK.
      " Record più corto (dati posizione) ma volume molto maggiore.

      " ── Anagrafica materiali ──────────────────────────────────────────────────
      ( table_name = `MARA` start_gb = '0.3'  growth_gb_yr = '0.02'  bytes_x_rec = 1800 )
      " Master data: ~200 campi, record pesante (~1800 byte). Cresce solo con
      " nuovi materiali a catalogo → quasi statica nel tempo.

      ( table_name = `MARC` start_gb = '0.7'  growth_gb_yr = '0.05'  bytes_x_rec = 1200 )
      " Dati materiale per plant: 1 record per materiale × plant.
      " Con 4-5 plant è circa 4-5x MARA in numero record. Record leggermente
      " più corto. Anch'essa master data, crescita lenta.

      " ── Movimenti di magazzino ────────────────────────────────────────────────
      ( table_name = `MKPF` start_gb = '0.5'  growth_gb_yr = '0.28'  bytes_x_rec = 190 )
      " Testate documenti materiale: 1 record per bolla di movimento.
      " Header molto snello (~190 byte), alto volume transazionale.

      ( table_name = `MSEG` start_gb = '1.8'  growth_gb_yr = '1.10'  bytes_x_rec = 520 )
      " Posizioni documenti materiale: la tabella più grande del lotto.
      " 3-4 righe per testata MKPF, record ricco (~520 byte). Cresce
      " aggressivamente: è il log di ogni singolo movimento fisico di merce.
    ).

    lv_start_year = sy-datum(4) - c_num_anni + 1.

    DATA(lv_seed_rec)  = cl_abap_random=>seed( ).
    DATA(lv_seed_size) = lv_seed_rec + 99991.

    DATA(lo_rand_noise_rec)  = cl_abap_random_int=>create( seed = lv_seed_rec
                                                            min  = 0
                                                            max  = 100 ).
    DATA(lo_rand_noise_size) = cl_abap_random_int=>create( seed = lv_seed_size
                                                            min  = 0
                                                            max  = 100 ).

    LOOP AT lt_table_cfg INTO ls_cfg.

      CHECK ls_cfg-table_name IN is_filtri-r_table_name[].

      DO c_num_mesi TIMES.

        " ── Anno/mese ─────────────────────────────────────────────────────────
        lv_month = ( sy-index - 1 ) MOD 12 + 1.
        lv_year  = lv_start_year + ( sy-index - 1 ) DIV 12.

        lv_mm = |{ lv_month WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
        lv_start      = |{ lv_year }{ lv_mm }01|.
        lv_date_start = lv_start.

        IF lv_month = 12.
          lv_next_year = lv_year + 1.
          lv_date_end  = |{ lv_next_year }0101|.
        ELSE.
          lv_next_month = lv_month + 1.
          lv_mm_next    = |{ lv_next_month WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
          lv_date_end   = |{ lv_year }{ lv_mm_next }01|.
        ENDIF.
        lv_date_end = lv_date_end - 1.
        lv_end      = CONV string( lv_date_end ).

        " ── Filtro su create_time (formato DD.MM.YYYY HH:MM:SS) ──────────────
        DATA lv_create_time TYPE hdb_column_tables_part_size-create_time.
        lv_create_time = |{ lv_date_start+6(2) }.{ lv_date_start+4(2) }.{ lv_date_start(4) } 00:00:00|.
        CHECK lv_create_time IN is_filtri-r_create_time[].


        " ── GB correnti: start_gb + crescita lineare mensile ──────────────────
        lv_current_gb = ls_cfg-start_gb
                      + ls_cfg-growth_gb_yr * ( sy-index - 1 ) / 12.

        " ── Record base derivati dai GB e dai byte/record della tabella ────────
        lv_rec_f     = lv_current_gb * 1073741824 / ls_cfg-bytes_x_rec.
        lv_base_rec  = CONV i( lv_rec_f ).
        lv_base_size = ls_cfg-bytes_x_rec.

        " ── Stagionalità ──────────────────────────────────────────────────────
        CASE lv_month.
          WHEN 1 OR 2.       lv_seas_pct = -8.
          WHEN 3 OR 4.       lv_seas_pct = -3.
          WHEN 5 OR 6 OR 7.  lv_seas_pct =  2.
          WHEN 8.            lv_seas_pct =  5.
          WHEN 9 OR 10.      lv_seas_pct =  8.
          WHEN 11 OR 12.     lv_seas_pct = 15.
        ENDCASE.

        " ── Rumore ±20% proporzionale + stagionale ────────────────────────────
        lv_noise_rec_pct  = lo_rand_noise_rec->get_next( ).
        lv_noise_size_pct = lo_rand_noise_size->get_next( ).

        lv_raw_rec_count = lv_base_rec
                         + lv_base_rec * ( lv_noise_rec_pct - 50 ) / 250
                         + lv_base_rec * lv_seas_pct / 100.
        IF lv_raw_rec_count < 1. lv_raw_rec_count = 1. ENDIF.

        lv_base_size = ls_cfg-bytes_x_rec
                     + ls_cfg-bytes_x_rec * ( lv_noise_size_pct - 50 ) / 500
                     + ls_cfg-bytes_x_rec * lv_seas_pct / 200.
        IF lv_base_size < 1. lv_base_size = 1. ENDIF.

        " ── Output ────────────────────────────────────────────────────────────
        APPEND INITIAL LINE TO yt_mock_data ASSIGNING FIELD-SYMBOL(<ls_stat>).
        <ls_stat>-table_name                     = ls_cfg-table_name.
        <ls_stat>-schema_name                    = 'SAPHANADB'.
        <ls_stat>-host                           = 'hanahost01'.
        <ls_stat>-port                           = 30003.
        <ls_stat>-snapshot_id                    = |{ lv_date_start DATE = ISO } 00:00:00.000|.
        <ls_stat>-create_time                    = |{ lv_date_start DATE = ISO } 00:00:00.000|.
        <ls_stat>-last_merge_time                = |{ lv_date_end   DATE = ISO } 23:59:59.000|.

        " Dimensioni (GB -> bytes)
        DATA lv_total_bytes TYPE int8.
        lv_total_bytes = CONV int8( lv_current_gb * 1073741824 ).

        <ls_stat>-memory_size_in_total           = lv_total_bytes.
        <ls_stat>-memory_size_in_main            = lv_total_bytes * 90 / 100.
        <ls_stat>-memory_size_in_delta           = lv_total_bytes * 10 / 100.
        <ls_stat>-estim_max_memory_size_in_total = lv_total_bytes * 110 / 100.

        " Record
        <ls_stat>-record_count                   = lv_raw_rec_count.
        <ls_stat>-raw_record_count_in_main       = lv_raw_rec_count * 90 / 100.
        <ls_stat>-raw_record_count_in_delta      = lv_raw_rec_count * 10 / 100.
        <ls_stat>-raw_rec_cnt_in_history_main    = 0.
        <ls_stat>-raw_rec_cnt_in_hisotry_delta   = 0.
        <ls_stat>-last_compressed_record_count   = lv_raw_rec_count * 90 / 100.

        " Stato
        <ls_stat>-is_delta_loaded                = 'X'.
        <ls_stat>-loaded                         = 'FULL'.
        <ls_stat>-location                       = 'COLUMN'.
        <ls_stat>-part_id                        = 0.
        <ls_stat>-part_count                     = 1.

      ENDDO.

    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_ODATAV4_ARCH_DATA->READ_LIST_DB02_DISK_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_LIST
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_LIST
* | [--->] IV_ORDERBY_STRING              TYPE        STRING
* | [--->] IV_WHERE_CLAUSE                TYPE        STRING
* | [--->] IV_SELECT_STRING               TYPE        STRING
* | [--->] IS_FILTRI                      TYPE        ZML_CL_BSN_LOGIC=>TS_FILTERS
* | [--->] IV_SKIP                        TYPE        I
* | [--->] IV_TOP                         TYPE        I
* | [--->] IS_DONE_LIST                   TYPE        /IWBEP/IF_V4_REQU_BASIC_LIST=>TY_S_TODO_PROCESS_LIST
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD read_list_db02_disk_size.
    DATA: lt_key_arch_db02_disk_size TYPE STANDARD TABLE OF ts_db02_disk_size,
          lr_key_arch_db02_disk_size TYPE zml_if_odatav4_arch=>ts_key_range-tabname,
          lv_max_index               TYPE i,
          lt_arch_db02_disk_size     TYPE STANDARD TABLE OF ts_db02_disk_size.

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
            et_key_data = lt_key_arch_db02_disk_size
      ).

      CLEAR lr_key_arch_db02_disk_size[].
      lr_key_arch_db02_disk_size = VALUE #( FOR <key> IN lt_key_arch_db02_disk_size
          ( sign = 'I' option = 'EQ' low = <key>-table_name )
      ).
      ls_done_list-key_data = abap_true.

    ENDIF.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        DATA(lc_bsn_logic) = NEW zml_cl_bsn_logic( ).

        lc_bsn_logic->get_db02_disk_size(
          EXPORTING
            xs_filters = is_filtri
          IMPORTING
            yt_tab     = DATA(lt_tab)
        ).

        lt_key_arch_db02_disk_size = CORRESPONDING #( lt_tab ).


        "TODO - simulazione
*        lt_key_arch_db02_disk_size = me->mock_data_ram_size( is_filtri ).

        io_response->set_busi_data( it_busi_data = lt_key_arch_db02_disk_size ).
    ENDCASE.

    io_response->set_is_done( ls_done_list ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_ODATAV4_ARCH_DATA->READ_LIST_DB02_RAM_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_REQUEST                     TYPE REF TO /IWBEP/IF_V4_REQU_BASIC_LIST
* | [--->] IO_RESPONSE                    TYPE REF TO /IWBEP/IF_V4_RESP_BASIC_LIST
* | [--->] IV_ORDERBY_STRING              TYPE        STRING
* | [--->] IV_WHERE_CLAUSE                TYPE        STRING
* | [--->] IV_SELECT_STRING               TYPE        STRING
* | [--->] IS_FILTRI                      TYPE        ZML_CL_BSN_LOGIC=>TS_FILTERS
* | [--->] IV_SKIP                        TYPE        I
* | [--->] IV_TOP                         TYPE        I
* | [--->] IS_DONE_LIST                   TYPE        /IWBEP/IF_V4_REQU_BASIC_LIST=>TY_S_TODO_PROCESS_LIST
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD read_list_db02_ram_size.
    DATA: lt_key_arch_db02_ram_size TYPE STANDARD TABLE OF ts_db02_ram_size,
          lr_key_arch_db02_ram_size TYPE zml_if_odatav4_arch=>ts_key_range-tabname,
          lv_max_index              TYPE i,
          lt_arch_db02_ram_size     TYPE STANDARD TABLE OF ts_db02_ram_size.

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
            et_key_data = lt_key_arch_db02_ram_size
      ).

      CLEAR lr_key_arch_db02_ram_size[].
      lr_key_arch_db02_ram_size = VALUE #( FOR <key> IN lt_key_arch_db02_ram_size
          ( sign = 'I' option = 'EQ' low = <key>-table_name )
      ).
      ls_done_list-key_data = abap_true.

    ENDIF.

    CASE ls_todo_list-return-busi_data.
      WHEN abap_true.

        DATA(lc_bsn_logic) = NEW zml_cl_bsn_logic( ).

        lc_bsn_logic->get_db02_ram_size(
          EXPORTING
            xs_filters = is_filtri
          IMPORTING
            yt_tab     = DATA(lt_tab)
        ).

        lt_key_arch_db02_ram_size = CORRESPONDING #( lt_tab ).

        "TODO - simulazione
        lt_key_arch_db02_ram_size = CORRESPONDING #( me->mock_data_ram_size( is_filtri ) ).


        io_response->set_busi_data( it_busi_data = lt_key_arch_db02_ram_size ).
    ENDCASE.

    io_response->set_is_done( ls_done_list ).
  ENDMETHOD.
ENDCLASS.