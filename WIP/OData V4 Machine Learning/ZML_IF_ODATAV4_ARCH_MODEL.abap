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
      ts_top_tables        FOR zml_if_odatav4_arch~ts_top_tables,
      ts_table_growth      FOR zml_if_odatav4_arch~ts_table_growth,
      ts_growth_point      FOR zml_if_odatav4_arch~ts_growth_point,
      tc_entity_set_names  FOR zml_if_odatav4_arch~tc_entity_set_names,
      tc_entity_type_names FOR zml_if_odatav4_arch~tc_entity_type_names,
      tc_nav_prop_names    FOR zml_if_odatav4_arch~tc_nav_prop_names.

    METHODS:
      define_top_tables
        IMPORTING
          io_model TYPE REF TO /iwbep/if_v4_med_model
        RAISING
          /iwbep/cx_gateway.

    METHODS:
      define_table_growth
        IMPORTING
          io_model TYPE REF TO /iwbep/if_v4_med_model
        RAISING
          /iwbep/cx_gateway.

    METHODS:
      define_growth_point
        IMPORTING
          io_model TYPE REF TO /iwbep/if_v4_med_model
        RAISING
          /iwbep/cx_gateway.
ENDCLASS.



CLASS ZML_CL_ODATAV4_ARCH_MODEL IMPLEMENTATION.


  METHOD /iwbep/if_v4_mp_basic~define.

    define_top_tables( io_model ).
    define_table_growth( io_model ).
    define_growth_point( io_model ).

  ENDMETHOD.


  METHOD define_top_tables.

    DATA: ls_ref_structure  TYPE ts_top_tables,
          lo_primitive_prop TYPE REF TO /iwbep/if_v4_med_prim_prop.

    "Create Entity Type
    "---------------------------------------------------------------
    DATA(lo_entity_type) = io_model->create_entity_type_by_struct(
                             iv_entity_type_name          = tc_entity_type_names-internal-top_tables
                             is_structure                 = ls_ref_structure
                             iv_add_conv_to_prim_props    = abap_true
                             iv_add_f4_help_to_prim_props = abap_true
                             iv_gen_prim_props            = abap_true
    ).
    lo_entity_type->set_edm_name( tc_entity_type_names-edm-top_tables ).

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

    " Create Entity Set
    "---------------------------------------------------------------
    DATA(lo_entity_set) = lo_entity_type->create_entity_set(
        iv_entity_set_name = tc_entity_set_names-internal-top_tables
    ).
    lo_entity_set->set_edm_name( tc_entity_set_names-edm-top_tables ).

  ENDMETHOD.


  METHOD define_table_growth.

    DATA: ls_ref_structure  TYPE ts_table_growth,
          lo_primitive_prop TYPE REF TO /iwbep/if_v4_med_prim_prop,
          lo_nav_prop       TYPE REF TO /iwbep/if_v4_med_nav_prop.

    " Create Entity Type
    "---------------------------------------------------------------
    DATA(lo_entity_type) = io_model->create_entity_type_by_struct(
        iv_entity_type_name          = tc_entity_type_names-internal-table_growth
        is_structure                 = ls_ref_structure
        iv_gen_prim_props            = abap_true
        iv_add_conv_to_prim_props    = abap_true
        iv_add_f4_help_to_prim_props = abap_true
    ).
    lo_entity_type->set_edm_name( tc_entity_type_names-edm-table_growth ).

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

    " Create Entity Set / Add the binding of the navigation path
    "---------------------------------------------------------------
    DATA(lo_entity_set) = lo_entity_type->create_entity_set(
        iv_entity_set_name = tc_entity_set_names-internal-table_growth
    ).
    lo_entity_set->set_edm_name( tc_entity_set_names-edm-table_growth ).

    lo_entity_set->add_navigation_prop_binding(
      EXPORTING
        iv_navigation_property_path = CONV #( tc_nav_prop_names-internal-growth_to_history )
        iv_target_entity_set        = tc_entity_set_names-internal-growth_point
    ).

    " Create Navigation Property
    "---------------------------------------------------------------
    FREE lo_nav_prop.
    lo_nav_prop = lo_entity_type->create_navigation_property(
        iv_property_name = tc_nav_prop_names-internal-growth_to_history
    ).
    lo_nav_prop->set_edm_name( tc_nav_prop_names-edm-growth_to_history ).

    lo_nav_prop->set_target_entity_type_name( tc_entity_type_names-internal-growth_point ).
    lo_nav_prop->set_target_multiplicity( /iwbep/if_v4_med_element=>gcs_med_nav_multiplicity-to_many_optional ).
    lo_nav_prop->set_on_delete_action( /iwbep/if_v4_med_element=>gcs_med_on_delete_action-none ).

  ENDMETHOD.


  METHOD define_growth_point.

    DATA: ls_ref_structure  TYPE ts_growth_point,
          lo_primitive_prop TYPE REF TO /iwbep/if_v4_med_prim_prop.

    "Create Entity Type
    "---------------------------------------------------------------
    DATA(lo_entity_type) = io_model->create_entity_type_by_struct(
                             iv_entity_type_name          = tc_entity_type_names-internal-growth_point
                             is_structure                 = ls_ref_structure
                             iv_add_conv_to_prim_props    = abap_true
                             iv_add_f4_help_to_prim_props = abap_true
                             iv_gen_prim_props            = abap_true
    ).
    lo_entity_type->set_edm_name( tc_entity_type_names-edm-growth_point ).

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

    " Set Key Fields — chiave composta: una tabella ha più snapshot storici
    "---------------------------------------------------------------
    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'TABLE_NAME' ).
    lo_primitive_prop->set_is_key( ).

    FREE lo_primitive_prop.
    lo_primitive_prop = lo_entity_type->get_primitive_property( 'SNAPSHOT_DATE' ).
    lo_primitive_prop->set_is_key( ).

    " Create Entity Set
    "---------------------------------------------------------------
    DATA(lo_entity_set) = lo_entity_type->create_entity_set(
        iv_entity_set_name = tc_entity_set_names-internal-growth_point
    ).
    lo_entity_set->set_edm_name( tc_entity_set_names-edm-growth_point ).

  ENDMETHOD.
ENDCLASS.
