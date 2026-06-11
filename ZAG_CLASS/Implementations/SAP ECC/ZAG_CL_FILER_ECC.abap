CLASS zag_cl_filer DEFINITION
  INHERITING FROM zag_cl_converter.

  PUBLIC SECTION.

    " Types
    "-------------------------------------------------
    TYPES:
      BEGIN OF ts_files,
        filename    TYPE string,
        sap_content TYPE REF TO data,
        conv_errors TYPE tt_conversions_errors,
      END OF ts_files,
      tt_files TYPE TABLE OF ts_files WITH DEFAULT KEY.


    " Constants
    "-------------------------------------------------
    CONSTANTS:
      BEGIN OF tc_file_source,
        local  TYPE char1 VALUE 'L' ##NO_TEXT,
        server TYPE char1 VALUE 'S' ##NO_TEXT,
      END OF tc_file_source,

      BEGIN OF tc_filetype,
        csv  TYPE char3 VALUE 'CSV'  ##NO_TEXT,
        xlsx TYPE char4 VALUE 'XLSX' ##NO_TEXT,
        txt  TYPE char3 VALUE 'TXT'  ##NO_TEXT,
      END OF tc_filetype.


    " Methods
    "-------------------------------------------------
    CLASS-METHODS:
      f4_help_dir_input
        IMPORTING
          !xv_source     TYPE abap_char1 DEFAULT tc_file_source-local
        EXPORTING
          !yv_path_input TYPE string,

      f4_help_dir_output
        IMPORTING
          !xv_source      TYPE abap_char1 DEFAULT tc_file_source-local
        EXPORTING
          !yv_path_output TYPE string,

      get_desktop_directory
        RETURNING value(yv_desktop_dir) TYPE string.

    METHODS:
      file_download
        IMPORTING
          !xv_filename  TYPE string
          !xv_source    TYPE char1     DEFAULT tc_file_source-local
          !xv_separator TYPE c OPTIONAL
        CHANGING
          !yref_tsap    TYPE REF TO data
        RAISING
          cx_ai_system_fault,

      file_upload
        IMPORTING
          !xv_filename    TYPE string
          !xv_source      TYPE char1   DEFAULT tc_file_source-local
        CHANGING
          !yref_tsap      TYPE REF TO data
          !yt_conv_errors TYPE tt_conversions_errors
          !xv_separator TYPE c OPTIONAL
        RAISING
          cx_ai_system_fault,

      zip_download
        IMPORTING
          !xv_zip_name TYPE string
          !xv_source   TYPE char1  DEFAULT tc_file_source-local
        CHANGING
          !yt_files    TYPE tt_files
        RAISING
          cx_ai_system_fault,

      zip_upload
        IMPORTING
          !xv_zip_name TYPE string
          !xv_source   TYPE char1     DEFAULT tc_file_source-local
        CHANGING
          !yt_files    TYPE tt_files
        RAISING
          cx_ai_system_fault.

  PROTECTED SECTION.


  PRIVATE SECTION.

    CONSTANTS:
      c_mandt TYPE fieldname VALUE 'MANDT' ##NO_TEXT.

    DATA:
      gref_sap_data  TYPE REF TO data,
      gt_str_data    TYPE string_table,

      gv_filetype    TYPE string,
      gv_filename    TYPE string,
      gv_header      TYPE abap_char1,
      gv_separator   TYPE abap_char1,

      go_structdescr TYPE REF TO cl_abap_structdescr,
      gt_fcat        TYPE lvc_t_fcat,
      go_zip         TYPE REF TO cl_abap_zip,
      gv_zip_name    TYPE string.


    " Methods
    "-------------------------------------------------
    METHODS:
      init_instance
        IMPORTING
          !xv_filename  TYPE string
          !xv_header    TYPE abap_char1    DEFAULT abap_true
          !xv_separator TYPE c OPTIONAL
        CHANGING
          !yref_tsap    TYPE REF TO data
        RAISING
          cx_ai_system_fault,

      download_csv_local
        RAISING
          cx_ai_system_fault,

      download_csv_server
        RAISING
          cx_ai_system_fault,

      download_excel_local
        RAISING
          cx_ai_system_fault,

      download_excel_server
        RAISING
          cx_ai_system_fault,

      download_zip_local
        RAISING
          cx_ai_system_fault,

      download_zip_server
        RAISING
          cx_ai_system_fault,

      upload_csv_local
        RAISING
          cx_ai_system_fault,

      upload_csv_server
        RAISING
          cx_ai_system_fault,

      upload_excel_local
        RAISING
          cx_ai_system_fault,

      upload_zip_local
        RAISING
          cx_ai_system_fault,

      upload_zip_server
        RAISING
          cx_ai_system_fault.

ENDCLASS.                    "zag_cl_filer DEFINITION



*----------------------------------------------------------------------*
*       CLASS zag_cl_filer IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zag_cl_filer IMPLEMENTATION.


  METHOD f4_help_dir_input.

    DATA:
      lv_path           TYPE string VALUE IS INITIAL,

      lv_server         TYPE msxxlist-name,
      lv_path_tmp       TYPE dxfields-longpath,
      lv_instancenumber TYPE instanz-systemnr VALUE IS INITIAL,

      lt_filetable      TYPE filetable,
      lcl_ref_itab      TYPE REF TO file_table,
      lv_rc             TYPE i.

    "-------------------------------------------------

    CASE xv_source.

      WHEN tc_file_source-server.

        CALL FUNCTION 'GET_SYSTEM_NUMBER'
          IMPORTING
            instancenumber = lv_instancenumber.

        lv_server = |{ sy-host }_{ sy-sysid }_{ lv_instancenumber }|.
        CONDENSE lv_server NO-GAPS.

        lv_path_tmp = ''.
        CALL FUNCTION 'F4_DXFILENAME_TOPRECURSION'
          EXPORTING
            i_location_flag = 'A'
            i_server        = lv_server
            filemask        = '*.*'
            fileoperation   = 'R'
          IMPORTING
            o_path          = lv_path_tmp
          EXCEPTIONS
            rfc_error       = 1
            error_with_gui  = 2
            OTHERS          = 3.
        CHECK sy-subrc EQ 0.
        lv_path = lv_path_tmp.

      WHEN tc_file_source-local.

        lv_path = get_desktop_directory( ).

        CALL METHOD cl_gui_frontend_services=>file_open_dialog
          EXPORTING
            initial_directory = lv_path
          CHANGING
            file_table        = lt_filetable
            rc                = lv_rc.

        FIELD-SYMBOLS <filetable> LIKE LINE OF lt_filetable.
        READ TABLE lt_filetable ASSIGNING <filetable> INDEX 1.
        CHECK sy-subrc EQ 0.
        lv_path = <filetable>-filename.

    ENDCASE.

    yv_path_input = lv_path.

  ENDMETHOD.                    "f4_help_dir_input


  METHOD f4_help_dir_output.

    DATA:
      lv_path TYPE string VALUE IS INITIAL.

    "------------------------------------------------

    CASE xv_source.

      WHEN tc_file_source-server.

        CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
          EXPORTING
*           directory        = ''
            filemask         = '.dummysap'
          IMPORTING
            serverfile       = lv_path
          EXCEPTIONS
            canceled_by_user = 1
            OTHERS           = 2.
        CHECK sy-subrc EQ 0.

      WHEN tc_file_source-local.

        lv_path = get_desktop_directory( ).

        CALL METHOD cl_gui_frontend_services=>directory_browse
          EXPORTING
            window_title         = ''
            initial_folder       = lv_path
          CHANGING
            selected_folder      = lv_path
          EXCEPTIONS
            cntl_error           = 1
            error_no_gui         = 2
            not_supported_by_gui = 3
            OTHERS               = 4.
        CHECK sy-subrc EQ 0.

    ENDCASE.

    yv_path_output = lv_path.

  ENDMETHOD.                    "f4_help_dir_output


  METHOD get_desktop_directory.

    yv_desktop_dir = ''.
    CALL METHOD cl_gui_frontend_services=>get_desktop_directory
      CHANGING
        desktop_directory = yv_desktop_dir
      EXCEPTIONS
        cntl_error        = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>update_view.

    yv_desktop_dir = |{ yv_desktop_dir }/|.

  ENDMETHOD.                    "get_desktop_directory


  METHOD file_download.
    DATA lx_ai_system_fault TYPE REF TO cx_ai_system_fault.

    FIELD-SYMBOLS:
      <lt_sap_data> TYPE STANDARD TABLE.

    TRY.

        "Init Instance Attribute
        "-------------------------------------------------
        init_instance(
          EXPORTING
            xv_filename  = xv_filename
            xv_header    = abap_true
            xv_separator = xv_separator
          CHANGING
            yref_tsap    = yref_tsap
        ).


        "Convert SAP Table data into String table Data
        "-------------------------------------------------
        ASSIGN me->gref_sap_data->* TO <lt_sap_data>.

        me->gt_str_data = me->conv_tsap_to_ext( xt_tsap_int  = <lt_sap_data>
                                                xv_header    = me->gv_header
                                                xv_separator = me->gv_separator
        ).


        "Start Download on Local / Server
        "-------------------------------------------------
        CASE xv_source.

          WHEN tc_file_source-local.

            CASE me->gv_filetype.

              WHEN tc_filetype-csv
                OR tc_filetype-txt.
                me->download_csv_local( ).

              WHEN tc_filetype-xlsx.
                me->download_excel_local( ).

            ENDCASE.

          WHEN tc_file_source-server.

            CASE me->gv_filetype.

              WHEN tc_filetype-csv
                OR tc_filetype-txt.
                me->download_csv_server( ).

              WHEN tc_filetype-xlsx.
                me->download_excel_server( ).

            ENDCASE.

        ENDCASE.



      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        DATA lv_except_msg TYPE string.
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION lx_ai_system_fault.
    ENDTRY.

  ENDMETHOD.                    "file_download


  METHOD file_upload.

    DATA:
      lv_xcontent        TYPE xstring,
      lx_ai_system_fault TYPE REF TO cx_ai_system_fault.

    FIELD-SYMBOLS:
      <lt_sap_data> TYPE STANDARD TABLE.

    TRY.

        "Init Instance Attribute
        "-------------------------------------------------
        init_instance(
          EXPORTING
            xv_filename  = xv_filename
            xv_header    = abap_true
            xv_separator = xv_separator
          CHANGING
            yref_tsap    = yref_tsap
        ).


        "Start Download on Local / Server
        "-------------------------------------------------
        CASE xv_source.

          WHEN tc_file_source-local.

            CASE me->gv_filetype.

              WHEN tc_filetype-csv
                OR tc_filetype-txt.
                me->upload_csv_local( ).

              WHEN tc_filetype-xlsx.
                "Upload from XLSX with in-built conversion in SAP Format
                me->upload_excel_local( ).

            ENDCASE.

          WHEN tc_file_source-server.

            CASE me->gv_filetype.

              WHEN tc_filetype-csv
                OR tc_filetype-txt.
                me->upload_csv_server( ).

              WHEN tc_filetype-xlsx.
                RAISE EXCEPTION TYPE cx_ai_system_fault
                  EXPORTING
                    errortext = tc_exception_msg-unable_read_file.

            ENDCASE.

        ENDCASE.


        "Conversion in SAP Format for CSV
        "-------------------------------------------------
        ASSIGN me->gref_sap_data->* TO <lt_sap_data>.

        me->conv_tsap_to_int(
          EXPORTING
            xt_tsap_ext           = me->gt_str_data[]
            xv_header             = me->gv_header
            xv_separator          = me->gv_separator
          CHANGING
            yt_tsap_int           = <lt_sap_data>
            yt_conversions_errors = yt_conv_errors
        ).


      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        DATA lv_except_msg TYPE string.
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION lx_ai_system_fault.
    ENDTRY.

  ENDMETHOD.                    "file_upload


  METHOD zip_download.

    DATA: lv_flat_str TYPE string,
          lv_xstr     TYPE xstring.

    DATA: lx_bcs TYPE REF TO cx_bcs.

    FIELD-SYMBOLS:
        <lt_sap_data> TYPE STANDARD TABLE.

    CREATE OBJECT me->go_zip.
    me->gv_zip_name = xv_zip_name.

    DATA lx_ai_system_fault TYPE REF TO cx_ai_system_fault.
    TRY.

        FIELD-SYMBOLS <files> LIKE LINE OF yt_files.
        LOOP AT yt_files ASSIGNING <files>.

          "Init Instance Attribute
          "-------------------------------------------------
          init_instance(
            EXPORTING
              xv_filename = <files>-filename
              xv_header   = abap_true
            CHANGING
              yref_tsap   = <files>-sap_content
          ).


          "Convert SAP Table data into String table Data
          "-------------------------------------------------
          ASSIGN me->gref_sap_data->* TO <lt_sap_data>.

          me->gt_str_data = me->conv_tsap_to_ext( xt_tsap_int  = <lt_sap_data>
                                                  xv_header    = me->gv_header
                                                  xv_separator = me->gv_separator
          ).

          TRY.
              lv_flat_str = me->conv_tstring_to_string( me->gt_str_data ).
              lv_xstr     = cl_bcs_convert=>string_to_xstring( lv_flat_str ).

              me->go_zip->add( name    = <files>-filename
                               content = lv_xstr
              ).
              me->go_zip->save( ).

            CATCH cx_bcs INTO lx_bcs.
          ENDTRY.

        ENDLOOP.


        CASE xv_source.

          WHEN tc_file_source-local.
            me->download_zip_local( ).

          WHEN tc_file_source-server.
            me->download_zip_server( ).

        ENDCASE.

      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        DATA lv_except_msg TYPE string.
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION lx_ai_system_fault.
    ENDTRY.

  ENDMETHOD.                    "zip_download


  METHOD zip_upload.

    DATA:
        lv_xcontent TYPE xstring,
        lv_flat_str TYPE string.

    FIELD-SYMBOLS:
      <lt_sap_data> TYPE STANDARD TABLE.

    CREATE OBJECT me->go_zip.
    me->gv_zip_name  = xv_zip_name.

    DATA lx_ai_system_fault TYPE REF TO cx_ai_system_fault.
    TRY.
        CASE xv_source.
          WHEN tc_file_source-local.
            me->upload_zip_local( ).

          WHEN tc_file_source-server.
            me->upload_zip_server( ).

        ENDCASE.


        FIELD-SYMBOLS <files> LIKE LINE OF yt_files.
        LOOP AT yt_files ASSIGNING <files>.

          "Init Instance Attribute
          "-------------------------------------------------
          init_instance(
            EXPORTING
              xv_filename = <files>-filename
              xv_header   = abap_true
            CHANGING
              yref_tsap   = <files>-sap_content
          ).


          "Load from ZIP
          "-------------------------------------------------
          CLEAR lv_xcontent.
          me->go_zip->get(
            EXPORTING
              name                    = <files>-filename
            IMPORTING
              content                 = lv_xcontent
            EXCEPTIONS
              zip_index_error         = 1
              zip_decompression_error = 2
              OTHERS                  = 3
          ).

          lv_flat_str = cl_bcs_convert=>xstring_to_string(
                                   iv_xstr = lv_xcontent
                                   iv_cp   = '4110'
          ).

          me->gt_str_data = conv_string_to_tstring( lv_flat_str ).




          "Conversion in SAP Format for CSV
          "-------------------------------------------------
          ASSIGN <files>-sap_content->* TO <lt_sap_data>.

          me->conv_tsap_to_int(
            EXPORTING
              xt_tsap_ext           = me->gt_str_data[]
              xv_header             = me->gv_header
              xv_separator          = me->gv_separator
            CHANGING
              yt_tsap_int           = <lt_sap_data>
              yt_conversions_errors = <files>-conv_errors
          ).

        ENDLOOP.

      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        DATA lv_except_msg TYPE string.
        lv_except_msg = lx_ai_system_fault->get_text( ).
        RAISE EXCEPTION lx_ai_system_fault.
    ENDTRY.


  ENDMETHOD.                    "zip_upload


  METHOD init_instance.

    FIELD-SYMBOLS:
     <sap_table> TYPE STANDARD TABLE.


    "Check if file is supported
    "-------------------------------------------------
    me->gv_filetype = ''.
    IF xv_filename CP '*.xlsx'.
      me->gv_filetype  = tc_filetype-xlsx.
      me->gv_separator = tc_separator-horizontal_tab.

    ELSEIF xv_filename CP '*.csv'.
      me->gv_filetype  = tc_filetype-csv.
      me->gv_separator = tc_separator-semicolon.

    ELSEIF xv_filename CP '*.txt'.
      me->gv_filetype  = tc_filetype-txt.
      me->gv_separator = tc_separator-semicolon.

    ELSE.
      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-not_supported_file.

    ENDIF.

    
    IF xv_separator IS NOT INITIAL.
      me->gv_separator = xv_separator.
    ENDIF.


    "Set Data Table
    "---------------------------------------------------------------
    me->gref_sap_data  = yref_tsap.
    me->gv_filename    = xv_filename.
    me->gv_header      = xv_header.

    ASSIGN me->gref_sap_data->* TO <sap_table>.



    "Set Fieldcat and Fields Descriptor
    "---------------------------------------------------------------
    DATA lx_ai_system_fault TYPE REF TO cx_ai_system_fault.
    TRY.
        me->get_fieldcat_from_data(
          EXPORTING
            xt_sap_table              = <sap_table>
          IMPORTING
            yo_structdescr            = me->go_structdescr
            yt_fcat                   = me->gt_fcat
        ).

        DELETE me->gt_fcat WHERE fieldname EQ c_mandt.


      CATCH cx_ai_system_fault INTO lx_ai_system_fault.
        RAISE EXCEPTION lx_ai_system_fault.
    ENDTRY.

  ENDMETHOD.                    "init_instance


  METHOD download_csv_local.

    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename                = me->gv_filename
      CHANGING
        data_tab                = me->gt_str_data[]
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        not_supported_by_gui    = 22
        error_no_gui            = 23
        OTHERS                  = 24.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

  ENDMETHOD.                    "download_csv_local


  METHOD download_csv_server.

    OPEN DATASET me->gv_filename FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.

      CLOSE DATASET me->gv_filename.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.


    FIELD-SYMBOLS: <str_data> LIKE LINE OF me->gt_str_data.
    LOOP AT me->gt_str_data ASSIGNING <str_data>.
      TRANSFER <str_data> TO me->gv_filename.
    ENDLOOP.

    CLOSE DATASET me->gv_filename.

  ENDMETHOD.                    "download_csv_server


  METHOD download_excel_local.

*    TYPES: BEGIN OF ts_string,
*             string TYPE string,
*           END OF ts_string.
*
*    DATA lt_str_data TYPE TABLE OF ts_string.
*
*    get_fieldcat_from_data(
*      EXPORTING
*        xt_sap_table              = lt_str_data
*      IMPORTING
*        yt_fcat                   = DATA(lt_fcat)
*      EXCEPTIONS
*        unable_define_structdescr = 1
*        OTHERS                    = 2
*    ).
*    IF sy-subrc <> 0.
**     MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
*
*    lt_str_data = VALUE #( FOR <str> IN xt_str_data ( string = <str> ) ).
*    DATA(lref_str_data) = REF #( lt_str_data ).
*
*
*    cl_salv_bs_lex=>export_from_result_data_table(
*      EXPORTING
*        is_format            = if_salv_bs_lex_format=>mc_format_xlsx
*        ir_result_data_table = cl_salv_ex_util=>factory_result_data_table( r_data          = lref_str_data
*                                                                           t_fieldcatalog  = lt_fcat )
*      IMPORTING
*        er_result_file       = DATA(lv_xdata) ).



    "Standard Version ->
    "Conversion of fields like data, numbers exc.
    "will be performed by SAP Standard
    "-------------------------------------------------
    DATA lv_xdata TYPE xstring.
    cl_salv_bs_lex=>export_from_result_data_table(
      EXPORTING
        is_format            = if_salv_bs_lex_format=>mc_format_xlsx
        ir_result_data_table = cl_salv_ex_util=>factory_result_data_table( r_data          = me->gref_sap_data
                                                                           t_fieldcatalog  = me->gt_fcat )
      IMPORTING
        er_result_file       = lv_xdata ).


    DATA: lv_xlength TYPE i,
          lt_bin_tab TYPE solix_tab.

    lv_xlength = xstrlen( lv_xdata ).
    lt_bin_tab = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_xdata ).

    cl_gui_frontend_services=>gui_download(
        EXPORTING
          bin_filesize              = lv_xlength           " File length for binary files
          filename                  = me->gv_filename      " Name of file
          filetype                  = 'BIN'                " File type (ASCII, binary ...)
        CHANGING
          data_tab                  = lt_bin_tab          " Transfer table
        EXCEPTIONS
          file_write_error          = 1                    " Cannot write to file
          no_batch                  = 2                    " Cannot execute front-end function in background
          gui_refuse_filetransfer   = 3                    " Incorrect Front End
          invalid_type              = 4                    " Invalid value for parameter FILETYPE
          no_authority              = 5                    " No Download Authorization
          unknown_error             = 6                    " Unknown error
          header_not_allowed        = 7                    " Invalid header
          separator_not_allowed     = 8                    " Invalid separator
          filesize_not_allowed      = 9                    " Invalid file size
          header_too_long           = 10                   " Header information currently restricted to 1023 bytes
          dp_error_create           = 11                   " Cannot create DataProvider
          dp_error_send             = 12                   " Error Sending Data with DataProvider
          dp_error_write            = 13                   " Error Writing Data with DataProvider
          unknown_dp_error          = 14                   " Error when calling data provider
          access_denied             = 15                   " Access to File Denied
          dp_out_of_memory          = 16                   " Not enough memory in data provider
          disk_full                 = 17                   " Storage medium is full.
          dp_timeout                = 18                   " Data provider timeout
          file_not_found            = 19                   " Could not find file
          dataprovider_exception    = 20                   " General Exception Error in DataProvider
          control_flush_error       = 21                   " Error in Control Framework
          not_supported_by_gui      = 22                   " GUI does not support this
          error_no_gui              = 23                   " GUI not available
          OTHERS                    = 24
        ).
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

  ENDMETHOD.                    "download_excel_local


  METHOD download_excel_server.

    DATA: lt_data_ref TYPE REF TO data.

    FIELD-SYMBOLS: <t_sap_data> TYPE STANDARD TABLE.

    "-------------------------------------------------

    DATA lv_xdata TYPE xstring.
    cl_salv_bs_lex=>export_from_result_data_table(
      EXPORTING
        is_format            = if_salv_bs_lex_format=>mc_format_xlsx
        ir_result_data_table = cl_salv_ex_util=>factory_result_data_table( r_data          = me->gref_sap_data
                                                                           t_fieldcatalog  = me->gt_fcat )
      IMPORTING
        er_result_file       = lv_xdata ).


    DATA lv_xlength TYPE i.
    lv_xlength = xstrlen( lv_xdata ).

    "-------------------------------------------------

    OPEN DATASET me->gv_filename FOR OUTPUT IN BINARY MODE.
    IF sy-subrc <> 0.

      CLOSE DATASET me->gv_filename.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

    TRANSFER lv_xdata TO me->gv_filename.

    CLOSE DATASET me->gv_filename.

  ENDMETHOD.                    "download_excel_server


  METHOD download_zip_local.

    DATA: lv_xzip     TYPE xstring,
          lt_bin_zip  TYPE solix_tab,
          lv_filesize TYPE i.

    lv_xzip     = me->go_zip->save( ).
    lt_bin_zip  = cl_bcs_convert=>xstring_to_solix( lv_xzip ).
    lv_filesize = xstrlen( lv_xzip ).


    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename                = me->gv_zip_name
        filetype                = 'BIN'
        bin_filesize            = lv_filesize
      CHANGING
        data_tab                = lt_bin_zip[]
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        not_supported_by_gui    = 22
        error_no_gui            = 23
        OTHERS                  = 24.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

  ENDMETHOD.                    "download_zip_local


  METHOD download_zip_server.

    DATA: lv_zipname TYPE string,
          lv_xzip    TYPE xstring.

    lv_zipname = me->gv_zip_name.
    OPEN DATASET lv_zipname FOR OUTPUT IN BINARY MODE.
    IF sy-subrc <> 0.
      CLOSE DATASET lv_zipname.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

    lv_xzip = me->go_zip->save( ).

    TRANSFER lv_xzip TO lv_zipname.
    CLOSE DATASET lv_zipname.

  ENDMETHOD.                    "download_zip_server


  METHOD upload_csv_local.

    CLEAR me->gt_str_data[].
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename = me->gv_filename
        filetype = 'ASC'
      CHANGING
        data_tab = me->gt_str_data[]
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

  ENDMETHOD.                    "upload_csv_local


  METHOD upload_csv_server.

    DATA:
      ls_str_data TYPE string.

    "-------------------------------------------------

    OPEN DATASET me->gv_filename FOR INPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.

      CLOSE DATASET me->gv_filename.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

    DO.

      CLEAR ls_str_data.
      READ DATASET me->gv_filename INTO ls_str_data.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      APPEND ls_str_data TO me->gt_str_data.

    ENDDO.

    CLOSE DATASET me->gv_filename.

  ENDMETHOD.                    "upload_csv_server


  METHOD upload_excel_local.

    DATA:
      lv_except_msg    TYPE string,
      lt_bin_tab       TYPE solix_tab,
      lcl_excel_ref    TYPE REF TO cl_fdt_xl_spreadsheet,
      lcl_table_descr  TYPE REF TO cl_abap_tabledescr,
      lcl_struct_descr TYPE REF TO cl_abap_structdescr.

    FIELD-SYMBOLS:
      <t_excel_data> TYPE STANDARD TABLE,
      <str_data>     TYPE string.

    "-------------------------------------------------

    CLEAR: me->gt_str_data[].

    "Read in binary the excel
    "-------------------------------------------------
    DATA: lv_filelen TYPE i,
          lv_headerx TYPE xstring.

    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename   = me->gv_filename
        filetype   = 'BIN'
      IMPORTING
        filelength = lv_filelen
        header     = lv_headerx
      CHANGING
        data_tab   = lt_bin_tab[]
      EXCEPTIONS
        OTHERS     = 1.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.


    "Conversion in XSTRING NB cl_bcs_convert not returns headerx
    "-------------------------------------------------
*      DATA(lv_xstr_tab) = cl_bcs_convert=>solix_to_xstring( it_solix   = lt_bin_tab
*                                                            iv_size    = lv_filelen ).
    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_filelen
      IMPORTING
        buffer       = lv_headerx
      TABLES
        binary_tab   = lt_bin_tab[]
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-internal_error.

    ENDIF.


    "Reading excel content using HEADERX
    "-------------------------------------------------
    DATA lx_excel_core TYPE REF TO cx_fdt_excel_core.
    TRY.
        CREATE OBJECT lcl_excel_ref
          EXPORTING
            document_name = me->gv_filename
            xdocument     = lv_headerx.

      CATCH cx_fdt_excel_core INTO lx_excel_core.
        lv_except_msg = lx_excel_core->get_text( ).
    ENDTRY .

    CHECK lcl_excel_ref IS BOUND.

    DATA lt_worksheets TYPE if_fdt_doc_spreadsheet=>t_worksheet_names.
    lcl_excel_ref->if_fdt_doc_spreadsheet~get_worksheet_names(
      IMPORTING
        worksheet_names = lt_worksheets ).


    "Takes the first worksheet as default
    "-------------------------------------------------
    FIELD-SYMBOLS <woksheetname> LIKE LINE OF lt_worksheets.
    READ TABLE lt_worksheets ASSIGNING <woksheetname> INDEX 1.

    DATA lcl_data_ref TYPE REF TO data.
    lcl_data_ref = lcl_excel_ref->if_fdt_doc_spreadsheet~get_itab_from_worksheet( <woksheetname> ).
    ASSIGN lcl_data_ref->* TO <t_excel_data>.


    "Convert to CSV String format
    "---------------------------------------------------------------
    FIELD-SYMBOLS: <excel>     TYPE any,
                   <comp>      LIKE LINE OF me->go_structdescr->components,
                   <excel_col> TYPE any.

    LOOP AT <t_excel_data> ASSIGNING <excel>.

      APPEND INITIAL LINE TO me->gt_str_data ASSIGNING <str_data>.

      LOOP AT me->go_structdescr->components ASSIGNING <comp>.

        ASSIGN COMPONENT sy-tabix OF STRUCTURE <excel> TO <excel_col>.
        CHECK sy-subrc EQ 0.
        IF <str_data> EQ ''.
          <str_data> = <excel_col>.
        ELSEIF <str_data> NE ''.
          <str_data> =  |{ <str_data> }{ me->gv_separator }{ <excel_col> }|.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.                    "upload_excel_local


  METHOD upload_zip_local.

    DATA: lt_bin_zip  TYPE solix_tab,
          lv_filesize TYPE i.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename                = me->gv_zip_name
        filetype                = 'BIN'
*        has_field_separator     = space
      IMPORTING
        filelength              = lv_filesize
*        header                  =
      CHANGING
        data_tab                = lt_bin_zip[]
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19
    ).
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

    DATA lv_xstr_zip TYPE xstring.
    lv_xstr_zip = cl_bcs_convert=>solix_to_xstring(
                          it_solix = lt_bin_zip
                          iv_size  = lv_filesize
                        ).
    me->go_zip->load( lv_xstr_zip ).


  ENDMETHOD.                    "upload_zip_local


  METHOD upload_zip_server.

    DATA: lv_xstr_zip TYPE xstring,
          lv_zipname  TYPE string.

    lv_zipname = me->gv_zip_name.
    OPEN DATASET lv_zipname IN BINARY MODE FOR INPUT.
    IF sy-subrc <> 0.
      CLOSE DATASET lv_zipname.

      RAISE EXCEPTION TYPE cx_ai_system_fault
        EXPORTING
          errortext = tc_exception_msg-unable_read_file.

    ENDIF.

    READ DATASET lv_zipname INTO lv_xstr_zip.

    me->go_zip->load( lv_xstr_zip ).

    CLOSE DATASET lv_zipname.


  ENDMETHOD.                    "upload_zip_server

ENDCLASS.                    "zag_cl_filer IMPLEMENTATION