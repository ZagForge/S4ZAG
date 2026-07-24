# OData V4 — Table Growth (ZAG_CL_ML_TABLE_GROWTH)

Il servizio espone 3 entity set, ciascuno mappato 1:1 su un metodo pubblico di
`ZAG_CL_ML_TABLE_GROWTH`. Non ci sono più le entity `Db02RamSize`/`Db02DiskSize`
(basate su `ZML_CL_BSN_LOGIC`/DB02): sono state sostituite del tutto.

> Sostituisci `<SERVICE_URL>` con il path effettivo del servizio attivato in
> `/IWFND/MAINT_SERVICE` (o equivalente per OData V4) sul tuo sistema —
> non è ricavabile dai soli file ABAP di questa cartella.

---

## 1. TopTables — discovery, solo dimensione attuale

Metodo: `get_top_tables( xv_top_n )`

| Campo (EDM)     | Tipo ABAP    | Note                                              |
|-----------------|--------------|----------------------------------------------------|
| TableName       | tabname      | chiave                                              |
| SchemaName      | char30       |                                                      |
| DiskBytes       | int8         | byte (HDB: `MEMORY_SIZE_IN_TOTAL`, MSS: `RESERVED`) |
| RecCount        | int8         | record count corrente                               |
| ModIndicator    | int8         | attività recente: delta bytes (HDB) / ROWMODCTR (MSS) |

**Esempi:**

```
GET <SERVICE_URL>/TopTables
GET <SERVICE_URL>/TopTables?$top=10
GET <SERVICE_URL>/TopTables?$orderby=DiskBytes desc
GET <SERVICE_URL>/TopTables?$select=TableName,DiskBytes
```

Note:
- `$top` viene spinto come `xv_top_n` (limite lato query DB), quindi filtra
  davvero quante righe la classe calcola — non è un semplice taglio a posteriori.
- `$skip` non è gestito internamente: se lo usi, il framework pagina sul
  risultato che la classe restituisce.

---

## 2. TableHistory — storico mensile (o snapshot MSS)

Metodo: `get_table_history( xt_table_name, xv_date_from, xv_date_to )`

| Campo (EDM)     | Tipo ABAP    | Note                                                |
|-----------------|--------------|------------------------------------------------------|
| TableName       | tabname      | chiave                                                |
| SnapshotDate    | d            | chiave — 1° del mese (HDB) o data campione (MSS)      |
| SchemaName      | char30       |                                                        |
| RecordCount     | int8         | record del periodo (HDB) o totali a quella data (MSS) |
| DiskBytes       | int8         | stima in byte (HDB) o dato reale (MSS)                |

**Esempi:**

```
GET <SERVICE_URL>/TableHistory?$filter=TableName eq 'VBAK'
GET <SERVICE_URL>/TableHistory?$filter=TableName eq 'VBAK' or TableName eq 'MSEG'
GET <SERVICE_URL>/TableHistory?$filter=TableName eq 'VBAK' and SnapshotDate ge 2024-01-01 and SnapshotDate le 2024-12-31
GET <SERVICE_URL>/TableHistory
```

Note:
- Se non passi `$filter` su `TableName`, la classe fa comunque un fallback
  automatico: prende il top N (`get_top_tables`) e ne calcola lo storico —
  quindi la chiamata senza filtro non va in errore, ma può essere pesante
  (interroga N tabelle in sequenza).
- Il filtro `SnapshotDate` supporta `ge`/`le`/`eq` singoli o combinati (viene
  ridotto a due estremi `xv_date_from`/`xv_date_to` lato ABAP).
- Su HDB serve un mapping tabella → campo data (`get_date_field_mapping`
  nella classe): se una tabella non è mappata, torna un errore per quella
  tabella specifica (`error_code = 'NM'`), le altre proseguono normalmente.

---

## 3. TableSize — peso attuale di tabelle specifiche

Metodo: `get_table_size( xt_table_name )`

| Campo (EDM) | Tipo ABAP | Note    |
|-------------|-----------|---------|
| TableName   | tabname   | chiave  |
| SchemaName  | char30    |         |
| RecCount    | int8      |         |
| DiskBytes   | int8      |         |

**Esempi:**

```
GET <SERVICE_URL>/TableSize?$filter=TableName eq 'VBAK'
GET <SERVICE_URL>/TableSize?$filter=TableName eq 'VBAK' or TableName eq 'BKPF'
GET <SERVICE_URL>/TableSize
```

Note:
- Stesso fallback di `TableHistory`: nessun filtro → prende il top N.
- Su MSS non c'è una query "peso attuale" diretta: si usa l'ultimo snapshot
  disponibile da `MSS_GET_TABHIST` (quello con `SnapshotDate` più recente).

---

## Dati finti per test senza sistema reale

In `ZML_IF_ODATAV4_ARCH_DATA` c'è `mock_data_table_history`, che genera 10
anni di storico mensile con crescita lineare + stagionalità + rumore per un
set fisso di tabelle (VBAK, VBAP, MARA, MARC, MKPF, MSEG). Per usarlo,
in `read_list_table_history` decommenta:

```abap
"TODO - simulazione: decommentare per usare dati finti invece del DB reale
lt_growth = mock_data_table_history( is_filtri ).
```

subito dopo la chiamata a `get_table_history`.

---

## Cosa NON è (ancora) gestito

- Gli errori restituiti da `ZAG_CL_ML_TABLE_GROWTH` (`yt_errors`) vengono
  raccolti ma **non sollevano un'eccezione** verso il chiamante OData: per
  ora, se una tabella fallisce, semplicemente non compare nel risultato.
- `read_entity` (GET su singola entity by key), `create_entity`,
  `update_entity`, `delete_entity` restano stub vuoti (nessuna scrittura
  prevista, solo lettura via `read_entity_list`).
