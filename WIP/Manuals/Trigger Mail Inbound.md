# Ricezione mail → classe ABAP custom su SAP S/4HANA (on-premise)

Guida operativa per abilitare l'**inbound email processing**: quando una mail arriva a un indirizzo del dominio SAP, il sistema richiama automaticamente una classe ABAP custom che esegue la logica di business.

> **Scenario di riferimento**
> Un mittente (`lamiamail@gmail.com`) scrive a un indirizzo gestito dal sistema SAP
> (es. `supporto@s4prod.tuazienda.com`). Alla ricezione, SAP estrae dati dalla mail
> (mittente, oggetto, corpo, allegati) e fa partire un'azione: aggiornare uno stato,
> creare un documento, sollevare un workflow, ecc.

---

## 1. Come funziona (panoramica)

```
Mittente esterno
      │  SMTP
      ▼
Mail server aziendale (Exchange / O365)     ← inoltra il dominio SAP verso l'ICM
      │  SMTP
      ▼
ICM di SAP (porta SMTP in ascolto)          ← SICF: servizio SAPconnect
      │
      ▼
SCOT (Default Domain + nodo SMTP)           ← "il sistema sa ricevere su questo dominio"
      │
      ▼
SO50 (regola: indirizzo → classe exit)      ← instradamento
      │
      ▼
Classe ABAP  IF_INBOUND_EXIT_BCS            ← LA TUA LOGICA
```

Punto chiave: **l'inbound è push, non polling.** Appena la mail arriva all'ICM, il messaggio viene spinto dentro in tempo reale; non serve nessun job schedulato (i job di SCOT riguardano solo l'invio).

---

## 2. Divisione delle responsabilità

| #   | Attività                                               | Owner             | Transazione / Oggetto      |
| --- | ------------------------------------------------------ | ----------------- | -------------------------- |
| 1   | Record DNS/MX e connettore SMTP verso SAP              | Basis + IT rete   | Exchange / DNS             |
| 2   | Attivazione porta SMTP sull'ICM (parametri di profilo) | Basis             | RZ10 / SMICM               |
| 3   | Attivazione servizio SAPconnect (utente di servizio)   | Basis             | SICF                       |
| 4   | Default Domain e nodo SMTP inbound                     | Basis             | SCOT                       |
| 5   | Utenza tecnica e autorizzazioni per l'inbound          | Basis / Security  | SU01 / PFCG                |
| 6   | **Regola di distribuzione in entrata**                 | ABAP / Funzionale | **SO50**                   |
| 7   | **Classe handler `IF_INBOUND_EXIT_BCS`**               | **ABAP**          | **SE24 / ADT**             |
| 8   | Logica di business (BAPI, workflow, tabelle)           | ABAP / Funzionale | secondo caso d'uso         |
| 9   | Log applicativo                                        | ABAP              | SLG1 (oggetto custom)      |
| 10  | Test end-to-end e troubleshooting                      | Basis + ABAP      | SMICM / SOIN / SOST / SLG1 |

I passi **1–5** sono infrastruttura (Basis). I passi **6–9** sono lato applicativo. Possono procedere in parallelo: il team ABAP sviluppa e testa la classe con il trigger offline `FP_TEST_INBOUND` mentre Basis prepara il canale.

---

# PARTE A — Attività Basis / Infrastruttura

## A0. Prima di iniziare: cos'è già configurato?

Gran parte di questi controlli si fanno **in visualizzazione**, senza toccare nulla. Il segnale più rapido è: _il sistema manda e riceve già mail?_ L'inbound riusa quasi tutta l'infrastruttura dell'outbound (ICM + nodo SCOT), quindi se l'outbound è sano manca "solo" l'inbound vero e proprio (SICF/SCOT lato ricezione + SO50).

### A0.1 Cosa controllare (in visualizzazione)

| Componente               | Dove                                                   | Cosa vedi se è a posto                                            |
| ------------------------ | ------------------------------------------------------ | ----------------------------------------------------------------- |
| Porta SMTP ICM           | **SMICM** → Goto → Services                            | riga servizio `SMTP`, porta valorizzata, stato _active_ (verde)   |
| Parametri di profilo     | **RZ11** su `icm/server_port_*`, `is/SMTP/virt_host_*` | valorizzati con `PROT=SMTP`                                       |
| Servizio SAPconnect      | **SICF** → `default_host` → `sapconnect`               | nodo attivo (non grigio) con utente di servizio assegnato         |
| Default Domain           | **SCOT** → Settings → Default Domain                   | dominio del sistema impostato (non vuoto)                         |
| Nodo SMTP                | **SCOT**                                               | nodo SMTP presente e attivo; Mail Host/Port del relay valorizzati |
| Regole inbound esistenti | **SO50** (o SCOT → Settings → Inbound Processing)      | eventuali regole già presenti (non romperle)                      |
| Utente inbound           | **SU01** sull'utente del nodo SICF                     | esiste e ha il profilo `S_A.SCON`                                 |

### A0.2 Il test rapido (albero decisionale)

Manda una mail a un indirizzo qualsiasi sul dominio del sistema (es. `test@<fqdn-del-sistema>`) e verifica:

1. **SMICM → trace**: il messaggio ha "bussato" alla porta SMTP?
   - **No** → il canale rete/ICM inbound non è pronto → lavoro Basis (A1–A2).
2. **SOIN**: la mail è arrivata dentro al sistema?
   - **No** (ma SMICM la vede) → SICF/SCOT inbound da sistemare (A3–A4).
   - **Sì** → l'infrastruttura inbound c'è: manca solo regola SO50 + classe (B1–B4).

### A0.3 Come leggere gli stati in SOST (outbound)

SOST mostra le richieste di invio. Il colore conta:

| Colore    | Significato                                                                                 |
| --------- | ------------------------------------------------------------------------------------------- |
| 🟢 Verde  | trasferita al nodo con successo                                                             |
| 🟡 Giallo | **in attesa / in transito**: non ancora inviata (job non girato, oppure errore transitorio) |
| 🔴 Rosso  | errore definitivo, non inviabile                                                            |

Il giallo **non** significa "inviata": la mail è ancora in coda. Se resta gialla, o il send job SCOT non è schedulato, o c'è un problema di collegamento verso il relay (vedi sotto).

### A0.4 Troubleshooting: "Messaggio non trasferibile al nodo SMTP per errore collegamento"

Questo errore è **outbound**: l'ICM non riesce ad aprire il collegamento SMTP verso il relay di posta aziendale. Non blocca di per sé l'inbound (verso opposto), ma condivide il servizio SMTP dell'ICM e impedisce l'invio di qualsiasi risposta (quindi anche il test "system status"). Controlli in ordine:

1. **SMICM → Goto → Services**: il servizio SMTP è _active_ e verde? Se è giù/assente, è la causa: inbound e outbound sono entrambi fermi.
2. **SCOT → nodo SMTP → Mail Host / Mail Port**: host del relay e porta (25 o 587) corretti e raggiungibili? Host vuoto o errato dà esattamente questo messaggio.
3. **Rete/firewall**: dall'host SAP dev'essere aperto il flusso verso `relay:25` (Basis può testare con `telnet host 25`).
4. **Relay aziendale**: Exchange/O365 deve accettare il _relay_ dall'IP del server SAP (spesso bloccato di default).

Il fatto che ci siano richieste in coda in SOST conferma che il nodo SCOT e il report di invio `RSCONN01` esistono: manca il salto finale verso il relay. È un intervento Basis: _"outbound SMTP verso il relay in errore di collegamento"_.

> **Implicazione per il progetto:** finché questo errore persiste, il test end-to-end con
> risposta via mail non è verificabile. In attesa che Basis sistemi l'outbound, si può comunque
> sviluppare e provare la classe con il trigger offline `FP_TEST_INBOUND` (vedi §4), e testare
> l'inbound "a metà" verificando l'arrivo in SOIN senza attendersi la risposta.

## A1. Instradamento della posta (rete + Exchange)

Obiettivo: far sì che le mail destinate al dominio/indirizzo SAP arrivino all'ICM del sistema SAP invece di restare su Exchange.

- Definire un **send connector** (o equivalente) su Exchange/O365 che, per il dominio o sottodominio dedicato a SAP (es. `s4prod.tuazienda.com`), inoltri i messaggi via SMTP all'host e porta dell'ICM.
- In alternativa, un record MX dedicato che punti direttamente all'host SAP (raro in produzione, di solito si passa dal mail server aziendale per antispam/antivirus).
- Aprire il flusso di rete (firewall) dal mail server verso `host_SAP:porta_SMTP`.

> **Nota security:** non esporre mai l'ICM direttamente su Internet. Il percorso deve essere
> `Internet → mail gateway aziendale (filtri AV/AS) → ICM SAP` in rete interna.

## A2. Attivazione della porta SMTP sull'ICM

Parametri di profilo (RZ10), tipicamente:

```
icm/server_port_1 = PROT=SMTP,PORT=25000,TIMEOUT=180,PROCTIMEOUT=180
is/SMTP/virt_host_0 = *:25000;
```

- `PORT` = porta su cui l'ICM ascolta SMTP (concordare con la rete).
- `is/SMTP/virt_host_0` definisce il virtual host che accetta i messaggi.
- Dopo la modifica: riavvio dell'ICM o dell'istanza secondo policy. Verifica in **SMICM → Goto → Services** che il servizio SMTP sia attivo.

## A3. Servizio SAPconnect (SICF)

- In **SICF**, sotto `default_host`, verificare/attivare il servizio **`SAPconnect`** (nodo che gestisce l'handshake SMTP inbound).
- Creare un'**utenza tecnica** dedicata (es. `SAPMAIL`) e impostarla come utente del nodo SAPconnect: è l'utente sotto cui gira tutta l'elaborazione inbound, quindi la classe handler viene eseguita con le sue autorizzazioni. Deve avere il profilo **`S_A.SCON`** più le autorizzazioni per le operazioni di business richieste (rif. OSS note 455140, sez. 2.A).

## A4. Configurazione SCOT

In **SCOT**:

1. **Default Domain** — `Settings → Default Domain`. Impostare il dominio del sistema (es. `s4prod.tuazienda.com`). È il passo più importante lato SCOT: la risoluzione degli indirizzi in ingresso e il match delle regole SO50 avvengono rispetto a questo dominio. Se manca o non combacia con l'indirizzo destinatario, l'inbound non trova dove instradare.
2. **Nodo SMTP** — verificare che il nodo SMTP esista e sia attivo (lo stesso nodo usato per l'uscita gestisce anche l'handshake). Doppio click sul nodo per controllare stato e area indirizzi.
3. **Nessun send job per l'inbound** — la schedulazione periodica di SCOT serve solo all'outbound.

## A5. Utenza e autorizzazioni

- L'utenza di servizio SAPconnect (SICF) deve avere accesso in **debug** se serve fare troubleshooting sulla classe, ed essere abilitata come richiesto dal caso d'uso.
- Le autorizzazioni di business (es. rilascio ordini, creazione notifiche) sono quelle che la classe eseguirà a nome di questa utenza.

---

# PARTE B — Attività lato SAP / ABAP

## B1. La regola di distribuzione (SO50)

In **SO50** ("Regole per la distribuzione in entrata") si crea la voce che collega un indirizzo alla classe handler:

| Campo                  | Valore d'esempio                 | Note                                           |
| ---------------------- | -------------------------------- | ---------------------------------------------- |
| Tipo di comunicazione  | `Internet Mail` (INT)            | posta internet                                 |
| Indirizzo destinatario | `supporto*@s4prod.tuazienda.com` | il `*` funge da wildcard                       |
| Classe documento       | `*`                              | `*` cattura tutti i tipi; restringere se serve |
| Nome exit              | `ZCL_EMAIL_INBOUND_HANDLER`      | la classe custom                               |
| Sequenza / Call ID     | `1`                              | ordine di chiamata se ci sono più exit         |

> Suggerimento pratico ricorrente: se la classe "non parte", provare `*` sia sull'indirizzo
> sia sulla classe documento per isolare se il problema è nel matching della regola.

## B2. La classe handler

La classe deve implementare l'interfaccia **`IF_INBOUND_EXIT_BCS`** ed è un **singleton**. Deve implementare almeno due metodi:

- **`CREATE_INSTANCE`** — crea/restituisce l'istanza singleton (parametro returning `RO_REF`).
- **`PROCESS_INBOUND`** — riceve la mail e contiene la logica. Firma (verificare i tipi esatti in SE24 sulla vostra release):

| Parametro       | Direzione | Tipo                  | Contenuto                                           |
| --------------- | --------- | --------------------- | --------------------------------------------------- |
| `IO_SREQ`       | importing | `CL_SEND_REQUEST_BCS` | l'oggetto messaggio (mittente, documento, allegati) |
| `IT_DOCTYPES`   | importing | `BCSY_SODOC`          | tipi di documento che compongono la mail            |
| `IT_RECIPIENTS` | importing | `BCSY_SMTPA`          | destinatari                                         |
| `E_RETCODE`     | exporting | `I`                   | controlla la prosecuzione della catena di exit      |
| `ES_T100MSG`    | exporting | `BCSS_T100M`          | messaggio T100 per il log                           |

Dati principali si ricavano da `IO_SREQ`:

- documento: `io_sreq->get_document( )` → oggetto `IF_DOCUMENT_BCS`;
- oggetto della mail: `lo_document->get_subject( )`;
- corpo: `lo_document->get_body_part_content( '1' )` (per multipart/MHT il parsing è più articolato);
- mittente: `io_sreq->get_sender( )` → `IF_SENDER_BCS`;
- oggetto di risposta (per rispondere al mittente): `io_sreq->reply( )`.

**Controllo della catena di exit (`E_RETCODE`).** L'interfaccia espone due costanti:

| Costante                            | Effetto                                                                                                    |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `if_inbound_exit_bcs=>gc_continue`  | prosegue l'elaborazione standard: la mail viene comunque consegnata (es. inbox SAPoffice del destinatario) |
| `if_inbound_exit_bcs=>gc_terminate` | "l'ho gestita io": ferma la catena, la mail **non** viene consegnata altrove                               |

Regola pratica: se la mail è valida e gestita dalla tua logica → `GC_TERMINATE`; se **non** è in whitelist e vuoi scartarla → `GC_TERMINATE` (drop silenzioso); se vuoi lasciarla al flusso standard → `GC_CONTINUE`.

## B3. Whitelist mittenti (anti-spam)

Per evitare che chiunque possa triggerare la logica, la classe deve **prima di tutto** verificare che il mittente sia autorizzato, e scartare il resto. È lo stesso approccio dell'esempio "Advanced Inbound Email Handling": controllare che la mail provenga da un elenco di mittenti/domini definiti.

Meglio non cablare i domini nel codice: si usa una **tabella di customizing** manutenibile via SM30, così aggiungere un dominio non richiede un trasporto.

**Tabella `ZEMAIL_WHITELIST`** (SE11, con manutenzione SM30):

| Campo     | Tipo      | Descrizione                                                        |
| --------- | --------- | ------------------------------------------------------------------ |
| `MANDT`   | `MANDT`   | client (chiave)                                                    |
| `PATTERN` | `CHAR255` | dominio (`tuazienda.com`) o indirizzo completo (`fornitore@x.com`) |
| `ACTIVE`  | `CHAR1`   | flag attivo                                                        |

Il match si fa così: si estrae il dominio del mittente (parte dopo la `@`) e si verifica se esiste una riga con l'indirizzo completo **oppure** con il solo dominio. Se nessun match → drop.

> **Alternativa rapida (per un primo test).** L'esempio originale di T. Jung cabla il
> controllo nel codice, es. `IF sender_addr CS '@KIMBALL.COM'` dopo aver messo l'indirizzo
> in maiuscolo. Va benissimo per validare la catena, ma per andare in produzione è preferibile
> la tabella `ZEMAIL_WHITELIST`, così i domini si gestiscono senza modificare/trasportare codice.

## B4. Esempio completo: handler di "system status" + whitelist

Caso di test: si manda una mail al sistema e questo **risponde** con lo stato (SID, client, host, ora, work process attivi) — utile come smoke test end-to-end. In testa c'è il controllo whitelist.

> ⚠️ **Template, non codice "copia-incolla-e-compila".** Alcuni nomi di metodo e tipi
> (getter dell'indirizzo mittente, struttura del contenuto MIME) variano tra release:
> verificarli in **SE24** su `IF_INBOUND_EXIT_BCS`, `IF_DOCUMENT_BCS`, `IF_SENDER_BCS`,
> `CL_SEND_REQUEST_BCS`. La struttura logica e il flusso restano validi.

```abap
CLASS zcl_email_inbound_handler DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_inbound_exit_bcs.

  PRIVATE SECTION.
    " istanza singleton
    CLASS-DATA go_instance TYPE REF TO zcl_email_inbound_handler.

    " ANTI-SPAM: verifica che il mittente sia in whitelist
    METHODS is_sender_allowed
      IMPORTING iv_sender         TYPE ad_smtpadr
      RETURNING VALUE(rv_allowed) TYPE abap_bool.

    " TEST: costruisce il testo con lo stato del sistema
    METHODS build_status_text
      RETURNING VALUE(rt_text) TYPE soli_tab.

    " invia la risposta al mittente
    METHODS send_reply
      IMPORTING io_reply   TYPE REF TO cl_send_request_bcs
                iv_subject TYPE so_obj_des
                it_content TYPE soli_tab.

    " log applicativo (SLG1)
    METHODS log
      IMPORTING iv_text TYPE string
                iv_type TYPE symsgty DEFAULT 'I'.
ENDCLASS.


CLASS zcl_email_inbound_handler IMPLEMENTATION.

  METHOD if_inbound_exit_bcs~create_instance.
    " singleton: una sola istanza per processo
    IF go_instance IS INITIAL.
      go_instance = NEW zcl_email_inbound_handler( ).
    ENDIF.
    ro_ref = go_instance.
  ENDMETHOD.


  METHOD if_inbound_exit_bcs~process_inbound.
    DATA lo_document TYPE REF TO if_document_bcs.
    DATA lo_sender   TYPE REF TO if_sender_bcs.
    DATA lo_reply    TYPE REF TO cl_send_request_bcs.
    DATA lv_sender   TYPE ad_smtpadr.
    DATA lv_subject  TYPE so_obj_des.

    CLEAR: e_retcode, es_t100msg.

    TRY.
        " --- mittente ---
        lo_sender = io_sreq->get_sender( ).
        lv_sender = lo_sender->address_string( ). " confermato: metodo di IF_SENDER_BCS

        " --- ANTI-SPAM: whitelist ---
        IF is_sender_allowed( lv_sender ) = abap_false.
          log( iv_text = |Mittente non autorizzato, scartato: { lv_sender }|
               iv_type = 'W' ).
          " drop silenzioso: gestita da noi, non consegnare altrove
          e_retcode = if_inbound_exit_bcs=>gc_terminate.
          RETURN.
        ENDIF.

        " --- oggetto ---
        lo_document = io_sreq->get_document( ).
        lv_subject  = lo_document->get_subject( ).

        log( |System check richiesto da { lv_sender }| ).

        " --- LOGICA (TEST): risponde con lo stato del sistema ---
        lo_reply = io_sreq->reply( ).       " oggetto di risposta al mittente
        send_reply(
          io_reply   = lo_reply
          iv_subject = |System status { sy-sysid }/{ sy-mandt }|
          it_content = build_status_text( ) ).

        " gestita completamente: ferma l'elaborazione standard
        e_retcode = if_inbound_exit_bcs=>gc_terminate.

      CATCH cx_root INTO DATA(lx_err).
        e_retcode = if_inbound_exit_bcs=>gc_continue.  " fallback al flusso standard
        log( iv_text = |Errore inbound: { lx_err->get_text( ) }| iv_type = 'E' ).
    ENDTRY.
  ENDMETHOD.


  METHOD is_sender_allowed.
    " Estrae il dominio (parte dopo @) e cerca in ZEMAIL_WHITELIST
    " un match sull'indirizzo completo OPPURE sul solo dominio.
    DATA lv_domain TYPE ad_smtpadr.

    SPLIT to_lower( iv_sender ) AT '@' INTO DATA(lv_local) lv_domain.

    SELECT SINGLE @abap_true FROM zemail_whitelist
      INTO @rv_allowed
      WHERE active  = @abap_true
        AND ( pattern = @iv_sender OR pattern = @lv_domain ).
    " nota: per case-insensitive robusto conviene salvare i pattern
    " già in minuscolo e confrontare con to_lower( iv_sender ).
  ENDMETHOD.


  METHOD build_status_text.
    " Stato del sistema come output HTML dell'overview processi (SM50),
    " esattamente come nell'esempio di T. Jung: si esegue il report ALV
    " dei work process, si preleva la lista dalla memoria e la si converte
    " in HTML pronto per il corpo della mail.
    DATA lt_list TYPE TABLE OF abaplist.

    SUBMIT rsmon000_alv AND RETURN
      EXPORTING LIST TO MEMORY.

    CALL FUNCTION 'LIST_FROM_MEMORY'
      TABLES
        listobject = lt_list
      EXCEPTIONS
        not_found  = 1.

    CALL FUNCTION 'WWW_HTML_FROM_LISTOBJECT'
      EXPORTING
        template_name = 'WEBREPORTING_REPORT'
      TABLES
        html          = rt_text          " HTML risultante → corpo mail (tipo 'HTM')
        listobject    = lt_list.

    " Variante minimale (corpo di tipo 'RAW'), se non serve l'HTML SM50:
    " APPEND |Sistema: { sy-sysid }/{ sy-mandt } host { sy-host }| TO rt_text.
    " APPEND |Data/ora: { sy-datum } { sy-uzeit }|                 TO rt_text.
  ENDMETHOD.


  METHOD send_reply.
    " Pattern di invio risposta come nell'esempio di T. Jung.
    DATA lo_bcs TYPE REF TO cl_bcs.

    " corpo HTML (coerente con build_status_text che produce HTML)
    DATA(lo_doc) = cl_document_bcs=>create_document(
                     i_type    = 'HTM'
                     i_text    = it_content
                     i_subject = iv_subject ).
    io_reply->set_document( lo_doc ).

    " Mittente distinto: non l'utente di servizio (SAPMAIL) sotto cui gira
    " l'inbound, ma una mailbox di supporto. Sostituire 'ZSUPPORT'.
    io_reply->set_sender( cl_sapuser_bcs=>create( 'ZSUPPORT' ) ).

    " Nessuna notifica di stato (evita loop/bounce)
    io_reply->set_status_mail( 'N' ).
    io_reply->set_requested_status( 'N' ).

    " Invio immediato tramite facade, poi release + commit
    lo_bcs = io_reply->get_facade( ).
    lo_bcs->set_send_immediately( 'X' ).
    io_reply->release( ).
    COMMIT WORK.
  ENDMETHOD.


  METHOD log.
    " Scrivere su application log (BAL_LOG_* / SLG1) con un oggetto custom
    " creato in SLG0 (es. oggetto ZEMAIL, sotto-oggetto INBOUND).
    " Qui semplificato.
    MESSAGE iv_text TYPE iv_type.   " placeholder
  ENDMETHOD.

ENDCLASS.
```

## B5. Log applicativo (SLG0 / SLG1)

- Creare in **SLG0** un oggetto log custom (es. `ZEMAIL`, sotto-oggetto `INBOUND`).
- Scrivere i passi con le API `BAL_LOG_CREATE` / `BAL_LOG_MSG_ADD` / `BAL_DB_SAVE`.
- Consultare gli eventi in **SLG1**. Fondamentale per capire, in produzione, se e quando la classe è stata chiamata e con quale esito.

## 3. Esempio end-to-end

**Caso di test (system status):** un utente autorizzato manda una mail al sistema, che risponde con lo stato. Serve a validare tutta la catena prima di innestare la logica di business reale.

1. **Mail:** `mario.rossi@tuazienda.com` → `supporto@s4prod.tuazienda.com`, oggetto qualsiasi (es. `status`).
2. **Rete/Exchange (A1):** il connettore inoltra al dominio `s4prod.tuazienda.com` verso l'ICM.
3. **ICM (A2):** riceve sulla porta SMTP e passa a SAPconnect.
4. **SCOT (A4):** Default Domain `s4prod.tuazienda.com` → il messaggio è riconosciuto come locale.
5. **SO50 (B1):** l'indirizzo `supporto*@s4prod.tuazienda.com` matcha la regola → chiama `ZCL_EMAIL_INBOUND_HANDLER`.
6. **Whitelist (B3):** `is_sender_allowed` verifica il dominio `tuazienda.com` in `ZEMAIL_WHITELIST` → autorizzato. (Una mail da `sconosciuto@spam.com` verrebbe scartata qui con `GC_TERMINATE`.)
7. **Classe (B4):** `PROCESS_INBOUND` costruisce lo stato del sistema e lo invia in risposta al mittente con `io_sreq->reply( )`.
8. **Log (B5):** l'esito finisce in SLG1; la mail è tracciata in SOIN, la risposta in SOST.

Quando il test funziona, si sostituisce il corpo di `PROCESS_INBOUND` con la logica reale (parsing oggetto/corpo, BAPI, evento di workflow), mantenendo invariati il controllo whitelist e la struttura.

---

## 4. Test e troubleshooting

| Sintomo                              | Dove guardare                    | Causa tipica                                                                  |
| ------------------------------------ | -------------------------------- | ----------------------------------------------------------------------------- |
| La mail non arriva all'ICM           | **SMICM** trace, log di Exchange | connettore/firewall, porta SMTP chiusa                                        |
| L'ICM riceve ma "non succede niente" | trace SMICM + **SCOT**           | Default Domain assente o diverso dall'indirizzo destinatario                  |
| Ricevuta ma la classe non parte      | **SO50**                         | regola mancante o indirizzo/classe documento troppo restrittivi (provare `*`) |
| La classe parte ma non fa nulla      | **SLG1**, debug                  | logica interna, autorizzazioni dell'utenza di servizio                        |
| Serve debuggare la classe            | vedi sotto                       | —                                                                             |

**Transazioni utili:** `SMICM` (trace ICM), `SCOT` (config + trace), `SOIN` (mail in ingresso), `SOST` (stato messaggi), `SLG1` (log applicativo), `SM50` (work process), `SICF` (servizio SAPconnect).

**Debug della classe inbound:**

- L'utenza di servizio SAPconnect (SICF) deve avere accesso in debug ed essere di tipo dialog.
- In **SCOT** digitare `DBG+` nel campo comando per attivare il debug dell'inbound.
- In alternativa, external breakpoint nel metodo `PROCESS_INBOUND` (SE80/ADT) impostato sull'utente che esegue il servizio SAPconnect.
- Se il breakpoint "non aggancia", verificare che sia l'utente giusto e controllare in SM50 il processo che gestisce la mail.

**Test senza mail reale:** in fase di sviluppo si può usare il trigger di inbound offline `FP_TEST_INBOUND` per invocare la logica senza dipendere dal canale mail, mentre Basis completa l'infrastruttura.

---

## 5. Checklist di go-live

**Basis**

- [ ] Connettore SMTP Exchange → ICM configurato e testato
- [ ] Porta SMTP ICM attiva (`icm/server_port_*`, `is/SMTP/virt_host_*`) e visibile in SMICM
- [ ] Servizio SAPconnect attivo in SICF con utenza di servizio e autorizzazioni
- [ ] Default Domain e nodo SMTP impostati in SCOT
- [ ] Flusso di rete/firewall aperto solo dalla rete interna

**ABAP / Funzionale**

- [ ] Regola SO50 creata (indirizzo → classe, tipo `Internet Mail`)
- [ ] Classe `IF_INBOUND_EXIT_BCS` implementata (`CREATE_INSTANCE` + `PROCESS_INBOUND`)
- [ ] Tabella `ZEMAIL_WHITELIST` creata (SE11) e popolata (SM30); check whitelist attivo in testa a `PROCESS_INBOUND`
- [ ] Semantica `GC_CONTINUE` / `GC_TERMINATE` verificata (drop dei non autorizzati)
- [ ] Logica di business collegata (BAPI / workflow / tabella)
- [ ] Oggetto log SLG0 creato e scrittura SLG1 attiva
- [ ] Test end-to-end con mail reale + verifica SOIN/SLG1
- [ ] Gestione errori e casi limite (mail senza dati attesi, allegati, mittente sconosciuto)

---

# PARTE C — Alternativa quando l'ICM è gestito da terzi

Tutta la Parte A presuppone di poter intervenire su ICM/SICF/SCOT. Se l'ICM è gestito da un fornitore/team esterno e aprire una porta SMTP inbound comporta un onere organizzativo sproporzionato rispetto al caso d'uso, conviene **non toccare affatto il canale SMTP di SAP** e spostare il "catch" della richiesta esterna fuori da SAP, su un livello ponte che poi chiama semplicemente le **OData** già disponibili in intranet.

## C1. Quando usarla

- Il caso d'uso è "far arrivare una richiesta/ticket da un utente esterno", non necessariamente una vera casella mail SAP.
- Le OData necessarie sono già esposte in intranet (create/aggiornamento ticket, ecc.).
- Coinvolgere il fornitore esterno dell'ICM per il canale SMTP è complesso o lento; il proprio IT interno può però esporre un canale alternativo o attivare strumenti già disponibili in M365.

## C2. Principio architetturale

Non si fa arrivare la mail dentro SAP: si intercetta il canale esterno (mail e/o form) **fuori** da SAP, si applicano lì i controlli (whitelist, validazione, dedup), e solo alla fine si chiama l'OData interna. SAP non riceve mai SMTP grezzo; riceve solo chiamate OData autenticate, che è il tipo di traffico che l'infrastruttura già gestisce normalmente.

```
Utente esterno
   │
   ├─ mail a supporto@miodominio.com  (casella condivisa, non distribution list)
   └─ form pubblico
              │
              ▼
   [Orchestratore: Power Automate oppure servizio applicativo custom]
   - whitelist mittente/dominio
   - validazione dati
   - dedup / marcatura "processato"
   - log della richiesta
              │
              ▼
   Connettività verso l'intranet
   (On-premises Data Gateway, oppure regola di rete dedicata)
              │
              ▼
       OData SAP (intranet) → crea ticket/richiesta
              │
              ▼
   Risposta automatica al mittente (conferma + ID ticket)
```

Punto chiave sulla mail: se si vuole intercettarla, serve una **casella condivisa** (shared mailbox, es. `supporto@miodominio.com`), non una distribution list — quest'ultima inoltra solo ai membri e non ha un proprio inbox su cui agganciare un trigger.

## C3. Due opzioni di implementazione

| | Opzione A — Microsoft 365 / Power Automate | Opzione B — VM applicativa in DMZ |
| --- | --- | --- |
| Form pubblico | Microsoft Forms (incluso in M365) | Pagina/route custom sulla VM |
| Cattura mail | Trigger nativo "nuova mail" su casella condivisa | Webhook su Microsoft Graph API verso una route della VM |
| Orchestratore | Flow Power Automate (whitelist, validazione, dedup, log) | Codice custom (es. Flask) sulla VM |
| Connettività verso OData | **On-premises Data Gateway** (Microsoft), installato su una macchina interna che raggiunge l'OData; connessione solo in uscita, nessuna porta da aprire | Regola firewall dedicata: 443 in ingresso solo verso la VM (con alias DNS + TLS) e outbound ristretto dalla VM verso host:porta dell'OData |
| Dipendenza | Licenza Power Automate (verificare se serve Premium per l'azione verso il gateway) | Manutenzione continuativa del server (patch, certificato TLS, uptime, monitoraggio) — tipicamente richiede coinvolgere un team infra/sicurezza nel tempo |
| Adatto se | Non si vuole gestire infrastruttura server nel tempo; il team non ha competenze di rete | Si preferisce controllo pieno via codice e non c'è disponibilità/licenza Premium |

**Nota sulla portabilità:** cambiare in futuro da un'opzione all'altra richiede riscrivere solo il livello orchestratore (logica di whitelist/validazione/dedup nel nuovo linguaggio/strumento) e il meccanismo di connettività (gateway vs regola di rete). Restano invariati: il contratto OData lato SAP, l'utente tecnico e le relative autorizzazioni, la casella condivisa, e i requisiti funzionali stessi.

## C4. Requisiti funzionali obbligatori fin dal primo giorno

Non differibili a una fase successiva, indipendentemente dall'opzione scelta:

1. **Whitelist mittenti/domini** — check preliminare prima di processare qualsiasi submission o mail; se non in whitelist, scarto silenzioso (o coda per revisione manuale), non arriva mai a toccare l'OData.
2. **Validazione input** — campi obbligatori e formati corretti prima della chiamata OData.
3. **Idempotenza/dedup** — mail processate marcate/spostate per non essere rielaborate dal trigger; per il form, un token/ID di submission per evitare doppio invio.
4. **Riscontro automatico al mittente** — conferma con ID ticket, sia per mail che per form.
5. **Logging di ogni richiesta** (chi, quando, canale, esito) — necessario per troubleshooting/audit fin dal primo giorno.

## C5. Scalabilità futura: app Fiori esterna

L'architettura non esclude un domani un'app Fiori per l'apertura ticket: si aggiunge come un ulteriore canale che chiama la stessa OData, senza toccare mail/form. La differenza sostanziale è il modello di fiducia: mail/form funzionano in modo anonimo (whitelist su dominio/mittente), mentre un'app Fiori per utenti esterni richiede una vera identità/login. La strada tipica è **SAP BTP + Identity Authentication Service (IAS)** per gestire l'identità di clienti/fornitori esterni, con il Launchpad esposto tramite **SAP Cloud Connector** (stesso principio "connessione solo in uscita" già usato per il gateway M365). Scegliere fin da subito un service user OData con autorizzazioni ben segregate facilita l'aggiunta di questo layer in un secondo momento.

## C6. Traccia email da inviare all'IT

Da adattare con i propri riferimenti; lascia volutamente a IT la scelta tra le due opzioni in base a licenze/capacità disponibili.

> **Oggetto:** Richiesta pilota — raccolta richieste esterne verso SAP (form + mail), nessun impatto su ICM — valutazione soluzione
>
> Ciao [Nome],
>
> vorrei attivare un piccolo pilota per permettere a utenti esterni (clienti/fornitori) di inviare ticket/richieste che vengano create automaticamente sul nostro SAP, tramite le OData già disponibili in intranet — **senza toccare l'ICM SAP**, che so essere gestito dal fornitore esterno.
>
> L'idea di massima (schema sotto) è: l'utente esterno scrive a una casella mail dedicata oppure compila un form pubblico → un livello intermedio valida/filtra la richiesta → chiama la nostra OData interna per creare il ticket.
>
> Il nostro team lavora su ABAP/Fiori, non abbiamo competenze di infrastruttura di rete, quindi vi giro due possibili strade e vorrei un vostro parere su quale sia più adatta con quello che avete già in casa — non abbiamo una preferenza vincolante, l'obiettivo è la funzionalità:
>
> **Opzione A — Microsoft 365 / Power Automate**
> - Casella condivisa `supporto@miodominio.com`
> - Microsoft Forms per il form pubblico
> - Power Automate come orchestratore (richiede verificare se abbiamo licenza Premium, necessaria per l'azione verso il gateway)
> - On-premises Data Gateway installato su una macchina interna che raggiunge l'OData (connessione solo in uscita, nessuna porta da aprire in ingresso)
>
> **Opzione B — Piccola VM in DMZ**
> - Una VM (anche minimale) con un servizio applicativo che espone solo la route del form/webhook
> - Regola firewall in ingresso: solo 443, solo verso quella VM, con alias DNS e certificato TLS
> - Regola firewall in uscita dalla VM: solo verso host:porta della nostra OData
> - Comporta la vostra gestione continuativa del server (patch, certificato, uptime)
>
> Vi chiederei di dirci quale delle due è preferibile per voi, tenendo conto di licenze Power Automate disponibili e capacità di gestire una VM esposta nel tempo. È un progetto **sperimentale/pilota**: se vedete criticità di rete/sicurezza in una o entrambe le proposte, o avete un'alternativa che non abbiamo considerato, siamo aperti — l'obiettivo è la funzionalità, non l'implementazione specifica.
>
> Disponibili per una call se serve confrontarci prima di decidere.
>
> Grazie,
> [Il tuo nome]

---

### Note di release

Su S/4HANA recenti i nomi dei menu SCOT, i path SICF e le firme di `IF_INBOUND_EXIT_BCS` / `IF_DOCUMENT_BCS` possono differire leggermente. Verificare sempre i nomi esatti di metodi e tipi in **SE24** sul sistema di destinazione prima dello sviluppo definitivo.
