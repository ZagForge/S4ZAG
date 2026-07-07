# ZAG_CL_SEND_MAIL <a name="zag_cl_send_mail"></a>
- SEND_MAIL
    - In addition to the classic parameters such as Recipient / Email Subject / Email Body,
    it allows attaching files like CSV, XLSX, and PDF.

    - Furthermore, you will be able to use a Standard Text created by Trx SO10 as the Email Body.
    It will be enough to provide the name of the Standard Text and, if necessary,
    you will be able to provide a variable name in the Standard Text
    (for example &LIFNR&) which will be replaced automatically by corresponding value provided.
    
>NB: If you not provide any mail body, the class will automatically put the subject mail as body because it is a mandatory parameter.

---

```abap
  "Example 1 -> Simple mail
  "-------------------------------------------------

  DATA: lt_recipients TYPE zag_cl_send_mail=>ts_mail_params-recipients.

  lt_recipients = VALUE #(
    (
      smtp_addr = 'yourmail@domain.com'
      copy      = space
    )
    (
      smtp_addr = 'yourmailcopy@domain.com'
      copy      = 'X'
    )
  ).


  TRY.
      DATA(lo_send_mail) = NEW zag_cl_send_mail( ).

      DATA(lv_mail_sent) = lo_send_mail->send_mail( xs_mail_params = VALUE #(
                                                                        sender     = sy-uname
                                                                        recipients = lt_recipients[]
                                                                        object    = 'Mail Object'
                                                                        body      = 'Mail Body'
                                                                     )
      ).

    CATCH cx_ai_system_fault INTO DATA(lx_ai_system_fault). " Application Integration: Technical Error
      WRITE lx_ai_system_fault->get_text( ).
  ENDTRY.
```

---

```abap
  "Example 2 -> Mail with attach. and Standard Text as Mail Body
  "-------------------------------------------------

  DATA:
    lt_recipients       TYPE zag_cl_send_mail=>ts_mail_params-recipients,
    ls_mail_body_stdtxt TYPE zag_cl_send_mail=>ts_mail_params-body_stdtxt,
    lt_attch            TYPE zag_cl_send_mail=>ts_mail_params-attachments.


  SELECT * FROM bseg UP TO 10 ROWS INTO TABLE @DATA(lt_data).

  lt_recipients = VALUE #(
    (
      smtp_addr = 'yourmail@domain.com'
      copy      = space
    )
    (
      smtp_addr = 'yourmailcopy@domain.com'
      copy      = 'X'
    )
  ).


  APPEND INITIAL LINE TO lt_attch ASSIGNING FIELD-SYMBOL(<attch>).
  <attch>-subject = 'your_file_name'.

  DATA(lo_converter) = NEW zag_cl_converter( ).
  <attch>-data_csv = lo_converter->conv_tsap_to_ext(
                       xt_tsap_int  = lt_data
                       xv_header    = abap_true
                       xv_separator = zag_cl_converter=>tc_separator-semicolon
  ).


  ls_mail_body_stdtxt-std_txt_name = 'ZAG_SEND_MAIL_BCS_STDTXT'.
  ls_mail_body_stdtxt-replacement  = VALUE #(
    (
      varname = '&REPLACE_VAR&'
      value   = sy-datum
    )
  ).


  TRY.
      DATA(lo_send_mail) = NEW zag_cl_send_mail( ).

      DATA(lv_mail_sent) = lo_send_mail->send_mail( xs_mail_params = VALUE #(
                                                                        sender      = sy-uname
                                                                        recipients  = lt_recipients[]
                                                                        object      = 'Mail Object'
                                                                        body        = 'Mail Body'
                                                                        body_stdtxt = ls_mail_body_stdtxt
                                                                        attachments = lt_attch[]
                                                                     )
                                                     xv_commit      = abap_true
      ).

      IF lv_mail_sent NE abap_true.
        WRITE 'Mail was not sent'.
      ENDIF.

    CATCH cx_ai_system_fault INTO DATA(lx_ai_system_fault). " Application Integration: Technical Error
      WRITE lx_ai_system_fault->get_text( ).
  ENDTRY.
```