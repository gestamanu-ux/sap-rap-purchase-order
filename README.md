# SAP RAP — Purchase Order Service

Proyecto de portafolio desarrollado con ABAP RESTful 
Application Programming Model (RAP) en SAP BTP ABAP Environment.

## Arquitectura

| Objeto | Nombre | Descripción |
|---|---|---|
| Tabla | ZDA_HEADER | Cabecera del pedido |
| Tabla | ZDA_ITEM | Posiciones del pedido |
| Interface View | ZI_HEADER | CDS raíz con composición |
| Interface View | ZI_ITEM | CDS items |
| Consumption View | ZC_HEADER | Vista con anotaciones UI |
| Consumption View | ZC_ITEMSPO | Vista items con anotaciones UI |
| BDEF | ZI_HEADER | Managed + Draft Handling |
| Service Definition | ZSD_PURCHASE_ORDER | Exposición del servicio |
| Service Binding | ZSB_PURCHASE_ORDER | OData V4 UI |

## Funcionalidades

- CRUD completo de órdenes de compra
- Draft Handling para edición segura
- Validación de estados: DRAFT / SUBMITTED / APPROVED / REJECTED
- Numeración automática de OrderId
- Status por defecto DRAFT al crear
- Cálculo automático de ItemAmount y TotalAmount
- Autorización global e instancia
- Fiori Elements app generada automáticamente

## Flujo de estados

DRAFT → SUBMITTED → APPROVED
                 ↘ REJECTED → DRAFT

## Stack técnico

- SAP BTP ABAP Environment
- ABAP RAP (Managed BO con Draft)
- OData V4
- SAP Fiori Elements
- Eclipse ADT

<img width="1850" height="494" alt="image" src="https://github.com/user-attachments/assets/32af2606-f550-4fd9-8ba2-21dc018dbcc9" />

<img width="1860" height="760" alt="image" src="https://github.com/user-attachments/assets/421de674-0950-4c4a-9b92-d0779b5a68e0" />


