# ADR-002: Adoptar PostgreSQL como Base de Datos Principal

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Juan Camilo Alba, Laura Garzón, Carlos Villegas, Arley Bernal  
**Relacionado con:** RNF-01, RNF-02, RNF-06, DR-01, DR-02, DR-03, DR-05, DR-06, DR-07  
**Grupo:** 1

---

## Contexto y Problema

Necesitamos seleccionar la base de datos principal para ParkEasy. El sistema debe almacenar y gestionar:
- Usuarios y roles (conductores, operadores, administradores)
- Espacios y disponibilidad en tiempo real por parqueadero
- Reservas anticipadas y registros de entrada/salida
- Transacciones de pago y facturas electrónicas 
- Configuración de tarifas por zona

**Requisitos clave:**
- Garantía de consistencia en operaciones concurrentes (evitar doble asignación de espacios)
- Consultas complejas para reportes de ocupación e ingresos
- Escalabilidad de 450 a 1.200 espacios sin rediseño
- Cumplimiento de retención de datos regulatorios (DIAN, Ley 1581)
- Costo dentro del presupuesto de $2.000 USD/mes junto con el resto de la infraestructura

**Alternativas consideradas:**
1. PostgreSQL
2. MongoDB
3. DynamoDB

---

## Drivers de Decisión

- **DR-01:** Performance de entrada/salida - ≤ 5 segundos P95 (Prioridad: Alta)
- **DR-02:** Escalabilidad - 450 a 1.200 espacios sin rediseño arquitectural (Prioridad: Alta)
- **DR-03:** Disponibilidad en horas pico - 0 downtime en franjas 7–10 am y 5–8 pm (Prioridad: Alta)
- **DR-05:** Cumplimiento regulatorio DIAN - Retención de facturas mínimo 5 años (Prioridad: Media)
- **DR-06:** Seguridad y protección de datos - PCI-DSS + Ley 1581/2012 (Prioridad: Alta)
- **DR-07:** Costo de infraestructura - Máximo $2.000 USD/mes en el MVP (Prioridad: Media)

---

## Alternativas Consideradas

### Alternativa 1: PostgreSQL

**Descripción:**
Base de datos relacional de código abierto con soporte completo de transacciones ACID, consultas SQL avanzadas, esquemas separados por dominio y configuración de alta disponibilidad en AWS RDS Multi-AZ.

**Pros:**
- Transacciones ACID completas: garantiza que dos conductores no puedan reservar el mismo espacio simultáneamente.
- Soporte nativo para consultas complejas (joins, funciones de ventana, vistas materializadas) necesarias para los reportes de ocupación e ingresos del administrador.
- Esquemas separados por servicio dentro de una misma instancia, alineado con la decisión ADR-001.
- Alta disponibilidad con RDS Multi-AZ: conmutación automática ante fallos en menos de 60 segundos.
- Costo predecible y dentro del presupuesto: estimado $150–200 USD/mes con instancia db.t3.medium.
- Amplio conocimiento en el equipo, sin curva de aprendizaje adicional.

**Contras:**
- Escalamiento de escrituras limitado verticalmente: para volúmenes extremos requiere estrategias adicionales como particionado o réplicas de lectura.
- Configuración y mantenimiento más exigente que una base de datos gestionada sin servidor.

---

### Alternativa 2: MongoDB

**Descripción:**
Base de datos NoSQL orientada a documentos. Almacena datos en formato JSON flexible, sin esquema fijo, con escalamiento horizontal nativo.

**Pros:**
- Esquema flexible: útil cuando la estructura de los datos cambia frecuentemente.
- Escalamiento horizontal nativo para volúmenes de escritura muy altos.
- Modelo de datos intuitivo para ciertos dominios con estructuras anidadas.

**Contras:**
- Sin garantías ACID multi-documento en su configuración estándar: las operaciones que involucran reserva, cobro y registro de entrada quedan expuestas a inconsistencias.
- Consultas complejas para reportes (agrupaciones, totales, cruces entre colecciones) son más difíciles de escribir y menos eficientes que en SQL.
- Sin experiencia en el equipo, lo que incrementa el riesgo técnico en un proyecto de 8 meses.
- El modelo de datos de ParkEasy es inherentemente relacional (espacios, reservas, pagos, usuarios), lo que no favorece un modelo documental.

---

### Alternativa 3: DynamoDB

**Descripción:**
Base de datos NoSQL sin servidor (serverless) de AWS, con escalamiento automático y latencia baja para patrones de acceso simples y predecibles.

**Pros:**
- Escalamiento automático sin administración de infraestructura.
- Latencia muy baja para operaciones de lectura y escritura con clave primaria conocida.
- Sin costos fijos: se paga por operación.

**Contras:**
- Sin soporte para consultas relacionales (no hay joins): los reportes de ocupación e ingresos requerirían lógica adicional en la aplicación o un servicio analítico separado.
- Costo impredecible con patrones de acceso variables, como los picos de 80 vehículos/hora de ParkEasy.
- Transacciones entre tablas posibles pero con limitaciones y mayor complejidad de implementación.
- Curva de aprendizaje alta para un equipo con experiencia en bases de datos relacionales.

---

## Decisión

Adoptamos **PostgreSQL 15** desplegado en **AWS RDS con configuración Multi-AZ**.

**Configuración:**
- Instancia: db.t3.medium (2 vCPUs, 4 GB RAM)
- Almacenamiento: 100 GB SSD (gp3), con autoescalado habilitado
- Multi-AZ activo para conmutación automática ante fallos
- Backups automatizados con retención de 30 días (cubre requisito DIAN de auditoría)
- Réplica de lectura: se añade si la carga de consultas supera el 70% de capacidad

**Organización de datos:**
- Un esquema por servicio: `access`, `reservations`, `payments`, `notifications`, `admin`
- Índices en: `plate` (acceso), `space_id`, `start_time` (reservas), `transaction_id` (pagos)
- Particionado por mes en la tabla de registros de entrada/salida para mantener el rendimiento con el crecimiento histórico

---

## Justificación

### Por qué PostgreSQL y no MongoDB:

El modelo de datos de ParkEasy es estructurado y relacional: un conductor tiene reservas, cada reserva está asociada a un espacio, cada espacio pertenece a un parqueadero, y cada salida genera una transacción de pago y una factura. Forzar este modelo en documentos JSON de MongoDB añade complejidad sin beneficio real.

Más crítico aún, la operación de asignación de espacio debe ser atómica: si dos conductores intentan reservar el mismo espacio simultáneamente, el sistema debe garantizar que solo uno lo obtenga (DR-01). Las transacciones ACID nativas de PostgreSQL resuelven esto de forma directa. En MongoDB, esta garantía requiere configuración adicional y tiene un costo de rendimiento.

### Por qué PostgreSQL y no DynamoDB:

Los reportes de ocupación e ingresos que requieren los administradores implican consultas con agrupaciones, filtros por rango de fechas y cruces entre registros de entrada, espacios y pagos. DynamoDB no está diseñado para este tipo de consultas: cada reporte requeriría múltiples operaciones de lectura y lógica adicional en la aplicación, incrementando la latencia y la complejidad de desarrollo.

Adicionalmente, el costo de DynamoDB con patrones de acceso variables (picos de 80 vehículos/hora) es impredecible y difícil de estimar dentro del presupuesto de $2.000 USD/mes (DR-07).

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Índices en `plate` y `space_id` garantizan tiempos de consulta inferiores a 10 ms en el flujo crítico de acceso. Las transacciones ACID evitan doble asignación de espacios. |
| DR-02 | Particionado por mes y réplicas de lectura permiten escalar a 1.200 espacios sin rediseño del esquema. |
| DR-03 | RDS Multi-AZ con conmutación automática en menos de 60 segundos. Cumple el requisito de disponibilidad en horas pico. |
| DR-05 | Backups automatizados con retención de 30 días y almacenamiento de largo plazo en S3 para facturas. Cumple retención mínima de 5 años exigida por la DIAN. |
| DR-06 | Encriptación en reposo (AES-256) y en tránsito (TLS) habilitadas en RDS. Datos de tarjetas nunca almacenados en texto plano (PCI-DSS). |
| DR-07 | Estimado $150–200 USD/mes con db.t3.medium Multi-AZ. Representa el 10% del presupuesto total de infraestructura. |

---

## Consecuencias

### Positivas:

1. **Consistencia garantizada:** Las transacciones ACID previenen la doble asignación de espacios incluso bajo carga concurrente en horas pico.
2. **Reportes sin complejidad adicional:** SQL nativo cubre todos los casos de uso de reportes del administrador sin capas adicionales de procesamiento.
3. **Alta disponibilidad:** La configuración Multi-AZ garantiza conmutación automática ante fallos, sin intervención manual durante horas pico.
4. **Cumplimiento regulatorio simplificado:** La persistencia estructurada y los backups automatizados facilitan el cumplimiento de retención de facturas (DIAN) y protección de datos (Ley 1581).
5. **Alineación con ADR-001:** Un esquema por servicio en una instancia compartida es coherente con la arquitectura de servicios adoptada, sin overhead de múltiples bases de datos independientes.

### Negativas (y mitigaciones):

1. **Escalamiento de escrituras limitado verticalmente**
   - **Riesgo:** Con un crecimiento significativo de parqueaderos o volumen de operaciones, una única instancia de escritura puede convertirse en un cuello de botella.
   - **Mitigación:** Para el MVP (450 espacios, 1.200 operaciones/día), una instancia db.t3.medium es suficiente. Si el volumen supera las 3.000 operaciones/día, se añade una réplica de lectura para consultas de reportes y se evalúa escalar la instancia.

2. **Costo incremental con el crecimiento**
   - **Riesgo:** A medida que el volumen de datos históricos crece (facturas, registros de entrada/salida), el almacenamiento y el tamaño de instancia requerido aumentan.
   - **Mitigación:** Particionado por mes en tablas de alta inserción. Archivado de datos históricos a S3 para facturas con más de 1 año, manteniendo solo los índices en la base de datos activa.

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó MongoDB:

MongoDB fue descartado porque el modelo de datos de ParkEasy es inherentemente relacional y las operaciones críticas del sistema requieren garantías de consistencia que una base de datos documental no ofrece de forma nativa. La operación de reserva de espacio, el registro de entrada y la generación del cobro deben ejecutarse como una unidad atómica; implementar esto en MongoDB requiere configuración adicional y tiene un costo de rendimiento que comprometería el SLA de 5 segundos P95 (DR-01).

**Cuándo sería la mejor opción:**
- Datos con estructura muy variable o no definida en tiempo de diseño.
- Aplicaciones con requisitos de escalamiento horizontal de escritura extremo (más de 10.000 escrituras por segundo).
- Equipos con experiencia consolidada en bases de datos documentales.

### Por qué se descartó DynamoDB:

DynamoDB fue descartado principalmente por su incompatibilidad con los requisitos de consulta del sistema. Los reportes de ocupación e ingresos que necesitan los administradores requieren cruces entre múltiples entidades (espacios, reservas, pagos), algo que DynamoDB no soporta de forma nativa. Implementar esos reportes implicaría lógica adicional en la aplicación o un servicio analítico separado, incrementando la complejidad y el costo por encima del presupuesto disponible (DR-07).

**Cuándo sería la mejor opción:**
- Patrones de acceso simples y altamente predecibles, principalmente por clave primaria.
- Necesidad de escalamiento automático sin administración de infraestructura.
- Equipos con experiencia en modelado NoSQL para DynamoDB.

---

## Validación

- [x] Cumple con DR-01: Índices en campos críticos garantizan tiempos de consulta inferiores a 10 ms. Transacciones ACID evitan doble asignación de espacios bajo carga concurrente.
- [x] Cumple con DR-02: Particionado por mes y réplicas de lectura permiten escalar a 1.200 espacios sin cambios en el esquema.
- [x] Cumple con DR-03: RDS Multi-AZ con conmutación automática en menos de 60 segundos cubre el requisito de 0 downtime en horas pico.
- [x] Cumple con DR-05: Backups con retención de 30 días y archivado en S3 cubren la retención mínima de 5 años exigida por la DIAN.
- [x] Cumple con DR-06: Encriptación en reposo y en tránsito habilitadas. Sin almacenamiento de datos de tarjetas en texto plano (PCI-DSS).
- [x] Cumple con DR-07: Estimado $150–200 USD/mes, representando el 10% del presupuesto total de infraestructura disponible.

---

## Notas Adicionales

Esta decisión se revisará al finalizar el MVP si el volumen de operaciones supera las 3.000 entradas/salidas diarias. En ese escenario se evaluará añadir una réplica de lectura dedicada para el Admin Service, implementar connection pooling con PgBouncer para optimizar el uso de conexiones, y revisar la estrategia de particionado.

---

## Referencias

- [SRS] Software Requirements Specification – ParkEasy v1.0, Grupo 1 (18/03/2026)
- [ADR-001] Adoptar Service-Based Architecture – ParkEasy, Grupo 1 (19/03/2026)
- [ENUNCIADO] Taller: Documentación Arquitectural Completa – ParkEasy, Pontificia Universidad Javeriana, 2026
- Architectural Decision Records (ADRs). https://adr.github.io/

---

**Estado final:** ACEPTADO

**Firmas del equipo:**
- Juan Camilo Alba: __________ - Fecha: 19/03/2026
- Laura Garzón: __________ - Fecha: 19/03/2026
- Carlos Villegas: __________ - Fecha: 19/03/2026
- Arley Bernal: __________ - Fecha: 19/03/2026
