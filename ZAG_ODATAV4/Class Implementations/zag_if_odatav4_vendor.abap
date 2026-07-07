INTERFACE zag_if_odatav4_vendor
  PUBLIC .

  TYPES:

    " Data Sources List
    "---------------------------------------------------------------
    BEGIN OF ts_cds_views,
      vendor   TYPE zag_cds_lfa1,
      company  TYPE zag_cds_lfb1,
      purchorg TYPE zag_cds_lfm1,
    END OF ts_cds_views,


    " KEY Fields
    "---------------------------------------------------------------
    BEGIN OF ts_key_range,
      lifnr TYPE RANGE OF ts_cds_views-vendor-lifnr,
      bukrs TYPE RANGE OF ts_cds_views-company-bukrs,
      ekorg TYPE RANGE OF ts_cds_views-purchorg-ekorg,
    END OF ts_key_range.


  TYPES:

    " Deep Structure
    "---------------------------------------------------------------
    BEGIN OF ts_deep_struct.
      INCLUDE TYPE ts_cds_views-vendor.
    TYPES:
      _company  TYPE TABLE OF ts_cds_views-company  WITH DEFAULT KEY,
      _purchorg TYPE TABLE OF ts_cds_views-purchorg WITH DEFAULT KEY,
    END OF ts_deep_struct,
    tt_deep_struct TYPE TABLE OF ts_deep_struct WITH KEY lifnr.


  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  CONSTANTS:

    " Data Sources Names
    "---------------------------------------------------------------
    BEGIN OF tc_cds_view_names,
      vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFA1',
      company  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFB1',
      purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFM1',
    END OF tc_cds_view_names,


    " Entity Type Names
    "---------------------------------------------------------------
    BEGIN OF tc_entity_type_names,
      BEGIN OF internal,
        vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFA1',
        company  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFB1',
        purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFM1',
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
        vendor   TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFA1',
        company  TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFB1',
        purchorg TYPE /iwbep/if_v4_med_element=>ty_e_med_internal_name VALUE 'ZAG_CDS_LFM1',
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
