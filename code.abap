* SICF ……..  http://<192......  /zrest/<serno>/20000353       Double Click  to get to “Handler List”  (HTTP) …. Z_CL_SERV_NOTIF_READ (SAP-Class) ….  
* See class-method “IF_HTTP_EXTENSION~HANDLE_REQUEST” (HTTP-Handler)
* Allows ‘Get’ function to make a RESTful call …. SE24  

======================

Class  :  Z_CL_SERV_NOTIF_READ
Method :  IF_HTTP_EXTENSION~HANDLE_REQUEST.                 Instance Method	Public	                               	Called for request handling for each incoming HTTP request


*  method IF_HTTP_EXTENSION~HANDLE_REQUEST.
*  endmethod.


method IF_HTTP_EXTENSION~HANDLE_request.
* DATA DEFINITION
DATA:
         path_info     TYPE string,
         verb          TYPE string,
         w_action      TYPE string,
         w_attr        TYPE string,
         w_body        TYPE string,
         gv_snotif_no           TYPE QMNUM,
         gv_systemstatus        TYPE QMSTTXT,
         gv_userstatus          TYPE CO_ASTTX,
         gv_syststat            TYPE  BAPI2080_NOTSTI .
DATA:
         gv_notifheader_export TYPE BAPI2080_NOTHDRE,
         gv_notifhdtext        TYPE  BAPI2080_NOTHDTXTE.


* INTERPRET REQUEST
       path_info = server->request->get_header_field( name = '~path_info' ).
       verb = server->request->get_header_field( name = '~request_method' ).
* CHECK METHOD
* Check if method is get.
       IF verb NE 'GET'.
         CALL METHOD server->response->set_header_field(
           name = 'Allow'       value = 'GET' ).
          CALL METHOD server->response->set_status(       code = '405'       reason = 'Method not allowed' ).
         EXIT.
       ENDIF.
         SHIFT path_info LEFT BY 1 PLACES.
         SPLIT path_info AT '/' INTO w_action w_attr.
* RETRIEVE DATA
* Try to update the service notification by service notification .

       gv_snotif_no = w_attr.
       concatenate '000' gv_snotif_no into gv_snotif_no.   "concatenate leading zeros into gv_snotif_no for the FM

*       gv_syststat-refdate = sy-datum.
*       gv_syststat-reftime = sy-uzeit.

*       CALL FUNCTION 'BAPI_ALM_NOTIF_GET_DETAIL'
*         EXPORTING
*           number            = gv_snotif_no
*         IMPORTING
*           NOTIFHEADER_EXPORT = gv_notifheader_export
*           NOTIFHDTEXT        = gv_notifhdtext.

data: gv_qmnum type QMNUM,
      gv_QMTXT type QMTXT,
      gv_aenam type AENAM,
      gv_aedat type AEDAT,
      gv_phase type QM_PHASE,
      gv_phase_txt type string.

* Keep it simple to reading service notification record by service-notif #


* data: a, b.
* a = 'X'.
* do.
*   if a = b.
*     exit.
*   endif.
* enddo.


select single QMNUM QMTXT AENAM AEDAT PHASE
       from qmel
       into ( gv_qmnum , gv_qmtxt , gv_aenam, gv_aedat, gv_phase )
       where qmnum = gv_snotif_no.


* 1	Outstanding
* 2	Postponed
* 3	In Process
* 4	Completed
* 5	Deletion Flag

if gv_phase = '1' .
  gv_phase_txt = 'Outstanding'.
elseif gv_phase = '2'.
  gv_phase_txt = 'Postponed'.
elseif gv_phase = '3'.
  gv_phase_txt = 'In Process'.
elseif gv_phase = '4'.
  gv_phase_txt = 'Completed'.
elseif gv_phase = '5'.
  gv_phase_txt = 'Deleted'.
endif.


concatenate gv_qmnum '-' gv_qmtxt '-' gv_aenam '-' gv_aedat '-' gv_phase_txt into w_body .


* ERROR OCCORRED
* Abort with 404 if error

        IF sy-subrc ne 0.
          CALL METHOD server->response->set_status(
           code = '404'
           reason = 'ERROR' ).

          CONCATENATE ''  ''  ''  ''  ''  'h1. ERROR with input param:  '  w_attr  ' '  ''  ''  INTO w_body.
                   CALL METHOD server->response->set_cdata( data = w_body ).
          EXIT.
         ENDIF.
*  (STORE ATTRIBUTE)
*       w_body = sy-subrc.
*                gv_systemstatus + gv_userstatus

*      concatenate gv_snotif_no gv_notifheader_export-short_text gv_notifhdtext-equidescr into w_body.

*      w_body = gv_snotif_no .
*      concatenate w_body ' --> 1 COMPLETED' into w_body.

*  (SET CONTENT TYPE)
* Return attribute value in response body

       CALL METHOD server->response->set_header_field(
         name = 'Content-Type'
         value = 'text/plain; charset=utf-8' ).
*  (PUT DATA IN RESPONSE BODY)
       CALL METHOD server->response->set_cdata( data = w_body ).
    endmethod.                    "IF_HTTP_EXTENSION~HANDLE_REQUEST


