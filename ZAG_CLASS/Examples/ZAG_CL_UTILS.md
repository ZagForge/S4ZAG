# ZAG_CL_UTILS <a name="zag_cl_utils"></a>
- ALM_BUFFER_REFRESH
    - It allows to reset PM/PP order buffers (status, confirmations, costing) so that subsequent order processing reads fresh data instead of stale buffered values.

- OBJ_STATUS_CHANGE_EXTERN
    - It allows to change the user status of an object (e.g. order, notification) by providing its object number and the target status short text, performing the commit automatically.

- F4_HELP
    - It allows to display a generic F4 search help popup for any table/field pair, returning the value selected by the user.

- FORMAT_MESSAGE
    - It allows to build the formatted long text of a system message, using either the message data you provide or, if not provided, the current SY-MSG* values.

- GET_STDTXT
    - It allows to read a standard text (SO10) and replace its placeholders with the values you provide, returning the resulting text lines.

- GET_VALUE_FROM_SET
    - It allows to read all the values contained in a Set (GS01/GS02) and to return them ready-to-use as a generic range table (SIGN/OPTION/LOW/HIGH).

- EXE_UNIX_COMM
    - It allows to execute an operating system (unix) command from ABAP and collect its output.

---

```abap

"Example 1 -> Refresh ALM/PP buffers
"-------------------------------------------------

zag_cl_utils=>alm_buffer_refresh( ).

```

---

```abap

"Example 2 -> Change external status of an object
"-------------------------------------------------

DATA(lv_subrc) = zag_cl_utils=>obj_status_change_extern(
    xv_objnr      = 'OR000000001234'
    xv_new_status = 'REL '
).

IF lv_subrc EQ 0.
  WRITE 'Status changed successfully'.
ENDIF.

```

---

```abap

"Example 3 -> Show F4 help popup on a custom table/field
"-------------------------------------------------

DATA(lv_value) = zag_cl_utils=>f4_help(
    xv_tabname   = 'MARA'
    xv_fieldname = 'MATNR'
).

```

---

```abap

"Example 4 -> Format a message text
"-------------------------------------------------

DATA(lv_msg) = zag_cl_utils=>format_message(
    xv_msgid = 'DB'
    xv_msgno = '646'
    xv_msgv1 = 'Error'
    xv_msgv2 = 'occurred'
).

"If no message data is provided, current SY-MSG* values will be used instead
DATA(lv_current_msg) = zag_cl_utils=>format_message( ).

```

---

```abap

"Example 5 -> Read a standard text (SO10) replacing placeholders
"-------------------------------------------------

DATA(lt_lines) = zag_cl_utils=>get_stdtxt(
    xs_std_text = VALUE zag_cl_utils=>ts_standard_text(
        std_txt_name = 'ZMY_STD_TEXT'
        replacement  = VALUE zag_cl_utils=>tt_standard_text(
            ( varname = '&NAME&' value = 'John Doe' )
            ( varname = '&DATE&' value = sy-datum )
        )
    )
).

```

---

```abap

"Example 6 -> Get values from a Set as a range table
"-------------------------------------------------

DATA: lt_werks_range TYPE RANGE OF t001w-werks.

zag_cl_utils=>get_value_from_set(
  EXPORTING
    xv_setname    = 'ZMY_PLANT_SET'
  CHANGING
    yr_set_values = lt_werks_range
).

SELECT * FROM t001w INTO TABLE @DATA(lt_t001w)
  WHERE werks IN @lt_werks_range.

```

---

```abap

"Example 7 -> Execute a unix command
"-------------------------------------------------

zag_cl_utils=>exe_unix_comm( x_unixcom = 'ls' ).

```
