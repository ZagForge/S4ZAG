CLASS zml_cl_table_growth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    " === Output unificato ===
    TYPES:
      BEGIN OF ts_table_growth,
        table_name    TYPE tabname,
        schema_name   TYPE char30,
        snapshot_date TYPE d,          " primo giorno del mese (YYYYMM01) su HDB, data campione su MSS
        record_count  TYPE int8,       " record inseriti nel periodo
        disk_mb       TYPE p LENGTH 8 DECIMALS 2, " stima MB (HDB) o dato reale (MSS)
      END OF ts_table_growth,
      tt_table_growth TYPE TABLE OF ts_table_growth WITH DEFAULT KEY.

    " === Errori ===
    " Codici: NM = nessun mapping data, SE = sql error, FM = function module error
    TYPES:
      BEGIN OF ts_error,
        table_name TYPE tabname,
        error_code TYPE sychar02,
        error_msg  TYPE string,
      END OF ts_error,
      tt_error TYPE TABLE OF ts_error WITH DEFAULT KEY.

    TYPES: tt_tabname TYPE TABLE OF tabname WITH DEFAULT KEY.

    " === Entry point ===
    METHODS get_table_growth
      IMPORTING
        xt_table_name TYPE tt_tabname       OPTIONAL  " se vuoto → top N
        xv_top_n      TYPE i                DEFAULT 20
        xv_date_from  TYPE sy-datum         OPTIONAL
        xv_date_to    TYPE sy-datum         OPTIONAL
      EXPORTING
        yt_growth     TYPE tt_table_growth
        yt_errors     TYPE tt_error.

  PRIVATE SECTION.

    " Mapping tabella → campo data (usato solo su HDB per query stimata)
    TYPES:
      BEGIN OF ts_date_field_map,
        table_name TYPE tabname,
        date_field TYPE fieldname,
      END OF ts_date_field_map,
      tt_date_field_map TYPE TABLE OF ts_date_field_map WITH DEFAULT KEY.

    " Lista tabelle di lavoro (da top N o da filtro input)
    TYPES:
      BEGIN OF ts_top_table,
        table_name  TYPE tabname,
        schema_name TYPE char30,
        disk_mb     TYPE p LENGTH 8 DECIMALS 2,
        rec_count   TYPE int8,
      END OF ts_top_table,
      tt_top_table TYPE TABLE OF ts_top_table WITH DEFAULT KEY.

    " Output query HANA top N — l'ordine dei campi deve rispettare l'ordine SELECT
    TYPES:
      BEGIN OF ts_hdb_top_result,
        table_name  TYPE char128,
        schema_name TYPE char128,
        rec_count   TYPE int8,
        disk_bytes  TYPE int8,
      END OF ts_hdb_top_result,
      tt_hdb_top_result TYPE TABLE OF ts_hdb_top_result WITH DEFAULT KEY.

    " Output query stimata mensile — ordine: MONTH_KEY, RECORD_COUNT
    TYPES:
      BEGIN OF ts_month_count,
        month_key    TYPE char6,   " YYYYMM
        record_count TYPE int8,
      END OF ts_month_count,
      tt_month_count TYPE TABLE OF ts_month_count WITH DEFAULT KEY.

    " Stats correnti tabella HDB — ordine: REC_COUNT, DISK_BYTES
    TYPES:
      BEGIN OF ts_hdb_cur_stats,
        rec_count  TYPE int8,
        disk_bytes TYPE int8,
      END OF ts_hdb_cur_stats,
      tt_hdb_cur_stats TYPE TABLE OF ts_hdb_cur_stats WITH DEFAULT KEY.

    " Schema ABAP corrente
    TYPES:
      BEGIN OF ts_schema,
        schema_name TYPE char128,
      END OF ts_schema.

    " Parametri per C_DB_FUNCTION
    TYPES:
      BEGIN OF ty_param,
        data_ref    TYPE REF TO data,
        ind_ref     TYPE REF TO int2,
        inout_type  TYPE typint1,
        eval_ind(1) TYPE x,
      END OF ty_param,
      tt_param     TYPE STANDARD TABLE OF ty_param WITH DEFAULT KEY,
      ty_conda(80) TYPE x.

    METHODS get_db_system
      RETURNING VALUE(yv_dbsys) TYPE syst_dbsys.

    METHODS get_date_field_mapping
      RETURNING VALUE(yt_map) TYPE tt_date_field_map.

    METHODS get_top_n_tables_hdb
      IMPORTING
        xv_top_n  TYPE i
        xv_schema TYPE char30
      EXPORTING
        yt_tables TYPE tt_top_table
        yt_errors TYPE tt_error.

    " Interfaccia MSS_GET_TOP_N_TABLES da verificare (nomi parametri/campi potrebbero differire)
    METHODS get_top_n_tables_mss
      IMPORTING
        xv_top_n  TYPE i
      EXPORTING
        yt_tables TYPE tt_top_table
        yt_errors TYPE tt_error.

    METHODS get_history_hdb
      IMPORTING
        xv_table_name  TYPE tabname
        xv_schema_name TYPE char30
        xv_date_field  TYPE fieldname
        xv_date_from   TYPE d OPTIONAL
        xv_date_to     TYPE d OPTIONAL
      EXPORTING
        yt_growth      TYPE tt_table_growth
        yt_errors      TYPE tt_error.

    " Campi MSSTABSTATS (rowcnt, reserved) da verificare
    METHODS get_history_mss
      IMPORTING
        xv_table_name TYPE tabname
        xv_date_from  TYPE d OPTIONAL
        xv_date_to    TYPE d OPTIONAL
      EXPORTING
        yt_growth     TYPE tt_table_growth
        yt_errors     TYPE tt_error.

    METHODS execute_hana_query
      IMPORTING
        xv_statement TYPE string
        xt_inparams  TYPE tt_param
      EXPORTING
        yv_sql_code  TYPE i
        yv_sql_msg   TYPE dbsqlmsg
      CHANGING
        xyt_outtab   TYPE REF TO data.

ENDCLASS.



CLASS zml_cl_table_growth IMPLEMENTATION.


  METHOD execute_hana_query.

    " ─────────────────────────────────────────────────────────────────
    " Binding output posizionale via SET_PARAM_TABLE; parametri di
    " input bindati in ordine con SET_PARAM (uno per ogni '?').
    " ─────────────────────────────────────────────────────────────────

    FIELD-SYMBOLS: <outtab> TYPE ANY TABLE,
                   <in>     TYPE any.

    ASSIGN xyt_outtab->* TO <outtab>.
    CLEAR <outtab>.

    TRY.
        DATA(lo_connection) = cl_sql_connection=>get_connection( ).
        DATA(lo_statement)  = lo_connection->create_statement( ).

        LOOP AT xt_inparams INTO DATA(ls_in).
          ASSIGN ls_in-data_ref->* TO <in>.
          lo_statement->set_param( <in> ).
        ENDLOOP.

        DATA(lo_result) = lo_statement->execute_query( xv_statement ).
        lo_result->set_param_table( REF #( <outtab> ) ).

        DO.
          DATA(lv_rows) = lo_result->next_package( ).
          IF lv_rows = 0.
            EXIT.
          ENDIF.
        ENDDO.

        lo_result->close( ).
        yv_sql_code = 0.

      CATCH cx_sql_exception INTO DATA(lx_sql).
        yv_sql_code = lx_sql->sql_code.
        yv_sql_msg  = lx_sql->get_text( ).
    ENDTRY.

  ENDMETHOD.

  METHOD get_date_field_mapping.

    " ─────────────────────────────────────────────────────────────────
    " MAPPING TABELLA → CAMPO DATA (solo percorso HDB)
    " Aggiungere righe qui per tabelle non presenti
    " ─────────────────────────────────────────────────────────────────

    yt_map = VALUE #(
      " --- Vendite ---
      ( table_name = 'VBAK'   date_field = 'ERDAT' )   " data creazione ordine
      ( table_name = 'VBAP'   date_field = 'ERDAT' )   " data creazione posizione
      ( table_name = 'VBEP'   date_field = 'EDATU' )   " data confermata riga schedule
      ( table_name = 'VBFA'   date_field = 'ERDAT' )   " documento successivo/precedente

      " --- Acquisti ---
      ( table_name = 'EKKO'   date_field = 'ERDAT' )   " data creazione ordine acquisto
      ( table_name = 'EKPO'   date_field = 'ERDAT' )   " data creazione posizione OA
      ( table_name = 'EKET'   date_field = 'EINDT' )   " data consegna prevista

      " --- Contabilità ---
      ( table_name = 'BKPF'   date_field = 'BUDAT' )   " data registrazione
      ( table_name = 'BSEG'   date_field = 'BUDAT' )   " data registrazione
      ( table_name = 'BSAK'   date_field = 'BUDAT' )   " partite aperte fornitori archivio
      ( table_name = 'BSIK'   date_field = 'BUDAT' )   " partite aperte fornitori
      ( table_name = 'BSAD'   date_field = 'BUDAT' )   " partite aperte clienti archivio
      ( table_name = 'BSID'   date_field = 'BUDAT' )   " partite aperte clienti

      " --- Fatturazione passiva ---
      ( table_name = 'RBKP'   date_field = 'BUDAT' )   " data registrazione fattura

      " --- Movimenti merci ---
      ( table_name = 'MKPF'   date_field = 'BUDAT' )   " data registrazione movimento
      ( table_name = 'MSEG'   date_field = 'BUDAT' )   " data registrazione posizione

      " --- S/4HANA ---
      ( table_name = 'ACDOCA' date_field = 'BUDAT' )   " universal journal
      ( table_name = 'ACDOCP' date_field = 'BUDAT' )   " universal journal plan

      " --- Anagrafiche ---
      ( table_name = 'MARA'   date_field = 'ERSDA' )   " data creazione materiale
      ( table_name = 'KNA1'   date_field = 'ERDAT' )   " data creazione cliente
      ( table_name = 'LFA1'   date_field = 'ERDAT' )   " data creazione fornitore

      " --- Change Documents ---
      ( table_name = 'CDHDR'  date_field = 'UDATE' )   " data modifica

      " --- Application Log ---
      ( table_name = 'BALHDR' date_field = 'ALDATE' )  " data scrittura log
    ).
  ENDMETHOD.


  METHOD get_db_system.

    " ─────────────────────────────────────────────────────────────────
    " RILEVAMENTO DB
    " ─────────────────────────────────────────────────────────────────

    " HDB = SAP HANA, MSS = Microsoft SQL Server
    yv_dbsys = sy-dbsys.
  ENDMETHOD.


  METHOD get_history_hdb.

    " ─────────────────────────────────────────────────────────────────
    " STORICO MENSILE — HDB (approccio rustico)
    "
    " 1. Legge stats correnti da M_CS_TABLES → calcola bytes/riga
    " 2. COUNT(*) GROUP BY mese sul campo data mappato
    " 3. Stima disk_mb = record_mese * bytes_per_riga_corrente / 1024 / 1024
    "    (approssimazione per ML: trend corretto, valore assoluto stimato)
    " ─────────────────────────────────────────────────────────────────

    DATA lv_code TYPE i.
    DATA lv_msg  TYPE dbsqlmsg.

    " ── 1. Stats correnti per stima bytes/riga ─────────────────
    DATA lt_cur TYPE tt_hdb_cur_stats.
    DATA lr_cur TYPE REF TO data.
    GET REFERENCE OF lt_cur INTO lr_cur.

    DATA lv_statement TYPE string.

    lv_statement = |SELECT RECORD_COUNT, MEMORY_SIZE_IN_TOTAL | &&
                   |FROM M_CS_TABLES | &&
                   |WHERE SCHEMA_NAME = '{ xv_schema_name }' | &&
                   |AND TABLE_NAME = '{ xv_table_name }'|.

    execute_hana_query(
      EXPORTING
        xv_statement = lv_statement
        xt_inparams  = VALUE tt_param( )
      IMPORTING
        yv_sql_code  = lv_code
        yv_sql_msg   = lv_msg
      CHANGING
        xyt_outtab   = lr_cur ).

    IF lv_code <> 0.
      APPEND VALUE ts_error(
        table_name = xv_table_name
        error_code = 'SE'
        error_msg  = |Stats correnti { xv_table_name }: { lv_msg }|
      ) TO yt_errors.
      RETURN.
    ENDIF.

    READ TABLE lt_cur INTO DATA(ls_cur) INDEX 1.
    DATA(lv_bytes_per_row) = COND int8(
      WHEN ls_cur-rec_count > 0
      THEN ls_cur-disk_bytes / ls_cur-rec_count
      ELSE 0 ).

    " ── 2. Costruisce WHERE per filtro date ────────────────────
    DATA lv_conditions TYPE string.
    IF xv_date_from IS NOT INITIAL.
      lv_conditions = |{ xv_date_field } >= '{ xv_date_from }'|.
    ENDIF.
    IF xv_date_to IS NOT INITIAL.
      lv_conditions = |{ lv_conditions }| &&
                      |{ COND #( WHEN lv_conditions IS NOT INITIAL THEN ' AND ' ELSE '' ) }| &&
                      |{ xv_date_field } <= '{ xv_date_to }'|.
    ENDIF.
    DATA(lv_where) = COND string(
      WHEN lv_conditions IS NOT INITIAL
      THEN |WHERE { lv_conditions } |
      ELSE '' ).

    " ── 3. Query rustica: record per mese ──────────────────────
    DATA lt_months TYPE tt_month_count.
    DATA lr_months TYPE REF TO data.
    GET REFERENCE OF lt_months INTO lr_months.

    lv_statement = |SELECT SUBSTRING({ xv_date_field }, 1, 6) AS MONTH_KEY, | &&
                   |COUNT(*) AS RECORD_COUNT | &&
                   |FROM { xv_schema_name }.{ xv_table_name } | &&
                   |{ lv_where }| &&
                   |GROUP BY SUBSTRING({ xv_date_field }, 1, 6) | &&
                   |ORDER BY 1|.

    execute_hana_query(
      EXPORTING
        xv_statement = lv_statement
        xt_inparams  = VALUE tt_param( )
      IMPORTING
        yv_sql_code  = lv_code
        yv_sql_msg   = lv_msg
      CHANGING
        xyt_outtab   = lr_months ).

    IF lv_code <> 0.
      APPEND VALUE ts_error(
        table_name = xv_table_name
        error_code = 'SE'
        error_msg  = |Storico mensile { xv_table_name }: { lv_msg }|
      ) TO yt_errors.
      RETURN.
    ENDIF.

    " ── 4. Mappa in et_growth ──────────────────────────────────
    LOOP AT lt_months INTO DATA(ls_month).
      APPEND VALUE ts_table_growth(
        table_name    = xv_table_name
        schema_name   = xv_schema_name
        snapshot_date = CONV d( ls_month-month_key && '01' )
        record_count  = ls_month-record_count
        disk_mb       = COND #(
          WHEN lv_bytes_per_row > 0
          THEN CONV #( ls_month-record_count * lv_bytes_per_row / 1024 / 1024 )
          ELSE 0 )
      ) TO yt_growth.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_history_mss.


    " ─────────────────────────────────────────────────────────────────
    " STORICO — MSS (tramite MSS_GET_TABHIST)
    " ⚠️ Campi MSSTABSTATS da verificare: rowcnt, reserved
    " ─────────────────────────────────────────────────────────────────

    DATA lt_hist TYPE TABLE OF msstabstats WITH DEFAULT KEY.

    CALL FUNCTION 'MSS_GET_TABHIST'
      EXPORTING
        tabname       = xv_table_name
      TABLES
        tabstats_list = lt_hist
      EXCEPTIONS
        OTHERS        = 1.

    IF sy-subrc <> 0.
      APPEND VALUE ts_error(
        table_name = xv_table_name
        error_code = 'FM'
        error_msg  = |MSS_GET_TABHIST { xv_table_name } failed: sy-subrc={ sy-subrc }|
      ) TO yt_errors.
      RETURN.
    ENDIF.

    LOOP AT lt_hist INTO DATA(ls).

      " Filtro date post-fetch su SAMPLEDATE (TYPE d)
      IF xv_date_from IS NOT INITIAL AND ls-sampledate < xv_date_from. CONTINUE. ENDIF.
      IF xv_date_to   IS NOT INITIAL AND ls-sampledate > xv_date_to.   CONTINUE. ENDIF.

      APPEND VALUE ts_table_growth(
        table_name    = CONV #( ls-tablename )
        snapshot_date = ls-sampledate
        record_count  = ls-rowmodctr        " ⚠️ da verificare nome campo
        disk_mb       = ls-reserved / 1024  " ⚠️ da verificare (reserved in KB?)
      ) TO yt_growth.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_table_growth.

    " ─────────────────────────────────────────────────────────────────
    " ENTRY POINT
    " ─────────────────────────────────────────────────────────────────

    DATA lt_work_tables TYPE tt_top_table.
    DATA(lv_dbsys)      = get_db_system( ).
    DATA lv_schema      TYPE char30.

    CALL FUNCTION 'DB_DBSCHEMA'
      IMPORTING
        dbschema = lv_schema. "ABAP Database or Access Schema

    " ── 1. Determina lista tabelle ──────────────────────────────
    IF xt_table_name IS NOT INITIAL.

      lt_work_tables = VALUE #( FOR <tabname> IN xt_table_name
                                ( table_name = <tabname> )
      ).

    ELSE.
      " Top N dal database
      CASE lv_dbsys.
        WHEN 'HDB'.
          get_top_n_tables_hdb(
            EXPORTING
              xv_top_n  = xv_top_n
              xv_schema = lv_schema
            IMPORTING
              yt_tables = lt_work_tables
              yt_errors = yt_errors ).

        WHEN 'MSS'.
          get_top_n_tables_mss(
            EXPORTING
              xv_top_n  = xv_top_n
            IMPORTING
              yt_tables = lt_work_tables
              yt_errors = yt_errors ).
      ENDCASE.
    ENDIF.

    CHECK lt_work_tables IS NOT INITIAL.

    " ── 2. Storico per ogni tabella ─────────────────────────────
    DATA(lt_mapping) = get_date_field_mapping( ).

    LOOP AT lt_work_tables INTO DATA(ls_tab).

      DATA lt_growth TYPE tt_table_growth.
      DATA lt_errors TYPE tt_error.

      CASE lv_dbsys.

        WHEN 'HDB'.
          " Su HANA serve il campo data dal mapping
          READ TABLE lt_mapping INTO DATA(ls_map)
            WITH KEY table_name = ls_tab-table_name.

          IF sy-subrc <> 0.
            APPEND VALUE ts_error(
              table_name = ls_tab-table_name
              error_code = 'NM'
              error_msg  = |Nessun mapping campo data per { ls_tab-table_name } — aggiungere in get_date_field_mapping|
            ) TO yt_errors.
            CONTINUE.
          ENDIF.

          get_history_hdb(
            EXPORTING
              xv_table_name  = ls_tab-table_name
              xv_schema_name = COND #( WHEN ls_tab-schema_name IS NOT INITIAL
                                       THEN ls_tab-schema_name
                                       ELSE lv_schema )
              xv_date_field  = ls_map-date_field
              xv_date_from   = xv_date_from
              xv_date_to     = xv_date_to
            IMPORTING
              yt_growth      = lt_growth
              yt_errors      = lt_errors ).

        WHEN 'MSS'.
          " Su MSS il mapping non serve: MSS_GET_TABHIST ha già lo storico
          get_history_mss(
            EXPORTING
              xv_table_name = ls_tab-table_name
              xv_date_from  = xv_date_from
              xv_date_to    = xv_date_to
            IMPORTING
              yt_growth     = lt_growth
              yt_errors     = lt_errors ).

      ENDCASE.

      APPEND LINES OF lt_growth TO yt_growth.
      APPEND LINES OF lt_errors TO yt_errors.
      CLEAR: lt_growth, lt_errors.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_top_n_tables_hdb.

    " ─────────────────────────────────────────────────────────────────
    " TOP N TABELLE — HDB (da M_CS_TABLES, snapshot corrente)
    " ─────────────────────────────────────────────────────────────────

    DATA lt_result TYPE tt_hdb_top_result.
    DATA lr_out    TYPE REF TO data.
    DATA lv_code   TYPE i.
    DATA lv_msg    TYPE dbsqlmsg.

    GET REFERENCE OF lt_result INTO lr_out.

    " TOP N embedded come intero — nessun rischio injection
    DATA(lv_stmt) =
      |SELECT TOP { xv_top_n } | &&
      |TABLE_NAME, SCHEMA_NAME, | &&
      |SUM(RECORD_COUNT) AS REC_COUNT, | &&
      |SUM(MEMORY_SIZE_IN_TOTAL) AS DISK_BYTES | &&
      |FROM M_CS_TABLES | &&
      |WHERE SCHEMA_NAME = '{ xv_schema }' | &&
      |GROUP BY TABLE_NAME, SCHEMA_NAME | &&
      |ORDER BY SUM(MEMORY_SIZE_IN_TOTAL) DESC|.

    execute_hana_query(
      EXPORTING
        xv_statement = lv_stmt
        xt_inparams  = VALUE tt_param( )
      IMPORTING
        yv_sql_code  = lv_code
        yv_sql_msg   = lv_msg
      CHANGING
        xyt_outtab   = lr_out ).

    IF lv_code <> 0.
      APPEND VALUE ts_error(
        table_name = '*'
        error_code = 'SE'
        error_msg  = |get_top_n_tables_hdb: { lv_msg }|
      ) TO yt_errors.
      RETURN.
    ENDIF.

    LOOP AT lt_result INTO DATA(ls).
      APPEND VALUE ts_top_table(
        table_name  = ls-table_name
        schema_name = ls-schema_name
        rec_count   = ls-rec_count
        disk_mb     = ls-disk_bytes / 1024 / 1024
      ) TO yt_tables.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_top_n_tables_mss.

    " ─────────────────────────────────────────────────────────────────
    " TOP N TABELLE — MSS
    " ⚠️ Interfaccia MSS_GET_TOP_N_TABLES da verificare:
    "    - nome parametro EXPORTING (topn / top_n / i_topn ?)
    "    - nome tabella   TABLES    (top_tables / et_tables ?)
    "    - campi risultato: tablename, owner, rows, reserved (KB)
    " ─────────────────────────────────────────────────────────────────

    DATA: BEGIN OF ls_mss_tab,
            tablename TYPE msstable,
            owner     TYPE mssschema,
            rows      TYPE int8,
            reserved  TYPE int8,       " ⚠️ in KB, da verificare
          END OF ls_mss_tab.
    DATA lt_result LIKE TABLE OF ls_mss_tab.

    CALL FUNCTION 'MSS_GET_TOP_N_TABLES'
      EXPORTING
        topn       = xv_top_n           " ⚠️ da verificare nome parametro
      TABLES
        top_tables = lt_result          " ⚠️ da verificare nome parametro
      EXCEPTIONS
        OTHERS     = 1.

    IF sy-subrc <> 0.
      APPEND VALUE ts_error(
        table_name = '*'
        error_code = 'FM'
        error_msg  = |MSS_GET_TOP_N_TABLES failed: sy-subrc={ sy-subrc }|
      ) TO yt_errors.
      RETURN.
    ENDIF.

    LOOP AT lt_result INTO DATA(ls).
      APPEND VALUE ts_top_table(
        table_name  = ls-tablename
        schema_name = ls-owner
        rec_count   = ls-rows
        disk_mb     = ls-reserved / 1024  " KB → MB
      ) TO yt_tables.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.