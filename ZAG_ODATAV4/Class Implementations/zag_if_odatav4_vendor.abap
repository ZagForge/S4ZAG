INTERFACE zag_if_odatav4_vendor
  PUBLIC .

  TYPES:

    " Data Sources List — strutture curate sulle tabelle DB dirette
    " (solo i campi che vogliamo esporre via OData)
    "---------------------------------------------------------------
    BEGIN OF ts_vendor,
      lifnr TYPE lfa1-lifnr,
      name1 TYPE lfa1-name1,
      name2 TYPE lfa1-name2,
      name3 TYPE lfa1-name3,
      name4 TYPE lfa1-name4,
      land1 TYPE lfa1-land1,
      ort01 TYPE lfa1-ort01,
      pstlz TYPE lfa1-pstlz,
      regio TYPE lfa1-regio,
      stras TYPE lfa1-stras,
      adrnr TYPE lfa1-adrnr,
      loevm TYPE lfa1-loevm,
      sperm TYPE lfa1-sperm,
      stcd1 TYPE lfa1-stcd1,
      stcd2 TYPE lfa1-stcd2,
      stceg TYPE lfa1-stceg,
    END OF ts_vendor,

    BEGIN OF ts_company,
      lifnr TYPE lfb1-lifnr,
      bukrs TYPE lfb1-bukrs,
      sperr TYPE lfb1-sperr,
      loevm TYPE lfb1-loevm,
      akont TYPE lfb1-akont,
      zterm TYPE lfb1-zterm,
      hbkid TYPE lfb1-hbkid,
    END OF ts_company,

    BEGIN OF ts_purchorg,
      lifnr TYPE lfm1-lifnr,
      ekorg TYPE lfm1-ekorg,
      sperm TYPE lfm1-sperm,
      loevm TYPE lfm1-loevm,
      waers TYPE lfm1-waers,
      zterm TYPE lfm1-zterm,
      inco1 TYPE lfm1-inco1,
      inco2 TYPE lfm1-inco2,
      ekgrp TYPE lfm1-ekgrp,
    END OF ts_purchorg,

    BEGIN OF ts_vendor_structures,
      vendor   TYPE ts_vendor,
      company  TYPE ts_company,
      purchorg TYPE ts_purchorg,
    END OF ts_vendor_structures,


    " KEY Fields
    "---------------------------------------------------------------
    BEGIN OF ts_key_range,
      lifnr TYPE RANGE OF ts_vendor-lifnr,
      bukrs TYPE RANGE OF ts_company-bukrs,
      ekorg TYPE RANGE OF ts_purchorg-ekorg,
    END OF ts_key_range.


  TYPES:

    " Deep Structure
    "---------------------------------------------------------------
    BEGIN OF ts_deep_struct.
      INCLUDE TYPE ts_vendor.
    TYPES:
      _company  TYPE TABLE OF ts_company  WITH DEFAULT KEY,
      _purchorg TYPE TABLE OF ts_purchorg WITH DEFAULT KEY,
    END OF ts_deep_struct,
    tt_deep_struct TYPE TABLE OF ts_deep_struct WITH KEY lifnr.


  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  CONSTANTS:

    " Entity Type Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_type_names,
      BEGIN OF internal,
        vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'VENDOR',
        company  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'COMPANY',
        purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'PURCHORG',
      END OF internal,

      BEGIN OF edm,
        vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'VendorType',
        company  TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'CompanyType',
        purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'PurchorgType',
      END OF edm,
    END OF tc_entity_type_names,


    " Entity Set Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_set_names,
      BEGIN OF internal,
        vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'VENDOR',
        company  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'COMPANY',
        purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'PURCHORG',
      END OF internal,
      BEGIN OF edm,
        vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Vendor',
        company  TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Company',
        purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE 'Purchorg',
      END OF edm,
    END OF tc_entity_set_names ,


    " Navigation Properties Names
    "---------------------------------------------------------------
    BEGIN OF tc_nav_prop_names,
      BEGIN OF internal,
        vendor_to_company  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE '_COMPANY',
        vendor_to_purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE '_PURCHORG',
      END OF internal,
      BEGIN OF edm,
        vendor_to_company  TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE '_Company',
        vendor_to_purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_edm_name VALUE '_Purchorg',
      END OF edm,
    END OF tc_nav_prop_names.

ENDINTERFACE.
