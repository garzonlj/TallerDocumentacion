# ADR-001: Adoptar Service-Based Architecture para ParkEasy

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Juan Camilo Alba, Laura Garzón, Carlos Villegas, Arley Bernal  
**Relacionado con:** RF-01 a RF-08, RNF-01, RNF-02, RNF-03, DR-01, DR-02, DR-03, DR-07  
**Grupo:** 1

---

## Contexto y Problema

ParkEasy necesita digitalizar la operación de 3 parqueaderos en Bogotá (Zona T, Unicentro y Andino) con 450 espacios actuales y proyección de crecer hasta 1.200 espacios (6 parqueaderos) sin rediseño. El sistema debe procesar aproximadamente 1.200 entradas/salidas por día con picos de 80 vehículos/hora en horas críticas, donde el downtime es inaceptable.

El problema central es elegir un estilo arquitectural que permita construir un MVP funcional en 8 meses con un equipo de 4 desarrolladores, dentro de un presupuesto de infraestructura de $2.000 USD/mes, sin sacrificar la disponibilidad ni el desempeño crítico del flujo de entrada/salida (≤ 5 segundos P95). Adicionalmente, el sistema debe integrarse con componentes externos heterogéneos: cámaras LPR (REST), un sistema de cobro legacy en VB6 (SOAP, escasamente documentado), la pasarela Wompi y la DIAN para facturación electrónica.

La coexistencia con el sistema legacy y las restricciones de equipo y presupuesto impiden adoptar una arquitectura de alta complejidad operacional. Al mismo tiempo, la necesidad de escalar funcionalidades de forma independiente (el flujo de acceso LPR tiene carga muy distinta al módulo de reportes administrativos) descarta una solución completamente monolítica.

**Alternativas consideradas:**
1. Monolito tradicional (Modular Monolith)
2. **Service-Based Architecture**  Decisión adoptada
3. Microservicios

---

## Drivers de Decisión

| ID | Driver | Valor / Métrica | Prioridad |
|----|--------|-----------------|-----------|
| **DR-01** | Performance de entrada/salida | ≤ 5 segundos P95 (LPR → barrera) | Alta |
| **DR-02** | Escalabilidad de espacios | 450 → 1.200 espacios sin rediseño | Alta |
| **DR-03** | Disponibilidad en horas pico | 0 downtime 7–10 am y 5–8 pm | Alta |
| **DR-04** | Integración con sistema legacy | SOAP/VB6 no reemplazable en MVP | Alta |
| **DR-06** | Seguridad y protección de datos | PCI-DSS + Ley 1581/2012 | Alta |
| **DR-07** | Costo de infraestructura | ≤ $2.000 USD/mes en MVP | Media |
| **DR-08** | Time-to-market y capacidad del equipo | 8 meses, 4 desarrolladores | Alta |

---

## Alternativas Consideradas

### Alternativa 1: Monolito Modular

**Descripción:**  
Una única aplicación backend con módulos internos bien definidos (acceso, reservas, pagos, notificaciones, admin), desplegada como un solo proceso. La base de datos es compartida. Toda la lógica reside en un único repositorio y artefacto desplegable.

**Pros:**
- ✅ **Desarrollo más rápido al inicio:** Un solo proyecto, sin overhead de comunicación entre servicios.
- ✅ **Menor complejidad operacional:** Un único proceso a monitorear, una sola pipeline de CI/CD.
- ✅ **Transacciones ACID simples:** Operaciones que cruzan dominios (reserva + cobro + apertura de barrera) ocurren en una sola transacción de base de datos.
- ✅ **Costo mínimo de infraestructura:** Un solo contenedor o instancia desplegada; menor gasto en $USD/mes.

**Contras:**
- ❌ **No escala selectivamente:** El módulo de acceso LPR (crítico, alta carga en pico) no puede escalarse de forma independiente del módulo admin (baja carga). Toda la aplicación debe escalar como una sola unidad.
- ❌ **Despliegues de alto riesgo:** Un bug en el módulo de reportes obliga a redesplegar todo el sistema, incluyendo el flujo de acceso que no puede tener downtime (DR-03).
- ❌ **Aislamiento de fallos inexistente:** Un error no controlado en cualquier módulo (e.g., integración con legacy VB6) puede tumbar el proceso completo, afectando el flujo crítico de entrada/salida.
- ❌ **Deuda técnica acumulada:** Con 4 integraciones externas (LPR, VB6, Wompi, DIAN) la complejidad interna del monolito crece rápidamente y se vuelve difícil de mantener.
- ❌ **Conflictos de merge frecuentes:** 4 desarrolladores trabajando en el mismo proyecto sobre módulos relacionados generan fricciones en el control de versiones.

---

### Alternativa 2: Microservicios

**Descripción:**  
Cada capacidad de negocio se despliega como un servicio autónomo, con su propia base de datos, su propio ciclo de despliegue y comunicación exclusivamente por red (REST/gRPC o eventos). Típicamente requiere 10+ servicios para un dominio de esta complejidad.

**Pros:**
- ✅ **Escalabilidad extrema:** Cada microservicio escala de forma completamente independiente.
- ✅ **Aislamiento total de fallos:** Un microservicio caído no afecta a los demás si los circuit breakers están configurados.
- ✅ **Soberanía de datos real:** Cada servicio es dueño exclusivo de su esquema y base de datos.
- ✅ **Tecnología heterogénea:** Cada servicio puede usar el lenguaje o la base de datos más adecuada para su función.

**Contras:**
- ❌ **Overhead operacional inviable para el equipo:** Service mesh, distributed tracing, gestión de secretos, orquestación avanzada — todo esto excede la capacidad de 4 desarrolladores en 8 meses.
- ❌ **Latencia de red acumulada:** El flujo de entrada (LPR → verificar reserva → abrir barrera) involucra múltiples llamadas entre microservicios, comprometiendo el SLA de ≤ 5 seg P95 (DR-01).
- ❌ **Costo de infraestructura prohibitivo:** Base de datos por servicio, brokers de mensajes, API Gateway empresarial, herramientas de observabilidad distribuida → estimado > $5.000 USD/mes, superando el presupuesto (DR-07).
- ❌ **Transacciones distribuidas:** Operaciones como "reservar + cobrar + registrar factura" requieren sagas o 2PC, aumentando la complejidad en semanas-hombre que el MVP no puede absorber.
- ❌ **Tiempo de desarrollo > 8 meses:** Solo la infraestructura base de microservicios (CI/CD por servicio, configuración de service mesh, etc.) puede consumir 2–3 meses del plazo total.

---

## Decisión

Adoptamos **Service-Based Architecture** con **5 servicios de grano grueso**, cada uno representando un dominio de negocio claramente delimitado:

| # | Servicio | Responsabilidades principales |
|---|----------|-------------------------------|
| 1 | **Access Service** | Integración LPR, control de barrera, registro de entradas/salidas, contingencia manual |
| 2 | **Reservation Service** | Disponibilidad en tiempo real, reservas anticipadas, liberación automática de espacios |
| 3 | **Payment Service** | Pagos digitales (Wompi), cálculo de tarifas, emisión de facturas electrónicas (DIAN), sincronización con legacy VB6 |
| 4 | **Notification Service** | Envío de emails y SMS (confirmaciones, facturas, alertas) |
| 5 | **Admin Service** | Dashboard de ocupación, reportes de ingresos, configuración de tarifas por zona |

**Decisiones técnicas complementarias:**
- **Base de datos compartida** (PostgreSQL), con **schemas separados por servicio** (`access`, `reservations`, `payments`, `notifications`, `admin`) para controlar el acoplamiento.
- **Comunicación síncrona** vía HTTP/REST entre servicios cuando se requiere respuesta inmediata (e.g., Access Service consulta disponibilidad a Reservation Service).
- **Comunicación asíncrona** vía RabbitMQ para eventos que no bloquean el flujo crítico (e.g., Payment Service publica evento `payment.completed` → Notification Service envía factura).
- **Despliegue independiente** de cada servicio en contenedores Docker sobre AWS ECS Fargate.
- **API Gateway** (AWS API Gateway o Kong OSS) como punto de entrada único para clientes externos.

---

## Justificación

### Por qué Service-Based y no Monolito

El principal limitante del monolito para ParkEasy es el aislamiento de fallos y la escalabilidad selectiva. El **Access Service** es el componente más crítico del sistema: debe procesar hasta 80 vehículos/hora en horas pico con un SLA de ≤ 5 segundos P95, y no puede tener downtime. En un monolito, un bug en el módulo de reportes (que se desarrolla y despliega junto con todo lo demás) puede interrumpir este flujo crítico.

Con Service-Based Architecture, el Access Service es un proceso independiente. Un problema en el Admin Service o en el Notification Service no afecta la apertura de barreras. Además, si en horas pico el Access Service requiere más recursos, puede escalarse horizontalmente sin tocar los demás servicios (DR-02, DR-03).

La integración con el sistema legacy VB6 (DR-04) es otro factor determinante. Encapsular la lógica SOAP en un adaptador dentro del Payment Service evita que esa complejidad contamine el resto de la aplicación. En un monolito, esa integración oscura e inestable estaría directamente acoplada al núcleo del sistema.

### Por qué Service-Based y no Microservicios

El equipo de 4 desarrolladores y el presupuesto de $2.000 USD/mes hacen inviable el overhead operacional de microservicios (DR-07, DR-08). La complejidad de gestionar 10+ servicios con bases de datos independientes, sagas para transacciones distribuidas y herramientas de observabilidad distribuida consumiría el tiempo del equipo en infraestructura, no en funcionalidad de negocio.

Más crítico aún, el flujo de entrada de un vehículo requiere coordinación entre acceso, reservas y pagos. En microservicios, esto implica 3+ llamadas de red encadenadas, cada una con su overhead de latencia, comprometiendo el SLA de ≤ 5 seg P95 (DR-01). Con Service-Based y base de datos compartida, el Access Service puede consultar directamente el estado de reservas con una query SQL, sin latencia de red adicional.

### Cómo cumple con los drivers

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Access Service aislado con queries directas a PostgreSQL; sin latencia de red entre servicios para el flujo crítico de barrera |
| DR-02 | Cada servicio escala independientemente en ECS Fargate; se puede agregar instancias de Access Service sin tocar Admin o Notification |
| DR-03 | Fallos en servicios no críticos (Admin, Notification) no tumban Access Service; deploy rolling de servicios individuales sin downtime global |
| DR-04 | Adaptador SOAP/VB6 encapsulado dentro de Payment Service; falla del legacy no detiene el flujo de acceso |
| DR-06 | Payment Service aislado facilita el scope de PCI-DSS; datos de placas encriptados gestionados exclusivamente en Access Service |
| DR-07 | Estimado $1.200–1.600 USD/mes con ECS Fargate + RDS PostgreSQL + RabbitMQ + API Gateway; dentro del presupuesto con margen |
| DR-08 | 5 servicios bien delimitados permiten trabajo en paralelo; estimado 1.5 meses por servicio con 1 dev asignado; alcanzable en 8 meses |

---

## Consecuencias

### ✅ Positivas

1. **Aislamiento de fallos en el flujo crítico:** Un fallo en Notification o Admin Service no impide que los vehículos entren y salgan. El Access Service opera de forma autónoma.
2. **Escalabilidad selectiva:** En horas pico, solo Access Service y Reservation Service necesitan más instancias; Admin Service puede tener 0 réplicas adicionales durante la madrugada.
3. **Despliegues de bajo riesgo:** Un hotfix en Payment Service se despliega en minutos sin tocar el resto del sistema. Se elimina el riesgo de downtime global por cambios locales.
4. **Trabajo en paralelo del equipo:** Cada desarrollador puede ser responsable de 1–2 servicios sin conflictos constantes de merge en el repositorio.
5. **Encapsulación de la complejidad legacy:** La integración inestable con VB6 queda contenida en Payment Service y no contamina los demás dominios.
6. **Time-to-market alcanzable:** La arquitectura no requiere infraestructura adicional compleja (no hay service mesh, no hay distributed tracing obligatorio desde el día 1).

### ⚠️ Negativas (y mitigaciones)

1. **Acoplamiento por base de datos compartida**
   - **Riesgo:** Un cambio de schema en la tabla `spaces` puede impactar tanto Access Service como Reservation Service si no se coordina.
   - **Mitigación:** Schemas separados por servicio en PostgreSQL (`access.*`, `reservations.*`, etc.). Todo cambio de schema pasa por una revisión de impacto y se versionan las migraciones con Flyway. Los servicios solo leen su propio schema directamente; acceden a datos de otros schemas a través del servicio propietario vía REST.

2. **No hay soberanía de datos estricta**
   - **Riesgo:** Un desarrollador puede hacer una query directa al schema de otro servicio, violando el encapsulamiento del dominio.
   - **Mitigación:** Linting rules a nivel de repositorio que detecten queries entre schemas. Code reviews obligatorios para cualquier nueva query de base de datos. Repository pattern en cada servicio que oculta el acceso directo a tablas.

3. **Coordinación de transacciones cross-servicio**
   - **Riesgo:** La operación "registrar entrada + descontar espacio reservado" involucra Access Service y Reservation Service. Si falla a mitad, puede quedar en estado inconsistente.
   - **Mitigación:** Para operaciones críticas se implementa outbox pattern: el Access Service escribe su evento en su propia tabla dentro de la misma transacción PostgreSQL, y un worker lo publica a RabbitMQ de forma garantizada. La consistencia eventual es aceptable para este caso de uso.

4. **Mayor complejidad operacional que un monolito**
   - **Riesgo:** 5 servicios implican 5 pipelines de CI/CD, 5 imágenes Docker, mayor superficie de configuración.
   - **Mitigación:** Monorepo con scripts de build compartidos, CloudWatch centralizado para logs de todos los servicios, alertas unificadas en un solo dashboard operacional.

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó el Monolito

El monolito fue descartado principalmente por la incapacidad de aislar fallos en el flujo crítico de acceso vehicular. ParkEasy tiene una restricción explícita de 0 downtime en horas pico (DR-03), y desplegar todo el sistema como una unidad única hace que cualquier fix o feature en módulos secundarios ponga en riesgo la disponibilidad del flujo de barreras.

Adicionalmente, la integración con el sistema legacy VB6 (SOAP, mal documentado) es una fuente conocida de inestabilidad. En un monolito, un timeout o error en esa integración podría propagarse y bloquear threads del servidor web, degradando el sistema completo. La separación en servicios permite que el Access Service continúe operando incluso si Payment Service (que maneja el legacy) está temporalmente degradado.

**Cuándo el monolito sería la mejor opción:**
- Equipo de 1–2 desarrolladores sin experiencia en sistemas distribuidos.
- MVP con plazo < 3 meses donde el time-to-market es el único criterio.
- Volumen < 200 operaciones/día sin requisitos de disponibilidad diferenciada por módulo.
- Sin integraciones externas inestables o heterogéneas.

### Por qué se descartaron los Microservicios

Los microservicios fueron descartados por la combinación crítica de tres restricciones simultáneas: equipo pequeño (4 devs), presupuesto limitado ($2.000 USD/mes) y tiempo de entrega ajustado (8 meses). Cualquiera de estas restricciones individualmente haría a los microservicios desafiantes; las tres juntas los hacen inviables para este MVP.

El costo de infraestructura estimado para microservicios con las integraciones de ParkEasy (base de datos por servicio, service mesh, distributed tracing, múltiples brokers de mensajes) superaría los $5.000 USD/mes, 2.5x el presupuesto disponible (DR-07). A esto se suma que el flujo de entrada vehicular (SLA de ≤ 5 seg P95) se vería comprometido por la latencia acumulada de 3–5 llamadas de red encadenadas entre microservicios.

**Cuándo los microservicios serían la mejor opción:**
- Equipos de 10+ desarrolladores con experiencia en sistemas distribuidos.
- Escalabilidad extrema requerida (> 10.000 usuarios concurrentes, > 50 parqueaderos).
- Presupuesto de infraestructura > $5.000 USD/mes.
- Dominios de negocio totalmente independientes con equipos dedicados por dominio.
- La organización ha crecido al punto donde el modelo de Conway favorece la separación total.

---

## Validación

- [x] **Cumple DR-01** (≤ 5 seg P95): Access Service tiene acceso directo a PostgreSQL sin llamadas de red adicionales para el flujo crítico. Estimado ≤ 2–3 seg incluyendo LPR API.
- [x] **Cumple DR-02** (450 → 1.200 espacios): ECS Fargate permite auto-scaling horizontal de cada servicio de forma independiente sin rediseño arquitectural.
- [x] **Cumple DR-03** (0 downtime en picos): Servicios independientes permiten deploys rolling. Fallo en servicios no críticos no afecta Access Service.
- [x] **Cumple DR-04** (legacy VB6): Adaptador SOAP encapsulado en Payment Service; el resto del sistema no conoce la existencia del sistema legacy.
- [x] **Cumple DR-06** (PCI-DSS + Ley 1581): Payment Service aislado facilita el scope de PCI-DSS. Datos de placas gestionados exclusivamente en Access Service con encriptación en reposo.
- [x] **Cumple DR-07** ($2.000 USD/mes): Estimado $1.200–1.600 USD/mes (5x ECS Fargate t3.small + 1x RDS db.t3.medium + RabbitMQ + API Gateway). Dentro del presupuesto con margen.
- [x] **Cumple DR-08** (8 meses, 4 devs): 5 servicios bien delimitados permiten trabajo en paralelo. Estimado 1.5 meses por servicio con 1 dev asignado; alcanzable.

---

## Notas Adicionales

Esta decisión se revisará al finalizar el MVP (mes 8) cuando se evalúe la expansión a los 6 parqueaderos y 1.200 espacios. Si el volumen de operaciones supera las 3.000 entradas/salidas diarias o el equipo crece a 8+ desarrolladores, se evaluará:

- Migrar a base de datos por servicio (primer paso hacia microservicios).
- Implementar CQRS para el Admin Service (queries de reportes separadas de las escrituras operacionales).
- Reemplazar el sistema legacy VB6 (eliminando el adaptador SOAP de Payment Service).

**Supuesto clave documentado:** El presupuesto de infraestructura se interpreta como $2.000 USD/mes (ver SUP-01 en SRS). Si el presupuesto fuera $2.000.000 USD/mes, microservicios o una arquitectura más robusta sería viable.

---

## Referencias8

- [SRS] Software Requirements Specification – ParkEasy v1.0, Grupo 1 (18/03/2026)
- [ENUNCIADO] Taller: Documentación Arquitectural Completa – ParkEasy, PUJ 2026
- [EJEMPLO] ADR-001 CourtBooker – Adoptar Service-Based Architecture (referencia de clase)
- Architectural Decision Records (ADRs). (2026). Architectural Decision Records. https://adr.github.io/

---

**Estado final:** ACEPTADO ✅

**Firmas del equipo:**

| Nombre | Firma | Fecha |
|--------|-------|-------|
| Juan Camilo Alba | Juan Camilo Alba | 19/03/2026 |
| Laura Garzón | Laura Juliana Garzón Arias | 19/03/2026 |
| Carlos Villegas | Carlos Villegas Ruiz | 19/03/2026 |
| Arley Bernal | Arley Bernal Muñetón | 19/03/2026 |
