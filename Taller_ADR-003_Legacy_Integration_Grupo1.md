# ADR-003: Adoptar Redis como Caché para Disponibilidad en Tiempo Real

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Juan Camilo Alba, Laura Garzón, Carlos Villegas, Arley Bernal  
**Relacionado con:** RF-02, RF-04, RNF-01, RNF-02, DR-01, DR-02, DR-07  
**Grupo:** 1

---

## Contexto y Problema

Necesitamos decidir cómo gestionar la disponibilidad de espacios en tiempo real para los 3 parqueaderos. Esta información es consultada de forma frecuente por tres fuentes simultáneas: conductores que revisan disponibilidad antes de llegar, el sistema de reconocimiento de placas (LPR) al momento del ingreso, y el panel del operador en caseta.

El problema es que consultar el estado de disponibilidad directamente en la base de datos en cada solicitud, bajo una carga de 80 vehículos por hora en horas pico, puede generar una presión innecesaria sobre PostgreSQL y comprometer el tiempo de respuesta del flujo crítico de entrada (DR-01). Se necesita una estrategia que mantenga la información disponible de forma rápida sin depender de una consulta a base de datos en cada petición.

**Alternativas consideradas:**
1. Sin caché: consulta directa a la base de datos en cada solicitud
2. Caché en memoria dentro de cada servicio
3. Redis como caché distribuido

---

## Drivers de Decisión

- **DR-01:** Performance de entrada/salida - ≤ 5 segundos P95 (Prioridad: Alta)
- **DR-02:** Escalabilidad - 450 a 1.200 espacios sin rediseño arquitectural (Prioridad: Alta)
- **DR-03:** Disponibilidad en horas pico - 0 downtime en franjas 7–10 am y 5–8 pm (Prioridad: Alta)
- **DR-07:** Costo de infraestructura - Máximo $2.000 USD/mes en el MVP (Prioridad: Media)

---

## Alternativas Consideradas

### Alternativa 1: Sin caché — consulta directa a la base de datos

**Descripción:**
Cada solicitud de disponibilidad realiza una consulta directa a PostgreSQL. No hay ninguna capa intermedia de almacenamiento temporal; el estado de los espacios se lee siempre desde la fuente de datos principal.

**Pros:**
- Sin infraestructura adicional: no requiere ningún componente nuevo.
- La información devuelta siempre refleja el estado exacto y más reciente de la base de datos.
- Implementación inmediata sin configuración adicional.

**Contras:**
- En horas pico con 80 vehículos por hora, las consultas simultáneas de disponibilidad desde conductores, el sistema LPR y los paneles de operador generan una carga sostenida sobre PostgreSQL que puede degradar el tiempo de respuesta del flujo crítico de entrada.
- No escala bien al aumentar el número de parqueaderos y espacios (DR-02): más espacios implican consultas más pesadas en cada solicitud.
- Un aumento en el tráfico web (conductores consultando disponibilidad desde la app) afecta directamente el rendimiento de las operaciones de escritura en la base de datos.

---

### Alternativa 2: Caché en memoria dentro de cada servicio

**Descripción:**
Cada instancia del Reservation Service mantiene en su propia memoria una copia del estado de disponibilidad, con una expiración configurada. No se requiere ningún componente externo; el caché vive dentro del proceso de la aplicación.

**Pros:**
- Sin infraestructura adicional: no requiere un servicio externo.
- Latencia mínima: el acceso a memoria es más rápido que cualquier llamada de red.
- Sin costo adicional de infraestructura.

**Contras:**
- Cada instancia del servicio mantiene su propia copia del estado, que puede ser diferente entre instancias. Con múltiples instancias del Reservation Service corriendo en paralelo, dos conductores podrían ver disponibilidades distintas al mismo tiempo.
- Cuando una instancia se reinicia, pierde su caché y debe reconstruirlo desde la base de datos, generando una carga puntual.
- No es viable en una arquitectura de servicios con múltiples instancias, que es exactamente el escenario de ParkEasy en horas pico (DR-02).

---

### Alternativa 3: Redis como caché distribuido

**Descripción:**
Un servidor Redis centralizado almacena el estado de disponibilidad de todos los parqueaderos. Todas las instancias de todos los servicios consultan y actualizan el mismo caché. Cuando un vehículo entra o sale, el servicio correspondiente actualiza Redis; las consultas de disponibilidad se resuelven desde Redis sin tocar PostgreSQL.

**Pros:**
- Estado de disponibilidad consistente entre todas las instancias de todos los servicios: no hay divergencias entre réplicas.
- Tiempos de respuesta en el rango de 1–2 ms para consultas de disponibilidad, sin impacto sobre PostgreSQL.
- Soporte nativo para estructuras de datos como contadores y sets, útiles para gestionar el estado de espacios por parqueadero.
- Escala horizontalmente junto con el resto de la arquitectura sin cambios en el diseño (DR-02).
- AWS ElastiCache for Redis ofrece alta disponibilidad con replicación automática.

**Contras:**
- Requiere un componente adicional en la infraestructura con su propio costo y configuración.
- Introduce la necesidad de gestionar la invalidación del caché: cuando el estado de un espacio cambia, Redis debe actualizarse de forma inmediata para evitar información desactualizada.

---

## Decisión

Adoptamos **Redis** desplegado en **AWS ElastiCache** como caché distribuido para el estado de disponibilidad de espacios.

**Qué se almacena en Redis:**
- Estado de cada espacio por parqueadero: libre, ocupado o reservado
- Conteo de espacios disponibles por parqueadero (para la vista general del conductor)
- Expiración de reservas activas (TTL por reserva)

**Política de actualización del caché:**
- Cuando un vehículo entra o sale, el Access Service actualiza Redis de forma inmediata como parte de la misma operación
- Cuando se crea o cancela una reserva, el Reservation Service actualiza Redis en el mismo flujo
- TTL de respaldo de 60 segundos en cada clave: si una actualización falla por algún motivo, el caché se invalida automáticamente y la siguiente consulta reconstruye el estado desde PostgreSQL

**Configuración:**
- Instancia: cache.t3.micro (suficiente para 1.200 espacios y el volumen del MVP)
- Replicación automática habilitada en ElastiCache para cumplir el requisito de disponibilidad (DR-03)
- Estimado: $20–30 USD/mes

---

## Justificación

### Por qué Redis y no consulta directa:

La consulta directa a PostgreSQL en cada solicitud de disponibilidad funciona bien en condiciones normales, pero en horas pico el volumen combinado de consultas desde la app, el LPR y los paneles de operador puede degradar el tiempo de respuesta de las operaciones de escritura (registros de entrada, reservas, pagos), que son las más críticas del sistema. Redis elimina esta presión: las consultas de disponibilidad se resuelven en memoria sin tocar la base de datos.

### Por qué Redis y no caché en memoria:

El caché en memoria es inviable en una arquitectura con múltiples instancias del mismo servicio. En horas pico, el Reservation Service y el Access Service escalan horizontalmente con varias instancias en paralelo. Si cada instancia mantiene su propia copia del estado, dos conductores consultando instancias distintas pueden ver disponibilidades diferentes en el mismo momento, lo que puede resultar en doble asignación de espacios. Redis centraliza ese estado y garantiza que todas las instancias vean siempre la misma información.

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Las consultas de disponibilidad se resuelven desde Redis en 1–2 ms, sin impacto sobre el tiempo de respuesta del flujo de entrada vehicular. |
| DR-02 | Redis escala junto con el resto de la arquitectura; agregar nuevos parqueaderos y espacios es configuración, no rediseño. |
| DR-03 | ElastiCache con replicación automática garantiza disponibilidad del caché durante horas pico sin intervención manual. |
| DR-07 | Estimado $20–30 USD/mes con cache.t3.micro. Representa menos del 2% del presupuesto total de infraestructura. |

---

## Consecuencias

### Positivas:

1. **Menor presión sobre PostgreSQL:** Las consultas de disponibilidad, que son las más frecuentes del sistema, dejan de impactar la base de datos en cada solicitud.
2. **Tiempo de respuesta predecible:** Las consultas de disponibilidad se resuelven siempre en el mismo rango de tiempo, independientemente de la carga sobre la base de datos.
3. **Estado consistente entre servicios:** Todas las instancias de todos los servicios leen y escriben sobre el mismo caché, eliminando el riesgo de divergencias en el estado de disponibilidad.
4. **Extensible:** Redis puede usarse en el futuro para otros casos de uso como la gestión de sesiones de usuario o la limitación de tasa de peticiones.

### Negativas (y mitigaciones):

1. **Complejidad en la invalidación del caché**
   - **Riesgo:** Si una actualización de estado falla y Redis no se actualiza, los conductores pueden ver información incorrecta sobre la disponibilidad.
   - **Mitigación:** TTL de 60 segundos en cada clave como mecanismo de respaldo. Si Redis no se actualiza correctamente, el caché expira y la siguiente consulta reconstruye el estado desde PostgreSQL. Dado que RF-02 acepta una antigüedad máxima de 30 segundos, este TTL cumple el requisito.

2. **Componente adicional en la infraestructura**
   - **Riesgo:** Un fallo de Redis deja al sistema sin caché, forzando todas las consultas de disponibilidad directamente a PostgreSQL.
   - **Mitigación:** El sistema está diseñado para funcionar sin caché como modo de degradación controlada: si Redis no está disponible, el Reservation Service cae en modo de consulta directa a PostgreSQL. La disponibilidad de los espacios puede verse afectada en términos de latencia, pero el flujo de acceso vehicular no se interrumpe.

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó la consulta directa a la base de datos:

En condiciones de baja carga, la consulta directa es perfectamente viable. El problema aparece en horas pico, donde el volumen combinado de consultas de solo lectura (disponibilidad) compite con las operaciones de escritura críticas (registros de entrada, reservas, pagos) por los recursos de PostgreSQL. Al separar estas cargas mediante Redis, las escrituras críticas no se ven afectadas por el tráfico de lectura.

**Cuándo sería la mejor opción:**
- Volumen de operaciones muy bajo, sin picos de carga significativos.
- Un único parqueadero con pocos espacios y usuarios concurrentes reducidos.

### Por qué se descartó el caché en memoria:

El caché en memoria es adecuado cuando hay una única instancia del servicio, pero ParkEasy requiere escalamiento horizontal en horas pico. Con múltiples instancias del Reservation Service corriendo en paralelo, cada una con su propia copia del estado, el riesgo de inconsistencias entre instancias es alto y puede derivar en doble asignación de espacios, que es uno de los problemas centrales que el sistema debe evitar.

**Cuándo sería la mejor opción:**
- Una única instancia del servicio sin necesidad de escalamiento horizontal.
- Datos que no se comparten entre servicios y cuya inconsistencia temporal no tiene consecuencias operativas.

---

## Validación

- [x] Cumple con DR-01: Consultas de disponibilidad resueltas desde Redis en 1–2 ms, sin impacto sobre el tiempo de respuesta del flujo de entrada vehicular.
- [x] Cumple con DR-02: Redis escala con la arquitectura; agregar parqueaderos y espacios no requiere cambios en el diseño del caché.
- [x] Cumple con DR-03: ElastiCache con replicación automática mantiene el caché disponible durante horas pico sin intervención manual ante fallos.
- [x] Cumple con DR-07: Estimado $20–30 USD/mes. Incremento menor al 2% sobre el presupuesto total de infraestructura disponible.

---

## Notas Adicionales

Esta decisión se revisará al finalizar el MVP si el volumen de operaciones supera las 3.000 entradas/salidas diarias o si se incorporan más de 6 parqueaderos. En ese escenario se evaluará migrar a una instancia de mayor capacidad en ElastiCache o habilitar clustering de Redis para distribuir la carga de lectura.

---

## Referencias

- [SRS] Software Requirements Specification – ParkEasy v1.0, Grupo 1 (18/03/2026)
- [ADR-001] Adoptar Service-Based Architecture – ParkEasy, Grupo 1 (19/03/2026)
- [ADR-002] Adoptar PostgreSQL como Base de Datos Principal – ParkEasy, Grupo 1 (19/03/2026)
- [ENUNCIADO] Taller: Documentación Arquitectural Completa – ParkEasy, Pontificia Universidad Javeriana, 2026
- Architectural Decision Records (ADRs). https://adr.github.io/

---

**Estado final:** ACEPTADO

**Firmas del equipo:**
- Juan Camilo Alba: __________ - Fecha: 19/03/2026
- Laura Garzón: __________ - Fecha: 19/03/2026
- Carlos Villegas: __________ - Fecha: 19/03/2026
- Arley Bernal: __________ - Fecha: 19/03/2026
