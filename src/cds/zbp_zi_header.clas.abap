CLASS lhc_PurchaseOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR PurchaseOrder RESULT result.

    METHODS setDefaultStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseOrder~setDefaultStatus.

    METHODS setOrderId FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseOrder~setOrderId.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchaseOrder~validateStatus.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PurchaseOrder
      RESULT result.

ENDCLASS.

CLASS lhc_PurchaseOrder IMPLEMENTATION.

  METHOD get_instance_authorizations.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #(
        %tky    = ls_key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD setDefaultStatus.
    READ ENTITIES OF zi_header IN LOCAL MODE
      ENTITY PurchaseOrder
        FIELDS ( OrderStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders)
      FAILED DATA(lt_failed).

    DATA lt_update TYPE TABLE FOR UPDATE zi_header.

    LOOP AT lt_orders INTO DATA(ls_order).
      IF ls_order-OrderStatus IS INITIAL.
        APPEND VALUE #(
          %tky        = ls_order-%tky
          OrderStatus = 'DRAFT'
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    CHECK lt_update IS NOT INITIAL.

    MODIFY ENTITIES OF zi_header IN LOCAL MODE
      ENTITY PurchaseOrder
        UPDATE FIELDS ( OrderStatus )
        WITH lt_update
      REPORTED DATA(lt_reported).
  ENDMETHOD.

  METHOD setOrderId.
    READ ENTITIES OF zi_header IN LOCAL MODE
      ENTITY PurchaseOrder
        FIELDS ( OrderId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders)
      FAILED DATA(lt_failed).

    DATA lt_update TYPE TABLE FOR UPDATE zi_header.

    LOOP AT lt_orders INTO DATA(ls_order).
      IF ls_order-OrderId IS INITIAL.
        APPEND VALUE #(
          %tky    = ls_order-%tky
          OrderId = |PO-{ cl_abap_context_info=>get_system_time( ) }|
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    CHECK lt_update IS NOT INITIAL.

    MODIFY ENTITIES OF zi_header IN LOCAL MODE
      ENTITY PurchaseOrder
        UPDATE FIELDS ( OrderId )
        WITH lt_update
      REPORTED DATA(lt_reported).
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITIES OF zi_header IN LOCAL MODE
      ENTITY PurchaseOrder
        FIELDS ( OrderStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders)
      FAILED DATA(lt_failed).

    DATA lt_valid_status TYPE RANGE OF zda_header-order_status.
    lt_valid_status = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'DRAFT'     )
      ( sign = 'I' option = 'EQ' low = 'SUBMITTED'  )
      ( sign = 'I' option = 'EQ' low = 'APPROVED'   )
      ( sign = 'I' option = 'EQ' low = 'REJECTED'   )
    ).

    LOOP AT lt_orders INTO DATA(ls_order).
      IF ls_order-OrderStatus NOT IN lt_valid_status.

        APPEND VALUE #( %tky = ls_order-%tky )
          TO failed-purchaseorder.

        APPEND VALUE #(
          %tky        = ls_order-%tky
          %state_area = 'VALIDATE_STATUS'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Status '{ ls_order-OrderStatus }' invalid. |
                                   && |Valid values: DRAFT, SUBMITTED, APPROVED, REJECTED.|
                        )
          %element-OrderStatus = if_abap_behv=>mk-on
        ) TO reported-purchaseorder.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_PurchaseOrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateItemAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseOrderItem~calculateItemAmount.
    METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchaseOrderItem~calculateTotalAmount.

ENDCLASS.

CLASS lhc_PurchaseOrderItem IMPLEMENTATION.

METHOD calculateItemAmount.

  READ ENTITIES OF zi_header IN LOCAL MODE
    ENTITY PurchaseOrderItem
      FIELDS ( Quantity UnitPrice ItemAmount )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_items)
    FAILED DATA(lt_failed).

  DATA lt_update TYPE TABLE FOR UPDATE zi_header\\PurchaseOrderItem.

  LOOP AT lt_items INTO DATA(ls_item).

    " ── Declarar tipo explícito para evitar el warning ───────────────
    DATA(lv_new_amount) = CONV zda_item-item_amount(
                            ls_item-Quantity * ls_item-UnitPrice ).

    IF ls_item-ItemAmount <> lv_new_amount.
      APPEND VALUE #(
        %tky       = ls_item-%tky
        ItemAmount = lv_new_amount
      ) TO lt_update.
    ENDIF.

  ENDLOOP.

  CHECK lt_update IS NOT INITIAL.

  MODIFY ENTITIES OF zi_header IN LOCAL MODE
    ENTITY PurchaseOrderItem
      UPDATE FIELDS ( ItemAmount )
      WITH lt_update
    REPORTED DATA(lt_reported).

ENDMETHOD.


METHOD calculateTotalAmount.

  " 1) Leer items modificados
  READ ENTITIES OF zi_header IN LOCAL MODE
    ENTITY PurchaseOrderItem
      FIELDS ( OrderUuid ItemAmount )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_items)
    FAILED DATA(lt_failed).

  CHECK lt_items IS NOT INITIAL.

  " 2) Navegar al padre para obtener su %tky correcto
  READ ENTITIES OF zi_header IN LOCAL MODE
    ENTITY PurchaseOrderItem BY \_PurchaseOrder
      FIELDS ( OrderUuid TotalAmount )
      WITH CORRESPONDING #( lt_items )
    RESULT DATA(lt_orders)
    FAILED DATA(lt_failed2).

  CHECK lt_orders IS NOT INITIAL.

  DATA lt_header_update TYPE TABLE FOR UPDATE zi_header.

  " 3) Para cada cabecera única
  LOOP AT lt_orders INTO DATA(ls_order)
    GROUP BY ls_order-%tky.

    " 4) Leer TODOS los items de esa cabecera
    READ ENTITIES OF zi_header IN LOCAL MODE
      ENTITY PurchaseOrder BY \_Items
        FIELDS ( ItemAmount )
        WITH VALUE #( ( %tky = ls_order-%tky ) )
      RESULT DATA(lt_all_items)
      FAILED DATA(lt_failed3).

    " 5) Sumar todos los importes
    DATA(lv_total) = CONV zda_header-total_amount( 0 ).
    LOOP AT lt_all_items INTO DATA(ls_all_item).
      lv_total += ls_all_item-ItemAmount.
    ENDLOOP.

    " 6) Actualizar cabecera usando %tky correcto
    APPEND VALUE #(
      %tky        = ls_order-%tky
      TotalAmount = lv_total
    ) TO lt_header_update.

  ENDLOOP.

  CHECK lt_header_update IS NOT INITIAL.

  MODIFY ENTITIES OF zi_header IN LOCAL MODE
    ENTITY PurchaseOrder
      UPDATE FIELDS ( TotalAmount )
      WITH lt_header_update
    REPORTED DATA(lt_reported).

ENDMETHOD.

ENDCLASS.
