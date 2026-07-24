# OData V4 — Table Growth (ZAG_CL_ML_TABLE_GROWTH)

Il servizio espone 3 entity set. Non ci sono più le entity
`Db02RamSize`/`Db02DiskSize` (basate su `ZML_CL_BSN_LOGIC`/DB02): sono state
sostituite del tutto.

> Sostituisci `<SERVICE_URL>` con il path effettivo del servizio attivato in
> `/IWFND/MAINT_SERVICE` (o equivalente per OData V4) sul tuo sistema —
> non è ricavabile dai soli file ABAP di questa cartella.

---

## 1. TopTables — discovery, solo dimensione attuale

Metodo: `get_top_tables( xv_top_n )`

| Campo (EDM)  | Tipo ABAP | Note                                                   |
|--------------|-----------|---------------------------------------------------------|
| TableName    | tabname   | chiave                                                   |
| SchemaName   | char30    |                                                           |
| DiskBytes    | int8      | byte (HDB: `MEMORY_SIZE_IN_TOTAL`, MSS: `RESERVED`)      |
| RecCount     | int8      | record count corrente                                    |
| ModIndicator | int8      | attività recente: delta bytes (HDB) / ROWMODCTR (MSS)    |

**Esempi:**

```
GET <SERVICE_URL>/TopTables
GET <SERVICE_URL>/TopTables?$top=10
GET <SERVICE_URL>/TopTables?$orderby=DiskBytes desc
```

Note:
- `$top` viene spinto come `xv_top_n` (limite lato query DB).
- `$skip` non è gestito internamente: lo fa il framework sul risultato restituito.

---

## 2. TableGrowth — sintesi attuale (piatta)

Metodo: `get_table_growth( xt_table_name, xv_top_n, xv_include_history = false )`

| Campo (EDM) | Tipo ABAP | Note   |
|-------------|-----------|--------|
| TableName   | tabname   | chiave |
| SchemaName  | char30    |        |
| DiskBytes   | int8      |        |
| RecCount    | int8      |        |

**Esempi:**

```
GET <SERVICE_URL>/TableGrowth?$filter=TableName eq 'VBAK'
GET <SERVICE_URL>/TableGrowth?$filter=TableName eq 'VBAK' or TableName eq 'BKPF'
GET <SERVICE_URL>/TableGrowth
GET <SERVICE_URL>/TableGrowth?$top=10
GET <SERVICE_URL>/TableGrowth?$filter=TableName eq 'VBAK'&$expand=_History
```

**Storico delle prime N tabelle in una chiamata**: basta combinare `$top` con
`$expand`, senza passare `$filter` su `TableName` — scatta il fallback sul
top N e per ognuna delle tabelle risultanti arriva anche lo storico annidato:

```
GET <SERVICE_URL>/TableGrowth?$top=10&$expand=_History
```

Note:
- Chiama `get_table_growth` sempre con `xv_include_history = abap_false`:
  qui serve solo la sintesi, lo storico si ottiene con `$expand=_History`
  (vedi sotto) — niente query storiche inutili se non richieste.
- Se non passi `$filter` su `TableName`, `get_table_growth` fa da sola il
  fallback sul top N (`get_top_tables`), e `$top` viene spinto come `xv_top_n`
  per controllare quante (di default 20 se non specificato).
- `$top` è rilevante solo quando manca il `$filter` su `TableName`: se filtri
  già per tabelle specifiche, `$top` non viene applicato (non ha senso "le
  prime N" su un elenco che hai già scelto tu esplicitamente).

---

## 3. GrowthPoint — storico, raggiunto via `$expand=_History` da TableGrowth

Entity separata (chiave `TableName` + `SnapshotDate`), collegata a
`TableGrowth` con la navigation property `_History` (stesso pattern —
verificato — di `Vendor → _Company`/`_Purchorg` in `ZAG_ODATAV4`).

| Campo (EDM)  | Tipo | Note                                     |
|--------------|------|---------------------------------------------|
| TableName    | tabname | chiave                                   |
| SnapshotDate | d    | chiave — 1° del mese (HDB) o data campione (MSS) |
| RecordCount  | int8 |                                               |
| DiskBytes    | int8 |                                               |

**Esempio (nesting in un'unica chiamata):**

```
GET <SERVICE_URL>/TableGrowth?$filter=TableName eq 'VBAK'&$expand=_History
```

Risposta attesa:

```json
{
  "TableName": "VBAK",
  "SchemaName": "SAPHANADB",
  "DiskBytes": 419430400,
  "RecCount": 332579,
  "_History": [
    { "TableName": "VBAK", "SnapshotDate": "2024-01-01", "RecordCount": 12000, "DiskBytes": 4500000 },
    { "TableName": "VBAK", "SnapshotDate": "2024-02-01", "RecordCount": 12500, "DiskBytes": 4700000 }
  ]
}
```

Accesso diretto all'entity set (senza passare da TableGrowth) è supportato
filtrando per `TableName`/`SnapshotDate`:

```
GET <SERVICE_URL>/GrowthPoint?$filter=TableName eq 'VBAK' and SnapshotDate ge 2024-01-01
```

**Risposta reale di esempio**: vedi [`esempio-response.json`](esempio-response.json)
— una `GET /TableGrowth?$filter=TableName eq 'VBAK'&$expand=_History` presa
da un sistema vero, utile come riferimento per mockare i dati lato client.

---

## Come funziona `$expand` sotto al cofano

1. Il framework OData chiama `read_ref_target_key_data_list` su `TableGrowth`
   per la tabella richiesta → `read_ref_key_list_table_growth` invoca
   `get_table_growth(xv_include_history = abap_true)` per quella sola
   tabella e restituisce le chiavi (`TableName`+`SnapshotDate`) di ogni
   punto storico.
2. Il framework richiama poi `read_entity_list` su `GrowthPoint` con quelle
   chiavi → `read_list_growth_point` rifà la chiamata a `get_table_growth`
   (per le tabelle richieste) e restituisce le righe piatte.

Nota: questo significa che per un `$expand` la storia viene calcolata due
volte lato ABAP (una per risolvere le chiavi, una per i dati) — è il prezzo
del pattern a navigation property; se diventa un problema di performance si
può ottimizzare più avanti (es. cache per richiesta).

---

## Cosa NON è (ancora) gestito

- Gli errori restituiti da `ZAG_CL_ML_TABLE_GROWTH` (`yt_errors`) vengono
  raccolti ma **non sollevano un'eccezione** verso il chiamante OData.
- `read_entity` (GET su singola entity by key), `create_entity`,
  `update_entity`, `delete_entity` restano stub vuoti.
