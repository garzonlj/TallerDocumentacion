# ADR-003: Adoptar un Servicio Adaptador para la Integración con el Sistema Legacy VB6

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Juan Camilo Alba, Laura Garzón, Carlos Villegas, Arley Bernal  
**Relacionado con:** RF-06, RF-07, RNF-01, RNF-02, DR-01, DR-03, DR-04, DR-07  
**Grupo:** 1

---

## Contexto y Problema

Necesitamos decidir cómo integrar ParkEasy con el sistema de cobro legacy desarrollado en Visual Basic 6 (VB6), que opera mediante un protocolo SOAP escasamente documentado y no puede ser reemplazado durante el MVP. Este sistema es el registro oficial de cobros de los parqueaderos y debe mantenerse sincronizado con cada transacción procesada por ParkEasy.

El principal riesgo es que la inestabilidad conocida de este sistema —tiempos de respuesta variables, fallos intermitentes y falta de documentación— se propague al resto de la arquitectura, afectando el flujo crítico de entrada y salida de vehículos (DR-01, DR-03). La decisión debe aislar esta complejidad y proteger al resto de los servicios de una dependencia directa con el legacy.

**Alternativas consideradas:**
1. Integración directa desde cada servicio
2. Servicio adaptador dedicado
3. Anti-Corruption Layer con cola de mensajes

---

## Drivers de Decisión

- **DR-01:** Performance de entrada/salida - ≤ 5 segundos P95 (Prioridad: Alta)
- **DR-03:** Disponibilidad en horas pico - 0 downtime en franjas 7–10 am y 5–8 pm (Prioridad: Alta)
- **DR-04:** Integración con sistema legacy - Adaptador SOAP/VB6 no reemplazable en el MVP (Prioridad: Alta)
- **DR-07:** Costo de infraestructura - Máximo $2.000 USD/mes en el MVP (Prioridad: Media)

---

## Alternativas Consideradas

### Alternativa 1: Integración directa desde cada servicio

**Descripción:**
Cada servicio que necesite comunicarse con el sistema legacy implementa su propia lógica de cliente SOAP de forma independiente. No hay un componente centralizado; cada servicio gestiona su propia conexión, manejo de errores y reintentos contra el VB6.

**Pros:**
- Sin infraestructura adicional: no requiere un servicio nuevo ni su despliegue independiente.
- Implementación inicial más rápida: cada equipo puede conectarse al legacy según lo necesite.

**Contras:**
- La lógica de integración con el SOAP se duplica en múltiples servicios, incrementando la deuda técnica.
- Un cambio en el protocolo o en la interfaz del legacy obliga a modificar y redesplegar todos los servicios afectados de forma coordinada.
- Sin un punto central de control, los fallos del legacy se propagan de forma directa a cada servicio que dependa de él, incluyendo aquellos del flujo crítico de acceso.
- La falta de documentación del protocolo SOAP se convierte en un problema distribuido: varios desarrolladores deben hacer ingeniería inversa de forma independiente.

---

### Alternativa 2: Servicio adaptador dedicado

**Descripción:**
Un único servicio —Legacy Adapter Service— encapsula toda la comunicación con el sistema VB6. Expone una API REST interna limpia y documentada hacia el resto de los servicios de ParkEasy, ocultando completamente el protocolo SOAP y la complejidad del legacy. Los demás servicios nunca conocen la existencia del sistema legacy.

**Pros:**
- Un único punto de integración con el legacy: los cambios en el protocolo SOAP solo requieren modificar el adaptador.
- El resto de los servicios se comunican con una API REST estable y bien definida, sin acoplamiento al legacy.
- La lógica de reintentos, timeouts y manejo de errores del SOAP se implementa una sola vez.
- Facilita las pruebas: el adaptador puede ser reemplazado por un mock en entornos de desarrollo sin afectar a los demás servicios.
- Si en el futuro el legacy es reemplazado, solo el adaptador necesita cambiar; el resto de la arquitectura permanece intacto.

**Contras:**
- Requiere desarrollar y mantener un servicio adicional, con su propio ciclo de despliegue.
- La comunicación con el adaptador sigue siendo síncrona: si el legacy no responde, el servicio que llama debe esperar o gestionar el timeout.

---

### Alternativa 3: Anti-Corruption Layer con cola de mensajes

**Descripción:**
La comunicación con el legacy se realiza de forma completamente asíncrona a través de una cola de mensajes (RabbitMQ). Los servicios publican eventos de cobro a la cola y un componente consumidor se encarga de traducirlos al protocolo SOAP y enviarlos al VB6 en segundo plano, sin bloquear el flujo principal.

**Pros:**
- Desacoplamiento total: los servicios de ParkEasy no dependen en absoluto de la disponibilidad del legacy para completar sus operaciones.
- Alta resiliencia: si el legacy está caído, los mensajes se acumulan en la cola y se procesan cuando el sistema recupera disponibilidad.
- Protección completa del flujo crítico frente a fallos del legacy.

**Contras:**
- Introduce consistencia eventual: el registro en el sistema legacy puede quedar desactualizado respecto a ParkEasy por un período variable.
- Mayor complejidad de implementación: requiere gestionar la cola, el consumidor, los reintentos y la conciliación de estados entre ambos sistemas.
- En un MVP de 8 meses con 4 desarrolladores, la complejidad operacional adicional supera el beneficio para el volumen de operaciones esperado (DR-07).

---

## Decisión

Adoptamos un **servicio adaptador dedicado** — **Legacy Adapter Service** — que encapsula toda la comunicación con el sistema VB6 y expone una API REST interna hacia el resto de los servicios de ParkEasy.

**Responsabilidades del Legacy Adapter Service:**
- Traducir las peticiones REST internas al protocolo SOAP requerido por el VB6
- Gestionar la autenticación y la sesión con el sistema legacy
- Implementar la política de reintentos y timeouts ante fallos del legacy
- Registrar cada interacción con el legacy para facilitar la auditoría y la depuración
- Exponer un endpoint de health check que refleje el estado de la conexión con el VB6

**Configuración:**
- Desplegado como contenedor independiente en AWS ECS Fargate
- Timeout máximo por petición al legacy: 3 segundos
- Política de reintentos: 2 intentos adicionales con backoff de 500 ms entre cada uno
- Circuit breaker: si el legacy falla 5 peticiones consecutivas, el adaptador retorna un error controlado y notifica al operador

---

## Justificación

### Por qué servicio adaptador y no integración directa:

La integración directa distribuye la complejidad del legacy en múltiples servicios. Dado que el protocolo SOAP del VB6 está escasamente documentado (DR-04), hacer ingeniería inversa del protocolo una sola vez y encapsularla en un adaptador es significativamente más eficiente que replicarla en cada servicio. Cualquier cambio futuro en el comportamiento del legacy requeriría modificar un único componente en lugar de coordinar cambios en múltiples servicios.

Adicionalmente, el aislamiento que ofrece el adaptador protege el resto de la arquitectura de la inestabilidad del legacy. Si el VB6 presenta fallos intermitentes, el impacto queda contenido en el adaptador y no se propaga al Payment Service ni, por extensión, al flujo de acceso vehicular.

### Por qué servicio adaptador y no Anti-Corruption Layer con cola:

El enfoque asíncrono ofrece mayor resiliencia, pero introduce consistencia eventual entre ParkEasy y el sistema legacy. Para el MVP, donde el sistema VB6 sigue siendo el registro oficial de cobros, es importante que la sincronización ocurra dentro de la misma operación de pago, no en segundo plano. Una discrepancia temporal entre ambos sistemas podría generar inconsistencias en los registros de cobro que el negocio no está preparado para gestionar.

La complejidad operacional adicional de gestionar una cola, un consumidor dedicado y procesos de conciliación supera el beneficio para un volumen de 1.200 operaciones diarias con un equipo de 4 desarrolladores en 8 meses (DR-07).

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | El timeout máximo de 3 segundos y la política de circuit breaker garantizan que un fallo del legacy no bloquea indefinidamente el flujo de pago, manteniendo el SLA de 5 segundos P95. |
| DR-03 | El circuit breaker retorna un error controlado ante fallos del legacy sin tumbar el Payment Service ni afectar el flujo de acceso vehicular durante horas pico. |
| DR-04 | La lógica SOAP y la ingeniería inversa del protocolo VB6 están encapsuladas en un único componente. El resto de los servicios interactúan con una API REST estable. |
| DR-07 | Un único servicio adicional en ECS Fargate (t3.small) representa un incremento estimado de $20–30 USD/mes sobre el presupuesto actual de infraestructura. |

---

## Consecuencias

### Positivas:

1. **Aislamiento de la inestabilidad legacy:** Los fallos del VB6 quedan contenidos en el adaptador y no se propagan al resto de los servicios ni al flujo crítico de acceso vehicular.
2. **Un único punto de mantenimiento:** Cambios en el protocolo SOAP, credenciales o comportamiento del legacy se resuelven modificando únicamente el adaptador.
3. **Sustitución simplificada:** Si el legacy es reemplazado en el futuro, solo el adaptador debe actualizarse; el resto de la arquitectura no requiere cambios.
4. **Observabilidad centralizada:** Todos los registros de interacción con el legacy se concentran en un único componente, facilitando la auditoría y la depuración.

### Negativas (y mitigaciones):

1. **Punto único de fallo para la integración con el legacy**
   - **Riesgo:** Si el adaptador falla, ningún servicio puede comunicarse con el VB6.
   - **Mitigación:** ECS Fargate mantiene al menos dos instancias del adaptador en ejecución. El circuit breaker evita que peticiones fallidas agoten los recursos disponibles.

2. **Latencia adicional en el flujo de pago**
   - **Riesgo:** La llamada al adaptador añade un salto de red adicional entre el Payment Service y el legacy VB6.
   - **Mitigación:** El adaptador se despliega en la misma VPC y zona de disponibilidad que el Payment Service, manteniendo la latencia de red interna por debajo de 5 ms.

3. **Complejidad en la gestión de errores del legacy**
   - **Riesgo:** El VB6 puede devolver respuestas de error no documentadas o comportarse de forma inesperada, difíciles de anticipar en el diseño del adaptador.
   - **Mitigación:** El adaptador registra todas las respuestas del legacy en un log estructurado. Las respuestas no reconocidas se tratan como error controlado y se notifica al operador para revisión manual.

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó la integración directa:

La duplicación de la lógica SOAP en múltiples servicios genera una deuda técnica difícil de gestionar con un equipo de 4 personas. Dado que el protocolo del VB6 no está documentado, cualquier descubrimiento sobre su comportamiento tendría que propagarse a todos los servicios afectados de forma manual. Ante un cambio en el legacy, la coordinación de modificaciones en múltiples servicios en paralelo incrementa el riesgo de errores y de downtime en el flujo de cobro.

**Cuándo sería la mejor opción:**
- Un único servicio necesita comunicarse con el legacy, sin posibilidad de que eso cambie.
- El protocolo del legacy está completamente documentado y es estable.

### Por qué se descartó el Anti-Corruption Layer con cola de mensajes:

La consistencia eventual que introduce este enfoque es incompatible con el modelo operativo actual de ParkEasy, donde el VB6 sigue siendo el sistema de registro oficial de cobros. Una discrepancia temporal entre ambos sistemas, por corta que sea, puede generar inconsistencias en los registros financieros que el negocio no está en condiciones de conciliar de forma automatizada durante el MVP.

**Cuándo sería la mejor opción:**
- El sistema legacy puede operar de forma completamente independiente de ParkEasy, sin necesidad de sincronización en tiempo real.
- El volumen de operaciones es suficientemente alto como para justificar la complejidad de una cola de mensajes dedicada a la integración.
- El equipo tiene experiencia en el diseño de sistemas con consistencia eventual y procesos de conciliación.

---

## Validación

- [x] Cumple con DR-01: Timeout de 3 segundos y circuit breaker garantizan que el legacy no bloquea el SLA de 5 segundos P95 del flujo de pago.
- [x] Cumple con DR-03: El circuit breaker retorna errores controlados ante fallos del legacy sin afectar el Access Service ni el flujo de acceso en horas pico.
- [x] Cumple con DR-04: Protocolo SOAP y complejidad del VB6 encapsulados en un único componente. El resto de los servicios interactúan con una API REST estable y documentada.
- [x] Cumple con DR-07: Incremento estimado de $20–30 USD/mes para el servicio adicional en ECS Fargate. Dentro del margen disponible del presupuesto de infraestructura.

---

## Notas Adicionales

Esta decisión se revisará al finalizar el MVP. Si el volumen de operaciones supera las 3.000 transacciones diarias o los fallos del legacy se vuelven frecuentes, se evaluará migrar hacia el enfoque asíncrono con cola de mensajes (Alternativa 3), aprovechando la infraestructura de RabbitMQ ya disponible en la arquitectura. El reemplazo total del sistema VB6 eliminaría la necesidad de este adaptador y simplificaría la arquitectura de forma significativa.

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
