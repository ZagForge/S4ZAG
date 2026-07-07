# ZAG_CL_UTILS_MIGRATION <a name="zag_cl_utils_migration"></a>

- FETCH_TADIR
  - Retrieves objects from the TADIR table based on the provided filters (object name and object type ranges).
  - Raises `object_not_found` if no matching objects are found.

- FETCH_FM_USEREXIT
  - Retrieves implemented Function Module User Exits, filterable by CMOD name, SMOD name, or FM name.
  - The field `activ` in the returned structure indicates whether the user exit is actually implemented in the system.

- FETCH_SCREEN_EXIT
  - Retrieves implemented Screen User Exits, filterable by CMOD name, SMOD name.
  - The field `activ` in the returned structure indicates whether the user exit is actually implemented in the system.

- UPLOAD_TR
  - Uploads a Transport Request (both `cofiles` and `data` files) from the frontend to the SAP server.
  - If no frontend directory is provided, the user's Desktop is used as the default source path.

- DOWNLOAD_TR
  - Downloads a Transport Request (both `cofiles` and `data` files) from the SAP server to the frontend.
  - If no frontend directory is provided, the user's Desktop is used as the default destination path.

- GET_TR_PATH
  - Returns the SAP Transport Directory path on the server, reading the system parameter `DIR_TRANS`.

- INSERT_OBJ_INTO_TR
  - Inserts ABAP objects into one or two Transport Requests (development TR and/or repair TR).
  - Objects are automatically split: local objects go into the development TR, objects originating from a different system go into the repair TR.
  - Objects that could not be inserted are returned in the `yt_tadir_err` export parameter.

---

```abap
"Example 1 -> Fetch TADIR objects
"-------------------------------------------------

DATA(lo_mig) = NEW zag_cl_utils_migration( ).

DATA(lt_tadir) = lo_mig->fetch_tadir(
  xr_obj_name = VALUE #( ( sign = 'I' option = 'EQ' low = 'ZMY_CLASS' ) )
  xr_object   = VALUE #( ( sign = 'I' option = 'EQ' low = 'CLAS' ) )
  EXCEPTIONS
    object_not_found = 1
    OTHERS           = 2
).
```

---

```abap
"Example 2.1 -> Fetch implemented User Exits for a given CMOD
"-------------------------------------------------

DATA(lo_mig) = NEW zag_cl_utils_migration( ).

DATA(lt_userexit) = lo_mig->fetch_fm_userexit(
  xr_cmod_name = VALUE #( ( sign = 'I' option = 'EQ' low = 'ZMYCMOD' ) )
).

LOOP AT lt_userexit ASSIGNING FIELD-SYMBOL(<ue>).
  IF <ue>-activ EQ abap_true.
    WRITE: / 'Implemented:', <ue>-funcname.
  ENDIF.
ENDLOOP.
```

```abap
"Example 2.2 -> Fetch implemented User Exits for a given CMOD
"-------------------------------------------------

DATA(lo_mig) = NEW zag_cl_utils_migration( ).

DATA(lt_screenexit) = lo_mig->fetch_screen_exit(
  xr_cmod_name = VALUE #( ( sign = 'I' option = 'EQ' low = 'ZMYCMOD' ) )
).

LOOP AT lt_screenexit ASSIGNING FIELD-SYMBOL(<se>).
  IF <se>-activ EQ abap_true.
    WRITE: / 'Implemented:', <se>-called_prog, <se>-called_dynnr.
  ENDIF.
ENDLOOP.
```

---

```abap
"Example 3 -> Download a TR to the Desktop
"-------------------------------------------------

DATA(lo_mig) = NEW zag_cl_utils_migration( ).

lo_mig->download_tr(
  EXPORTING
    xv_tr_number    = 'DEV000123'
  EXCEPTIONS
    tr_not_found    = 1
    download_failed = 2
    OTHERS          = 3
).
IF sy-subrc <> 0.
  WRITE 'Error downloading TR'.
ENDIF.
```

---

```abap
"Example 4 -> Upload a TR from a specific directory
"-------------------------------------------------

DATA(lo_mig) = NEW zag_cl_utils_migration( ).

lo_mig->upload_tr(
  EXPORTING
    xv_tr_number    = 'DEV000123'
    xv_frontend_dir = 'C:\Transports\'
  EXCEPTIONS
    upload_failed = 1
    OTHERS        = 2
).
IF sy-subrc <> 0.
  WRITE 'Error uploading TR'.
ENDIF.
```

---

```abap
"Example 5 -> Insert objects into a development TR and a repair TR
"-------------------------------------------------

DATA(lo_mig) = NEW zag_cl_utils_migration( ).

lo_mig->insert_obj_into_tr(
  EXPORTING
    xr_obj_name  = VALUE #( ( sign = 'I' option = 'CP' low = 'ZMY*' ) )
    xr_object    = VALUE #( ( sign = 'I' option = 'EQ' low = 'PROG' ) )
    xv_tr_svil   = 'DEV000100'
    xv_tr_rep    = 'DEV000200'
  IMPORTING
    yt_tadir_err = DATA(lt_err)
  EXCEPTIONS
    object_not_found = 1
    input_error      = 2
    generic_error    = 3
    OTHERS           = 4
).

IF sy-subrc EQ 3.
  LOOP AT lt_err ASSIGNING FIELD-SYMBOL(<err>).
    WRITE: / 'Failed object:', <err>-object, <err>-obj_name.
  ENDLOOP.
ENDIF.
```
