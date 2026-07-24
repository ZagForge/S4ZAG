CLASS zml_cl_bsn_logic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      tt_db02_ram_size  TYPE TABLE OF hdb_column_tables_part_size WITH DEFAULT KEY,
      tt_db02_disk_size TYPE TABLE OF hdb_global_table_persist_stat WITH DEFAULT KEY,
      tt_tab_history    TYPE TABLE OF msstabstats WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ts_filters,
        r_table_name  TYPE RANGE OF hdb_column_tables_part_size-table_name,
        r_create_time TYPE RANGE OF hdb_column_tables_part_size-create_time,
        r_start_date  TYPE RANGE OF sy-datum,
        r_end_date    TYPE RANGE OF sy-datum,
      END OF ts_filters.

    METHODS get_db02_ram_size
      IMPORTING
        !xs_filters TYPE ts_filters OPTIONAL
      EXPORTING
        !yt_tab     TYPE tt_db02_ram_size.

    METHODS get_db02_disk_size
      IMPORTING
        !xs_filters TYPE ts_filters OPTIONAL
      EXPORTING
        !yt_tab     TYPE tt_db02_disk_size.

    " History tabelle MSSQL via MSS_GET_TABHIST.
    " Se is_conname e iv_obj_schema non vengono passati (initial),
    " MSS_GET_TABHIST risolve connessione e schema internamente.
    " Filtro date: post-fetch su MSSTABSTATS-SAMPLEDATE (TYPE d).
    METHODS get_db02_tab_history
      IMPORTING
        !iv_tabname    TYPE msstable             " nome tabella (obbligatorio)
        !is_conname    TYPE dbcon-con_name OPTIONAL " connessione MSSQL; initial = default
        !iv_obj_schema TYPE mssschema     OPTIONAL " schema oggetto; initial = default
        !xs_filters    TYPE ts_filters    OPTIONAL
      EXPORTING
        !yt_tab        TYPE tt_tab_history.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_param,
        data_ref    TYPE REF TO data,
        ind_ref     TYPE REF TO int2,
        inout_type  TYPE typint1,
        eval_ind(1) TYPE x,
      END OF ty_param,
      tt_param     TYPE STANDARD TABLE OF ty_param WITH DEFAULT KEY,
      ty_conda(80) TYPE x.

    METHODS execute_hana_query
      IMPORTING
        iv_statement TYPE string
        it_inparams  TYPE tt_param
      CHANGING
        ct_outtab    TYPE REF TO data.

    METHODS build_timestamp_params
      IMPORTING
        xs_filters       TYPE ts_filters
      RETURNING
        VALUE(rt_params) TYPE tt_param.

ENDCLASS.



CLASS ZML_CL_BSN_LOGIC IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_BSN_LOGIC->BUILD_TIMESTAMP_PARAMS
* +-------------------------------------------------------------------------------------------------+
* | [--->] XS_FILTERS                     TYPE        TS_FILTERS
* | [<-()] RT_PARAMS                      TYPE        TT_PARAM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD build_timestamp_params.

    " ATTENZIONE: i parametri devono essere allocati sull'heap con CREATE DATA.
    " Se dichiarati come variabili locali TYPE string, vengono liberati al
    " return del metodo -> SYSTEM_DATA_ALREADY_FREE al C_DB_FUNCTION PO.

    DATA: lv_date   TYPE d,
          lv_time   TYPE t,
          ls_param  LIKE LINE OF rt_params,
          lv_ts_ref TYPE REF TO string.

    " --- Start timestamp ---
    lv_date = COND #(
      WHEN xs_filters-r_start_date IS NOT INITIAL
      THEN VALUE #( xs_filters-r_start_date[ 1 ]-low OPTIONAL )
      ELSE sy-datum ).
    lv_time = '000001'.
    CREATE DATA lv_ts_ref.
    lv_ts_ref->* = |{ lv_date DATE = ISO } { lv_time TIME = ISO }.000|.
    ls_param-data_ref = lv_ts_ref.
    APPEND ls_param TO rt_params.
    CLEAR ls_param.

    " --- End timestamp ---
    lv_date = COND #(
      WHEN xs_filters-r_end_date IS NOT INITIAL
      THEN VALUE #( xs_filters-r_end_date[ 1 ]-low OPTIONAL )
      ELSE '99991230' ).
    lv_time = '235959'.
    CREATE DATA lv_ts_ref.
    lv_ts_ref->* = |{ lv_date DATE = ISO } { lv_time TIME = ISO }.000|.
    ls_param-data_ref = lv_ts_ref.
    APPEND ls_param TO rt_params.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_BSN_LOGIC->EXECUTE_HANA_QUERY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_STATEMENT                   TYPE        STRING
* | [--->] IT_INPARAMS                    TYPE        TT_PARAM
* | [<-->] CT_OUTTAB                      TYPE REF TO DATA
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD execute_hana_query.

    DATA: lv_con_name           TYPE dbcon_name,
          lv_con_da             TYPE ty_conda,
          lv_sql_code           TYPE i,
          lv_sql_msg            TYPE dbsqlmsg,
          lv_cursor             TYPE cursor,
          lv_tab_name_for_trace TYPE tabname,
          lv_hold_cursor        TYPE flag,
          lv_outvals_bound      TYPE flag,
          lv_into_corresponding TYPE flag,
          lv_upto               TYPE i,
          lv_rows_ret           TYPE i.

    DATA: lt_outparams TYPE tt_param,
          lv_line_ref  TYPE REF TO data,
          tdescr       TYPE REF TO cl_abap_typedescr,
          sdescr       TYPE REF TO cl_abap_structdescr.

    FIELD-SYMBOLS: <outtab> TYPE ANY TABLE,
                   <line>   TYPE any,
                   <struct> TYPE any,
                   <f>      TYPE any.

    " --------------------------------------------------------
    " 1. Costruisce il binding colonne dall'output table
    " --------------------------------------------------------
    ASSIGN ct_outtab->* TO <outtab>.
    CREATE DATA lv_line_ref LIKE LINE OF <outtab>.
    ASSIGN lv_line_ref->* TO <struct>.

    tdescr = cl_abap_typedescr=>describe_by_data_ref( lv_line_ref ).
    sdescr ?= tdescr.

    LOOP AT sdescr->components INTO DATA(ls_comp).
      DATA(ls_out) = VALUE ty_param( ).
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE <struct> TO <f>.
      GET REFERENCE OF <f> INTO ls_out-data_ref.
      APPEND ls_out TO lt_outparams.
    ENDLOOP.

    " --------------------------------------------------------
    " 2. DC — dichiara connessione
    " --------------------------------------------------------
    CALL 'C_DB_FUNCTION' ID 'FUNCTION' FIELD 'DB_SQL'
                         ID 'FCODE'    FIELD 'DC'
                         ID 'CONNAME'  FIELD lv_con_name
                         ID 'CONDA'    FIELD lv_con_da.

    " --------------------------------------------------------
    " 3. PO — prepara e apre il cursore
    " --------------------------------------------------------
    DATA(lt_inparams) = it_inparams.

    CALL 'C_DB_FUNCTION' ID 'FUNCTION'    FIELD 'DB_SQL'
                         ID 'FCODE'       FIELD 'PO'
                         ID 'CONNAME'     FIELD lv_con_name
                         ID 'CONDA'       FIELD lv_con_da
                         ID 'TAB_NAME'    FIELD lv_tab_name_for_trace
                         ID 'STMT_STR'    FIELD iv_statement
                         ID 'HOLD_CURSOR' FIELD lv_hold_cursor
                         ID 'INVALS'      FIELD lt_inparams
                         ID 'CURSOR'      FIELD lv_cursor
                         ID 'SQLCODE'     FIELD lv_sql_code
                         ID 'SQLMSG'      FIELD lv_sql_msg.

    " --------------------------------------------------------
    " 4. NP — fetch del pacchetto di righe
    " --------------------------------------------------------
    ASSIGN lv_line_ref->* TO <line>.
    ASSIGN ct_outtab->*   TO <outtab>.

    CALL 'C_DB_FUNCTION' ID 'FUNCTION' FIELD 'DB_SQL'
                         ID 'FCODE'    FIELD 'NP'
                         ID 'CONNAME'  FIELD lv_con_name
                         ID 'CONDA'    FIELD lv_con_da
                         ID 'CURSOR'   FIELD lv_cursor
                         ID 'BOUND'    FIELD lv_outvals_bound
                         ID 'CORRESP'  FIELD lv_into_corresponding
                         ID 'OUTVALS'  FIELD lt_outparams
                         ID 'OUTTAB'   FIELD <outtab>
                         ID 'LINE'     FIELD <line>
                         ID 'UPTO'     FIELD lv_upto
                         ID 'ROWCNT'   FIELD lv_rows_ret
                         ID 'SQLCODE'  FIELD lv_sql_code
                         ID 'SQLMSG'   FIELD lv_sql_msg.

    " --------------------------------------------------------
    " 5. CC + FC — chiude e libera il cursore
    " --------------------------------------------------------
    CALL 'C_DB_FUNCTION' ID 'FUNCTION' FIELD 'DB_SQL'
                         ID 'FCODE'    FIELD 'CC'
                         ID 'CONNAME'  FIELD lv_con_name
                         ID 'CONDA'    FIELD lv_con_da
                         ID 'CURSOR'   FIELD lv_cursor.

    CALL 'C_DB_FUNCTION' ID 'FUNCTION' FIELD 'DB_SQL'
                         ID 'FCODE'    FIELD 'FC'
                         ID 'CONNAME'  FIELD lv_con_name
                         ID 'CONDA'    FIELD lv_con_da
                         ID 'CURSOR'   FIELD lv_cursor.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_BSN_LOGIC->GET_DB02_DISK_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] XS_FILTERS                     TYPE        TS_FILTERS(optional)
* | [<---] YT_TAB                         TYPE        TT_DB02_DISK_SIZE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_db02_disk_size.

    DATA lv_statement TYPE string.

    lv_statement = |{ lv_statement }SELECT   SQ_EXC_AGGR.SERVER_TIMESTAMP AS SERVER_TIMESTAMP ,                                                                                                          |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.SCHEMA_NAME AS SCHEMA_NAME ,                                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.TABLE_NAME AS TABLE_NAME ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.INDEX AS INDEX ,                                                                                                                                |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.APPEND_COUNT AS APPEND_COUNT ,                                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.BYTESTREAM_WRITTEN AS BYTESTREAM_WRITTEN ,                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.BYTES_APPENDED AS BYTES_APPENDED ,                                                                                                              |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.BYTES_READ AS BYTES_READ ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.BYTES_WRITTEN AS BYTES_WRITTEN ,                                                                                                                |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.COPY_COUNT AS COPY_COUNT ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.DISK_SIZE AS DISK_SIZE ,                                                                                                                        |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.OPTIMIZE_COUNT AS OPTIMIZE_COUNT ,                                                                                                              |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.PAGE_COUNT AS PAGE_COUNT ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.READ_COUNT AS READ_COUNT ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.TRUNCATE_COUNT AS TRUNCATE_COUNT ,                                                                                                              |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.WRITE_COUNT AS WRITE_COUNT                                                                                                                      |.
    lv_statement = |{ lv_statement }FROM     (SELECT   INDEX ,                                                                                                                                           |.
    lv_statement = |{ lv_statement }                   MAX(APPEND_COUNT) AS APPEND_COUNT ,                                                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(BYTESTREAM_WRITTEN) AS BYTESTREAM_WRITTEN ,                                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(BYTES_APPENDED) AS BYTES_APPENDED ,                                                                                                           |.
    lv_statement = |{ lv_statement }                   MAX(BYTES_READ) AS BYTES_READ ,                                                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(BYTES_WRITTEN) AS BYTES_WRITTEN ,                                                                                                             |.
    lv_statement = |{ lv_statement }                   MAX(COPY_COUNT) AS COPY_COUNT ,                                                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(DISK_SIZE) AS DISK_SIZE ,                                                                                                                     |.
    lv_statement = |{ lv_statement }                   MAX(OPTIMIZE_COUNT) AS OPTIMIZE_COUNT ,                                                                                                           |.
    lv_statement = |{ lv_statement }                   MAX(PAGE_COUNT) AS PAGE_COUNT ,                                                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(READ_COUNT) AS READ_COUNT ,                                                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(TRUNCATE_COUNT) AS TRUNCATE_COUNT ,                                                                                                           |.
    lv_statement = |{ lv_statement }                   MAX(WRITE_COUNT) AS WRITE_COUNT ,                                                                                                                 |.
    lv_statement = |{ lv_statement }                   SCHEMA_NAME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   SERVER_TIMESTAMP ,                                                                                                                                |.
    lv_statement = |{ lv_statement }                   TABLE_NAME                                                                                                                                        |.
    lv_statement = |{ lv_statement }          FROM     (SELECT   GLOBAL_TABLE_PERSISTENCE_STATISTICS.INDEX AS INDEX ,                                                                                    |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.SCHEMA_NAME AS SCHEMA_NAME ,                                                                        |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.SERVER_TIMESTAMP AS SERVER_TIMESTAMP ,                                                              |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.TABLE_NAME AS TABLE_NAME ,                                                                          |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.APPEND_COUNT) AS APPEND_COUNT ,                                                                 |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.BYTESTREAM_WRITTEN) AS BYTESTREAM_WRITTEN ,                                                     |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.BYTES_APPENDED) AS BYTES_APPENDED ,                                                             |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.BYTES_READ) AS BYTES_READ ,                                                                     |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.BYTES_WRITTEN) AS BYTES_WRITTEN ,                                                               |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.COPY_COUNT) AS COPY_COUNT ,                                                                     |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.DISK_SIZE) AS DISK_SIZE ,                                                                       |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.OPTIMIZE_COUNT) AS OPTIMIZE_COUNT ,                                                             |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.PAGE_COUNT) AS PAGE_COUNT ,                                                                     |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.READ_COUNT) AS READ_COUNT ,                                                                     |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.TRUNCATE_COUNT) AS TRUNCATE_COUNT ,                                                             |.
    lv_statement = |{ lv_statement }                             MAX(GLOBAL_TABLE_PERSISTENCE_STATISTICS.WRITE_COUNT) AS WRITE_COUNT                                                                     |.
    lv_statement = |{ lv_statement }                    FROM     _SYS_STATISTICS.GLOBAL_TABLE_PERSISTENCE_STATISTICS AS GLOBAL_TABLE_PERSISTENCE_STATISTICS                                              |.
    lv_statement = |{ lv_statement }                    WHERE    GLOBAL_TABLE_PERSISTENCE_STATISTICS.SERVER_TIMESTAMP >= TO_TIMESTAMP( ? ) AND                                                           |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.SERVER_TIMESTAMP <= TO_TIMESTAMP( ? )                                                               |.
    lv_statement = |{ lv_statement }                    GROUP BY GLOBAL_TABLE_PERSISTENCE_STATISTICS.SERVER_TIMESTAMP ,                                                                                  |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.SCHEMA_NAME ,                                                                                       |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.TABLE_NAME ,                                                                                        |.
    lv_statement = |{ lv_statement }                             GLOBAL_TABLE_PERSISTENCE_STATISTICS.INDEX ) AS SQ_STD_AGGR                                                                              |.
    lv_statement = |{ lv_statement }          GROUP BY SERVER_TIMESTAMP ,                                                                                                                                |.
    lv_statement = |{ lv_statement }                   SCHEMA_NAME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   TABLE_NAME ,                                                                                                                                      |.
    lv_statement = |{ lv_statement }                   INDEX ) AS SQ_EXC_AGGR                                                                                                                            |.
    lv_statement = |{ lv_statement }ORDER BY DISK_SIZE DESC                                                                                                                                              |.
*   lv_statement = |{ lv_statement } LIMIT 100                                                                                                                                                           |.

    DATA(lt_params) = me->build_timestamp_params( xs_filters ).

    DATA lr_outtab TYPE REF TO data.
    GET REFERENCE OF yt_tab INTO lr_outtab.

    me->execute_hana_query(
      EXPORTING
        iv_statement = lv_statement
        it_inparams  = lt_params
      CHANGING
        ct_outtab    = lr_outtab
    ).

    IF xs_filters-r_table_name IS NOT INITIAL.
      LOOP AT yt_tab ASSIGNING FIELD-SYMBOL(<row>).
        IF <row>-table_name NOT IN xs_filters-r_table_name.
          DELETE yt_tab INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_BSN_LOGIC->GET_DB02_RAM_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] XS_FILTERS                     TYPE        TS_FILTERS(optional)
* | [<---] YT_TAB                         TYPE        TT_DB02_RAM_SIZE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_db02_ram_size.

    DATA lv_statement TYPE string.

    lv_statement = |{ lv_statement }SELECT   SQ_EXC_AGGR.HOST AS HOST ,                                                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.PORT AS PORT ,                                                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.SCHEMA_NAME AS SCHEMA_NAME ,                                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.TABLE_NAME AS TABLE_NAME ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.PART_ID AS PART_ID ,                                                                                                                            |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.SNAPSHOT_ID AS SNAPSHOT_ID ,                                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MEMORY_SIZE_IN_TOTAL AS MEMORY_SIZE_IN_TOTAL ,                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MEMORY_SIZE_IN_MAIN AS MEMORY_SIZE_IN_MAIN ,                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MEMORY_SIZE_IN_DELTA AS MEMORY_SIZE_IN_DELTA ,                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MEMORY_SIZE_IN_HISTORY_MAIN AS MEMORY_SIZE_IN_HISTORY_MAIN ,                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MEMORY_SIZE_IN_HISTORY_DELTA AS MEMORY_SIZE_IN_HISTORY_DELTA ,                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL AS ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL ,                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.RECORD_COUNT AS RECORD_COUNT ,                                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.RAW_RECORD_COUNT_IN_MAIN AS RAW_RECORD_COUNT_IN_MAIN ,                                                                                          |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.RAW_RECORD_COUNT_IN_DELTA AS RAW_RECORD_COUNT_IN_DELTA ,                                                                                        |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.RAW_RECORD_COUNT_IN_HISTORY_MAIN AS RAW_RECORD_COUNT_IN_HISTORY_MAIN ,                                                                          |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.RAW_RECORD_COUNT_IN_HISTORY_DELTA AS RAW_RECORD_COUNT_IN_HISTORY_DELTA ,                                                                        |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LAST_COMPRESSED_RECORD_COUNT AS LAST_COMPRESSED_RECORD_COUNT ,                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.IS_DELTA_LOADED_B AS IS_DELTA_LOADED_B ,                                                                                                        |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LOADED AS LOADED ,                                                                                                                              |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LAST_MERGE_TIME AS LAST_MERGE_TIME ,                                                                                                            |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LOCATION AS LOCATION ,                                                                                                                          |.
    lv_statement = |{ lv_statement }         0.0 AS PART_COUNT ,                                                                                                                                         |.
    lv_statement = |{ lv_statement }         0.0 AS TABLE_COLUMN_COUNT ,                                                                                                                                 |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.CREATE_TIME AS CREATE_TIME ,                                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.IS_LOG_DELTA_B AS IS_LOG_DELTA_B ,                                                                                                              |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LAST_ESTIMATED_MEMORY_SIZE AS LAST_ESTIMATED_MEMORY_SIZE ,                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LAST_ESTIMATED_MEMORY_SIZE_TIME AS LAST_ESTIMATED_MEMORY_SIZE_TIME ,                                                                            |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LAST_REPLAY_LOG_TIME AS LAST_REPLAY_LOG_TIME ,                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.LAST_TRUNCATION_TIME AS LAST_TRUNCATION_TIME ,                                                                                                  |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MAX_UDIV AS MAX_UDIV ,                                                                                                                          |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MERGE_COUNT AS MERGE_COUNT ,                                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.MODIFY_TIME AS MODIFY_TIME ,                                                                                                                    |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.PERSISTENT_MERGE_B AS PERSISTENT_MERGE_B ,                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.READ_COUNT AS READ_COUNT ,                                                                                                                      |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.SERVER_TIMESTAMP AS SERVER_TIMESTAMP ,                                                                                                          |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.UNUSED_RETENTION_PERIOD AS UNUSED_RETENTION_PERIOD ,                                                                                            |.
    lv_statement = |{ lv_statement }         SQ_EXC_AGGR.WRITE_COUNT AS WRITE_COUNT                                                                                                                      |.
    lv_statement = |{ lv_statement }FROM     (SELECT   CREATE_TIME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   HOST ,                                                                                                                                            |.
    lv_statement = |{ lv_statement }                   IS_DELTA_LOADED_B ,                                                                                                                               |.
    lv_statement = |{ lv_statement }                   IS_LOG_DELTA_B ,                                                                                                                                  |.
    lv_statement = |{ lv_statement }                   LOADED ,                                                                                                                                          |.
    lv_statement = |{ lv_statement }                   LOCATION ,                                                                                                                                        |.
    lv_statement = |{ lv_statement }                   MAX(ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL) AS ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL ,                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(LAST_COMPRESSED_RECORD_COUNT) AS LAST_COMPRESSED_RECORD_COUNT ,                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(LAST_ESTIMATED_MEMORY_SIZE) AS LAST_ESTIMATED_MEMORY_SIZE ,                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(LAST_ESTIMATED_MEMORY_SIZE_TIME) AS LAST_ESTIMATED_MEMORY_SIZE_TIME ,                                                                         |.
    lv_statement = |{ lv_statement }                   MAX(LAST_MERGE_TIME) AS LAST_MERGE_TIME ,                                                                                                         |.
    lv_statement = |{ lv_statement }                   MAX(LAST_REPLAY_LOG_TIME) AS LAST_REPLAY_LOG_TIME ,                                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(LAST_TRUNCATION_TIME) AS LAST_TRUNCATION_TIME ,                                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(MAX_UDIV) AS MAX_UDIV ,                                                                                                                       |.
    lv_statement = |{ lv_statement }                   MAX(MEMORY_SIZE_IN_DELTA) AS MEMORY_SIZE_IN_DELTA ,                                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(MEMORY_SIZE_IN_HISTORY_DELTA) AS MEMORY_SIZE_IN_HISTORY_DELTA ,                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(MEMORY_SIZE_IN_HISTORY_MAIN) AS MEMORY_SIZE_IN_HISTORY_MAIN ,                                                                                 |.
    lv_statement = |{ lv_statement }                   MAX(MEMORY_SIZE_IN_MAIN) AS MEMORY_SIZE_IN_MAIN ,                                                                                                 |.
    lv_statement = |{ lv_statement }                   MAX(MEMORY_SIZE_IN_TOTAL) AS MEMORY_SIZE_IN_TOTAL ,                                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(MERGE_COUNT) AS MERGE_COUNT ,                                                                                                                 |.
    lv_statement = |{ lv_statement }                   MAX(RAW_RECORD_COUNT_IN_DELTA) AS RAW_RECORD_COUNT_IN_DELTA ,                                                                                     |.
    lv_statement = |{ lv_statement }                   MAX(RAW_RECORD_COUNT_IN_HISTORY_DELTA) AS RAW_RECORD_COUNT_IN_HISTORY_DELTA ,                                                                     |.
    lv_statement = |{ lv_statement }                   MAX(RAW_RECORD_COUNT_IN_HISTORY_MAIN) AS RAW_RECORD_COUNT_IN_HISTORY_MAIN ,                                                                       |.
    lv_statement = |{ lv_statement }                   MAX(RAW_RECORD_COUNT_IN_MAIN) AS RAW_RECORD_COUNT_IN_MAIN ,                                                                                       |.
    lv_statement = |{ lv_statement }                   MAX(READ_COUNT) AS READ_COUNT ,                                                                                                                   |.
    lv_statement = |{ lv_statement }                   MAX(RECORD_COUNT) AS RECORD_COUNT ,                                                                                                               |.
    lv_statement = |{ lv_statement }                   MAX(UNUSED_RETENTION_PERIOD) AS UNUSED_RETENTION_PERIOD ,                                                                                         |.
    lv_statement = |{ lv_statement }                   MAX(WRITE_COUNT) AS WRITE_COUNT ,                                                                                                                 |.
    lv_statement = |{ lv_statement }                   MODIFY_TIME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   PART_ID ,                                                                                                                                         |.
    lv_statement = |{ lv_statement }                   PERSISTENT_MERGE_B ,                                                                                                                              |.
    lv_statement = |{ lv_statement }                   PORT ,                                                                                                                                            |.
    lv_statement = |{ lv_statement }                   SCHEMA_NAME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   SERVER_TIMESTAMP ,                                                                                                                                |.
    lv_statement = |{ lv_statement }                   SNAPSHOT_ID ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   TABLE_NAME                                                                                                                                        |.
    lv_statement = |{ lv_statement }          FROM     (SELECT   CASE HOST_COLUMN_TABLES_PART_SIZE.IS_DELTA_LOADED WHEN 'TRUE' THEN 'X' WHEN 'FALSE' THEN '' ELSE '-' END AS IS_DELTA_LOADED_B ,         |.
    lv_statement = |{ lv_statement }                             CASE HOST_COLUMN_TABLES_PART_SIZE.IS_LOG_DELTA WHEN 'TRUE' THEN 'X' WHEN 'FALSE' THEN '' ELSE '-' END AS IS_LOG_DELTA_B ,               |.
    lv_statement = |{ lv_statement }                             CASE HOST_COLUMN_TABLES_PART_SIZE.PERSISTENT_MERGE WHEN 'TRUE' THEN 'X' WHEN 'FALSE' THEN '' ELSE '-' END AS PERSISTENT_MERGE_B ,       |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.CREATE_TIME AS CREATE_TIME ,                                                                               |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.HOST AS HOST ,                                                                                             |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.LOADED AS LOADED ,                                                                                         |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.MODIFY_TIME AS MODIFY_TIME ,                                                                               |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.PART_ID AS PART_ID ,                                                                                       |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.PORT AS PORT ,                                                                                             |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SCHEMA_NAME AS SCHEMA_NAME ,                                                                               |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SERVER_TIMESTAMP AS SERVER_TIMESTAMP ,                                                                     |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SNAPSHOT_ID AS SNAPSHOT_ID ,                                                                               |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.TABLE_NAME AS TABLE_NAME ,                                                                                 |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL) AS ESTIMATED_MAX_MEMORY_SIZE_IN_TOTAL ,                            |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.LAST_COMPRESSED_RECORD_COUNT) AS LAST_COMPRESSED_RECORD_COUNT ,                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.LAST_ESTIMATED_MEMORY_SIZE) AS LAST_ESTIMATED_MEMORY_SIZE ,                                            |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.LAST_ESTIMATED_MEMORY_SIZE_TIME) AS LAST_ESTIMATED_MEMORY_SIZE_TIME ,                                  |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.LAST_MERGE_TIME) AS LAST_MERGE_TIME ,                                                                  |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.LAST_REPLAY_LOG_TIME) AS LAST_REPLAY_LOG_TIME ,                                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.LAST_TRUNCATION_TIME) AS LAST_TRUNCATION_TIME ,                                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MAX_UDIV) AS MAX_UDIV ,                                                                                |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MEMORY_SIZE_IN_DELTA) AS MEMORY_SIZE_IN_DELTA ,                                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MEMORY_SIZE_IN_HISTORY_DELTA) AS MEMORY_SIZE_IN_HISTORY_DELTA ,                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MEMORY_SIZE_IN_HISTORY_MAIN) AS MEMORY_SIZE_IN_HISTORY_MAIN ,                                          |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MEMORY_SIZE_IN_MAIN) AS MEMORY_SIZE_IN_MAIN ,                                                          |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MEMORY_SIZE_IN_TOTAL) AS MEMORY_SIZE_IN_TOTAL ,                                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.MERGE_COUNT) AS MERGE_COUNT ,                                                                          |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.RAW_RECORD_COUNT_IN_DELTA) AS RAW_RECORD_COUNT_IN_DELTA ,                                              |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.RAW_RECORD_COUNT_IN_HISTORY_DELTA) AS RAW_RECORD_COUNT_IN_HISTORY_DELTA ,                              |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.RAW_RECORD_COUNT_IN_HISTORY_MAIN) AS RAW_RECORD_COUNT_IN_HISTORY_MAIN ,                                |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.RAW_RECORD_COUNT_IN_MAIN) AS RAW_RECORD_COUNT_IN_MAIN ,                                                |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.READ_COUNT) AS READ_COUNT ,                                                                            |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.RECORD_COUNT) AS RECORD_COUNT ,                                                                        |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.UNUSED_RETENTION_PERIOD) AS UNUSED_RETENTION_PERIOD ,                                                  |.
    lv_statement = |{ lv_statement }                             MAX(HOST_COLUMN_TABLES_PART_SIZE.WRITE_COUNT) AS WRITE_COUNT ,                                                                          |.
    lv_statement = |{ lv_statement }                             M_TABLE_LOCATIONS.LOCATION AS LOCATION                                                                                                  |.
    lv_statement = |{ lv_statement }                    FROM      _SYS_STATISTICS.HOST_COLUMN_TABLES_PART_SIZE AS HOST_COLUMN_TABLES_PART_SIZE LEFT OUTER JOIN SYS.M_TABLE_LOCATIONS AS M_TABLE_LOCATIONS|.
    lv_statement = |{ lv_statement }                               ON HOST_COLUMN_TABLES_PART_SIZE.SCHEMA_NAME = M_TABLE_LOCATIONS.SCHEMA_NAME AND                                                       |.
    lv_statement = |{ lv_statement }                                  HOST_COLUMN_TABLES_PART_SIZE.TABLE_NAME = M_TABLE_LOCATIONS.TABLE_NAME AND                                                         |.
    lv_statement = |{ lv_statement }                                  HOST_COLUMN_TABLES_PART_SIZE.PART_ID = M_TABLE_LOCATIONS.PART_ID AND                                                               |.
    lv_statement = |{ lv_statement }                                  HOST_COLUMN_TABLES_PART_SIZE.PORT = M_TABLE_LOCATIONS.PORT AND                                                                     |.
    lv_statement = |{ lv_statement }                                  HOST_COLUMN_TABLES_PART_SIZE.HOST = M_TABLE_LOCATIONS.HOST                                                                         |.
    lv_statement = |{ lv_statement }                    WHERE    HOST_COLUMN_TABLES_PART_SIZE.SNAPSHOT_ID >=  TO_TIMESTAMP( ? ) AND                                                                      |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SNAPSHOT_ID <=  TO_TIMESTAMP( ? )                                                                          |.
    lv_statement = |{ lv_statement }                    GROUP BY HOST_COLUMN_TABLES_PART_SIZE.HOST ,                                                                                                     |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.PORT ,                                                                                                     |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SCHEMA_NAME ,                                                                                              |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.TABLE_NAME ,                                                                                               |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.PART_ID ,                                                                                                  |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SNAPSHOT_ID ,                                                                                              |.
    lv_statement = |{ lv_statement }                             CASE HOST_COLUMN_TABLES_PART_SIZE.IS_DELTA_LOADED WHEN 'TRUE' THEN 'X' WHEN 'FALSE' THEN '' ELSE '-' END ,                              |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.LOADED ,                                                                                                   |.
    lv_statement = |{ lv_statement }                             M_TABLE_LOCATIONS.LOCATION ,                                                                                                            |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.CREATE_TIME ,                                                                                              |.
    lv_statement = |{ lv_statement }                             CASE HOST_COLUMN_TABLES_PART_SIZE.IS_LOG_DELTA WHEN 'TRUE' THEN 'X' WHEN 'FALSE' THEN '' ELSE '-' END ,                                 |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.MODIFY_TIME ,                                                                                              |.
    lv_statement = |{ lv_statement }                             CASE HOST_COLUMN_TABLES_PART_SIZE.PERSISTENT_MERGE WHEN 'TRUE' THEN 'X' WHEN 'FALSE' THEN '' ELSE '-' END ,                             |.
    lv_statement = |{ lv_statement }                             HOST_COLUMN_TABLES_PART_SIZE.SERVER_TIMESTAMP ) AS SQ_STD_AGGR                                                                          |.
    lv_statement = |{ lv_statement }          GROUP BY HOST ,                                                                                                                                            |.
    lv_statement = |{ lv_statement }                   PORT ,                                                                                                                                            |.
    lv_statement = |{ lv_statement }                   SCHEMA_NAME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   TABLE_NAME ,                                                                                                                                      |.
    lv_statement = |{ lv_statement }                   PART_ID ,                                                                                                                                         |.
    lv_statement = |{ lv_statement }                   SNAPSHOT_ID ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   IS_DELTA_LOADED_B ,                                                                                                                               |.
    lv_statement = |{ lv_statement }                   LOADED ,                                                                                                                                          |.
    lv_statement = |{ lv_statement }                   LOCATION ,                                                                                                                                        |.
    lv_statement = |{ lv_statement }                   CREATE_TIME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   IS_LOG_DELTA_B ,                                                                                                                                  |.
    lv_statement = |{ lv_statement }                   MODIFY_TIME ,                                                                                                                                     |.
    lv_statement = |{ lv_statement }                   PERSISTENT_MERGE_B ,                                                                                                                              |.
    lv_statement = |{ lv_statement }                   SERVER_TIMESTAMP ) AS SQ_EXC_AGGR                                                                                                                 |.
    lv_statement = |{ lv_statement }ORDER BY MEMORY_SIZE_IN_DELTA DESC                                                                                                                                   |.
*   lv_statement = |{ lv_statement } LIMIT 100                                                                                                                                                           |.

    DATA(lt_params) = me->build_timestamp_params( xs_filters ).

    DATA lr_outtab TYPE REF TO data.
    GET REFERENCE OF yt_tab INTO lr_outtab.

    me->execute_hana_query(
      EXPORTING
        iv_statement = lv_statement
        it_inparams  = lt_params
      CHANGING
        ct_outtab    = lr_outtab
    ).

    IF xs_filters-r_table_name IS NOT INITIAL.
      LOOP AT yt_tab ASSIGNING FIELD-SYMBOL(<row>).
        IF <row>-table_name NOT IN xs_filters-r_table_name.
          DELETE yt_tab INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_BSN_LOGIC->GET_DB02_TAB_HISTORY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_TABNAME                     TYPE        MSSTABLE
* | [--->] IS_CONNAME                     TYPE        DBCON-CON_NAME(optional)
* | [--->] IV_OBJ_SCHEMA                  TYPE        MSSSCHEMA(optional)
* | [--->] XS_FILTERS                     TYPE        TS_FILTERS(optional)
* | [<---] YT_TAB                         TYPE        TT_TAB_HISTORY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_db02_tab_history.

    IF iv_tabname IS INITIAL.
      RETURN.
    ENDIF.

    " --------------------------------------------------------
    " Connessione: solo CON_NAME; rfcdest e dbschema restano
    " initial -> MSS_GET_TABHIST usa i default di sistema
    " --------------------------------------------------------
    DATA currcon    TYPE mssconndata.
    DATA obj_schema TYPE mssschema.

    currcon-con_name = is_conname.
    obj_schema       = iv_obj_schema.

    " --------------------------------------------------------
    " Chiamata FM - DESTINATION vuoto = locale, altrimenti RFC
    " --------------------------------------------------------
    CALL FUNCTION 'MSS_GET_TABHIST'
      DESTINATION currcon-rfcdest
      EXPORTING
        con_name    = currcon-con_name
        schema      = currcon-dbschema
        curr_schema = obj_schema
        tabname     = iv_tabname
      TABLES
        tabstats_list = yt_tab
      EXCEPTIONS
        OTHERS = 1.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " --------------------------------------------------------
    " Filtro post-fetch: TABLE_NAME dal range
    " --------------------------------------------------------
    IF xs_filters-r_table_name IS NOT INITIAL.
      LOOP AT yt_tab ASSIGNING FIELD-SYMBOL(<row>).
        DATA(lv_tname) = CONV hdb_column_tables_part_size-table_name( <row>-tablename ).
        IF lv_tname NOT IN xs_filters-r_table_name.
          DELETE yt_tab INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " --------------------------------------------------------
    " Filtro post-fetch: DATE su MSSTABSTATS-SAMPLEDATE (TYPE d)
    " I due limiti sono applicati separatamente (AND logico)
    " --------------------------------------------------------
    DATA lv_start TYPE d.
    DATA lv_end   TYPE d.

    IF xs_filters-r_start_date IS NOT INITIAL.
      lv_start = xs_filters-r_start_date[ 1 ]-low.
    ENDIF.
    IF xs_filters-r_end_date IS NOT INITIAL.
      lv_end = xs_filters-r_end_date[ 1 ]-low.
    ENDIF.

    IF lv_start IS NOT INITIAL OR lv_end IS NOT INITIAL.
      LOOP AT yt_tab ASSIGNING FIELD-SYMBOL(<drow>).
        DATA lv_delete TYPE abap_bool VALUE abap_false.

        IF lv_start IS NOT INITIAL AND <drow>-sampledate < lv_start.
          lv_delete = abap_true.
        ENDIF.
        IF lv_end IS NOT INITIAL AND <drow>-sampledate > lv_end.
          lv_delete = abap_true.
        ENDIF.

        IF lv_delete = abap_true.
          DELETE yt_tab INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.
ENDCLASS.