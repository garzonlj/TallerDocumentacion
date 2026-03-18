# Software Requirements Specification (SRS)
## Sistema de Gestión de Parqueaderos - "ParkEasy"

**Versión:** 1.0  
**Fecha:** 19/03/2026  
**Grupo:** [4]  
**Integrantes:**
- Juan Camilo Alba - 20520477
- Laura Garzon - [Código]
- Carlos Villegas - [Código]
- Arley Bernal - [Código]

---

## 1. INTRODUCCIÓN

### 1.1 Propósito
Este documento especifica los requisitos funcionales y no funcionales del sistema de gestión de parqueaderos "ParkEasy". Su objetivo es establecer una base clara y acordada entre el equipo de desarrollo y los stakeholders sobre qué debe construirse en el MVP, qué restricciones aplican y cuáles son los criterios de éxito del sistema. Sirve además como entrada principal para las decisiones arquitecturales documentadas en los ADRs y el SAD.

### 1.2 Alcance
ParkEasy digitalizará la operación de 3 parqueaderos en Bogotá (Zona T, Unicentro y Andino) con 450 espacios en total. El sistema permitirá a los conductores consultar disponibilidad en tiempo real, hacer reservas anticipadas, ingresar sin contacto mediante reconocimiento automático de placas (LPR) y pagar digitalmente con generación de factura electrónica. Los operadores podrán registrar entradas manuales y gestionar incidentes, y los administradores tendrán acceso a dashboards y reportes de ocupación e ingresos. Como beneficio principal, se reducirán los tiempos de entrada/salida, se eliminarán los tickets físicos y se habilitarán métodos de pago digitales.

### 1.3 Definiciones, Acrónimos y Abreviaciones

| Término | Definición |
|---------|------------|
| LPR | License Plate Recognition (Reconocimiento Automático de Placas) |
| MVP | Minimum Viable Product (Producto Mínimo Viable) |
| DIAN | Dirección de Impuestos y Aduanas Nacionales (Colombia) |
| PCI-DSS | Payment Card Industry Data Security Standard |
| P95 | Percentil 95 de tiempo de respuesta |
| COP | Peso Colombiano |
| JWT | JSON Web Token – mecanismo de autenticación sin estado |
| Legacy | Sistema de cobro existente en Visual Basic 6, en operación concurrente |
### 1.4 Referencias
- Enunciado del taller: *Taller: Documentación Arquitectural Completa – ParkEasy* (PUJ, 2026)
- Ley 1581 de 2012 – Protección de datos personales (Colombia)
- Normativa DIAN – Facturación electrónica
- PCI-DSS v4.0

---

## 2. DESCRIPCIÓN GENERAL DEL SISTEMA

### 2.1 Perspectiva del Producto
ParkEasy es un sistema standalone que coexiste con la infraestructura tecnológica existente de los parqueaderos. Se integra con las **cámaras LPR** instaladas mediante su API REST para automatizar el ingreso y la salida de vehículos. Durante el MVP, el **sistema de cobro legacy en VB6** continúa operando de forma concurrente; ParkEasy se sincroniza con él a través de un adaptador SOAP. Los pagos digitales se procesan a través de la **pasarela Wompi** (tarjeta, Nequi, Daviplata), y la **facturación electrónica** se remite a la DIAN. Las notificaciones y facturas se envían a conductores por medio de un **gateway de Email/SMS**.

### 2.2 Funciones del Producto
1. Gestión de disponibilidad en tiempo real por parqueadero
2. Reservas anticipadas de espacios (máximo 2 horas)
3. Control de acceso automático mediante LPR
4. Registro manual de entrada por operador (contingencia)
5. Procesamiento de pagos digitales al salir
6. Emisión y almacenamiento de facturas electrónicas (DIAN)
7. Gestión de incidentes por parte de operadores
8. Dashboard y reportes de ocupación e ingresos para administradores
9. Configuración de tarifas por zona

### 2.3 Características de Usuarios

| Tipo de Usuario | Descripción | Nivel de Expertise |
|-----------------|-------------|--------------------|
| **Conductor** | Persona que busca parquear su vehículo; consulta disponibilidad, reserva, ingresa sin contacto y paga digitalmente | Básico - no técnico |
| **Operador** | Personal en casetas de entrada/salida; registra entradas manuales y gestiona incidentes | Básico - educación básica |
| **Administrador** | Gerente del parqueadero; consulta dashboards, genera reportes y configura tarifas | Medio - usa Excel, reportes |

### 2.4 Restricciones del Sistema

**Restricciones técnicas:**
- Debe integrarse con las cámaras LPR existentes (API REST); no se pueden reemplazar
- El sistema de cobro legacy (VB6, SOAP) no puede ser reemplazado durante el MVP
- Las comunicaciones entre clientes y backend deben usar HTTPS/REST con autenticación JWT

**Restricciones de negocio:**
- Presupuesto: $2.000 USD/mes en infraestructura (ver supuesto SUP-01)
- Equipo: 4 desarrolladores, 8 meses para el MVP
- No puede haber downtime en horas pico (7:00–10:00 am y 5:00–8:00 pm)

**Restricciones regulatorias:**
- Ley 1581 de 2012 (Colombia) – protección de datos personales
- Normativa DIAN – almacenamiento de facturas electrónicas por mínimo 5 años
- PCI-DSS – no almacenar datos de tarjetas en texto plano

---

## 3. REQUISITOS FUNCIONALES

---

### RF-01: Autenticación y Autorización de Usuarios
**Prioridad:** Alta  
**Descripción:** El sistema debe permitir a conductores, operadores y administradores autenticarse con email y contraseña, gestionando el acceso a funcionalidades según su rol.

**Criterios de aceptación:**
- Login con email y contraseña para todos los roles (CONDUCTOR, OPERADOR, ADMIN)
- Sesión basada en JWT con expiración de 1 hora y refresh token con rotación
- Recuperación de contraseña por email en menos de 2 minutos
- Los conductores pueden registrarse de forma autónoma desde la web o app móvil
- El acceso a cada módulo está restringido al rol correspondiente; un intento no autorizado retorna HTTP 403

---

### RF-02: Visualización de Disponibilidad en Tiempo Real
**Prioridad:** Alta  
**Descripción:** El sistema debe mostrar en tiempo real el número de espacios disponibles, ocupados y reservados para cada parqueadero, accesible desde todas las interfaces.

**Criterios de aceptación:**
- Vista por parqueadero (Zona T, Unicentro, Andino) con estado de cada espacio
- Estados diferenciados visualmente: libre (verde), ocupado (rojo), reservado (amarillo)
- Actualización automática cada 30 segundos o ante cualquier evento de entrada/salida
- Datos con antigüedad máxima de 30 segundos respecto al estado real del parqueadero
- Accesible para conductores sin necesidad de autenticación (solo lectura)

---

### RF-03: Reserva Anticipada de Espacio
**Prioridad:** Alta  
**Descripción:** Los conductores autenticados pueden reservar un espacio disponible con un mínimo de 5 minutos y un máximo de 2 horas de anticipación respecto a su hora de llegada.

**Criterios de aceptación:**
- El sistema verifica disponibilidad en tiempo real antes de confirmar la reserva
- Confirmación de reserva enviada por email/SMS en menos de 10 segundos
- Máximo 1 reserva activa simultánea por conductor en el mismo parqueadero
- Si el conductor no llega en los 15 minutos posteriores a la hora reservada, el espacio se libera automáticamente
- Cancelación permitida hasta 15 minutos antes de la hora reservada sin penalidad
- El sistema rechaza reservas fuera del rango de 5 minutos–2 horas con mensaje de error claro

---

### RF-04: Ingreso sin Contacto mediante LPR
**Prioridad:** Alta  
**Descripción:** Al llegar a la entrada, la cámara LPR lee la placa del vehículo y el sistema levanta la barrera automáticamente si hay reserva activa o espacio disponible.

**Criterios de aceptación:**
- Lectura de placa y apertura de barrera en ≤ 5 segundos P95
- Si hay reserva activa para esa placa, el ingreso se asocia a la reserva existente
- Si no hay reserva pero hay espacio disponible, se permite el ingreso y se genera registro
- Si el parqueadero está lleno, la barrera no se levanta y se notifica al operador en su panel
- Cada entrada queda registrada con timestamp, placa, espacio asignado y parqueadero
- Si la confianza de lectura LPR es menor al 90%, el sistema alerta al operador para ingreso manual

---

### RF-05: Registro Manual de Entrada por Operador (Contingencia)
**Prioridad:** Alta  
**Descripción:** Ante fallo del LPR o de la red, el operador puede registrar manualmente la entrada de un vehículo desde el panel operador táctil.

**Criterios de aceptación:**
- El operador ingresa la placa y selecciona el espacio manualmente en ≤ 3 toques en pantalla táctil
- El registro queda marcado como "ingreso manual" con ID del operador, timestamp y motivo
- La disponibilidad en el cache se actualiza inmediatamente tras el registro
- El registro manual queda auditado y es trazable en el historial del parqueadero
- Funciona con conectividad reducida; la sincronización con el backend ocurre cuando se restaura la red

---

### RF-06: Pago Digital al Salir
**Prioridad:** Alta  
**Descripción:** Al momento de salida, el sistema calcula el monto según el tiempo de permanencia y las tarifas vigentes, y permite al conductor pagar con tarjeta, Nequi o Daviplata a través de Wompi.

**Criterios de aceptación:**
- Cálculo correcto: primera hora $4.000 COP, horas adicionales $3.000 COP/hora, máximo día $25.000 COP
- El pago digital se confirma en ≤ 10 segundos desde la aprobación de Wompi
- Si el pago falla, el sistema reintenta automáticamente hasta 3 veces antes de derivar al operador
- Tras pago confirmado, se genera la factura electrónica y se levanta la barrera de salida
- El cobro se sincroniza con el sistema legacy VB6 mediante SOAP en cada transacción
- Se acepta pago en efectivo al operador como alternativa; el operador lo registra en el panel

---

### RF-07: Emisión de Factura Electrónica
**Prioridad:** Alta  
**Descripción:** Por cada transacción de pago confirmada, el sistema genera y remite una factura electrónica válida ante la DIAN y la envía al conductor por email/SMS.

**Criterios de aceptación:**
- La factura cumple el formato exigido por la DIAN (resolución vigente)
- La factura se envía al conductor en ≤ 30 segundos tras la confirmación del pago
- Las facturas se almacenan de forma inmutable (sin modificación ni eliminación posible)
- Ante fallo de la API DIAN, la factura se encola y el sistema reintenta automáticamente
- El conductor recibe la factura en el correo o número registrado en su cuenta

---

### RF-08: Dashboard de Ocupación para Administrador
**Prioridad:** Media  
**Descripción:** El administrador puede consultar en tiempo real la ocupación actual de cada parqueadero con métricas consolidadas e individuales por sede.

**Criterios de aceptación:**
- Dashboard con métricas: % de ocupación, espacios libres, espacios reservados, ingresos del día en curso
- Vista consolidada (todos los parqueaderos) y desglosada por sede disponibles en la misma pantalla
- Datos con antigüedad máxima de 60 segundos
- Accesible únicamente para usuarios con rol ADMIN o SUPERVISOR

---

### RF-09: Reportes de Ingresos y Estadísticas
**Prioridad:** Media  
**Descripción:** El administrador puede generar reportes de ingresos diarios y mensuales, tiempos promedio de permanencia y niveles de ocupación por parqueadero y franja horaria.

**Criterios de aceptación:**
- Filtros disponibles: rango de fechas, parqueadero y franja horaria
- Generación de reporte mensual completo (todos los parqueaderos) en ≤ 5 segundos
- Exportación disponible en formato CSV
- Los datos históricos están disponibles desde la fecha de puesta en producción
- Las consultas se ejecutan sobre la réplica de lectura para no afectar la base transaccional

---

### RF-10: Gestión de Incidentes por Operador
**Prioridad:** Media  
**Descripción:** El operador puede registrar incidentes operativos (vehículos mal estacionados, bloqueos de salida, etc.) y actualizar el estado del espacio afectado.

**Criterios de aceptación:**
- Marcar un espacio como "en incidente" en ≤ 2 toques en pantalla táctil
- El espacio en incidente queda indisponible para nuevas reservas mientras dure el incidente
- Cada incidente registra: tipo, descripción, timestamp, operador responsable y estado de resolución
- El operador puede cerrar el incidente y liberar el espacio una vez resuelto

---

### RF-11: Configuración de Tarifas por Zona
**Prioridad:** Baja  
**Descripción:** El administrador puede configurar y actualizar las tarifas de cobro para cada parqueadero de forma independiente.

**Criterios de aceptación:**
- Configuración individual por parqueadero: primera hora, horas adicionales y tarifa máxima día
- Los cambios entran en vigor en la siguiente transacción tras ser guardados
- Se mantiene historial de cambios de tarifa con timestamp y usuario que realizó la modificación
- No es posible establecer una tarifa por hora adicional mayor a la tarifa de primera hora

---

## 4. REQUISITOS NO FUNCIONALES

---

### RNF-01: Performance
**ID:** RNF-01  
**Categoría:** Performance  
**Descripción:** El sistema debe procesar las operaciones de entrada y salida de vehículos dentro de los tiempos definidos para evitar congestión en las casetas.

**Métricas:**
- Tiempo de entrada/salida (lectura LPR → apertura de barrera): ≤ 5 segundos (P95)
- Consulta de disponibilidad en tiempo real: ≤ 500 ms (P95)
- Confirmación de reserva anticipada end-to-end: ≤ 3 segundos (P95)
- Capacidad de proceso en pico: 80 vehículos/hora sin degradación

**Justificación:** El proceso de entrada/salida es el cuello de botella principal de la operación. Superar los 5 segundos genera colas visibles en horas pico y afecta directamente los ingresos y la percepción del servicio.

---

### RNF-02: Disponibilidad
**ID:** RNF-02  
**Categoría:** Availability  
**Descripción:** El sistema debe estar disponible durante todo el horario operativo, con protección especial en horas pico donde cualquier interrupción tiene impacto inmediato.

**Métricas:**
- Uptime: ≥ 99,5% durante horario operativo (6:00 am – 11:00 pm)
- Downtime máximo permitido: 3,65 horas/mes en horario operativo
- Cero downtime planificado en horas pico (7:00–10:00 am y 5:00–8:00 pm)
- Recovery Time Objective (RTO): ≤ 15 minutos
- Recovery Point Objective (RPO): ≤ 30 minutos

**Justificación:** Una interrupción en horas pico genera congestión inmediata en las entradas, pérdida de ingresos y posibles incidentes de seguridad. El 99,5% equivale al SLA estándar de producción para sistemas críticos de negocio.

---

### RNF-03: Escalabilidad
**ID:** RNF-03  
**Categoría:** Scalability  
**Descripción:** El sistema debe soportar el crecimiento proyectado de la empresa sin necesidad de rediseño arquitectural.

**Métricas:**
- Escalar de 450 a 1.200 espacios (de 3 a 6 parqueaderos) sin cambios en la arquitectura base
- Soportar 200 transacciones concurrentes sin degradación mayor al 20% en latencia P95
- Escalado horizontal: adición de instancias del API Backend y réplicas de base de datos
- Costo de infraestructura: ≤ $2.000 USD/mes operando con 1.200 espacios activos

**Justificación:** La empresa tiene un plan de expansión confirmado a 6 parqueaderos. Un rediseño posterior representaría un costo de oportunidad y riesgo operativo inaceptables para el negocio.

---

### RNF-04: Seguridad
**ID:** RNF-04  
**Categoría:** Security  
**Descripción:** El sistema debe proteger los datos personales de los conductores, las placas vehiculares y las transacciones financieras, cumpliendo la normativa vigente.

**Métricas:**
- TLS 1.2+ obligatorio en todas las comunicaciones externas e internas
- Cifrado AES-256 en reposo para datos sensibles (placas, tokens de pago)
- Autenticación JWT con expiración de 1 hora y refresh token con rotación
- Cumplimiento PCI-DSS: no almacenar datos de tarjeta en texto plano
- Cumplimiento Ley 1581/2012: consentimiento explícito, política de privacidad y soporte al derecho al olvido
- Rate limiting: máximo 100 requests/minuto por IP
- Log de auditoría para todas las operaciones sensibles (accesos, pagos, cambios de tarifa)

**Justificación:** El sistema maneja datos personales y financieros; el incumplimiento de Ley 1581 y PCI-DSS conlleva sanciones legales y pérdida de confianza de los usuarios.

---

### RNF-05: Usabilidad
**ID:** RNF-05  
**Categoría:** Usability  
**Descripción:** Las interfaces deben ser accesibles para usuarios con diferentes niveles de formación, especialmente los operadores en casetas que tienen educación básica.

**Métricas:**
- Un operador sin experiencia previa en sistemas digitales completa las 3 tareas principales en ≤ 20 minutos de capacitación
- Panel operador: botones mínimo 44×44 px, iconografía clara y textos en español sin tecnicismos
- Un conductor nuevo completa su primera reserva desde la app en ≤ 3 minutos
- Tasa de éxito en tareas del panel operador ≥ 90% en prueba con 3 operadores reales antes del lanzamiento
- Interfaz responsive compatible con Chrome, Firefox y Safari (últimas 2 versiones)

**Justificación:** Los operadores pueden tener educación básica; una interfaz compleja incrementa los errores operativos, ralentiza el proceso en caseta y requiere mayor soporte técnico continuo.

---

### RNF-06: Retención de Datos
**ID:** RNF-06  
**Categoría:** Compliance  
**Descripción:** Las facturas electrónicas y los registros de transacciones deben conservarse cumpliendo la normativa regulatoria colombiana.

**Métricas:**
- Almacenamiento de facturas electrónicas por mínimo 5 años (DIAN)
- Facturas inmutables tras su emisión: sin eliminación ni modificación permitida
- Recuperación de cualquier factura dentro del período de retención en ≤ 3 segundos
- Backup en almacenamiento de objetos (S3 o equivalente) con replicación geográfica

**Justificación:** La normativa DIAN obliga a conservar facturas electrónicas por 5 años; el incumplimiento genera sanciones administrativas y tributarias para la empresa.

---

### RNF-07: Costo
**ID:** RNF-07  
**Categoría:** Cost  
**Descripción:** Los costos operacionales de infraestructura deben mantenerse dentro del presupuesto definido para el MVP.

**Métricas:**
- Infraestructura: ≤ $2.000 USD/mes para el MVP (450 espacios, 3 parqueaderos)
- Comisión por transacción Wompi: ≤ 3% por pago procesado
- Licencias de software de terceros: $0 (priorizar herramientas open source)

**Justificación:** El presupuesto de infraestructura está fijado por la dirección; superarlo requiere aprobación adicional y compromete la viabilidad financiera del MVP.

---

## 5. ALCANCE DEL MVP

### 5.1 Dentro de Alcance (MVP)

✅ Visualización de disponibilidad en tiempo real para los 3 parqueaderos  
✅ Reservas anticipadas de espacios (máximo 2 horas de anticipación)  
✅ Ingreso sin contacto mediante lectura automática de placas (LPR)  
✅ Registro manual de entrada por operador como contingencia  
✅ Pago digital al salir: tarjeta de crédito/débito, Nequi y Daviplata (Wompi)  
✅ Emisión de factura electrónica válida ante la DIAN  
✅ Envío de notificaciones y facturas por email/SMS  
✅ Panel operador táctil para casetas (registro manual, incidentes, ocupación)  
✅ Dashboard de ocupación en tiempo real para administradores  
✅ Reportes de ingresos diarios y mensuales con exportación CSV  
✅ Configuración de tarifas por zona  
✅ Integración con sistema de cobro legacy VB6 (adaptador SOAP)  
✅ Autenticación con roles diferenciados (Conductor, Operador, Administrador)  

### 5.2 Fuera de Alcance (MVP)

❌ Reemplazo total del sistema de cobro legacy VB6 – requiere análisis y migración que supera el plazo del MVP  
❌ Gestión de abonados o mensualidades – incrementa la complejidad del módulo de pagos  
❌ Aplicación móvil nativa iOS/Android – se usa React Native multiplataforma para reducir esfuerzo  
❌ Integración con sistemas de terceros distintos a los especificados – fuera del alcance contractual  
❌ Módulo de mantenimiento de infraestructura física – responsabilidad operativa del personal del parqueadero  
❌ Soporte para pagos en criptomonedas – sin demanda validada y complejidad regulatoria alta  
❌ Reportes avanzados con gráficas interactivas – disponibles en fase 2 según feedback  
❌ Multitenancy para redes de parqueaderos de terceros – requiere rediseño de modelo de datos  
❌ Cobertura en más de 3 parqueaderos – arquitectura preparada para escalar, despliegue inicial limitado  

---

## 6. SUPUESTOS Y DEPENDENCIAS

### 6.1 Supuestos

1. El presupuesto de "$2.000.000 USD/mes" indicado en el enunciado se interpreta como $2.000 USD/mes; se documenta como supuesto pendiente de confirmación con el cliente (SUP-01)
2. Las cámaras LPR instaladas exponen una API REST documentada y funcional en los 3 parqueaderos
3. El sistema legacy VB6 acepta peticiones SOAP; la integración se hará mediante ingeniería inversa del protocolo dado que la documentación es incompleta
4. Wompi es la pasarela de pagos seleccionada y dispone de entorno sandbox para pruebas del equipo
5. La matrícula del vehículo es el identificador único del conductor para el flujo de ingreso sin contacto
6. Los conductores que usen reservas anticipadas deben registrarse y autenticarse en la aplicación
7. Cada caseta cuenta con una tableta o PC con pantalla táctil para el panel operador
8. Los 3 parqueaderos tienen conectividad a internet estable con latencia < 100 ms hacia el API Backend

### 6.2 Dependencias

1. **Cámaras LPR:** Para el flujo de ingreso y salida automáticos; un fallo de las cámaras activa el modo de contingencia manual
2. **Sistema de Cobro Legacy VB6:** Para sincronización de cobros durante el MVP; opera en paralelo hasta su eventual reemplazo
3. **Wompi (Pasarela de Pagos):** Para procesar pagos digitales con tarjeta, Nequi y Daviplata
4. **Email/SMS Gateway:** Para envío de confirmaciones de reserva, notificaciones y facturas a los conductores
5. **DIAN (Facturación Electrónica):** Para remisión y validación de facturas electrónicas; el sistema encola facturas ante fallos de la API

---

## 7. CRITERIOS DE ACEPTACIÓN DEL SISTEMA

El sistema ParkEasy será aceptado cuando:

- [ ] Todos los RF de prioridad Alta (RF-01 a RF-07) estén implementados y funcionando en los 3 parqueaderos
- [ ] El tiempo de entrada/salida sea ≤ 5 segundos P95 bajo carga pico de 80 vehículos/hora
- [ ] La integración con las cámaras LPR funcione correctamente y levante la barrera de forma automática
- [ ] La integración con Wompi procese pagos exitosamente con tarjeta, Nequi y Daviplata
- [ ] La integración con el sistema legacy VB6 sincronice cobros sin errores en cada transacción
- [ ] La emisión de facturas electrónicas sea reconocida como válida por la DIAN
- [ ] 5 operadores beta completen 20 registros manuales sin errores críticos
- [ ] Los administradores generen reportes mensuales en ≤ 5 segundos
- [ ] El sistema supere una prueba de carga con 200 transacciones concurrentes sin degradación > 20%
- [ ] Documentación técnica completa (SAD, ADRs, C4) entregada y revisada
- [ ] Operadores capacitados en el uso del panel en ≤ 20 minutos por sesión de entrenamiento

---

## 8. DRIVERS ARQUITECTURALES IDENTIFICADOS

| ID | Driver | Valor/Métrica | Prioridad |
|----|--------|---------------|-----------|
| **DR-01** | Performance de entrada/salida | ≤ 5 segundos P95 (LPR → barrera) | Alta |
| **DR-02** | Escalabilidad de espacios | 450 → 1.200 espacios sin rediseño | Alta |
| **DR-03** | Disponibilidad en horas pico | 0 downtime (7–10 am, 5–8 pm) | Alta |
| **DR-04** | Integración con sistema legacy | SOAP/VB6 no reemplazable en MVP | Alta |
| **DR-05** | Cumplimiento regulatorio DIAN | Retención de facturas ≥ 5 años | Media |
| **DR-06** | Seguridad y protección de datos | PCI-DSS + Ley 1581/2012 | Alta |
| **DR-07** | Costo de infraestructura | ≤ $2.000 USD/mes en MVP | Media |

---

## APROBACIONES

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | Juan Camilo Alba | Juan Camilo Alba | 18/03/26 |
| **Integrante 2** | [Nombre] | __________ | ___/___/___ |
| **Integrante 3** | [Nombre] | __________ | ___/___/___ |
| **Integrante 4** | [Nombre] | __________ | ___/___/___ |

---

**Fin del Documento SRS**

---

