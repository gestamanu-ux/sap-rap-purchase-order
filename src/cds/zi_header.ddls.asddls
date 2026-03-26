@AccessControl.authorizationCheck:#NOT_REQUIRED
@EndUserText.label: 'PO Header - Interface View'

define root view entity ZI_HEADER
  as select from zda_header as h

  composition [0..*] of ZI_ITEM as _Items

{
  key h.order_uuid              as OrderUuid,
      h.order_id                as OrderId,
      h.supplier                as Supplier,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      h.total_amount            as TotalAmount,
      h.currency_code           as CurrencyCode,

      h.order_status            as OrderStatus,

      @Semantics.user.createdBy: true
      h.created_by              as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      h.created_at              as CreatedAt,
      @Semantics.user.lastChangedBy: true
      h.last_changed_by         as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      h.last_changed_at         as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      h.local_last_changed_at   as LocalLastChangedAt,

      _Items
}
