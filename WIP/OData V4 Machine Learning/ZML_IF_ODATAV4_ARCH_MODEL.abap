CLASS zml_cl_odatav4_arch_model DEFINITION
  PUBLIC
  INHERITING FROM /iwbep/cl_v4_abs_model_prov
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zml_if_odatav4_arch .

    "Methods - Redefinitions
    METHODS:
      /iwbep/if_v4_mp_basic~define REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

    ALIASES:
      ts_db02_ram_size  FOR zml_if_odatav4_arch~ts_db02_ram_size,
      ts_db02_disk_size FOR zml_if_odatav4_arch~ts_db02_disk_size,
      tc_entity_set_names    FOR zml_if_odatav4_arch~tc_entity_set_names,
      tc_entity_type_names   FOR zml_if_odatav4_arch~tc_entity_type_names.

    METHODS:
      define_db02_ram_size
        IMPORTING
          io_model TYPE REF TO /iwbep/if_v4_med_model
        RAISING
          /iwbep/cx_gateway.

    METHODS:
      define_db02_disk_size
        IMPORTING
          io_model TYPE REF TO /iwbep/if_v4_med_model
        RAISING
          /iwbep/cx_gateway.
ENDCLASS.



CLASS ZML_CL_ODATAV4_ARCH_MODEL IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZML_CL_ODATAV4_ARCH_MODEL->/IWBEP/IF_V4_MP_BASIC~DEFINE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_MODEL                       TYPE REF TO /IWBEP/IF_V4_MED_MODEL
* | [--->] IO_MODEL_INFO                  TYPE REF TO /IWBEP/IF_V4_MODEL_INFO
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_v4_mp_basic~define.

    define_db02_ram_size( io_model ).
    define_db02_disk_size( io_model ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_ODATAV4_ARCH_MODEL->DEFINE_DB02_DISK_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_MODEL                       TYPE REF TO /IWBEP/IF_V4_MED_MODEL
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD define_db02_disk_size.

    DATA: ls_ref_structure  TYPE ts_db02_disk_size,
          lo_primitive_prop TYPE REF TO /iwbep/if_v4_med_prim_prop.


    "Create Entity Type
    "---------------------------------------------------------------
    DATA(lo_entity_type) = io_model->create_entity_type_by_struct(
                             iv_entity_type_name          = tc_entity_type_names-internal-db02_disk_size
                             is_structure                 = ls_ref_structure
                             iv_add_conv_to_prim_props    = abap_true
                             iv_add_f4_help_to_prim_props = abap_true
                             iv_gen_prim_props            = abap_true
    ).
    lo_entity_type->set_edm_name( tc_entity_type_names-edm-db02_disk_size ).


    " Rename external EDM names of properties so that CamelCase notation is used
    "---------------------------------------------------------------
    lo_entity_type->get_primitive_properties(
      IMPORTING
        et_property = DATA(lt_primitive_prop)
    ).

    LOOP AT lt_primitive_prop ASSIGNING FIELD-SYMBOL(<lo_primitive_prop>).

      <lo_primitive_prop>->set_edm_name(
          iv_edm_name = to_mixed( val = <lo_primitive_prop>->get_internal_name( ) )
      ).

    ENDLOOP.


    " Set Key Fields
    "---------------------------------------------------------------
    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'TABLE_NAME' ).
    lo_primitive_prop->set_is_key( ).

    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'START_DATE' ).
    lo_primitive_prop->set_is_nullable( ).

    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'END_DATE' ).
    lo_primitive_prop->set_is_nullable( ).


    " Create Entity Set
    "---------------------------------------------------------------
    DATA(lo_entity_set) = lo_entity_type->create_entity_set(
        iv_entity_set_name = tc_entity_set_names-internal-db02_disk_size
    ).
    lo_entity_set->set_edm_name( tc_entity_set_names-edm-db02_disk_size ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZML_CL_ODATAV4_ARCH_MODEL->DEFINE_DB02_RAM_SIZE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_MODEL                       TYPE REF TO /IWBEP/IF_V4_MED_MODEL
* | [!CX!] /IWBEP/CX_GATEWAY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD define_db02_ram_size.

    DATA: ls_ref_structure  TYPE ts_db02_ram_size,
          lo_primitive_prop TYPE REF TO /iwbep/if_v4_med_prim_prop.


    "Create Entity Type
    "---------------------------------------------------------------
    DATA(lo_entity_type) = io_model->create_entity_type_by_struct(
                             iv_entity_type_name          = tc_entity_type_names-internal-db02_ram_size
                             is_structure                 = ls_ref_structure
                             iv_add_conv_to_prim_props    = abap_true
                             iv_add_f4_help_to_prim_props = abap_true
                             iv_gen_prim_props            = abap_true
    ).
    lo_entity_type->set_edm_name( tc_entity_type_names-edm-db02_ram_size ).


    " Rename external EDM names of properties so that CamelCase notation is used
    "---------------------------------------------------------------
    lo_entity_type->get_primitive_properties(
      IMPORTING
        et_property = DATA(lt_primitive_prop)
    ).

    LOOP AT lt_primitive_prop ASSIGNING FIELD-SYMBOL(<lo_primitive_prop>).

      <lo_primitive_prop>->set_edm_name(
          iv_edm_name = to_mixed( val = <lo_primitive_prop>->get_internal_name( ) )
      ).

    ENDLOOP.


    " Set Key Fields
    "---------------------------------------------------------------
    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'TABLE_NAME' ).
    lo_primitive_prop->set_is_key( ).

    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'CREATE_TIME' ).
    lo_primitive_prop->set_is_key( ).


    " Create Entity Set
    "---------------------------------------------------------------
    DATA(lo_entity_set) = lo_entity_type->create_entity_set(
        iv_entity_set_name = tc_entity_set_names-internal-db02_ram_size
    ).
    lo_entity_set->set_edm_name( tc_entity_set_names-edm-db02_ram_size ).

  ENDMETHOD.
ENDCLASS.