INTERFACE zml_if_odatav4_arch
  PUBLIC .

  TYPES:    BEGIN OF ts_db02_ram_size.
              INCLUDE TYPE hdb_column_tables_part_size.
  TYPES:     END OF ts_db02_ram_size.

  TYPES:    BEGIN OF ts_db02_disk_size.
              INCLUDE TYPE HDB_GLOBAL_TABLE_PERSIST_STAT.
            TYPES:
                        start_date TYPE sy-datum,
                        end_date   TYPE sy-datum.
  TYPES:    END OF ts_db02_disk_size.

  TYPES:
    tt_db02_ram_size  TYPE TABLE OF hdb_column_tables_part_size WITH DEFAULT KEY,
    tt_db02_disk_size TYPE TABLE OF hdb_global_table_persist_stat WITH DEFAULT KEY.


  TYPES:
    " KEY Fields
    "---------------------------------------------------------------
    BEGIN OF ts_key_range,
      tabname TYPE RANGE OF ts_db02_ram_size-table_name,
    END OF ts_key_range.


  CONSTANTS:

    " Entity Type Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_type_names,
      BEGIN OF internal,
        db02_ram_size  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'DB02_RAM_SIZE',
        db02_disk_size TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'DB02_DISK_SIZE',
      END OF internal,

      BEGIN OF edm,
        db02_ram_size  TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Db02RamSizeType',
        db02_disk_size TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Db02iskSizeType',
      END OF edm,
    END OF tc_entity_type_names,

    " Entity Set Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_set_names,
      BEGIN OF internal,
        db02_ram_size  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'DB02_RAM_SIZE',
        db02_disk_size TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'DB02_DISK_SIZE',
      END OF internal,
      BEGIN OF edm,
        db02_ram_size  TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Db02RamSize',
        db02_disk_size TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Db02DiskSize',
      END OF edm,
    END OF tc_entity_set_names.

ENDINTERFACE.