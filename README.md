# Taller: Documentación Arquitectural - ParkEasy
## Grupo 4

**Integrantes:**
- Juan Camilo Alba - 20520477 - alba-jc@javeriana.edu.co
- Laura Juliana Garzón Arias - 20511299 - garzonlj@javeriana.edu.co
- Carlos Villegas - 20532083 - villegas.carlos@javeriana.edu.co
- Arley Bernal Muñetón - 20510888 - be_arley@javeriana.edu.co


**Fecha de entrega:** 19/03/2026

---

## 📋 CONTENIDO DE LA ENTREGA

Este ZIP contiene la documentación arquitectural completa del sistema ParkEasy:

```
├── Taller_README_Grupo4.md                              (Este archivo)
├── Taller_SRS_ParkEasy_Grupo4.md                       (Requisitos)
├── Taller_ADR-001_[Nombre]_Grupo4.md                   (Decisión arquitectural 1)
├── Taller_ADR-002_[Nombre]_Grupo4.md                   (Decisión arquitectural 2)
├── Taller_ADR-003_[Nombre]_Grupo4.md                   (Decisión arquitectural 3)
├── Taller_ParkEasy_Architecture_Grupo4.dsl             (Vistas C4)
└── Taller_SAD_ParkEasy_Grupo4.md                       (Documento arquitectural)
```

---

## 🎨 CÓMO VISUALIZAR LAS VISTAS C4

### Opción 1: Structurizr Online (RECOMENDADO)

1. Ir a: https://structurizr.com/dsl
2. Abrir el archivo `Taller_ParkEasy_Architecture_Grupo4.dsl`
3. Copiar TODO el contenido
4. Pegar en el editor de Structurizr
5. Click en "Render"
6. Ver las vistas en el menú izquierdo:
   - **C4_L1_Context:** Vista de contexto (C4 Nivel 1)
   - **C4_L2_Containers:** Vista de contenedores (C4 Nivel 2)
   - **C4_L3_OperacionService:** Vista de componentes del Operacion Service (C4 Nivel 3)
   - **C4_Deployment_Production:** Diagrama de despliegue en AWS

### Opción 2: Structurizr Lite (Local)

```bash
docker pull structurizr/lite
docker run -it --rm -p 8080:8080 \
  -v $(pwd):/usr/local/structurizr \
  structurizr/lite
```

Abrir: http://localhost:8080

---

## 🏗️ DECISIONES ARQUITECTURALES CLAVE

### 1. Estilo Arquitectural: Service-Based Architecture

**Decisión:** Service-Based Architecture con 5 servicios de negocio independientes (Auth, Operación, Disponibilidad, Pagos, Reportes) detrás de un API Gateway.

**Alternativas consideradas:** Monolito modular, Microservicios

**Por qué lo elegimos:** Equilibra la modularidad necesaria para escalar los servicios críticos (entrada/salida, disponibilidad) de forma independiente, sin la complejidad operacional de microservicios que excede la capacidad de un equipo de 4 desarrolladores en 8 meses.

**Ver:** `Taller_ADR-001_[Nombre]_Grupo4.md`

---

### 2. Base de Datos: PostgreSQL (RDS Multi-AZ) + Redis + Read Replica

**Decisión:** PostgreSQL como base de datos principal (RDS Multi-AZ), Redis (ElastiCache) para disponibilidad en tiempo real, y una Read Replica de PostgreSQL para reportes.

**Alternativas consideradas:** MongoDB, MySQL, DynamoDB

**Por qué lo elegimos:** PostgreSQL ofrece transacciones ACID necesarias para la consistencia de reservas y pagos, soporte nativo para RDS Multi-AZ en AWS, y un modelo relacional apropiado para los datos estructurados del sistema. Redis permite el acceso sub-segundo a la disponibilidad de espacios.

**Ver:** `Taller_ADR-002_[Nombre]_Grupo4.md`

---

### 3. Integración con Sistema Legacy: Adaptador SOAP

**Decisión:** Adaptador SOAP encapsulado dentro del Operacion Service y Pagos Service para sincronizar con el sistema VB6 sin reemplazarlo durante el MVP.

**Alternativas consideradas:** Reemplazo completo del legacy, Anti-Corruption Layer independiente

**Por qué lo elegimos:** El sistema legacy no puede reemplazarse en el plazo del MVP. Un adaptador interno evita exponer SOAP al resto de los servicios y permite sustituirlo en fases posteriores sin impacto arquitectural.

**Ver:** `Taller_ADR-003_[Nombre]_Grupo4.md`

---

## 📊 RESUMEN DE LA ARQUITECTURA

### Estilo Arquitectural

Service-Based Architecture desplegada en AWS con contenedores Fargate (ECS).

### Componentes Principales

1. **Aplicación Web** - React / Next.js - Interfaz para conductores y administradores (disponibilidad, reservas, dashboards)
2. **App Móvil** - React Native - App para conductores (disponibilidad y reservas desde dispositivo móvil)
3. **Panel Operador** - React / Electron - Interfaz táctil instalada en casetas de entrada/salida
4. **API Gateway** - Kong / Express - Enruta solicitudes, valida tokens JWT y aplica rate limiting
5. **Auth Service** - Node.js / Express - Autenticación y autorización con JWT y roles diferenciados
6. **Operacion Service** - Node.js / Express - Gestiona reservas, control de acceso LPR e incidentes
7. **Disponibilidad Service** - Node.js / Express - Monitorea y expone ocupación en tiempo real
8. **Pagos Service** - Node.js / Express - Procesa pagos digitales y genera facturas electrónicas
9. **Reportes Service** - Node.js / Express - Genera dashboards y reportes de ingresos y ocupación

### Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend Web** | React / Next.js |
| **App Móvil** | React Native (Expo EAS) |
| **Panel Operador** | React / Electron |
| **Backend (servicios)** | Node.js 20 / Express |
| **API Gateway** | Kong / Express |
| **Base de Datos Principal** | PostgreSQL 14 (AWS RDS Multi-AZ) |
| **Base de Datos Reportes** | PostgreSQL 14 (AWS RDS Read Replica) |
| **Cache** | Redis 7 (AWS ElastiCache) |
| **Message Queue** | RabbitMQ (AWS Amazon MQ) |
| **Cloud** | AWS (ECS Fargate, RDS, ElastiCache, Amazon MQ, ALB) |

### Integraciones Externas

- **Cámaras LPR:** API REST – lectura automática de placas en entrada y salida
- **Sistema de Cobro Legacy (VB6):** SOAP/XML – sincronización de cobros durante el MVP
- **Wompi:** HTTPS – pasarela de pagos (tarjeta, Nequi, Daviplata)
- **Email/SMS Gateway:** SMTP/API – confirmaciones de reserva, notificaciones y facturas
- **DIAN:** HTTPS – remisión y validación de facturas electrónicas

---

## 💰 ESTIMACIÓN DE COSTOS

| Servicio | Costo mensual (USD) |
|----------|---------------------|
| AWS ECS Fargate (6 servicios, 2 tasks c/u) | ~$480 |
| AWS RDS PostgreSQL db.t3.large Multi-AZ | ~$280 |
| AWS RDS Read Replica db.t3.medium | ~$120 |
| AWS ElastiCache Redis (cache.t3.micro) | ~$60 |
| AWS Amazon MQ RabbitMQ (mq.t3.micro) | ~$60 |
| AWS Application Load Balancer | ~$30 |
| AWS S3 (almacenamiento facturas 5 años) | ~$25 |
| AWS CloudFront + Route 53 | ~$20 |
| Otros (CloudWatch, transfer, etc.) | ~$50 |
| **TOTAL** | **~$1.125 USD/mes** |

**¿Cumple con presupuesto de $2.000 USD/mes?** **SÍ** — margen de ~$875 USD para crecimiento.

> **Supuesto SUP-01:** El enunciado indica "$2.000.000/mes"; se interpreta como $2.000 USD/mes según lo documentado en el SRS (sección 6.1).

---

## 🎯 CÓMO CUMPLIMOS LOS DRIVERS

| Driver | Objetivo | Cómo lo cumplimos |
|--------|----------|-------------------|
| **DR-01: Performance** | Entrada/salida ≤ 5 seg P95 | Redis cache para disponibilidad; Operacion Service con auto-scaling 2–8 tasks en picos; LPR via REST directo |
| **DR-02: Escalabilidad** | 450 → 1.200 espacios sin rediseño | ECS auto-scaling por servicio; Read Replica separada para reportes; Redis escala independiente |
| **DR-03: Disponibilidad** | 0 downtime horas pico (7–10 am, 5–8 pm) | RDS Multi-AZ; ECS multi-task; ALB con health checks; modo contingencia manual en panel operador |
| **DR-04: Legacy** | SOAP/VB6 no reemplazable en MVP | Adaptador SOAP encapsulado en Operacion Service y Pagos Service; resto del sistema desacoplado |
| **DR-05: Regulatorio DIAN** | Retención facturas ≥ 5 años | S3 con replicación geográfica; facturas inmutables; recuperación ≤ 3 seg |
| **DR-06: Seguridad** | PCI-DSS + Ley 1581/2012 | JWT con expiración; Wompi maneja datos de tarjeta (no se almacenan en ParkEasy); HTTPS en todas las comunicaciones; encriptación de placas en BD |
| **DR-07: Costo** | ≤ $2.000 USD/mes | Costo estimado ~$1.125 USD/mes; instancias t3 para BD y cache en MVP |

---

## 📝 SUPUESTOS ASUMIDOS

1. **SUP-01 – Presupuesto:** El enunciado menciona "$2.000.000/mes"; se interpreta como $2.000 USD/mes. Se documenta como pendiente de confirmación con el cliente.
2. **SUP-02 – API LPR:** Las cámaras LPR instaladas en los 3 parqueaderos exponen una API REST documentada y funcional con uptime ≥ 99% y latencia < 200 ms.
3. **SUP-03 – Legacy SOAP:** El sistema VB6 acepta peticiones SOAP. La integración se implementará mediante ingeniería inversa del protocolo dado que la documentación es incompleta.
4. **SUP-04 – Wompi sandbox:** Wompi dispone de entorno sandbox disponible para el equipo durante el desarrollo y pruebas del MVP.
5. **SUP-05 – Identificador de conductor:** La matrícula del vehículo es el identificador único del conductor para el flujo de ingreso sin contacto (LPR).
6. **SUP-06 – Conectividad:** Los 3 parqueaderos tienen conectividad a internet estable con latencia < 100 ms hacia el API Backend.
7. **SUP-07 – Hardware casetas:** Cada caseta cuenta con una tableta o PC con pantalla táctil para ejecutar el Panel Operador (Electron).
8. **SUP-08 – Volumen de reservas:** Se asume que el 20% del volumen diario (~240 operaciones) corresponde a reservas anticipadas, lo que dimensiona la cola RabbitMQ.

---

## ⚠️ RIESGOS IDENTIFICADOS

| Riesgo | Mitigación |
|--------|------------|
| **Integración Legacy VB6 inestable** – Documentación SOAP incompleta puede generar errores de sincronización | Ingeniería inversa del protocolo en sprint 1; suite de pruebas de integración; modo fallback con registro manual en caseta |
| **Fallo de cámaras LPR en horas pico** – Un fallo de las cámaras en rush hour genera congestión severa | Modo contingencia manual activo siempre en el Panel Operador; alerta automática al operador si confianza LPR < 90% |
| **Subestimación de costos AWS** – El costo real puede superar la estimación si el tráfico crece más de lo proyectado | Monitoreo continuo con AWS Cost Explorer; alertas de presupuesto; instancias reservadas para RDS y ElastiCache en producción |

---

## 🔄 PROCESO DE TRABAJO DEL GRUPO

### División de Trabajo

| Integrante | Responsabilidades |
|------------|-------------------|
| Juan Camilo Alba | Líder del grupo, SRS, ADR-001 (Estilo Arquitectural) |
| Laura Juliana Garzón | ADR-002 (Base de Datos), vistas C4 (DSL Structurizr) |
| Carlos Villegas | ADR-003 (Integración Legacy), SAD |
| Arley Bernal | Revisión y integración de documentos, README |

### Metodología

Nos reunimos de forma virtual para analizar el enunciado juntos y distribuir responsabilidades. Cada integrante redactó su sección en paralelo usando Google Docs para colaborar. Antes de la entrega, revisamos entre todos la consistencia entre el SRS, los ADRs, las vistas C4 y el SAD.

---

## 💡 APRENDIZAJES Y REFLEXIONES

### ¿Qué aprendimos?

Aprendimos que las decisiones arquitecturales no son arbitrarias: cada una nace de un driver concreto y tiene trade-offs reales. Al evaluar microservicios vs. service-based, nos dimos cuenta de que el tamaño del equipo (4 personas) y el plazo (8 meses) son restricciones igual de importantes que los requisitos técnicos. Optar por microservicios habría sido una trampa de complejidad para un MVP.

También aprendimos a leer entre líneas de un enunciado de negocio para extraer drivers arquitecturales. El dato de "≤ 5 segundos P95" o "0 downtime en horas pico" no son solo requisitos: son fuerzas que moldean toda la arquitectura, desde la elección de Redis hasta el auto-scaling en ECS.

### Desafíos enfrentados

El mayor desafío fue modelar la integración con el sistema legacy VB6, para el cual la documentación es explícitamente incompleta en el enunciado. Decidimos encapsular el adaptador SOAP dentro de los servicios que lo necesitan y documentar el supuesto, en lugar de paralizar el diseño esperando información perfecta.

Otro reto fue estimar costos AWS de forma realista sin experiencia directa en producción. Usamos la calculadora oficial de AWS, anclamos las instancias a tipos t3 apropiados para MVP, y dejamos margen presupuestal deliberado.

### Si pudiéramos empezar de nuevo...

Empezaríamos por los drivers arquitecturales antes que por los requisitos funcionales. Definir primero DR-01 a DR-07 habría acelerado todas las decisiones posteriores y evitado algunas iteraciones en los ADRs.

---

## 📚 REFERENCIAS CONSULTADAS

- Ejemplo completo: CourtBooker (material del curso) – https://github.com/rocampoa/CourtBooker
- Structurizr DSL: https://structurizr.com/help/dsl
- AWS Pricing Calculator: https://calculator.aws/
- C4 Model: https://c4model.com/
- Formato ADR: https://adr.github.io/
- Ley 1581 de 2012 – Protección de datos personales (Colombia)
- PCI-DSS v4.0: https://www.pcisecuritystandards.org/
- Wompi API Docs: https://docs.wompi.co/

---

## ✅ VALIDACIÓN FINAL

Antes de entregar, verificamos:

- [x] Todos los archivos están incluidos en el ZIP
- [x] Archivo .dsl renderiza correctamente en Structurizr
- [x] SRS tiene mínimo 6 RF y 5 RNF con métricas
- [x] 3 ADRs completos con alternativas y trade-offs
- [x] SAD referencia correctamente todos los documentos
- [x] Costos estimados ≤ $2.000 USD/mes (~$1.125 USD/mes)
- [x] Documentos profesionales sin errores ortográficos
- [x] README explica claramente el trabajo

---

**Fecha de entrega:** 19/03/2026  
**Grupo:** 4  
**Curso:** Arquitectura de Software  
**Pontificia Universidad Javeriana**

---

## ANEXO: Estructura de Archivos Detallada

```
Grupo4_Taller_Documentacion_Arquitectural.zip
│
├── Taller_README_Grupo4.md (este archivo)
│   └── Explica todo el trabajo, cómo visualizar, decisiones clave
│
├── Taller_SRS_ParkEasy_Grupo4.md
│   └── Requisitos funcionales (RF-01 a RF-09) y no funcionales (RNF-01 a RNF-07)
│   └── Drivers arquitecturales DR-01 a DR-07
│
├── Taller_ADR-001_[NombreDecision]_Grupo4.md
│   └── Decisión: Estilo arquitectural (Service-Based Architecture)
│
├── Taller_ADR-002_[NombreDecision]_Grupo4.md
│   └── Decisión: Base de datos (PostgreSQL + Redis)
│
├── Taller_ADR-003_[NombreDecision]_Grupo4.md
│   └── Decisión: Integración con sistema legacy (Adaptador SOAP)
│
├── Taller_ParkEasy_Architecture_Grupo4.dsl
│   └── 4 vistas C4 en Structurizr DSL:
│       └── C4_L1_Context, C4_L2_Containers, C4_L3_OperacionService, C4_Deployment_Production
│
└── Taller_SAD_ParkEasy_Grupo4.md
    └── Documento maestro que integra todo
    └── Referencias a SRS, ADRs y vistas C4
```

---

**¡Gracias "Querido Profesor" por revisar nuestro trabajo!**
