INTERFACE zml_if_odatav4_arch
  PUBLIC .

  " === Tipi entity, presi direttamente dai tipi pubblici di ZAG_CL_ML_TABLE_GROWTH ===
  " Nessuna ridichiarazione manuale dei campi: se la classe cambia, qui si adegua da sola.
  TYPES:
    ts_top_tables    TYPE zag_cl_ml_table_growth=>ts_top_table,
    tt_top_tables    TYPE zag_cl_ml_table_growth=>tt_top_table,

    ts_table_history TYPE zag_cl_ml_table_growth=>ts_table_growth,
    tt_table_history TYPE zag_cl_ml_table_growth=>tt_table_growth,

    ts_table_size    TYPE zag_cl_ml_table_growth=>ts_table_size,
    tt_table_size    TYPE zag_cl_ml_table_growth=>tt_table_size.

  " === Filtri ===
  TYPES:
    tt_tabname_range TYPE RANGE OF tabname,
    tt_date_range    TYPE RANGE OF sy-datum.

  TYPES:
    BEGIN OF ts_filters,
      r_table_name    TYPE tt_tabname_range,  " TableHistory / TableSize
      r_snapshot_date TYPE tt_date_range,      " solo TableHistory
    END OF ts_filters.

  TYPES:
    " KEY Fields
    "---------------------------------------------------------------
    BEGIN OF ts_key_range,
      tabname TYPE RANGE OF tabname,
    END OF ts_key_range.


  CONSTANTS:

    " Entity Type Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_type_names,
      BEGIN OF internal,
        top_tables    TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TOP_TABLES',
        table_history TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TABLE_HISTORY',
        table_size    TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TABLE_SIZE',
      END OF internal,

      BEGIN OF edm,
        top_tables    TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TopTablesType',
        table_history TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TableHistoryType',
        table_size    TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TableSizeType',
      END OF edm,
    END OF tc_entity_type_names,

    " Entity Set Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_set_names,
      BEGIN OF internal,
        top_tables    TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TOP_TABLES',
        table_history TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TABLE_HISTORY',
        table_size    TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TABLE_SIZE',
      END OF internal,
      BEGIN OF edm,
        top_tables    TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TopTables',
        table_history TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TableHistory',
        table_size    TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TableSize',
      END OF edm,
    END OF tc_entity_set_names.

ENDINTERFACE.
