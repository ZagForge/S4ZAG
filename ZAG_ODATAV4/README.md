# OData V4

- [Implementations](#implementations)
- [Theory](#theory)

---

## OData V4 - CodeBased Implementation <a name="implementations"/>

### [SAP Reference](https://community.sap.com/t5/technology-blogs-by-members/simple-odata-v4-service-using-code-based-implementation/ba-p/13519406)

<br>

### 1. [System prerequisites](#system_prerequisites)
### 2. [What will be implemented](#implemented_objects)
### 3. [How to configure the service?](#service_config)
### 4. [How to run the service](#service_run)

---

### 1. System Prerequisites <a name="system_prerequisites"/>
- OData V4 uses a virus scan profile /IWBEP/V4/ODATA_UPLOAD. You have to config it with transaction **VSCANPROFILE** ( Basis activity ). Otherwise you can disable it using Tcode **/IWBEP/V4/ODATA_UPLOAD**
- Make sure thate the service group **/IWFND/CONFIG** is published. Otherwise, do it with Tcode **/IWBEP/V4_ADMIN**

### 2. What do you need to implement?<a name="implemented_objects"/>

> Questo esempio legge/scrive direttamente sulle tabelle standard **LFA1**/**LFB1**/**LFM1**,
> senza passare da CDS view: il framework OData V4 code-based non richiede una CDS come
> data source, basta una struttura qualsiasi (vedi `ts_vendor`/`ts_company`/`ts_purchorg`
> nell'interfaccia) da passare a `create_entity_type_by_struct`. Le CDS restano comunque
> un'opzione valida se vuoi riusare associazioni/annotazioni altrove, ma qui — essendo
> solo estrazione — avrebbero aggiunto un livello in più senza reale beneficio.

- **Interface**
	- [ZAG_IF_ODATAV4_VENDOR](https://github.com/avorio-dev/S4ZAG/blob/main/ZAG_ODATAV4/Class%20Implementations/zag_if_odatav4_vendor.abap)

- **Data Model**
	- [ZAG_CL_ODATAV4_VENDOR_MODEL](https://github.com/avorio-dev/S4ZAG/blob/main/ZAG_ODATAV4/Class%20Implementations/zag_cl_odatav4_vendor_model.abap)

- **Data Provider**
	- [ZAG_CL_ODATAV4_VENDOR_DATA](https://github.com/avorio-dev/S4ZAG/blob/main/ZAG_ODATAV4/Class%20Implementations/zag_cl_odatav4_vendor_data.abap)

> If you are using deep structures and you are having problems like
> "sap scan profile virus /IWBEP/V4/ODATA_UPLOAD inactive"
> You can:
> - Config the profile /IWBEP/V4/ODATA_UPLOAD in tcode **VSCANPROFILE** 
> - Disable in Tcode **/IWFND/VIRUS_SCAN** virus scan profile for V4

---

### 3. How to configure the service?<a name="service_config"/>

1. Run TCode **/iwbep/v4_admin**
2. Register a service group **ZAG_SG_VENDOR** 
3. Register a service **ZAG_SRV_VENDOR** providing the just created model and provider classes
4. Assign the service to the service group **ZAG_SG_VENDOR**
5. Publish the service group using transaction **/iwfnd/v4_admin** – (Gateway System)

---

### 4. How to run the service?<a name="service_run"/>

>Each link listed below will need to be concatenated to your **<system_host>** if you are testing with Browser/Postman.
>If you're using GW_CLIENT instead, it will be enough copy/paste it
	
- how to get the **metadata**:
	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/$metadata?sap-statistics=true

- how to get the **Vendors List**/**Companies List**/**Purch.Org List**
	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor
 
 	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Company

   	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Purchorg

- how to get a **Single Vendor**
  	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor('1')

- how to get a **Single Vendor** with all company/purchorg related info
  	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor('1')?$expand=_Company,_Purchorg

- how to get the **first 10** records
  	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor?$top=5

- how to get the **first 1/2 records** of respect. company/purchorg of a specific vendor
  	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor('100047')?$expand=_Company($top=1),_Purchorg($top=2)
   
- how to get the **data filtered** both main entity and expanded entities
  	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor?$expand=_Company($filter=Bukrs eq 'FCH1'),_Purchorg($filter=Ekorg eq 'BA00')&$filter=Ort01 eq 'Bari'

- how to get **specific fields**
	>		/sap/opu/odata4/sap/zag_sg_vendor/default/sap/zag_srv_vendor/0001/Vendor('1')?$select=Name1,Adrnr&$expand=_Company($select=Loevm,Akont)

---

## [OData V4 - Theory]

### [SAP Reference](https://community.sap.com/t5/technology-blogs-by-sap/odata-v4-code-based-implementation-overview/ba-p/13361814)

<br>


### 1. [Difference V2 and V4](#difference_v2_v4)
### 2. [OData V4 Framework](#odata_v4_framework)
### 3. [io_request and io_response](#io_req_io_resp)
### 4. [ToDo and Done-Flags](#todo_done_flags)

---

### 1. What's the difference between v4 and v2?<a name="difference_v2_v4"/>

The list of new & improved features in v4 is [extensive](http://docs.oasis-open.org/odata/new-in-odata/v4.0/new-in-odata-v4.0.html) and I will highlight just a few here:  

-   Better performance through reduced payload size (both for metadata and response data)  
-   Improved data types, e.g. separate date and time types rather than combined datetime only
-   You can filter and sort on expanded properties. For example, we can query order headers expanded to order items, with a filter for only order item quantity > 100. In v2 we could only filter by the main entity (in this case the order header)
-   The query syntax is much more logical with multiple expands. This is because the parameters are nested
  
Lets consider the last point in more detail. With v2 we would query like this  
> ..../Continents?$expand=Countries/Cities

With v4 we can query  
> ..../Continents?$expand=Countries($expand=Cities)

It's clear that with this syntax we can expand to any number of levels. We can also apply parameters like $select or $filter at any level we choose, e.g.  
> ..../Continents?$expand=Countries($expand=Cities($expand=Suburbs;$select=Name,Population),CapitalCity;$select=Name,Population)&$select=Name

What are we doing here? We select the _Continents_ and expand to _Countries_. From _Countries_ we expand to both _Cities_ and _CapitalCity_. From _Cities_ we expand again to _Suburbs_. For field selection we specify _Name_ only for _Continent_ and _Name_ & _Population_ for _Countries_ and for _Cities_.

### 2. OData V4 Framework<a name="odata_v4_framework"/>
- /IWBEP/IF_V4_DP_BASIC 
	- Methods provide basic functionality (Create, Update, Delete, Navigation, …)
	- When being implemented à Working OData service supporting most requests

- /IWBEP/IF_V4_DP_INTERMEDIATE
	- Medium complex functionality
	- eTag handling, PATCH, $expand
	- Contains generic calls to other (especially the basic) interfaces
  
- /IWBEP/IF_V4_DP_ADVANCED
	- Always called first by the framework
	- Contains generic calls to the other (especially the basic) interfaces
	- Will for example be overwritten by the new RESTful ABAP Programming model (planned)
  
- /IWBEP/IF_V4_DP_BATCH
	- $batch. Generic $batch and changeset
  
- /IWBEP/IF_V4_DP_PROCESS_STEPS
	- Transaction and lifecycle handling
 


### 3. io_request and io_response<a name="io_req_io_resp"/>
All interface methods have an import parameter called **io_request**.
It can be used to retrieve all information you need to handle the request in your service implemenation.
A UPDATE_ENTITY method for example will have the following methods
1. GET_BUSI_DATA to retrieve entity data from the request, for example the payload of the incoming request.
2. GET_ENTITY_SET to retrieve the entity set of the processed entity. So we can switch to entity set specific methods

The corresponding parameter **ip_response** is used to return business data to the SAP Gateway framework 
and to tell the framework which processing steps the service implementation has handled iself (see todo and done flags below).


### 4. ToDo and Done-Flags<a name="todo_done_flags"/>
The SAP Gateway V4 framework has introduced so called ToDo-Flags which provide a hint for the application developer what his implemenations has to do. 
Depending ont the query options that have been used in the request you will get simple list with boolean values for the following flags:
deltatoken, select, filter, skip, orderby, skiptoken, search, top, ...

Done-Flags confirm that the response fits to the request. They allow the application developer to inform the framework to handle feature generically e.g., $top, $skip, and $select. 
Using such flags also allows an implementation tobe compatible in the future. Instead of a wrong result an exception will be raised if a done flag is not set.