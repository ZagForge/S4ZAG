class ZAG_CL_ML_TABLE_GROWTH definition
  public
  final
  create public .

public section.

  types:
    " === Output unificato ===
    BEGIN OF ts_table_growth,
        table_name    TYPE tabname,
        snapshot_date TYPE d,          " primo giorno del mese (YYYYMM01) su HDB, data campione su MSS
        record_count  TYPE int8,       " record inseriti nel periodo (HDB) o totali a quella data (MSS)
        disk_bytes    TYPE int8,       " stima in byte (HDB) o dato reale (MSS)
      END OF ts_table_growth .
  types:
    tt_table_growth TYPE TABLE OF ts_table_growth WITH DEFAULT KEY .
  types:
    " === Errori ===
    " Codici: NM = nessun mapping data, SE = sql error, FM = function module error
    BEGIN OF ts_error,
        table_name TYPE tabname,
        error_code TYPE sychar02,
        error_msg  TYPE string,
      END OF ts_error .
  types:
    tt_error TYPE TABLE OF ts_error WITH DEFAULT KEY .
  types:
    tt_tabname TYPE TABLE OF tabname WITH DEFAULT KEY .
  types:
    " Lista tabelle top N (dimensione/record count correnti)
    BEGIN OF ts_top_table,
        table_name    TYPE tabname,
        disk_bytes    TYPE int8,
        rec_count     TYPE int8,
        mod_indicator TYPE int8, " attività recente: ROWMODCTR (MSS) / delta bytes (HDB)
      END OF ts_top_table .
  types:
    tt_top_table TYPE TABLE OF ts_top_table WITH DEFAULT KEY .
  types:
    " Peso attuale di una o più tabelle specifiche (non solo top N)
    BEGIN OF ts_table_size,
        table_name TYPE tabname,
        rec_count  TYPE int8,
        disk_bytes TYPE int8,
      END OF ts_table_size .
  types:
    tt_table_size TYPE TABLE OF ts_table_size WITH DEFAULT KEY .

  methods CONSTRUCTOR .
    " === Entry point combinato: top N + storico ===
  methods GET_TABLE_GROWTH
    importing
      !XT_TABLE_NAME type TT_TABNAME optional         " se vuoto → top N
      !XV_TOP_N type I default 20
      !XV_DATE_FROM type SY-DATUM optional
      !XV_DATE_TO type SY-DATUM optional
    exporting
      !YT_GROWTH type TT_TABLE_GROWTH
      !YT_ERRORS type TT_ERROR .
    " === Solo discovery: top N tabelle per dimensione ===
  methods GET_TOP_TABLES
    importing
      !XV_TOP_N type I default 20
    exporting
      !YT_TABLES type TT_TOP_TABLE
      !YT_ERRORS type TT_ERROR .
    " === Solo storico: crescita mensile per un elenco di tabelle note ===
  methods GET_TABLE_HISTORY
    importing
      !XT_TABLE_NAME type TT_TABNAME
      !XV_DATE_FROM type SY-DATUM optional
      !XV_DATE_TO type SY-DATUM optional
    exporting
      !YT_GROWTH type TT_TABLE_GROWTH
      !YT_ERRORS type TT_ERROR .
    " === Peso attuale di un elenco di tabelle note ===
  methods GET_TABLE_SIZE
    importing
      !XT_TABLE_NAME type TT_TABNAME
    exporting
      !YT_SIZES type TT_TABLE_SIZE
      !YT_ERRORS type TT_ERROR .
  PRIVATE SECTION.

    " Mapping tabella → campo data (usato solo su HDB per query stimata)
    TYPES:
      BEGIN OF ts_date_field_map,
        table_name TYPE tabname,
        date_field TYPE fieldname,
      END OF ts_date_field_map,
      tt_date_field_map TYPE TABLE OF ts_date_field_map WITH DEFAULT KEY.

    " Valorizzati una sola volta in CONSTRUCTOR: non cambiano durante la vita
    " dell'istanza, evitiamo di ricalcolarli ad ogni chiamata di metodo.
    DATA mv_dbsys          TYPE syst_dbsys.
    DATA mv_schema         TYPE char30.
    DATA mt_date_field_map TYPE tt_date_field_map.

    " Output query HANA top N — l'ordine dei campi deve rispettare l'ordine SELECT
    TYPES:
      BEGIN OF ts_hdb_top_result,
        table_name  TYPE char128,
        rec_count   TYPE int8,
        disk_bytes  TYPE int8,
        delta_bytes TYPE int8,
      END OF ts_hdb_top_result,
      tt_hdb_top_result TYPE TABLE OF ts_hdb_top_result WITH DEFAULT KEY.

    " Output query stimata mensile — ordine: MONTH_KEY, RECORD_COUNT
    TYPES:
      BEGIN OF ts_month_count,
        month_key    TYPE char6,   " YYYYMM
        record_count TYPE int8,
      END OF ts_month_count,
      tt_month_count TYPE TABLE OF ts_month_count WITH DEFAULT KEY.

    " Stats correnti tabella HDB (M_CS_TABLES) — l'ordine dei campi deve
    " rispettare l'ordine del SELECT in GET_HISTORY_HDB.
    " Solo numeriche/date: booleani e stringhe di stato esclusi.
    " *_TIME come stringa: tipo timestamp HANA non verificato, un target
    " string tollera qualsiasi tipo sorgente meglio di un target numerico.
    TYPES:
      BEGIN OF ts_hdb_cur_stats,
        rec_count                          TYPE int8,
        disk_bytes                         TYPE int8,   " MEMORY_SIZE_IN_TOTAL
        memory_size_in_main                TYPE int8,
        memory_size_in_delta               TYPE int8,
        memory_size_in_misc                TYPE int8,
        est_max_memory_size_total          TYPE int8,   " ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL
        last_estimated_memory_size         TYPE int8,
        last_est_memory_size_time          TYPE string,  " LAST_ESTIMATED_MEMORY_SIZE_TIME
        raw_record_count_in_main           TYPE int8,
        raw_record_count_in_delta          TYPE int8,
        last_compressed_record_count       TYPE int8,
        max_udiv                           TYPE int8,
        max_rowid                          TYPE int8,
        create_time                        TYPE string,
        modify_time                        TYPE string,
        last_merge_time                    TYPE string,
        last_replay_log_time               TYPE string,
        last_consistency_check_time        TYPE string,
        read_count                         TYPE int8,
        write_count                        TYPE int8,
        merge_count                        TYPE int8,
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

    METHODS get_top_n_tables_mss
      IMPORTING
        xv_top_n  TYPE i
      EXPORTING
        yt_tables TYPE tt_top_table
        yt_errors TYPE tt_error.

    METHODS get_current_stats_hdb
      IMPORTING
        xv_table_name  TYPE tabname
        xv_schema_name TYPE char30
      EXPORTING
        ys_stats       TYPE ts_hdb_cur_stats
        yt_errors      TYPE tt_error.

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



CLASS ZAG_CL_ML_TABLE_GROWTH IMPLEMENTATION.


  METHOD CONSTRUCTOR.
    " ─────────────────────────────────────────────────────────────────
    " Valorizzati una volta sola: sistema DB e mapping campo data non
    " cambiano durante la vita dell'istanza.
    " ─────────────────────────────────────────────────────────────────

    mv_dbsys          = get_db_system( ).
    mt_date_field_map = get_date_field_mapping( ).

    CALL FUNCTION 'DB_DBSCHEMA'
      IMPORTING
        dbschema = mv_schema. "ABAP Database or Access Schema — valida sia su HDB che su MSS

  ENDMETHOD.


  METHOD EXECUTE_HANA_QUERY.
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


  METHOD GET_DATE_FIELD_MAPPING.
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


  METHOD GET_DB_SYSTEM.
    " ─────────────────────────────────────────────────────────────────
    " RILEVAMENTO DB
    " ─────────────────────────────────────────────────────────────────

    " HDB = SAP HANA, MSS = Microsoft SQL Server
    yv_dbsys = sy-dbsys.
  ENDMETHOD.


  METHOD GET_HISTORY_HDB.
    " ─────────────────────────────────────────────────────────────────
    " STORICO MENSILE — HDB (approccio rustico)
    "
    " 1. Legge stats correnti da M_CS_TABLES → calcola bytes/riga
    " 2. COUNT(*) GROUP BY mese sul campo data mappato
    " 3. Stima disk_bytes = record_mese * bytes_per_riga_corrente
    "    (approssimazione per ML: trend corretto, valore assoluto stimato)
    " ─────────────────────────────────────────────────────────────────

    DATA lv_code TYPE i.
    DATA lv_msg  TYPE dbsqlmsg.

    " ── 1. Stats correnti per stima bytes/riga ─────────────────
    get_current_stats_hdb(
      EXPORTING
        xv_table_name  = xv_table_name
        xv_schema_name = xv_schema_name
      IMPORTING
        ys_stats       = DATA(ls_cur)
        yt_errors      = DATA(lt_stats_errors) ).

    IF lt_stats_errors IS NOT INITIAL.
      APPEND LINES OF lt_stats_errors TO yt_errors.
      RETURN.
    ENDIF.

    DATA(lv_bytes_per_row) = COND int8(
      WHEN ls_cur-rec_count > 0
      THEN ls_cur-disk_bytes / ls_cur-rec_count
      ELSE 0 ).

    DATA lv_statement TYPE string.

    " ── 2. Costruisce WHERE per filtro date ────────────────────
    DATA lv_conditions TYPE string.
    IF xv_date_from IS NOT INITIAL.
      lv_conditions = |{ xv_date_field } >= '{ xv_date_from }'|.
    ENDIF.
    IF xv_date_to IS NOT INITIAL.
      lv_conditions = |{ lv_conditions }|
                      && | { COND #( WHEN lv_conditions IS NOT INITIAL THEN 'AND' ELSE '' ) }|
                      && | { xv_date_field } <= '{ xv_date_to }'|.
    ENDIF.
    DATA(lv_where) = COND string(
      WHEN lv_conditions IS NOT INITIAL
      THEN |WHERE { lv_conditions } |
      ELSE '' ).

    " ── 3. Query rustica: record per mese ──────────────────────
    DATA lt_months TYPE tt_month_count.
    DATA lr_months TYPE REF TO data.
    GET REFERENCE OF lt_months INTO lr_months.

    lv_statement = |SELECT SUBSTRING({ xv_date_field }, 1, 6) AS MONTH_KEY, |
                   && |COUNT(*) AS RECORD_COUNT |
                   && |FROM { xv_schema_name }.{ xv_table_name } |
                   && |{ lv_where }|
                   && |GROUP BY SUBSTRING({ xv_date_field }, 1, 6) |
                   && |ORDER BY 1|.

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
        snapshot_date = CONV d( ls_month-month_key && '01' )
        record_count  = ls_month-record_count
        disk_bytes    = ls_month-record_count * lv_bytes_per_row
      ) TO yt_growth.
    ENDLOOP.

  ENDMETHOD.


  METHOD GET_HISTORY_MSS.
    " ─────────────────────────────────────────────────────────────────
    " STORICO — MSS (tramite MSS_GET_TABHIST)
    " ─────────────────────────────────────────────────────────────────

    DATA lt_hist TYPE TABLE OF msstabstats WITH DEFAULT KEY.

    " Solo TABNAME valorizzato: CON_NAME/SCHEMA/CURR_SCHEMA restano ai
    " default della FM (connessione e schema correnti)
    CALL FUNCTION 'MSS_GET_TABHIST'
      EXPORTING
        tabname        = xv_table_name
      TABLES
        tabstats_list  = lt_hist
      EXCEPTIONS
        internal_error = 1
        db_error       = 2
        connect_error  = 3
        OTHERS         = 4.

    IF sy-subrc <> 0.
      DATA(lv_reason) = SWITCH string( sy-subrc
        WHEN 1 THEN 'INTERNAL_ERROR'
        WHEN 2 THEN 'DB_ERROR'
        WHEN 3 THEN 'CONNECT_ERROR'
        ELSE 'UNKNOWN' ).
      APPEND VALUE ts_error(
        table_name = xv_table_name
        error_code = 'FM'
        error_msg  = |MSS_GET_TABHIST { xv_table_name } failed: { lv_reason } (sy-subrc={ sy-subrc })|
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
        record_count  = ls-totalrows         " righe totali a quella data (reale)
        disk_bytes    = ls-reserved * 1024   " KB → byte, come MSSTOPLARGE-RESERVED
      ) TO yt_growth.

    ENDLOOP.

  ENDMETHOD.


  METHOD GET_TABLE_GROWTH.
    " ─────────────────────────────────────────────────────────────────
    " ENTRY POINT COMBINATO — comodità: se non passi tabelle, prende il
    " top N via GET_TOP_TABLES e ne calcola lo storico via GET_TABLE_HISTORY
    " ─────────────────────────────────────────────────────────────────

    DATA lt_tables TYPE tt_tabname.

    IF xt_table_name IS NOT INITIAL.
      lt_tables = xt_table_name.
    ELSE.
      DATA lt_top TYPE tt_top_table.
      get_top_tables(
        EXPORTING
          xv_top_n  = xv_top_n
        IMPORTING
          yt_tables = lt_top
          yt_errors = yt_errors ).

      lt_tables = VALUE #( FOR <top> IN lt_top ( <top>-table_name ) ).
    ENDIF.

    CHECK lt_tables IS NOT INITIAL.

    DATA lt_history_errors TYPE tt_error.

    get_table_history(
      EXPORTING
        xt_table_name = lt_tables
        xv_date_from  = xv_date_from
        xv_date_to    = xv_date_to
      IMPORTING
        yt_growth     = yt_growth
        yt_errors     = lt_history_errors ).

    APPEND LINES OF lt_history_errors TO yt_errors.

  ENDMETHOD.


  METHOD GET_TABLE_HISTORY.
    " ─────────────────────────────────────────────────────────────────
    " STORICO: crescita mensile per un elenco di tabelle note,
    " indipendente da come sono state individuate (top N o input diretto)
    " ─────────────────────────────────────────────────────────────────

    LOOP AT xt_table_name INTO DATA(lv_tabname).

      DATA lt_growth TYPE tt_table_growth.
      DATA lt_errors TYPE tt_error.

      CASE mv_dbsys.

        WHEN 'HDB'.
          " Su HANA serve il campo data dal mapping
          READ TABLE mt_date_field_map INTO DATA(ls_map)
            WITH KEY table_name = lv_tabname.

          IF sy-subrc <> 0.
            APPEND VALUE ts_error(
              table_name = lv_tabname
              error_code = 'NM'
              error_msg  = |Nessun mapping campo data per { lv_tabname } — aggiungere in get_date_field_mapping|
            ) TO yt_errors.
            CONTINUE.
          ENDIF.

          get_history_hdb(
            EXPORTING
              xv_table_name  = lv_tabname
              xv_schema_name = mv_schema
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
              xv_table_name = lv_tabname
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


  METHOD GET_TOP_N_TABLES_HDB.
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
      |SELECT TOP { xv_top_n } |
      && |TABLE_NAME, |
      && |SUM(RECORD_COUNT) AS REC_COUNT, |
      && |SUM(MEMORY_SIZE_IN_TOTAL) AS DISK_BYTES, |
      && |SUM(MEMORY_SIZE_IN_DELTA) AS DELTA_BYTES |
      && |FROM M_CS_TABLES |
      && |WHERE SCHEMA_NAME = '{ xv_schema }' |
      && |GROUP BY TABLE_NAME |
      && |ORDER BY SUM(MEMORY_SIZE_IN_TOTAL) DESC|.

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
        table_name    = ls-table_name
        rec_count     = ls-rec_count
        disk_bytes    = ls-disk_bytes
        mod_indicator = ls-delta_bytes
      ) TO yt_tables.
    ENDLOOP.

  ENDMETHOD.


  METHOD GET_TOP_N_TABLES_MSS.
    " ─────────────────────────────────────────────────────────────────
    " TOP N TABELLE — MSS (MSS_GET_TOP_N_TABLES, ORDER = 'L' → per dimensione)
    " Solo NUMBER e ORDER valorizzati, resto ai default della FM.
    " ─────────────────────────────────────────────────────────────────

    DATA: BEGIN OF ls_large,
            name      TYPE msstable,
            used      TYPE mssusedsize,
            reserved  TYPE mssressize,
            data      TYPE mssdatasize,
            rows      TYPE mssnumrows,
            rowmodctr TYPE mssrowmodctr,
          END OF ls_large.
    DATA lt_large LIKE TABLE OF ls_large.

    CALL FUNCTION 'MSS_GET_TOP_N_TABLES'
      EXPORTING
        number               = xv_top_n
        order                = 'L'
      TABLES
        large_tables         = lt_large
      EXCEPTIONS
        not_running_on_mssql = 1
        db_error             = 2
        internal_error       = 3
        db_not_found         = 4
        no_db_access         = 5
        schema_not_found     = 6
        invalid_input        = 7
        connect_error        = 8
        OTHERS               = 9.

    IF sy-subrc <> 0.
      DATA(lv_reason) = SWITCH string( sy-subrc
        WHEN 1 THEN 'NOT_RUNNING_ON_MSSQL'
        WHEN 2 THEN 'DB_ERROR'
        WHEN 3 THEN 'INTERNAL_ERROR'
        WHEN 4 THEN 'DB_NOT_FOUND'
        WHEN 5 THEN 'NO_DB_ACCESS'
        WHEN 6 THEN 'SCHEMA_NOT_FOUND'
        WHEN 7 THEN 'INVALID_INPUT'
        WHEN 8 THEN 'CONNECT_ERROR'
        ELSE 'UNKNOWN' ).
      APPEND VALUE ts_error(
        table_name = '*'
        error_code = 'FM'
        error_msg  = |MSS_GET_TOP_N_TABLES failed: { lv_reason } (sy-subrc={ sy-subrc })|
      ) TO yt_errors.
      RETURN.
    ENDIF.

    LOOP AT lt_large INTO ls_large.
      APPEND VALUE ts_top_table(
        table_name    = ls_large-name
        rec_count     = ls_large-rows
        disk_bytes    = ls_large-reserved * 1024  " KB → byte
        mod_indicator = ls_large-rowmodctr
      ) TO yt_tables.
    ENDLOOP.

  ENDMETHOD.


  METHOD GET_TOP_TABLES.
    " ─────────────────────────────────────────────────────────────────
    " DISCOVERY: top N tabelle per dimensione, indipendente dallo storico
    " ─────────────────────────────────────────────────────────────────

    CASE mv_dbsys.
      WHEN 'HDB'.
        get_top_n_tables_hdb(
          EXPORTING
            xv_top_n  = xv_top_n
            xv_schema = mv_schema
          IMPORTING
            yt_tables = yt_tables
            yt_errors = yt_errors ).

      WHEN 'MSS'.
        get_top_n_tables_mss(
          EXPORTING
            xv_top_n  = xv_top_n
          IMPORTING
            yt_tables = yt_tables
            yt_errors = yt_errors ).
    ENDCASE.

  ENDMETHOD.


  METHOD GET_CURRENT_STATS_HDB.
    " ─────────────────────────────────────────────────────────────────
    " STATS CORRENTI TABELLA — HDB (da M_CS_TABLES, snapshot attuale)
    " Estratto da GET_HISTORY_HDB per essere riusabile anche da GET_TABLE_SIZE.
    " ─────────────────────────────────────────────────────────────────

    DATA lt_cur TYPE tt_hdb_cur_stats.
    DATA lr_cur TYPE REF TO data.
    GET REFERENCE OF lt_cur INTO lr_cur.

    DATA(lv_statement) =
      |SELECT RECORD_COUNT, MEMORY_SIZE_IN_TOTAL, |
      && |MEMORY_SIZE_IN_MAIN, MEMORY_SIZE_IN_DELTA, MEMORY_SIZE_IN_MISC, |
      && |ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL, LAST_ESTIMATED_MEMORY_SIZE, |
      && |LAST_ESTIMATED_MEMORY_SIZE_TIME, |
      && |RAW_RECORD_COUNT_IN_MAIN, RAW_RECORD_COUNT_IN_DELTA, |
      && |LAST_COMPRESSED_RECORD_COUNT, MAX_UDIV, MAX_ROWID, |
      && |CREATE_TIME, MODIFY_TIME, LAST_MERGE_TIME, |
      && |LAST_REPLAY_LOG_TIME, LAST_CONSISTENCY_CHECK_TIME, |
      && |READ_COUNT, WRITE_COUNT, MERGE_COUNT |
      && |FROM M_CS_TABLES |
      && |WHERE SCHEMA_NAME = '{ xv_schema_name }' |
      && |AND TABLE_NAME = '{ xv_table_name }'|.

    execute_hana_query(
      EXPORTING
        xv_statement = lv_statement
        xt_inparams  = VALUE tt_param( )
      IMPORTING
        yv_sql_code  = DATA(lv_code)
        yv_sql_msg   = DATA(lv_msg)
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

    READ TABLE lt_cur INTO ys_stats INDEX 1.

  ENDMETHOD.


  METHOD GET_TABLE_SIZE.
    " ─────────────────────────────────────────────────────────────────
    " PESO ATTUALE — per un elenco di tabelle note (non solo top N)
    " HDB: snapshot da M_CS_TABLES. MSS: ultimo snapshot da MSS_GET_TABHIST.
    " ─────────────────────────────────────────────────────────────────

    LOOP AT xt_table_name INTO DATA(lv_tabname).

      CASE mv_dbsys.

        WHEN 'HDB'.
          get_current_stats_hdb(
            EXPORTING
              xv_table_name  = lv_tabname
              xv_schema_name = mv_schema
            IMPORTING
              ys_stats       = DATA(ls_cur)
              yt_errors      = DATA(lt_stats_errors) ).

          APPEND LINES OF lt_stats_errors TO yt_errors.

          IF lt_stats_errors IS INITIAL.
            APPEND VALUE ts_table_size(
              table_name = lv_tabname
              rec_count  = ls_cur-rec_count
              disk_bytes = ls_cur-disk_bytes
            ) TO yt_sizes.
          ENDIF.

        WHEN 'MSS'.
          get_history_mss(
            EXPORTING
              xv_table_name = lv_tabname
            IMPORTING
              yt_growth     = DATA(lt_hist)
              yt_errors     = DATA(lt_hist_errors) ).

          APPEND LINES OF lt_hist_errors TO yt_errors.

          IF lt_hist IS NOT INITIAL.
            SORT lt_hist BY snapshot_date DESCENDING.
            READ TABLE lt_hist INTO DATA(ls_latest) INDEX 1.
            APPEND VALUE ts_table_size(
              table_name = lv_tabname
              rec_count  = ls_latest-record_count
              disk_bytes = ls_latest-disk_bytes
            ) TO yt_sizes.
          ENDIF.

      ENDCASE.

      CLEAR: lt_stats_errors, lt_hist, lt_hist_errors.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.