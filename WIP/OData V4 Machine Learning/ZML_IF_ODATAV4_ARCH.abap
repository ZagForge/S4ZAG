INTERFACE zml_if_odatav4_arch
  PUBLIC .

  " === Tipi entity ===
  " TopTables: preso 1:1 dal tipo pubblico di ZAG_CL_ML_TABLE_GROWTH.
  " TableGrowth / GrowthPoint: strutture locali (non alias diretti della
  " classe) perché GROWTH_POINT qui è un'entity indipendente con chiave
  " propria (TABLE_NAME + SNAPSHOT_DATE) — la classe non ripete table_name
  " sul punto storico dato che nel suo output è già annidato sotto la
  " tabella radice; qui invece serve, essendo un entity set a sé.
  TYPES:
    ts_top_tables TYPE zag_cl_ml_table_growth=>ts_top_table,
    tt_top_tables TYPE zag_cl_ml_table_growth=>tt_top_table.

  TYPES:
    BEGIN OF ts_table_growth,
      table_name  TYPE tabname,
      schema_name TYPE char30,
      disk_bytes  TYPE int8,
      rec_count   TYPE int8,
    END OF ts_table_growth,
    tt_table_growth TYPE TABLE OF ts_table_growth WITH DEFAULT KEY.

  TYPES:
    BEGIN OF ts_growth_point,
      table_name    TYPE tabname,
      snapshot_date TYPE d,
      record_count  TYPE int8,
      disk_bytes    TYPE int8,
    END OF ts_growth_point,
    tt_growth_point TYPE TABLE OF ts_growth_point WITH DEFAULT KEY.

  " === Filtri ===
  TYPES:
    tt_tabname_range TYPE RANGE OF tabname,
    tt_date_range    TYPE RANGE OF sy-datum.

  TYPES:
    BEGIN OF ts_filters,
      r_table_name    TYPE tt_tabname_range,  " TableGrowth / GrowthPoint
      r_snapshot_date TYPE tt_date_range,      " solo GrowthPoint
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
        top_tables   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TOP_TABLES',
        table_growth TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TABLE_GROWTH',
        growth_point TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'GROWTH_POINT',
      END OF internal,

      BEGIN OF edm,
        top_tables   TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TopTablesType',
        table_growth TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TableGrowthType',
        growth_point TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'GrowthPointType',
      END OF edm,
    END OF tc_entity_type_names,

    " Entity Set Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_set_names,
      BEGIN OF internal,
        top_tables   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TOP_TABLES',
        table_growth TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'TABLE_GROWTH',
        growth_point TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'GROWTH_POINT',
      END OF internal,
      BEGIN OF edm,
        top_tables   TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TopTables',
        table_growth TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'TableGrowth',
        growth_point TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'GrowthPoint',
      END OF edm,
    END OF tc_entity_set_names,

    " Navigation Properties Names — TableGrowth -> GrowthPoint ($expand=_History)
    "---------------------------------------------------------------
    BEGIN OF tc_nav_prop_names,
      BEGIN OF internal,
        growth_to_history TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE '_HISTORY',
      END OF internal,
      BEGIN OF edm,
        growth_to_history TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE '_History',
      END OF edm,
    END OF tc_nav_prop_names.

ENDINTERFACE.
