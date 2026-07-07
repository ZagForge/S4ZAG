CLASS zag_cl_utils_migration DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    " Types
    "-------------------------------------------------
    TYPES:
      BEGIN OF ts_fm_userexit,
        cmod_name      TYPE modact-name,
        smod_name      TYPE modact-member,
        master_program TYPE tfdir-pname,
        fm_program     TYPE wbcrossi-include,
        cust_incl_name TYPE wbcrossi-name,
        funcname       TYPE modsap-member,
        activ          TYPE tsdir-activ,
      END OF ts_fm_userexit,

      BEGIN OF ts_screen_exit,
        cmod_name     TYPE modact-name,
        smod_name     TYPE modact-member,
        id_concat     TYPE modsap-member,
        calling_prog  TYPE tsdir-progname,
        calling_dynnr TYPE tsdir-dynnr,
        bername       TYPE tsdir-bername,
        called_prog   TYPE tsdir-progname,
        called_dynnr  TYPE tsdir-dynnr,
        activ         TYPE tsdir-activ,
      END OF ts_screen_exit,

      BEGIN OF ts_buffer,
        data(1024) TYPE x,
      END OF ts_buffer.

   " Types Tables
    "-------------------------------------------------
    TYPES:
      tt_tadir       TYPE TABLE OF tadir WITH DEFAULT KEY,
      tt_e071        TYPE TABLE OF e071 WITH DEFAULT KEY,
      tt_fm_userexit TYPE TABLE OF ts_fm_userexit WITH DEFAULT KEY,
      tt_screen_exit TYPE TABLE OF ts_screen_exit WITH DEFAULT KEY,
      tt_buffer      TYPE TABLE OF ts_buffer WITH DEFAULT KEY.

   " Types Range
    "-------------------------------------------------
    TYPES:
      tr_obj_name  TYPE RANGE OF tadir-obj_name,
      tr_object    TYPE RANGE OF tadir-object,
      tr_cmod_name TYPE RANGE OF modact-name,
      tr_smod_name TYPE RANGE OF modact-member,
      tr_funcname  TYPE RANGE OF modsap-member.


    "Methods
    "-------------------------------------------------
    METHODS:
      fetch_tadir
        IMPORTING
          !xr_obj_name    TYPE tr_obj_name
          !xr_object      TYPE tr_object
        RETURNING
          VALUE(yt_tadir) TYPE tt_tadir
        EXCEPTIONS
          object_not_found,

      fetch_fm_userexit
        IMPORTING
          !xr_cmod_name      TYPE tr_cmod_name OPTIONAL
          !xr_smod_name      TYPE tr_smod_name OPTIONAL
          !xr_funcname       TYPE tr_funcname OPTIONAL
        RETURNING
          VALUE(yt_userexit) TYPE tt_fm_userexit,

      fetch_screen_exit
        IMPORTING
          !xr_cmod_name         TYPE tr_cmod_name OPTIONAL
          !xr_smod_name         TYPE tr_smod_name OPTIONAL
        RETURNING
          VALUE(yt_screen_exit) TYPE tt_screen_exit,

      upload_tr
        IMPORTING
          !xv_tr_number    TYPE e070-trkorr
          !xv_frontend_dir TYPE string OPTIONAL
        EXCEPTIONS
          upload_failed,

      download_tr
        IMPORTING
          !xv_tr_number    TYPE e070-trkorr
          !xv_frontend_dir TYPE string OPTIONAL
        EXCEPTIONS
          tr_not_found
          download_failed,

      get_tr_path
        RETURNING
          VALUE(yv_path) TYPE string,

      insert_obj_into_tr
        IMPORTING
          !xr_obj_name  TYPE tr_obj_name
          !xr_object    TYPE tr_object
          !xv_tr_svil   TYPE e070-trkorr OPTIONAL
          !xv_tr_rep    TYPE e070-trkorr OPTIONAL
        EXPORTING
          !yt_tadir_err TYPE tt_tadir
        EXCEPTIONS
          object_not_found
          input_error
          generic_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS:
      build_e071
        IMPORTING
          !xt_tadir           TYPE tt_tadir
        EXPORTING
          VALUE(yt_e071_svil) TYPE tt_e071
          VALUE(yt_e071_rep)  TYPE tt_e071,

      get_desktop_directory
        RETURNING
          VALUE(yv_desktop_dir) TYPE string,

      gui_upload
        IMPORTING
          !xv_filename TYPE string
        EXPORTING
          !yt_bin      TYPE tt_buffer
          !yv_length   TYPE i,

      gui_download
        IMPORTING
          !xv_filename TYPE string
          !xt_bin      TYPE tt_buffer
          !xv_length   TYPE i,

      server_write
        IMPORTING
          !xv_filename TYPE string
          !xt_bin      TYPE tt_buffer
          !xv_length   TYPE i
        RETURNING
          VALUE(yv_ok) TYPE os_boolean,

      server_read
        IMPORTING
          !xv_filename TYPE string
        EXPORTING
          !yt_bin      TYPE tt_buffer
          !yv_length   TYPE i.

ENDCLASS.                    "zag_cl_utils_migration DEFINITION



*----------------------------------------------------------------------*
*       CLASS zag_cl_utils_migration IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS zag_cl_utils_migration IMPLEMENTATION.


  METHOD build_e071.

    DATA: ls_e071 TYPE e071.

    FIELD-SYMBOLS: <tadir> TYPE tadir.

    CLEAR yt_e071_svil.
    CLEAR yt_e071_rep.

    LOOP AT xt_tadir ASSIGNING <tadir>.

      CLEAR ls_e071.
      ls_e071-pgmid    = 'R3TR'.
      ls_e071-object   = <tadir>-object.
      ls_e071-obj_name = <tadir>-obj_name.

      IF <tadir>-srcsystem EQ sy-sysid.
        APPEND ls_e071 TO yt_e071_svil.
      ELSE.
        APPEND ls_e071 TO yt_e071_rep.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.                    "build_e071


  METHOD download_tr.

    DATA: lv_frontend_dir        TYPE string,
          lv_path_server_cofiles TYPE string,
          lv_path_server_data    TYPE string,
          lv_tr_cofiles          TYPE string,
          lv_tr_data             TYPE string,
          lv_filename            TYPE string,
          lt_tr_cofiles_bin      TYPE tt_buffer,
          lv_tr_cofiles_len      TYPE i,
          lt_tr_data_bin         TYPE tt_buffer,
          lv_tr_data_len         TYPE i.

    SELECT COUNT(*) FROM e070 WHERE trkorr EQ xv_tr_number.
    IF sy-dbcnt EQ 0.
      RAISE tr_not_found.
    ENDIF.


    IF xv_frontend_dir IS NOT INITIAL.
      lv_frontend_dir = xv_frontend_dir.
    ELSE.
      lv_frontend_dir = me->get_desktop_directory( ).
    ENDIF.

    " Add trailing "\" or "/"
    IF xv_frontend_dir CA '/'.
      REPLACE REGEX '([^/])\s*$' IN lv_frontend_dir WITH '$1/' .
    ELSE.
      REPLACE REGEX '([^\\])\s*$' IN lv_frontend_dir WITH '$1\\'.
    ENDIF.


    CONCATENATE get_tr_path( ) '/cofiles/' INTO lv_path_server_cofiles.
    CONCATENATE get_tr_path( ) '/data/'    INTO lv_path_server_data.

    CONCATENATE 'K' xv_tr_number+4 '.' xv_tr_number(3) INTO lv_tr_cofiles.
    CONDENSE lv_tr_cofiles NO-GAPS.

    CONCATENATE 'R' xv_tr_number+4 '.' xv_tr_number(3) INTO lv_tr_data.
    CONDENSE lv_tr_data NO-GAPS.


    " COFILES
    CONCATENATE lv_path_server_cofiles lv_tr_cofiles INTO lv_filename.
    me->server_read(
      EXPORTING
        xv_filename = lv_filename
      IMPORTING
        yt_bin      = lt_tr_cofiles_bin
        yv_length   = lv_tr_cofiles_len
    ).

    CONCATENATE lv_frontend_dir lv_tr_cofiles INTO lv_filename.
    me->gui_download(
      xv_filename = lv_filename
      xt_bin      = lt_tr_cofiles_bin
      xv_length   = lv_tr_cofiles_len
    ).


    " DATA
    CONCATENATE lv_path_server_data lv_tr_data INTO lv_filename.
    me->server_read(
      EXPORTING
        xv_filename = lv_filename
      IMPORTING
        yt_bin      = lt_tr_data_bin
        yv_length   = lv_tr_data_len
    ).

    CONCATENATE lv_frontend_dir lv_tr_data INTO lv_filename.
    me->gui_download(
      xv_filename = lv_filename
      xt_bin      = lt_tr_data_bin
      xv_length   = lv_tr_data_len
    ).

  ENDMETHOD.                    "download_tr


  METHOD fetch_fm_userexit.

    DATA: lv_incl TYPE rs38l-include,
          lv_fm   TYPE rs38l-name.

    FIELD-SYMBOLS: <userexit> TYPE ts_fm_userexit.

    CLEAR yt_userexit.

    SELECT DISTINCT
       modact~name modact~member tfdir~pname
       wbcrossi~include wbcrossi~name modsap~member
    INTO TABLE yt_userexit
    FROM modact AS modact
    INNER JOIN modsap AS modsap
            ON modsap~name EQ modact~member
    INNER JOIN tfdir AS tfdir
            ON tfdir~funcname EQ modsap~member
    INNER JOIN wbcrossi AS wbcrossi
            ON wbcrossi~master EQ tfdir~pname
    WHERE modsap~typ    EQ 'E'
      AND wbcrossi~name LIKE 'Z%'
      AND modact~name   IN xr_cmod_name
      AND modact~member IN xr_smod_name
      AND modsap~member IN xr_funcname.

    CHECK sy-subrc EQ 0.


    LOOP AT yt_userexit ASSIGNING <userexit>.

      <userexit>-activ = abap_false.

      lv_incl = <userexit>-fm_program.
      lv_fm   = ''.

      CALL FUNCTION 'FUNCTION_INCLUDE_INFO'
        CHANGING
          funcname            = lv_fm
          include             = lv_incl
        EXCEPTIONS
          function_not_exists = 1
          include_not_exists  = 2
          group_not_exists    = 3
          no_selections       = 4
          no_function_include = 5
          OTHERS              = 6.

      CHECK <userexit>-funcname EQ lv_fm.


      <userexit>-activ = abap_true.


    ENDLOOP.

    DELETE yt_userexit WHERE funcname IS INITIAL.

  ENDMETHOD.                    "fetch_fm_userexit


  METHOD fetch_screen_exit.

    DATA: BEGIN OF ls_raw,
            name   TYPE modact-name,
            member TYPE modact-member,
            idc    TYPE modsap-member,
          END OF ls_raw.

    DATA: lt_raw         LIKE TABLE OF ls_raw,
          ls_screen_exit TYPE ts_screen_exit,
          lt_d020s       TYPE TABLE OF d020s.

    FIELD-SYMBOLS: <raw>         LIKE ls_raw,
                   <screen_exit> TYPE ts_screen_exit.

    CLEAR yt_screen_exit.

    SELECT DISTINCT
       modact~name modact~member modsap~member
    INTO TABLE lt_raw
    FROM modact AS modact
    INNER JOIN modsap AS modsap
            ON modsap~name EQ modact~member
    WHERE modsap~typ    EQ 'S'
      AND modact~name   IN xr_cmod_name
      AND modact~member IN xr_smod_name.

    CHECK sy-subrc EQ 0.


    LOOP AT lt_raw ASSIGNING <raw>.

      CLEAR ls_screen_exit.
      ls_screen_exit-cmod_name     = <raw>-name.
      ls_screen_exit-smod_name     = <raw>-member.
      ls_screen_exit-id_concat     = <raw>-idc.
      ls_screen_exit-calling_prog  = <raw>-idc(8).
      ls_screen_exit-calling_dynnr = <raw>-idc+8(4).
      ls_screen_exit-bername       = <raw>-idc+13(8).
      ls_screen_exit-called_prog   = <raw>-idc+22(8).
      ls_screen_exit-called_dynnr  = <raw>-idc+30(4).

      APPEND ls_screen_exit TO yt_screen_exit.

    ENDLOOP.


    SELECT *
    INTO TABLE lt_d020s
    FROM d020s
    FOR ALL ENTRIES IN yt_screen_exit
    WHERE prog EQ yt_screen_exit-called_prog
      AND dnum EQ yt_screen_exit-called_dynnr
      ORDER BY PRIMARY KEY.

    CHECK sy-subrc EQ 0.

    LOOP AT yt_screen_exit ASSIGNING <screen_exit>.

      READ TABLE lt_d020s WITH KEY prog = <screen_exit>-called_prog
                                    dnum = <screen_exit>-called_dynnr
                           TRANSPORTING NO FIELDS.
      CHECK sy-subrc EQ 0.

      <screen_exit>-activ = 'X'.
    ENDLOOP.


  ENDMETHOD.                    "fetch_screen_exit


  METHOD fetch_tadir.

    CLEAR yt_tadir.

    SELECT * FROM tadir INTO TABLE yt_tadir
      WHERE object   IN xr_object
        AND obj_name IN xr_obj_name.
    IF sy-subrc <> 0.
      RAISE object_not_found.
    ENDIF.

  ENDMETHOD.                    "fetch_tadir


  METHOD get_desktop_directory.

    CLEAR yv_desktop_dir.
    cl_gui_frontend_services=>get_desktop_directory(
      CHANGING
        desktop_directory = yv_desktop_dir
      EXCEPTIONS
        cntl_error        = 1
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>update_view.

    CONCATENATE yv_desktop_dir '/' INTO yv_desktop_dir.

  ENDMETHOD.                    "get_desktop_directory


  METHOD get_tr_path.

    CLEAR yv_path.

    DATA lv_path TYPE c LENGTH 512.
    CALL 'C_SAPGPARAM' ID 'NAME'  FIELD 'DIR_TRANS'
                       ID 'VALUE' FIELD lv_path.

    yv_path = lv_path.

  ENDMETHOD.                    "get_tr_path


  METHOD gui_download.

    DATA lt_bin TYPE tt_buffer.
    lt_bin = xt_bin.

    cl_gui_frontend_services=>gui_download(
      EXPORTING
        bin_filesize            = xv_length
        filename                = xv_filename
        filetype                = 'BIN'
      CHANGING
        data_tab                = lt_bin
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
        OTHERS                  = 24
    ).
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.


  ENDMETHOD.                    "gui_download


  METHOD gui_upload.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename                = xv_filename
        filetype                = 'BIN'
      IMPORTING
        filelength              = yv_length
      CHANGING
        data_tab                = yt_bin
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
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

  ENDMETHOD.                    "gui_upload


  METHOD insert_obj_into_tr.

    DATA: lt_e071           TYPE TABLE OF e071,
          lt_e071k          TYPE TABLE OF e071k,
          lt_tadir          TYPE tt_tadir,
          lt_e071_svil      TYPE tt_e071,
          lt_e071_rep       TYPE tt_e071,
          lv_error_occurred TYPE abap_bool.

    FIELD-SYMBOLS: <e071>  TYPE e071,
                   <tadir> TYPE tadir.

    CLEAR yt_tadir_err.

    IF xv_tr_svil IS INITIAL
      AND xv_tr_rep IS INITIAL.
      RAISE input_error.
    ENDIF.

    me->fetch_tadir(
      EXPORTING
        xr_obj_name      = xr_obj_name
        xr_object        = xr_object
      RECEIVING
        yt_tadir         = lt_tadir
      EXCEPTIONS
        object_not_found = 1
        OTHERS           = 2
    ).
    IF sy-subrc <> 0.
      RAISE object_not_found.
    ENDIF.

    me->build_e071(
      EXPORTING
        xt_tadir     = lt_tadir
      IMPORTING
        yt_e071_svil = lt_e071_svil
        yt_e071_rep  = lt_e071_rep
    ).

    lv_error_occurred = abap_false.

    IF lt_e071_svil IS NOT INITIAL.

      LOOP AT lt_e071_svil ASSIGNING <e071>.

        CLEAR lt_e071.
        APPEND <e071> TO lt_e071.

        CALL FUNCTION 'TR_APPEND_TO_COMM_OBJS_KEYS'
          EXPORTING
            wi_trkorr = xv_tr_svil
          TABLES
            wt_e071   = lt_e071
            wt_e071k  = lt_e071k
          EXCEPTIONS
            OTHERS    = 1.
        IF sy-subrc <> 0.
          lv_error_occurred = abap_true.

          READ TABLE lt_tadir ASSIGNING <tadir>
            WITH KEY object   = <e071>-object
                     obj_name = <e071>-obj_name.
          IF sy-subrc EQ 0.
            APPEND <tadir> TO yt_tadir_err.
          ENDIF.

          CONTINUE.
        ENDIF.

        COMMIT WORK AND WAIT.

      ENDLOOP.

    ENDIF.


    IF lt_e071_rep IS NOT INITIAL.

      LOOP AT lt_e071_rep ASSIGNING <e071>.

        CLEAR lt_e071.
        APPEND <e071> TO lt_e071.

        CALL FUNCTION 'TR_APPEND_TO_COMM_OBJS_KEYS'
          EXPORTING
            wi_trkorr = xv_tr_rep
          TABLES
            wt_e071   = lt_e071
            wt_e071k  = lt_e071k
          EXCEPTIONS
            OTHERS    = 1.
        IF sy-subrc <> 0.
          lv_error_occurred = abap_true.

          READ TABLE lt_tadir ASSIGNING <tadir>
            WITH KEY object   = <e071>-object
                     obj_name = <e071>-obj_name.
          IF sy-subrc EQ 0.
            APPEND <tadir> TO yt_tadir_err.
          ENDIF.

          CONTINUE.
        ENDIF.

        COMMIT WORK AND WAIT.

      ENDLOOP.

    ENDIF.


    IF lv_error_occurred EQ abap_true.
      RAISE generic_error.
    ENDIF.

  ENDMETHOD.                    "insert_obj_into_tr


  METHOD server_read.

    DATA: ls_buffer TYPE ts_buffer,
          lv_reclen TYPE i.

    CLEAR: yt_bin, yv_length.

    OPEN DATASET xv_filename FOR INPUT IN BINARY MODE.
    IF sy-subrc <> 0.
      CLOSE DATASET xv_filename.
      EXIT.
    ENDIF.

    WHILE sy-subrc = 0.
      CLEAR ls_buffer.
      READ DATASET xv_filename INTO ls_buffer LENGTH lv_reclen.
      yv_length = yv_length + lv_reclen.
      APPEND ls_buffer TO yt_bin.
    ENDWHILE.

    CLOSE DATASET xv_filename.

  ENDMETHOD.                    "server_read


  METHOD server_write.

    DATA: lv_reclen  TYPE i,
          lv_filelen TYPE i.

    FIELD-SYMBOLS: <bin> TYPE ts_buffer.


    yv_ok = abap_false.


    lv_filelen = xv_length.

    OPEN DATASET xv_filename FOR OUTPUT IN BINARY MODE.
    IF sy-subrc <> 0.
      CLOSE DATASET xv_filename.
      EXIT.
    ENDIF.


    LOOP AT xt_bin ASSIGNING <bin>.
      DESCRIBE FIELD <bin>-data LENGTH lv_reclen IN BYTE MODE.

      IF lv_filelen > lv_reclen.
        lv_filelen = lv_filelen - lv_reclen.
      ELSE.
        lv_reclen = lv_filelen.
      ENDIF.

      TRANSFER <bin> TO xv_filename LENGTH lv_reclen.
    ENDLOOP.

    CLOSE DATASET xv_filename.

    yv_ok = abap_true.

  ENDMETHOD.                    "server_write


  METHOD upload_tr.

    DATA: lv_frontend_dir        TYPE string,
          lv_path_server_cofiles TYPE string,
          lv_path_server_data    TYPE string,
          lv_tr_cofiles          TYPE string,
          lv_tr_data             TYPE string,
          lv_filename            TYPE string,
          lt_cofiles_bin         TYPE tt_buffer,
          lv_cofiles_length      TYPE i,
          lt_data_bin            TYPE tt_buffer,
          lv_data_length         TYPE i,
          lv_ok                  TYPE os_boolean.

    IF xv_frontend_dir IS NOT INITIAL.
      lv_frontend_dir = xv_frontend_dir.
    ELSE.
      lv_frontend_dir = me->get_desktop_directory( ).
    ENDIF.

    " Add trailing "\" or "/"
    IF xv_frontend_dir CA '/'.
      REPLACE REGEX '([^/])\s*$' IN lv_frontend_dir WITH '$1/' .
    ELSE.
      REPLACE REGEX '([^\\])\s*$' IN lv_frontend_dir WITH '$1\\'.
    ENDIF.


    CONCATENATE get_tr_path( ) '/cofiles/' INTO lv_path_server_cofiles.
    CONCATENATE get_tr_path( ) '/data/'    INTO lv_path_server_data.


    CONCATENATE 'K' xv_tr_number+4 '.' xv_tr_number(3) INTO lv_tr_cofiles.
    CONDENSE lv_tr_cofiles NO-GAPS.

    CONCATENATE 'R' xv_tr_number+4 '.' xv_tr_number(3) INTO lv_tr_data.
    CONDENSE lv_tr_data NO-GAPS.



    " COFILES
    CONCATENATE lv_frontend_dir lv_tr_cofiles INTO lv_filename.
    me->gui_upload(
      EXPORTING
        xv_filename = lv_filename
      IMPORTING
        yt_bin      = lt_cofiles_bin
        yv_length   = lv_cofiles_length
    ).

    CONCATENATE lv_path_server_cofiles lv_tr_cofiles INTO lv_filename.
    lv_ok = me->server_write(
      xv_filename = lv_filename
      xt_bin      = lt_cofiles_bin
      xv_length   = lv_cofiles_length
    ).

    IF lv_ok EQ abap_false.
      RAISE upload_failed.
    ENDIF.



    " DATA
    CONCATENATE lv_frontend_dir lv_tr_data INTO lv_filename.
    me->gui_upload(
      EXPORTING
        xv_filename = lv_filename
      IMPORTING
        yt_bin      = lt_data_bin
        yv_length   = lv_data_length
    ).

    CONCATENATE lv_path_server_data lv_tr_data INTO lv_filename.
    lv_ok = me->server_write(
      xv_filename = lv_filename
      xt_bin      = lt_data_bin
      xv_length   = lv_data_length
    ).

    IF lv_ok EQ abap_false.
      RAISE upload_failed.
    ENDIF.

  ENDMETHOD.                    "upload_tr

ENDCLASS.                    "zag_cl_utils_migration IMPLEMENTATION
