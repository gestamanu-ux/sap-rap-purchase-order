@EndUserText.label: 'PO Header - Consumption View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_HEADER
  provider contract transactional_query
  as projection on ZI_HEADER

{
  key OrderUuid,
      OrderId,
      Supplier,
      TotalAmount,
      CurrencyCode,
      OrderStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Items : redirected to composition child ZC_ITEMSPO
}
