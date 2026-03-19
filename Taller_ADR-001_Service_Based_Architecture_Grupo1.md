# ADR-001: Adoptar Service-Based Architecture para ParkEasy

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Juan Camilo Alba, Laura Garzón, Carlos Villegas, Arley Bernal  
**Relacionado con:** RF-01 a RF-08, RNF-01, RNF-02, RNF-03, DR-01, DR-02, DR-03, DR-04, DR-07  
**Grupo:** 1

---

## Contexto y Problema

Necesitamos decidir el estilo arquitectural para ParkEasy. El sistema debe:
- Ser entregado en 8 meses por 4 desarrolladores
- Procesar 1.200 entradas/salidas por día con picos de 80 vehículos/hora sin downtime en horas pico
- Escalar de 450 a 1.200 espacios sin rediseño
- Mantenerse dentro del presupuesto de $2.000 USD/mes en infraestructura
- Integrarse con cámaras LPR (REST), sistema de cobro legacy VB6 (SOAP), pasarela Wompi y DIAN

**Alternativas consideradas:**
1. Monolito Modular
2. Microservicios
3. Service-Based Architecture

---

## Drivers de Decisión

- **DR-01:** Performance de entrada/salida - ≤ 5 segundos P95 (LPR a apertura de barrera) (Prioridad: Alta)
- **DR-02:** Escalabilidad - 450 a 1.200 espacios sin rediseño arquitectural (Prioridad: Alta)
- **DR-03:** Disponibilidad en horas pico - 0 downtime en franjas 7–10 am y 5–8 pm (Prioridad: Alta)
- **DR-04:** Integración con sistema legacy - Adaptador SOAP/VB6 no reemplazable en el MVP (Prioridad: Alta)
- **DR-06:** Seguridad y protección de datos - PCI-DSS + Ley 1581/2012 (Prioridad: Alta)
- **DR-07:** Costo de infraestructura - Máximo $2.000 USD/mes en el MVP (Prioridad: Media)
- **DR-08:** Capacidad del equipo y time-to-market - 8 meses, 4 desarrolladores (Prioridad: Alta)

---

## Alternativas Consideradas

### Alternativa 1: Monolito Modular

**Descripción:**
Una única aplicación backend con módulos internos bien definidos (acceso, reservas, pagos, notificaciones, admin), desplegada como un solo proceso. Base de datos compartida, un único artefacto desplegable.

**Pros:**
- Desarrollo más rápido al inicio: un solo proyecto sin overhead de comunicación entre servicios.
- Menor complejidad operacional: un único proceso, una sola pipeline de CI/CD.
- Transacciones ACID simples: operaciones cross-dominio ocurren en una sola transacción de base de datos.
- Costo mínimo de infraestructura: un solo contenedor, estimado $300–500 USD/mes.

**Contras:**
- No permite escalamiento selectivo: el módulo de acceso LPR no puede escalarse de forma independiente del módulo de administración.
- Despliegues de alto riesgo: un bug en reportes obliga a redesplegar toda la aplicación, incluido el flujo de acceso vehicular.
- Sin aislamiento de fallos: un error en la integración con el legacy VB6 puede degradar el sistema completo, incluido el flujo crítico de barreras.
- Conflictos frecuentes en el repositorio: 4 desarrolladores trabajando sobre el mismo artefacto generan fricciones constantes en el control de versiones.

---

### Alternativa 2: Microservicios

**Descripción:**
Cada capacidad de negocio se despliega como un servicio completamente autónomo, con su propia base de datos y ciclo de despliegue, comunicándose exclusivamente por red. Para el dominio de ParkEasy implicaría 10–15 servicios independientes.

**Pros:**
- Escalabilidad extrema e independiente por servicio.
- Aislamiento total de fallos entre dominios de negocio.
- Soberanía de datos real: cada servicio es propietario exclusivo de su esquema y base de datos.
- Flexibilidad tecnológica: cada servicio puede adoptar el stack más adecuado para su función.

**Contras:**
- Overhead operacional inviable: service mesh, distributed tracing, gestión de secretos y orquestación avanzada exceden la capacidad de 4 desarrolladores en 8 meses.
- Latencia acumulada en el flujo crítico: el ingreso vehicular requiere 3–5 llamadas de red encadenadas, comprometiendo el SLA de 5 seg P95 (DR-01).
- Costo de infraestructura prohibitivo: base de datos por servicio, brokers de mensajes y herramientas de observabilidad distribuida superan los $5.000 USD/mes (DR-07).
- Transacciones distribuidas complejas: operaciones como "reservar + cobrar + registrar factura" requieren implementar el patrón Saga o 2PC, añadiendo semanas de desarrollo que el MVP no puede absorber.

---

## Decisión

Adoptamos **Service-Based Architecture** con 5 servicios de grano grueso, cada uno representando un dominio de negocio claramente delimitado:

1. **Access Service** – Integración con cámaras LPR, control de barrera, registro de entradas/salidas, modo de contingencia manual para operadores.
2. **Reservation Service** – Disponibilidad de espacios en tiempo real, gestión de reservas anticipadas, liberación automática por expiración.
3. **Payment Service** – Procesamiento de pagos digitales (Wompi), cálculo de tarifas, emisión de facturas electrónicas (DIAN), sincronización con el sistema legacy VB6 vía adaptador SOAP.
4. **Notification Service** – Envío de emails y SMS: confirmaciones de reserva, facturas y alertas de incidentes.
5. **Admin Service** – Dashboard de ocupación en tiempo real, reportes de ingresos, configuración de tarifas por zona.

Cada servicio:
- Tiene un dominio de negocio claramente delimitado
- Se despliega de forma independiente en AWS ECS Fargate
- Comparte una base de datos PostgreSQL con schemas separados por servicio (`access`, `reservations`, `payments`, `notifications`, `admin`)
- Se comunica síncronamente vía HTTP/REST cuando se requiere respuesta inmediata
- Publica eventos a RabbitMQ para comunicación asíncrona en flujos no bloqueantes
- Es accesible desde los clientes a través de un API Gateway (Kong OSS)

---

## Justificación

### Por qué Service-Based y no Monolito:

ParkEasy tiene una restricción de 0 downtime en horas pico (DR-03) y la integración con el legacy VB6 es una fuente conocida de inestabilidad. En un monolito, un error en esa integración podría bloquear threads del servidor y degradar el flujo completo de acceso vehicular. Con servicios independientes, el Access Service opera aunque Payment Service esté degradado.

La escalabilidad selectiva requerida (DR-02) tampoco es posible con un monolito: escalar el módulo de acceso implica escalar también el de reportes, que tiene carga casi nula en horas pico, incrementando el costo innecesariamente.

### Por qué Service-Based y no Microservicios:

El equipo de 4 desarrolladores y el presupuesto de $2.000 USD/mes hacen inviable el overhead operacional de microservicios (DR-07, DR-08). El costo estimado de infraestructura para microservicios superaría los $5.000 USD/mes, 2.5 veces el presupuesto disponible.

El flujo de entrada vehicular (SLA de 5 seg P95, DR-01) se vería comprometido por la latencia acumulada de múltiples llamadas de red encadenadas entre microservicios. Con Service-Based y base de datos compartida, el Access Service consulta el estado de reservas mediante una query SQL directa, sin latencia de red adicional entre servicios.

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Access Service consulta PostgreSQL directamente sin llamadas de red en el flujo crítico. Estimado 2–3 seg incluyendo respuesta de la API LPR. |
| DR-02 | ECS Fargate permite auto-scaling horizontal de cada servicio de forma independiente. Parqueaderos adicionales son configuración, no código nuevo. |
| DR-03 | Fallos en servicios no críticos no afectan el Access Service. Despliegues rolling por servicio sin downtime global. |
| DR-04 | Adaptador SOAP/VB6 encapsulado exclusivamente en Payment Service. El resto del sistema no depende de su disponibilidad. |
| DR-06 | Payment Service aislado reduce el scope de certificación PCI-DSS. Datos de placas gestionados con encriptación en reposo en Access Service. |
| DR-07 | Estimado $1.200–1.600 USD/mes con 5x ECS Fargate t3.small + RDS db.t3.medium + RabbitMQ + Kong OSS. |
| DR-08 | 5 servicios bien delimitados permiten trabajo en paralelo. Estimado 1.5 meses por servicio con un desarrollador asignado. |

---

## Consecuencias

### Positivas:

1. **Aislamiento de fallos en el flujo crítico:** Un fallo en Notification Service o Admin Service no interrumpe el acceso vehicular. El Access Service opera de forma autónoma.
2. **Escalabilidad selectiva:** En horas pico, solo Access Service y Reservation Service requieren réplicas adicionales; Admin Service puede operar con una única instancia.
3. **Despliegues de bajo riesgo:** Un hotfix en Payment Service se despliega sin afectar al resto del sistema ni interrumpir el flujo de barreras.
4. **Trabajo en paralelo del equipo:** Cada desarrollador puede ser responsable de 1–2 servicios con interfaces bien definidas, reduciendo los conflictos de merge.
5. **Encapsulación de la inestabilidad legacy:** La integración VB6 queda contenida en Payment Service y no contamina los demás dominios.
6. **Time-to-market alcanzable:** No se requiere infraestructura compleja desde el día 1. La complejidad operacional se añade de forma incremental.

### Negativas (y mitigaciones):

1. **Acoplamiento por base de datos compartida**
   - **Riesgo:** Un cambio de schema puede impactar múltiples servicios si no se coordina.
   - **Mitigación:** Schemas separados por servicio en PostgreSQL. Todo cambio de schema requiere revisión de impacto y se versiona con Flyway. Los servicios acceden a datos de otros dominios exclusivamente vía REST, nunca por query directa a schema ajeno.

2. **Sin soberanía de datos estricta**
   - **Riesgo:** Un desarrollador puede realizar queries directas al schema de otro servicio, violando el encapsulamiento de dominio.
   - **Mitigación:** Linting rules que detecten y bloqueen queries entre schemas. Code reviews obligatorios para toda nueva query de base de datos. Repository pattern en cada servicio.

3. **Coordinación de transacciones cross-servicio**
   - **Riesgo:** La operación "registrar entrada + descontar espacio reservado" involucra dos servicios; un fallo parcial puede dejar el estado inconsistente.
   - **Mitigación:** Outbox Pattern para operaciones críticas: el Access Service escribe el evento en una tabla `outbox` dentro de la misma transacción PostgreSQL, y un worker lo publica a RabbitMQ de forma garantizada.

4. **Mayor complejidad operacional que un monolito**
   - **Riesgo:** 5 servicios implican 5 pipelines de CI/CD, 5 imágenes Docker y mayor superficie de configuración.
   - **Mitigación:** Monorepo con scripts de build compartidos. CloudWatch centralizado para logs de todos los servicios con correlación por `requestId` y un único dashboard operacional.

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó el Monolito:

El monolito fue descartado por la imposibilidad de aislar fallos en el flujo crítico de acceso vehicular y por la incapacidad de escalar selectivamente. La restricción de 0 downtime en horas pico (DR-03) es incompatible con un esquema de despliegue donde cualquier cambio, en cualquier módulo, requiere redesplegar la aplicación completa. La integración inestable con el legacy VB6 agrava este riesgo: en un monolito, un fallo en esa integración puede degradar el sistema completo.

**Cuándo sería la mejor opción:**
- Equipo de 1–2 desarrolladores sin experiencia en sistemas distribuidos.
- MVP con plazo menor a 3 meses y sin requisitos de disponibilidad diferenciada por módulo.
- Sin integraciones externas inestables o heterogéneas.

### Por qué se descartaron los Microservicios:

Los microservicios fueron descartados por la combinación de tres restricciones simultáneas: equipo de 4 personas, presupuesto de $2.000 USD/mes y plazo de 8 meses. El costo estimado de infraestructura superaría los $5.000 USD/mes, incumpliendo DR-07 por un factor de 2.5. Adicionalmente, el SLA de 5 seg P95 para el flujo de entrada vehicular (DR-01) es difícil de garantizar con múltiples llamadas de red encadenadas entre microservicios autónomos.

**Cuándo sería la mejor opción:**
- Equipos de 10 o más desarrolladores con experiencia en sistemas distribuidos.
- Escalabilidad extrema requerida (más de 10.000 usuarios concurrentes, más de 50 parqueaderos).
- Presupuesto de infraestructura superior a $5.000 USD/mes.
- Dominios de negocio totalmente independientes con equipos dedicados por dominio.

---

## Validación

- [x] Cumple con DR-01: Access Service consulta PostgreSQL directamente; sin llamadas de red adicionales en el flujo crítico. Estimado 2–3 seg.
- [x] Cumple con DR-02: ECS Fargate permite auto-scaling horizontal por servicio sin rediseño arquitectural hasta 1.200 espacios.
- [x] Cumple con DR-03: Despliegues rolling por servicio y aislamiento de fallos garantizan 0 downtime en el flujo de acceso durante horas pico.
- [x] Cumple con DR-04: Adaptador SOAP/VB6 encapsulado en Payment Service; fallo del legacy no detiene el flujo de acceso ni de reservas.
- [x] Cumple con DR-06: Scope de PCI-DSS reducido a Payment Service. Datos de placas encriptados en reposo gestionados exclusivamente por Access Service.
- [x] Cumple con DR-07: Estimado $1.200–1.600 USD/mes. Margen del 20–40% sobre el presupuesto disponible.
- [x] Cumple con DR-08: 5 servicios permiten trabajo en paralelo; 1.5 meses por servicio con 1 desarrollador asignado, alcanzable en 8 meses.

---

## Notas Adicionales

Esta decisión se revisará al finalizar el MVP (mes 8) cuando se evalúe la expansión a 6 parqueaderos y 1.200 espacios. Si el volumen supera las 3.000 entradas/salidas diarias o el equipo crece a 8 o más desarrolladores, se evaluará migrar a base de datos por servicio, implementar CQRS en el Admin Service y reemplazar el sistema legacy VB6.

---

## Referencias

- [SRS] Software Requirements Specification – ParkEasy v1.0, Grupo 1 (18/03/2026)
- [ENUNCIADO] Taller: Documentación Arquitectural Completa – ParkEasy, Pontificia Universidad Javeriana, 2026
- [EJEMPLO] ADR-001 CourtBooker – Adoptar Service-Based Architecture (material de referencia de clase)
- Architectural Decision Records (ADRs). https://adr.github.io/

---

**Estado final:** ACEPTADO

**Firmas del equipo:**
- Juan Camilo Alba: __________ - Fecha: 19/03/2026
- Laura Garzón: __________ - Fecha: 19/03/2026
- Carlos Villegas: __________ - Fecha: 19/03/2026
- Arley Bernal: __________ - Fecha: 19/03/2026
