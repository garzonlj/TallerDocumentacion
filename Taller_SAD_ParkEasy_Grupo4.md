# Software Architecture Document (SAD)
## Sistema de Gestión de Parqueaderos - "ParkEasy"

**Versión:** 1.0  
**Fecha:** 19/03/2026  
**Grupo:** 1  
**Preparado por:**
- Juan Camilo Alba - 20520477
- Laura Garzón - 20511299
- Carlos Villegas - 20532083
- Arley Bernal - [Código]

---

## CONTROL DE VERSIONES

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 0.1 | 19/03/2026 | Juan Camilo Alba | Borrador inicial |
| 1.0 | 19/03/2026 | Grupo completo | Versión final para entrega |

---

## TABLA DE CONTENIDOS

1. [Introducción](#1-introducción)
2. [Descripción General de la Arquitectura](#2-descripción-general-de-la-arquitectura)
3. [Vistas Arquitecturales (C4)](#3-vistas-arquitecturales-c4)
4. [Decisiones Arquitecturales (ADRs)](#4-decisiones-arquitecturales-adrs)
5. [Tecnologías y Herramientas](#5-tecnologías-y-herramientas)
6. [Seguridad](#6-seguridad)
7. [Despliegue e Infraestructura](#7-despliegue-e-infraestructura)
8. [Calidad y Atributos](#8-calidad-y-atributos)
9. [Riesgos y Deuda Técnica](#9-riesgos-y-deuda-técnica)

---

## 1. INTRODUCCIÓN

### 1.1 Propósito del Documento

Este documento describe la arquitectura del sistema **ParkEasy**, una plataforma de gestión digital de parqueaderos que digitaliza la operación de 3 sedes en Bogotá (Zona T, Unicentro y Andino) con 450 espacios en total. El sistema automatiza el control de acceso vehicular mediante reconocimiento de placas (LPR), habilita reservas anticipadas, procesa pagos digitales y emite facturación electrónica DIAN.

Este documento sirve como:
- **Guía de implementación** para el equipo de desarrollo: describe los servicios, sus responsabilidades, los contratos entre ellos y las tecnologías a usar en cada capa
- **Referencia técnica** para arquitectos y líderes técnicos: documenta las decisiones de diseño con sus justificaciones, alternativas descartadas y trade-offs asumidos
- **Documentación de decisiones** para futuros mantenedores: permite entender el razonamiento detrás de cada elección sin depender del conocimiento tácito del equipo original
- **Base de comunicación** entre stakeholders técnicos y no técnicos: traduce los requisitos del SRS en una arquitectura concreta y evaluable frente a los drivers de negocio

### 1.2 Audiencia

| Rol | Uso de este documento |
|-----|----------------------|
| **Desarrolladores** | Implementar componentes respetando los límites entre servicios y los contratos de API definidos |
| **Arquitectos** | Validar decisiones, evaluar evolución del sistema y detectar desviaciones arquitecturales en el tiempo |
| **DevOps / SRE** | Configurar infraestructura AWS, pipelines CI/CD y aplicar la estrategia de despliegue definida |
| **QA** | Diseñar estrategia de pruebas alineada con los atributos de calidad y flujos críticos del sistema |
| **Product Owner** | Entender restricciones técnicas, alcance del MVP y riesgos técnicos identificados |
| **Profesor** | Evaluar diseño arquitectural, trazabilidad de decisiones y calidad de la documentación |

### 1.3 Referencias

- **[SRS]** `Taller_SRS_ParkEasy_Grupo1.md` — Software Requirements Specification v1.0 (19/03/2026)
- **[DSL]** `Taller_ParkEasy_Architecture_Grupo1.dsl` — Vistas C4 en Structurizr
- **[ADR-001]** `Taller_ADR-001_Service_Based_Architecture_Grupo1.md` — Adoptar Service-Based Architecture para ParkEasy
- **[ADR-002]** `Taller_ADR-002_PostgreSQL_Database_Grupo1.md` — Adoptar PostgreSQL como Base de Datos Principal
- **[ADR-003]** `Taller_ADR-003_Legacy_Integration_Grupo1.md` — Adoptar Redis como Caché para Disponibilidad en Tiempo Real

### 1.4 Alcance

Este documento cubre la arquitectura del **MVP** de ParkEasy para los 3 parqueaderos iniciales.

**Dentro de alcance:**
- Visualización de disponibilidad en tiempo real para los 3 parqueaderos
- Reservas anticipadas de espacios (mínimo 5 minutos, máximo 2 horas de anticipación)
- Ingreso sin contacto mediante reconocimiento automático de placas (LPR)
- Registro manual de entrada por operador como contingencia ante fallo del LPR
- Pago digital al salir: tarjeta de crédito/débito, Nequi y Daviplata (Wompi)
- Emisión y almacenamiento de factura electrónica válida ante la DIAN
- Envío de notificaciones y facturas por email/SMS
- Panel operador táctil (Electron) para casetas: registro manual, incidentes y ocupación
- App móvil React Native para conductores
- Dashboard de ocupación en tiempo real para administradores
- Reportes de ingresos diarios y mensuales con exportación CSV
- Configuración de tarifas por zona
- Integración con sistema de cobro legacy VB6 mediante adaptador SOAP
- Autenticación con roles diferenciados: Conductor, Operador, Administrador

**Fuera de alcance:**
- Reemplazo total del sistema de cobro legacy VB6 (supera el plazo del MVP)
- Gestión de abonados o mensualidades
- Reportes avanzados con gráficas interactivas (disponibles en Fase 2)
- Multitenancy para redes de parqueaderos de terceros
- Soporte para pagos en criptomonedas
- Cobertura en más de 3 parqueaderos en esta fase

---

## 2. DESCRIPCIÓN GENERAL DE LA ARQUITECTURA

### 2.1 Filosofía de Diseño

La arquitectura de ParkEasy sigue estos principios:

1. **Simplicidad pragmática:** Elegir la solución más simple que satisfaga los drivers. No introducir complejidad que el equipo de 4 personas no pueda operar ni mantener dentro del plazo de 8 meses.
2. **Aislamiento de riesgos:** Encapsular las integraciones inestables (legacy VB6, cámaras LPR) en componentes dedicados, para que sus fallos no se propaguen al flujo crítico de acceso vehicular.
3. **Costo-eficiencia:** Mantener la infraestructura dentro de $2.000 USD/mes priorizando servicios gestionados de AWS que reducen el overhead operacional del equipo.
4. **Escalabilidad por configuración:** Agregar parqueaderos y espacios debe ser configuración, no código nuevo ni rediseño arquitectural.
5. **Trazabilidad de decisiones:** Cada elección tecnológica está respaldada por un ADR con contexto, alternativas evaluadas y trade-offs explícitos.

### 2.2 Estilo Arquitectural Principal

**Service-Based Architecture** (ver [ADR-001])

ParkEasy adopta Service-Based Architecture como punto de equilibrio entre un monolito modular y microservicios. El sistema se organiza en **6 servicios independientes** con dominios de negocio claramente delimitados, que comparten una base de datos PostgreSQL principal con una réplica de lectura dedicada para reportes y analytics.

Cada servicio se despliega de forma independiente en AWS ECS Fargate. La comunicación es síncrona (HTTP/REST) cuando se requiere respuesta inmediata —por ejemplo, el flujo de entrada vehicular— y asíncrona (Amazon MQ / RabbitMQ) para flujos no bloqueantes como notificaciones, facturación y analytics. Un API Gateway (Kong) centraliza el enrutamiento, la validación de tokens JWT y el rate limiting antes de que cualquier solicitud llegue a los servicios internos.

**Justificación:** Este estilo permite aislar fallos en el flujo crítico vehicular (DR-03), escalar selectivamente los servicios de mayor carga —Operacion Service y Disponibilidad Service— sin escalar los de baja carga —Reportes Service— (DR-02), desplegar servicios de forma independiente sin downtime global, y encapsular la integración inestable con el legacy VB6 dentro del Operacion Service y Pagos Service (DR-04). Todo dentro de la capacidad operacional de 4 desarrolladores y el presupuesto de $2.000 USD/mes (DR-07).

### 2.3 Drivers Arquitecturales (ASRs)

Los siguientes Architecturally Significant Requirements, extraídos del [SRS], guiaron todas las decisiones de diseño:

| ID | Driver | Valor / Métrica | Prioridad |
|----|--------|-----------------|-----------|
| **DR-01** | Performance de entrada/salida | ≤ 5 segundos P95 (LPR → apertura de barrera) | Alta |
| **DR-02** | Escalabilidad de espacios | 450 → 1.200 espacios sin rediseño arquitectural | Alta |
| **DR-03** | Disponibilidad en horas pico | 0 downtime en franjas 7–10 am y 5–8 pm | Alta |
| **DR-04** | Integración con sistema legacy | Adaptador SOAP/VB6 no reemplazable en el MVP | Alta |
| **DR-05** | Cumplimiento regulatorio DIAN | Retención de facturas electrónicas ≥ 5 años | Media |
| **DR-06** | Seguridad y protección de datos | PCI-DSS + Ley 1581/2012 (Colombia) | Alta |
| **DR-07** | Costo de infraestructura | ≤ $2.000 USD/mes en el MVP | Media |

---

## 3. VISTAS ARQUITECTURALES (C4)

Este documento utiliza el **modelo C4** (Context, Containers, Components, Deployment) para describir la arquitectura en distintos niveles de abstracción.

**Archivo Structurizr DSL:** `Taller_ParkEasy_Architecture_Grupo1.dsl`

**Cómo visualizar:**
1. Ir a https://structurizr.com/dsl
2. Copiar el contenido completo del archivo `Taller_ParkEasy_Architecture_Grupo1.dsl`
3. Hacer clic en **"Render"**
4. Seleccionar la vista deseada en el menú izquierdo:

| Clave en el DSL | Descripción |
|-----------------|-------------|
| `C4_L1_Context` | Nivel 1 — Diagrama de Contexto del Sistema |
| `C4_L2_Containers` | Nivel 2 — Diagrama de Contenedores |
| `C4_L3_OperacionService` | Nivel 3 — Componentes del Operacion Service |
| `C4_Deployment_Production` | Diagrama de Despliegue en AWS (Producción) |

### 3.1 C4 Nivel 1: Context Diagram

**Propósito:** Mostrar cómo ParkEasy se relaciona con sus usuarios y con los sistemas externos, sin entrar en los detalles internos del sistema.

**Elementos clave:**
- **Usuarios:**
  - *Conductor:* consulta disponibilidad, reserva espacios y paga digitalmente desde la web o app móvil
  - *Operador:* registra entradas manuales y gestiona incidentes desde el panel táctil en caseta
  - *Administrador:* consulta dashboards de ocupación, genera reportes y configura tarifas por zona
- **Sistema principal:** ParkEasy
- **Sistemas externos:**
  - *Cámaras LPR:* reconocimiento automático de placas vehiculares vía API REST, instaladas en los 3 parqueaderos
  - *Sistema de Cobro Legacy (VB6):* sistema existente integrado mediante adaptador SOAP para sincronizar cobros
  - *Wompi:* pasarela de pagos digitales (tarjeta, Nequi, Daviplata)
  - *Email/SMS Gateway:* envío de confirmaciones de reserva, notificaciones y facturas a conductores
  - *DIAN:* servicio estatal de facturación electrónica de Colombia

**Vista en Structurizr:** `"C4_L1_Context"`

### 3.2 C4 Nivel 2: Container Diagram

**Propósito:** Mostrar los contenedores que componen ParkEasy, las tecnologías usadas en cada uno y cómo se comunican entre sí.

**Contenedores principales:**

| Contenedor | Tecnología | Responsabilidad |
|------------|------------|-----------------|
| **Aplicación Web** | React / Next.js | Interfaz de conductor y administrador: disponibilidad, reservas, pagos y dashboard de reportes |
| **App Móvil** | React Native (Expo) | App para conductores: consulta de disponibilidad y reservas desde dispositivo móvil |
| **Panel Operador** | React / Electron | Interfaz táctil instalada en las casetas: registro manual de entradas, incidentes y ocupación |
| **API Gateway** | Kong / Express | Enruta solicitudes, valida tokens JWT y aplica rate limiting (100 req/min por IP) antes de los servicios |
| **Auth Service** | Node.js / Express | Autenticación y autorización: emite y valida JWT con roles (CONDUCTOR, OPERADOR, ADMIN) |
| **Operacion Service** | Node.js / Express | Gestiona reservas anticipadas, control de acceso (entrada/salida) e incidentes operativos |
| **Disponibilidad Service** | Node.js / Express | Monitorea y expone el estado de ocupación en tiempo real por parqueadero usando Redis como fuente principal |
| **Pagos Service** | Node.js / Express | Procesa pagos digitales (Wompi), calcula tarifas, genera facturas DIAN y sincroniza cobros con legacy VB6 |
| **Reportes Service** | Node.js / Express | Genera dashboards de ocupación y reportes de ingresos, tiempos y estadísticas para administradores |
| **Cache (Redis)** | AWS ElastiCache | Estado de disponibilidad de espacios en tiempo real; latencia de 1–2 ms sin impacto sobre PostgreSQL |
| **Base de Datos Principal** | PostgreSQL / AWS RDS | Reservas, vehículos, pagos y usuarios; escritura transaccional y lectura operacional |
| **Base de Datos Reportes** | PostgreSQL Read Replica | Históricos y analytics; réplica de lectura que aísla las queries pesadas del nodo principal de escritura |
| **Message Queue** | RabbitMQ / Amazon MQ | Eventos asíncronos entre servicios: `VehiculoIngresado`, `VehiculoSalido`, `ReservaCreada`, `IncidenteRegistrado` |

**Vista en Structurizr:** `"C4_L2_Containers"`

### 3.3 C4 Nivel 3: Component Diagrams

**Propósito:** Mostrar los componentes internos del Operacion Service, el servicio más crítico del sistema por concentrar reservas, acceso vehicular e incidentes.

**Servicio documentado:** Operacion Service

**Componentes:**

| Componente | Responsabilidad |
|------------|-----------------|
| **Operacion Router** | Expone los endpoints del servicio: `POST /reservas`, `POST /acceso/entrada`, `POST /acceso/salida`, `POST /incidentes` |
| **Auth Middleware** | Intercepta toda solicitud, valida el token JWT y verifica que el rol tenga permiso antes de continuar |
| **Reservas Controller** | Gestiona la creación, consulta y cancelación de reservas anticipadas |
| **Entrada Controller** | Orquesta el flujo de ingreso: solicita lectura al LPR, valida reserva activa, genera ticket y notifica al Disponibilidad Service |
| **Salida Controller** | Orquesta el flujo de salida: calcula tiempo de estadía, cierra el ticket de sesión, libera espacio y sincroniza con legacy |
| **Incidentes Controller** | Registra incidentes operativos y actualiza el estado del espacio afectado como no disponible |
| **Reservas Domain** | Aplica reglas de negocio: ventana de 5 min–2 horas, máximo 1 reserva activa por conductor, expiración automática a los 15 minutos de gracia |
| **Acceso Domain** | Aplica reglas de negocio: validación de reserva activa y cálculo del tiempo de estadía para el cobro |
| **Ticket Service** | Genera y valida tickets de acceso con código único por sesión de estacionamiento |
| **Reservas Repository** | CRUD de reservas sobre la base de datos principal (Sequelize) |
| **Acceso Repository** | CRUD de registros de entrada/salida y tickets activos sobre la base de datos principal |
| **Incidentes Repository** | Persistencia de incidentes y su estado de resolución |
| **Event Publisher** | Publica eventos en el Message Queue (AMQP): `VehiculoIngresado`, `VehiculoSalido`, `ReservaCreada`, `IncidenteRegistrado` |

**Vista en Structurizr:** `"C4_L3_OperacionService"`

**Flujo principal — ingreso automático por LPR:**
```
Cámara LPR detecta vehículo en la entrada
→ POST /acceso/entrada llega al API Gateway
→ Auth Middleware valida JWT
→ Entrada Controller recibe la placa
→ Acceso Domain consulta reserva activa en Redis (< 2 ms)
   → Si hay reserva activa: la asocia al ingreso
   → Si no hay reserva: verifica disponibilidad en PostgreSQL
→ Ticket Service genera ticket único de sesión
→ Entrada Controller notifica al Disponibilidad Service (reduce espacio disponible)
→ Entrada Controller sincroniza registro con Sistema Legacy (SOAP/XML)
→ Event Publisher publica "VehiculoIngresado" en el Message Queue
→ Acceso Repository persiste el registro de entrada en PostgreSQL
```

### 3.4 Vista de Deployment

**Propósito:** Mostrar cómo los contenedores se mapean a infraestructura real en AWS para el ambiente de producción.

**Vista en Structurizr:** `"C4_Deployment_Production"`

La infraestructura de producción está íntegramente en AWS (región us-east-1):

- **AWS CloudFront + S3:** CDN global para distribución del Web App (React/Next.js) y assets estáticos
- **AWS ECS Fargate Cluster:** 6 servicios backend con auto-scaling independiente por servicio
  - API Gateway: 2 tasks (auto-scaling hasta 6)
  - Auth Service: 2 tasks
  - Operacion Service: 2 tasks (auto-scaling hasta 8 en horas pico)
  - Disponibilidad Service: 2 tasks (auto-scaling hasta 6)
  - Pagos Service: 2 tasks
  - Reportes Service: 1 task
- **AWS Application Load Balancer:** balanceo de carga HTTPS hacia el ECS Cluster
- **AWS ElastiCache (Redis) Multi-AZ:** caché distribuido para disponibilidad en tiempo real
- **AWS RDS PostgreSQL Primary (db.t3.large) Multi-AZ:** base de datos principal con backups diarios
- **AWS RDS Read Replica:** réplica de lectura dedicada para el Reportes Service
- **AWS Amazon MQ (RabbitMQ) Multi-AZ:** broker de mensajes administrado
- **Expo EAS / App Stores:** build y distribución de la App Móvil React Native
- **Casetas Físicas (On-Premise):** PCs con Electron instalado para el Panel Operador

---

## 4. DECISIONES ARQUITECTURALES (ADRs)

Los documentos completos de cada ADR contienen el análisis detallado de alternativas, justificaciones, criterios de validación y firmas del equipo. A continuación se presenta el resumen ejecutivo de cada decisión.

### 4.1 ADR-001: Adoptar Service-Based Architecture para ParkEasy

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-001_Service_Based_Architecture_Grupo1.md`

**Resumen:** Se adopta Service-Based Architecture con 6 servicios independientes (Auth, Operacion, Disponibilidad, Pagos, Reportes + API Gateway) desplegados en AWS ECS Fargate, que comparten una base de datos PostgreSQL con esquemas separados y una réplica de lectura para reportes. Comunicación síncrona REST para flujos críticos y asíncrona (Amazon MQ) para flujos no bloqueantes.

**Alternativas consideradas:**
- *Monolito Modular:* descartado — no permite aislar fallos del flujo crítico vehicular ni escalar selectivamente. Un bug en reportes obliga a redesplegar toda la aplicación, incompatible con 0 downtime en horas pico (DR-03). La integración inestable con VB6 puede degradar el sistema completo.
- *Microservicios:* descartado — el costo de infraestructura superaría los $5.000 USD/mes (2.5× el presupuesto), el overhead operacional de service mesh y distributed tracing es inviable para 4 devs en 8 meses, y la latencia acumulada de múltiples llamadas de red encadenadas comprometería el SLA de 5s P95 (DR-01).

**Trade-off aceptado:** Acoplamiento por base de datos compartida a cambio de simplicidad operacional. Mitigado con esquemas separados por servicio y análisis estático en CI/CD que detecta consultas entre esquemas ajenos.

**Ver documento completo:** [ADR-001]

---

### 4.2 ADR-002: Adoptar PostgreSQL como Base de Datos Principal

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-002_PostgreSQL_Database_Grupo1.md`

**Resumen:** Se adopta PostgreSQL 15 en AWS RDS con configuración Multi-AZ (db.t3.large, 100 GB gp3) como base de datos principal, más una réplica de lectura exclusiva para el Reportes Service. Backups diarios con retención de 30 días y archivado a S3. Esquemas separados por servicio. Particionado por mes en tablas de alta inserción.

**Alternativas consideradas:**
- *MongoDB:* descartado — sin garantías ACID nativas en operaciones multi-documento. La asignación de espacio debe ser atómica para evitar doble booking simultáneo, y el modelo de datos de ParkEasy es inherentemente relacional (conductores → reservas → espacios → transacciones).
- *DynamoDB:* descartado — incompatible con las consultas relacionales de los reportes de ingresos y ocupación, costo impredecible con picos de 80 vehículos/hora, y curva de aprendizaje alta para el equipo.

**Trade-off aceptado:** Escalamiento de escrituras limitado verticalmente. Mitigado con particionado por mes y la opción de escalar la instancia o agregar réplicas si la carga supera el 70% de capacidad.

**Ver documento completo:** [ADR-002]

---

### 4.3 ADR-003: Adoptar Redis como Caché para Disponibilidad en Tiempo Real

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-003_Legacy_Integration_Grupo1.md`

**Resumen:** Se adopta Redis en AWS ElastiCache (cache.t3.micro, ~$25/mes) como caché distribuido del estado de disponibilidad de espacios. Almacena el estado de cada espacio (libre/ocupado/reservado), el conteo de disponibles por parqueadero y la expiración de reservas activas. TTL de respaldo de 60 segundos. Fallback a PostgreSQL si Redis no está disponible.

**Alternativas consideradas:**
- *Sin caché (consulta directa a PostgreSQL):* descartado — bajo la carga pico de 80 vehículos/hora, las consultas de disponibilidad desde la app, el LPR y los paneles de operador compiten con las escrituras críticas de PostgreSQL, comprometiendo el SLA de 5s P95 (DR-01).
- *Caché en memoria dentro de cada servicio:* descartado — con múltiples réplicas horizontales corriendo en paralelo, cada instancia mantiene su propia copia del estado y dos conductores pueden ver disponibilidades distintas en el mismo instante, lo que puede derivar en doble asignación de espacios.

**Trade-off aceptado:** Complejidad adicional en la gestión de invalidación del caché. Mitigada con TTL de 60 segundos y modo de degradación controlada (fallback a PostgreSQL si Redis no responde).

**Ver documento completo:** [ADR-003]

---

## 5. TECNOLOGÍAS Y HERRAMIENTAS

### 5.1 Stack Tecnológico

| Capa | Tecnología | Versión | Justificación |
|------|------------|---------|---------------|
| **Frontend Web** | React / Next.js | 14.x | SSR para tiempos de carga rápidos; ecosystem maduro con soporte responsive |
| **App Móvil** | React Native (Expo) | SDK 50 | Codebase compartido con el frontend web; distribución vía Expo EAS |
| **Panel Operador** | React + Electron | Electron 29 | App de escritorio instalable en PCs de casetas; funciona con conectividad reducida |
| **Estilos** | Tailwind CSS | 3.x | Desarrollo rápido de UI; componentes optimizados para pantalla táctil del operador |
| **Backend (servicios)** | Node.js + Express | 20 LTS | JavaScript full-stack, I/O asíncrono eficiente, expertise del equipo |
| **Type Safety** | TypeScript | 5.x | Reduce errores en integraciones críticas (LPR, SOAP, Wompi) |
| **ORM** | Sequelize | 6.x | Compatible con PostgreSQL y TypeScript; migraciones versionadas |
| **Base de Datos** | PostgreSQL | 15.x | ACID completo, queries relacionales complejos para reportes. Ver ADR-002 |
| **Caché** | Redis | 7.x | Caché distribuido de disponibilidad en tiempo real (1–2 ms). Ver ADR-003 |
| **Message Queue** | RabbitMQ | 3.12 | Broker confiable para eventos asíncronos entre servicios |
| **API Gateway** | Kong OSS | 3.x | Enrutamiento, rate limiting y validación JWT centralizada |
| **Autenticación** | JWT RS256 + bcrypt | — | Stateless auth con expiración 1h; contraseñas con cost factor 12 |

### 5.2 Servicios Cloud

**Proveedor:** AWS (Amazon Web Services)

| Servicio | Uso | Costo estimado/mes |
|----------|-----|--------------------|
| **CloudFront + S3** | CDN para Web App y assets estáticos | $30 |
| **Application Load Balancer** | Balanceo de carga HTTPS hacia ECS | $25 |
| **ECS Fargate** | Hosting de los 6 servicios backend con auto-scaling | $750 |
| **RDS PostgreSQL Multi-AZ (db.t3.large)** | Base de datos principal con failover automático | $220 |
| **RDS Read Replica** | Réplica de lectura exclusiva para Reportes Service | $110 |
| **ElastiCache Redis (cache.t3.micro)** | Caché distribuido de disponibilidad en tiempo real | $25 |
| **Amazon MQ (RabbitMQ)** | Message broker administrado Multi-AZ | $50 |
| **S3** | Backups de BD y archivado de facturas ≥ 5 años | $15 |
| **CloudWatch** | Logs, métricas y alertas centralizadas | $40 |
| **Route 53 + ACM** | DNS y certificados TLS administrados | $5 |
| **Secrets Manager** | Gestión segura de credenciales y secretos | $15 |
| **Expo EAS** | Build y distribución de la App Móvil | $30 |
| **TOTAL** | | **$1.315/mes** |

**Validación DR-07:** $1.315/mes representa el 65,8% del límite de $2.000 USD/mes. Margen disponible de $685/mes para crecimiento y servicios adicionales.

### 5.3 Servicios Externos

| Servicio | Uso | Costo |
|----------|-----|-------|
| **Cámaras LPR** | Control de acceso vehicular automático vía API REST | Infraestructura existente (sin costo adicional) |
| **Wompi** | Procesamiento de pagos digitales al salir (tarjeta, Nequi, Daviplata) | 2,9% + comisión fija por transacción |
| **Email/SMS Gateway** | Confirmaciones de reserva, notificaciones y facturas | ~$15/mes (hasta 40.000 mensajes) |
| **DIAN (API)** | Remisión y validación de facturas electrónicas | Gratuito (obligatorio por normativa colombiana) |

---

## 6. SEGURIDAD

### 6.1 Autenticación y Autorización

**Mecanismo:** JWT firmado con RS256 (par de claves pública/privada), expiración de 1 hora con refresh token de rotación automática.

**Flujo:**
1. El usuario envía email y contraseña al endpoint `POST /auth/login` a través del API Gateway
2. El Auth Service valida las credenciales contra PostgreSQL (contraseña hasheada con bcrypt, cost factor 12)
3. Si son válidas, genera un JWT con payload: `userId`, `role` (CONDUCTOR / OPERADOR / ADMIN) y `exp` (1 hora)
4. El cliente incluye el JWT en cada petición en el header: `Authorization: Bearer <token>`
5. El API Gateway (Kong) valida la firma del JWT con la clave pública antes de enrutar la solicitud
6. Cada servicio verifica el rol del JWT para autorizar la operación; responde `HTTP 403` si no tiene permiso

**Roles:**
- `conductor`: consulta disponibilidad sin autenticación, realiza reservas, accede solo a sus propios datos y facturas
- `operador`: registra entradas/salidas manuales y gestiona incidentes; acceso exclusivo al Panel Operador en caseta
- `admin`: acceso a dashboard, reportes y configuración de tarifas; solo lectura sobre datos operativos globales

### 6.2 Protección de Datos

**Cumplimiento Ley 1581 (Colombia):**
- [x] Consentimiento explícito al registrarse: política de privacidad visible y aceptación obligatoria
- [x] Política de privacidad accesible desde todas las interfaces del sistema
- [x] Encriptación en tránsito: TLS 1.2+ en todas las comunicaciones externas e internas
- [x] Encriptación en reposo: AES-256 activado en AWS RDS y ElastiCache
- [x] Derecho de acceso, rectificación y eliminación de datos personales habilitado en el perfil de conductor
- [x] Log de auditoría para todas las operaciones sensibles: accesos, pagos y cambios de tarifa

**Datos sensibles:**
- **Placas vehiculares:** almacenadas en el esquema `access`, acceso restringido al Operacion Service; cifradas en reposo en RDS
- **Datos de pago:** **nunca almacenados en ParkEasy**; Wompi gestiona la tokenización y el procesamiento completo bajo PCI-DSS. ParkEasy solo almacena el ID de transacción devuelto por Wompi

### 6.3 Protección de APIs

| Medida | Implementación |
|--------|----------------|
| **HTTPS / TLS 1.2+** | Obligatorio en todas las comunicaciones; certificados gestionados por AWS Certificate Manager |
| **Rate limiting** | 100 requests/minuto por IP, configurado en Kong OSS |
| **Input validation** | Esquemas de validación en todos los endpoints; rechazo inmediato de payloads malformados con `HTTP 400` |
| **SQL injection** | Sequelize prepared statements; sin concatenación de strings en queries SQL |
| **XSS** | React auto-escaping en el frontend + Content Security Policy header en todas las respuestas |
| **CORS** | Whitelist restringida al dominio del frontend de ParkEasy únicamente |
| **Secrets** | AWS Secrets Manager: ninguna credencial hardcodeada en código fuente ni en variables de entorno directas |
| **Auditoría** | Log de todas las operaciones sensibles retenido 90 días en CloudWatch |

---

## 7. DESPLIEGUE E INFRAESTRUCTURA

### 7.1 Ambientes

| Ambiente | Propósito | URL |
|----------|-----------|-----|
| **Development** | Desarrollo local con Docker Compose; todos los servicios en localhost | localhost:3000 |
| **Staging** | Pre-producción en AWS con datos sintéticos; validación de integraciones LPR, Wompi sandbox y DIAN habilitador | staging.parkeasy.co |
| **Production** | Ambiente de producción para los 3 parqueaderos en operación real | app.parkeasy.co |

### 7.2 Estrategia de Despliegue

**Método:** Rolling Update (ECS Fargate) — sin downtime

**Proceso:**
1. Push a la rama `main` → GitHub Actions ejecuta build, tests unitarios e integración, y despliega automáticamente a **Staging**
2. QA valida en Staging; si aprueba, el equipo crea un tag de release (`v*.*.*`) que requiere aprobación de 2 revisores para desplegar a **Production**
3. ECS Fargate realiza Rolling Update: las nuevas instancias pasan health checks (`GET /health`) antes de que las antiguas sean terminadas; máximo 1 instancia fuera de servicio simultáneamente
4. Si los health checks fallan en los primeros 5 minutos post-deploy, rollback automático a la versión anterior

**Para cambios de esquema en base de datos:** todas las migraciones deben ser backward-compatible. Si se requiere un breaking change, se usa Blue-Green deployment con ventana de 15 minutos anunciada con 48 horas de anticipación, fuera de las franjas de horas pico.

### 7.3 Configuración de Infraestructura

**ECS Services:**

| Service | Instancias base | CPU | RAM | Máx. instancias |
|---------|-----------------|-----|-----|-----------------|
| API Gateway | 2 | 0,5 vCPU | 1 GB | 6 |
| Auth Service | 2 | 0,5 vCPU | 1 GB | 4 |
| Operacion Service | 2 | 1 vCPU | 2 GB | 8 (horas pico) |
| Disponibilidad Service | 2 | 1 vCPU | 2 GB | 6 (horas pico) |
| Pagos Service | 2 | 0,5 vCPU | 1 GB | 4 |
| Reportes Service | 1 | 0,5 vCPU | 1 GB | 2 |

Auto-scaling: trigger CPU > 70% por 5 minutos → +1 instancia. Scale down si CPU < 30% por 10 minutos consecutivos.

**Base de Datos:**
- Instancia principal: db.t3.large (2 vCPU, 8 GB RAM) — Multi-AZ activo
- Réplica de lectura: db.t3.medium (exclusiva para Reportes Service)
- Storage: 100 GB SSD gp3 (3.000 IOPS) con autoescalado hasta 300 GB
- Multi-AZ: Sí — failover automático en menos de 60 segundos (DR-03)
- Backups: diarios automáticos, retención 30 días; archivado de facturas en S3 por mínimo 5 años (DR-05)
- Encriptación: en reposo (AES-256) y en tránsito (TLS) activadas en RDS

### 7.4 Monitoreo y Alertas

**Métricas clave:**
- ECS CPU > 80% sostenido 5 min - Threshold: 80% - Alerta: Email al equipo + trigger auto-scale
- RDS CPU > 85% sostenido 5 min - Threshold: 85% - Alerta: Email al equipo + evaluar upgrade de instancia
- ALB 5xx errors > 10/min - Threshold: 10 errores/min - Alerta: PagerDuty (alerta crítica 24/7)
- Latencia P95 > 4 segundos - Threshold: 4s - Alerta: PagerDuty (SLA en riesgo)
- Redis memoria > 80% - Threshold: 80% - Alerta: Email al equipo
- Amazon MQ queue > 500 mensajes - Threshold: 500 msgs - Alerta: Email al equipo
- RDS disk > 85% - Threshold: 85% - Alerta: Email inmediato al equipo

**Herramientas:**
- AWS CloudWatch: logs estructurados en JSON y métricas de infraestructura de todos los servicios
- Grafana OSS: dashboards de métricas de negocio (reservas/hora, ingresos en tiempo real, ocupación por sede)
- Sentry: error tracking en producción con alertas por nuevo tipo de error detectado
- Amazon MQ Console: monitoreo del estado de colas y consumidores del message broker

---

## 8. CALIDAD Y ATRIBUTOS

### 8.1 Mapa de Atributos a Decisiones

| Atributo | Objetivo (del SRS) | Decisión arquitectural |
|----------|--------------------|------------------------|
| **Performance** | RNF-01: ≤ 5s P95 entrada/salida; ≤ 500ms disponibilidad | Redis en Disponibilidad Service (ADR-003) + Operacion Service consulta Redis antes de PostgreSQL + índices en `plate`, `space_id`, `start_time` (ADR-002) |
| **Availability** | RNF-02: ≥ 99,5% horario operativo; 0 downtime en horas pico | RDS Multi-AZ con failover < 60s (ADR-002) + ElastiCache Multi-AZ (ADR-003) + aislamiento de fallos: caída de Reportes Service no afecta el acceso vehicular (ADR-001) |
| **Scalability** | RNF-03: 450 → 1.200 espacios sin rediseño | ECS Fargate auto-scaling independiente por servicio (ADR-001) + réplica de lectura para reportes (ADR-002) + Redis escala con la arquitectura sin rediseño (ADR-003) |
| **Security** | RNF-04: PCI-DSS + Ley 1581/2012 | Pagos Service aislado reduce scope PCI-DSS (ADR-001) + encriptación en reposo y tránsito en RDS (ADR-002) + JWT RS256 + Kong rate limiting |
| **Cost** | RNF-07: ≤ $2.000 USD/mes | Service-Based vs microservicios ahorra ~$3.700/mes (ADR-001). Total estimado: $1.315/mes (65,8% del presupuesto) |
| **Compliance** | RNF-06: facturas ≥ 5 años (DIAN) | Backups automáticos 30 días en RDS + archivado inmutable a S3 (ADR-002) |

### 8.2 Tácticas Arquitecturales Aplicadas

**Para Performance:**
- ✅ Caché distribuido de disponibilidad en Redis: consultas resueltas en 1–2 ms sin impacto sobre PostgreSQL (ADR-003)
- ✅ Réplica de lectura dedicada para el Reportes Service: queries analíticas no compiten con escrituras críticas
- ✅ Connection pooling en PostgreSQL para reducir overhead de conexiones concurrentes
- ✅ Índices en campos críticos: `plate` (acceso), `space_id` y `start_time` (reservas), `transaction_id` (pagos)
- ✅ CDN CloudFront para assets estáticos del Web App y la App Móvil

**Para Availability:**
- ✅ RDS Multi-AZ con failover automático en menos de 60 segundos
- ✅ ElastiCache Multi-AZ y Amazon MQ Multi-AZ para todos los componentes de infraestructura críticos
- ✅ Health checks en todos los servicios ECS con auto-restart ante fallos
- ✅ Graceful degradation: fallo del Reportes Service o Notification Service no interrumpe el flujo vehicular
- ✅ Modo de contingencia manual en el Panel Operador (Electron) para operar sin conectividad completa

**Para Scalability:**
- ✅ Auto-scaling horizontal independiente por servicio en ECS Fargate sin redesplegar los demás
- ✅ Servicios stateless: autenticación por JWT, sin sesiones en memoria compartida entre réplicas
- ✅ Particionado por mes en tablas de alta inserción (registros de acceso y transacciones de pago)
- ✅ Redis escala horizontalmente junto con la arquitectura sin cambios de diseño

**Para Maintainability:**
- ✅ Dominios de negocio separados en servicios con responsabilidades únicas y contratos API bien definidos
- ✅ Testing automatizado con coverage mínimo del 80% en funciones críticas de dominio
- ✅ Documentación de APIs con Swagger/OpenAPI 3.0 publicada por cada servicio
- ✅ Logging estructurado en JSON con campo de correlación para trazar flujos entre servicios

### 8.3 Testing Strategy

| Tipo | Herramienta | Coverage objetivo |
|------|-------------|-------------------|
| **Unit tests** | Jest / Vitest | 80% de funciones críticas (ReservasDomain, AccesoDomain, LegacySOAPAdapter) |
| **Integration tests** | Supertest + Docker Compose | Flujos completos por servicio: reserva, ingreso, salida, pago y notificación |
| **E2E tests** | Playwright | 5 flujos principales: reserva desde web, ingreso LPR, pago digital, emisión factura, reporte mensual |
| **Load tests** | k6 | 200 transacciones concurrentes sin degradación > 20% en latencia P95 |
| **Security tests** | OWASP ZAP | Scan anual de vulnerabilidades en todos los endpoints públicos |

---

## 9. RIESGOS Y DEUDA TÉCNICA

### 9.1 Riesgos Técnicos Identificados

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|--------------|---------|------------|
| **R-01** | Sistema legacy VB6 sin documentación completa — integración SOAP debe hacerse por ingeniería inversa del protocolo | Alta | Alto | Encapsular en `LegacySOAPAdapter` dentro del Operacion Service y Pagos Service. Captura de tráfico SOAP real en Staging. Tests de integración exhaustivos antes de salir a producción. |
| **R-02** | Fallo de las cámaras LPR en horas pico bloquea el ingreso automático de vehículos | Media | Alto | Modo de contingencia manual implementado en el Panel Operador (Electron). Operadores capacitados para activarlo en menos de 30 segundos. El sistema no pierde disponibilidad, solo baja a modo manual. |
| **R-03** | Downtime de Wompi bloquea el procesamiento de pagos digitales en salida | Baja | Alto | Queue de reintentos automáticos en Pagos Service (hasta 3 intentos con backoff exponencial). Cobro en efectivo al operador siempre disponible como alternativa; el operador lo registra en el Panel. |
| **R-04** | Base de datos compartida genera coupling no intencional entre servicios si no se respetan los esquemas | Alta | Medio | Esquemas separados por servicio en PostgreSQL. Análisis estático en CI/CD que detecta queries a esquemas ajenos. Code review obligatorio para toda nueva consulta de base de datos. |
| **R-05** | Equipo de 4 personas concentra conocimiento crítico; riesgo ante rotación de integrantes | Alta | Alto | Documentación exhaustiva: SAD, ADRs, Swagger por servicio y diagramas C4. Code reviews obligatorios entre todos los integrantes. Rotación de responsabilidades por servicio durante el desarrollo. |
| **R-06** | Fallo de Redis deja al Disponibilidad Service sin caché de estado en tiempo real | Baja | Medio | Fallback automático a consulta directa sobre PostgreSQL (modo degradado controlado). CloudWatch alerta si Redis no responde en 5 segundos. ElastiCache Multi-AZ reduce la probabilidad de fallo de infraestructura. |

### 9.2 Deuda Técnica Aceptada

| Ítem | Justificación | Plan de resolución |
|------|---------------|--------------------|
| **Base de datos compartida (no DB por servicio)** | Time-to-market de 8 meses y complejidad operacional inviable para 4 developers. Separar la BD por servicio añade ~2 meses adicionales de desarrollo en el MVP. | Evaluar al finalizar el MVP si el volumen supera 3.000 operaciones/día o si el equipo crece a 8+ personas. Priorizar primero el Pagos Service por su scope PCI-DSS. |
| **Sin distributed tracing** | Costo y complejidad de Jaeger o Zipkin no se justifican con 6 servicios en MVP. Los logs estructurados con campo de correlación en CloudWatch son suficientes para esta fase. | Implementar si el debugging de flujos entre servicios consume más de 2 horas semanales del equipo. |
| **Sin circuit breakers formales** | Los reintentos con backoff exponencial son suficientes para el volumen de carga del MVP. La configuración de Hystrix o Resilience4j añade complejidad no justificada hoy. | Implementar si se detectan cascading failures entre servicios en el ambiente de producción. |
| **Amazon MQ en configuración básica (no cluster activo-activo)** | Para mantener el costo dentro del presupuesto del MVP. El broker es suficiente para el volumen inicial de eventos asíncronos. | Migrar a configuración Multi-AZ activa de Amazon MQ al finalizar el MVP si el volumen supera 10.000 eventos/día. |

### 9.3 Supuestos Críticos

Los siguientes supuestos, tomados del [SRS], son condiciones necesarias para que la arquitectura funcione según lo diseñado:

1. **SUP-01:** El presupuesto de infraestructura es $2.000 USD/mes — pendiente de confirmación formal escrita con el cliente antes de iniciar el desarrollo
2. **SUP-02:** Las cámaras LPR instaladas en los 3 parqueaderos exponen una API REST documentada y funcional para el equipo de desarrollo
3. **SUP-03:** El sistema legacy VB6 acepta peticiones SOAP; la integración se realizará por ingeniería inversa del protocolo dado que la documentación original es incompleta
4. **SUP-04:** Wompi dispone de entorno sandbox con datos de prueba para que el equipo valide la integración de pagos antes de salir a producción
5. **SUP-05:** Los 3 parqueaderos tienen conectividad a internet estable con latencia inferior a 100 ms hacia el backend en AWS
6. **SUP-06:** Cada caseta cuenta con un PC o tableta con Windows para instalar el Panel Operador (Electron)

---

## APROBACIONES

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | Juan Camilo Alba | __________ | 19/03/2026 |
| **Arquitecto** | Laura Garzón | Laura Garzon | 19/03/2026 |
| **Desarrollador 1** | Carlos Villegas | __________ | 19/03/2026 |
| **Desarrollador 2** | Arley Bernal | __________ | 19/03/2026 |

---

**Fin del Documento SAD**
