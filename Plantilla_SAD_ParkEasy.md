# Software Architecture Document (SAD)
## Sistema de Gestión de Parqueaderos - "ParkEasy"

**Versión:** 1.0  
**Fecha:** [Completar]  
**Grupo:** [Número de grupo]  
**Preparado por:**
- [Nombre 1] - [Código]
- [Nombre 2] - [Código]
- [Nombre 3] - [Código]
- [Nombre 4] - [Código]

---

## CONTROL DE VERSIONES

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 0.1 | [Fecha] | [Nombre] | Borrador inicial |
| 1.0 | [Fecha] | [Grupo completo] | Versión final para entrega |

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

<!-- INSTRUCCIONES: Explicar para qué sirve este SAD -->
Este documento describe la arquitectura del sistema [completar descripción breve de ParkEasy].

Este documento sirve como:
- [Completar: para quién sirve y para qué]

### 1.2 Audiencia

| Rol | Uso de este documento |
|-----|----------------------|
| **Desarrolladores** | [Completar] |
| **Arquitectos** | [Completar] |
| **Profesor** | Evaluar diseño arquitectural |

### 1.3 Referencias

<!-- INSTRUCCIONES: Listar documentos relacionados -->
- **[SRS]** `Taller_SRS_ParkEasy_GrupoX.md` - Documento de requisitos
- **[DSL]** `Taller_ParkEasy_Architecture_GrupoX.dsl` - Vistas C4 en Structurizr
- **[ADR-001]** `Taller_ADR-001_[Nombre]_GrupoX.md` - [Título de la decisión]
- **[ADR-002]** `Taller_ADR-002_[Nombre]_GrupoX.md` - [Título de la decisión]
- **[ADR-003]** `Taller_ADR-003_[Nombre]_GrupoX.md` - [Título de la decisión]

### 1.4 Alcance

<!-- INSTRUCCIONES: Copiar alcance del SRS -->
Este documento cubre la arquitectura del **MVP** de ParkEasy.

**Dentro de alcance:**
- [Copiar de SRS]

**Fuera de alcance:**
- [Copiar de SRS]

---

## 2. DESCRIPCIÓN GENERAL DE LA ARQUITECTURA

### 2.1 Filosofía de Diseño

<!-- INSTRUCCIONES: Explicar los principios que guiaron el diseño -->
La arquitectura de ParkEasy sigue estos principios:

1. **[Principio 1]:** [Explicación]
2. **[Principio 2]:** [Explicación]
3. **[Principio 3]:** [Explicación]

**Ejemplo:**
1. **Time-to-market:** Priorizar entrega en 8 meses
2. **Costo-eficiencia:** Mantener infraestructura ≤ $2.000.000/mes

### 2.2 Estilo Arquitectural Principal

<!-- INSTRUCCIONES: Referenciar ADR-001 -->
**[Nombre del estilo]** (ver [ADR-001])

[Breve descripción del estilo elegido - 2-3 párrafos]

**Justificación:** [Por qué eligieron este estilo - referenciar drivers]

### 2.3 Drivers Arquitecturales (ASRs)

<!-- INSTRUCCIONES: Copiar tabla de drivers del SRS -->
Los siguientes Architecturally Significant Requirements guiaron las decisiones:

| ID | Driver | Valor | Prioridad |
|----|--------|-------|-----------|
| **DR-01** | [Copiar de SRS] | [Valor] | [Prioridad] |
| **DR-02** | [Copiar de SRS] | [Valor] | [Prioridad] |
| **DR-03** | [Copiar de SRS] | [Valor] | [Prioridad] |
| **DR-04** | [Copiar de SRS] | [Valor] | [Prioridad] |
| **DR-05** | [Copiar de SRS] | [Valor] | [Prioridad] |

---

## 3. VISTAS ARQUITECTURALES (C4)

<!-- INSTRUCCIONES: Explicar cómo visualizar las vistas C4 -->

Este documento utiliza el **modelo C4** para describir la arquitectura.

**Archivo Structurizr DSL:** `Taller_ParkEasy_Architecture_GrupoX.dsl`

**Cómo visualizar:**
1. Ir a https://structurizr.com/dsl
2. Copiar contenido del archivo .dsl
3. Click en "Render"
4. Ver vistas en menú izquierdo

### 3.1 C4 Nivel 1: Context Diagram

**Propósito:** Mostrar cómo ParkEasy se relaciona con usuarios y sistemas externos.

<!-- INSTRUCCIONES: Describir qué se ve en el diagrama Context -->

**Elementos clave:**
- **Usuarios:** [Listar]
- **Sistema principal:** ParkEasy
- **Sistemas externos:** [Listar]

**Vista en Structurizr:** "SystemContext"

### 3.2 C4 Nivel 2: Container Diagram

**Propósito:** Mostrar los contenedores que componen ParkEasy.

<!-- INSTRUCCIONES: Listar contenedores definidos en el .dsl -->

**Contenedores principales:**

| Contenedor | Tecnología | Responsabilidad |
|------------|------------|-----------------|
| **[Nombre]** | [Tecnología] | [Qué hace] |
| **[Nombre]** | [Tecnología] | [Qué hace] |
| **[Nombre]** | [Tecnología] | [Qué hace] |

**Ejemplo:**
| **Web App** | React.js | Interfaz de usuario |
| **Parking Service** | Node.js + Express | Gestión de disponibilidad |

**Vista en Structurizr:** "Containers"

### 3.3 C4 Nivel 3: Component Diagrams

**Propósito:** Mostrar componentes internos de [nombre del servicio].

<!-- INSTRUCCIONES: Describir componentes del servicio que documentaron -->

**Servicio documentado:** [Nombre del servicio]

**Componentes:**

| Componente | Responsabilidad |
|------------|-----------------|
| **[Nombre]** | [Qué hace] |
| **[Nombre]** | [Qué hace] |
| **[Nombre]** | [Qué hace] |

**Vista en Structurizr:** "Components[NombreServicio]"

---

## 4. DECISIONES ARQUITECTURALES (ADRs)

<!-- INSTRUCCIONES: Resumir cada uno de sus 3 ADRs -->

### 4.1 ADR-001: [Título de la decisión]

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-001_[Nombre]_GrupoX.md`

**Resumen:** [Breve resumen en 2-3 líneas de QUÉ decidieron]

**Alternativas consideradas:** [Listar brevemente]

**Trade-off aceptado:** [Principal trade-off]

**Ver documento completo:** [ADR-001]

---

### 4.2 ADR-002: [Título de la decisión]

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-002_[Nombre]_GrupoX.md`

**Resumen:** [Breve resumen en 2-3 líneas]

**Alternativas consideradas:** [Listar brevemente]

**Trade-off aceptado:** [Principal trade-off]

**Ver documento completo:** [ADR-002]

---

### 4.3 ADR-003: [Título de la decisión]

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-003_[Nombre]_GrupoX.md`

**Resumen:** [Breve resumen en 2-3 líneas]

**Alternativas consideradas:** [Listar brevemente]

**Trade-off aceptado:** [Principal trade-off]

**Ver documento completo:** [ADR-003]

---

## 5. TECNOLOGÍAS Y HERRAMIENTAS

### 5.1 Stack Tecnológico

<!-- INSTRUCCIONES: Listar todas las tecnologías que usarán -->

| Capa | Tecnología | Versión | Justificación |
|------|------------|---------|---------------|
| **Frontend** | [Ej: React.js] | [Ej: 18.x] | [Por qué] |
| **Backend** | [Ej: Node.js] | [Ej: 20 LTS] | [Por qué] |
| **Database** | [Completar] | [Completar] | [Ver ADR-002] |
| **Cache** | [Si aplica] | [Versión] | [Por qué] |
| **Message Queue** | [Si aplica] | [Versión] | [Por qué] |

### 5.2 Servicios Cloud

<!-- INSTRUCCIONES: Listar servicios cloud y estimar costos -->

**Proveedor:** [AWS / Azure / GCP]

| Servicio | Uso | Costo estimado/mes |
|----------|-----|-------------------|
| **[Ej: ECS]** | [Hosting de servicios] | $[XXX] |
| **[Ej: RDS]** | [Base de datos] | $[XXX] |
| **[Completar]** | [Completar] | $[XXX] |
| **TOTAL** | | **$[XXX]/mes** |

**Validación:** ¿Cumple con DR-XX (presupuesto ≤ $2.000.0000/mes)? [Sí/No]

### 5.3 Servicios Externos

<!-- INSTRUCCIONES: Listar APIs/servicios de terceros -->

| Servicio | Uso | Costo |
|----------|-----|-------|
| **Sistema LPR** | [Uso] | [Costo si aplica] |
| **Pasarela de pagos** | [Uso] | [% por transacción] |
| **[Completar]** | [Completar] | [Completar] |

---

## 6. SEGURIDAD

### 6.1 Autenticación y Autorización

**Mecanismo:** [Ej: JWT, OAuth2, Sesiones]

**Flujo:**
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

**Roles:**
- `driver`: [Permisos]
- `operator`: [Permisos]
- `admin`: [Permisos]

### 6.2 Protección de Datos

<!-- INSTRUCCIONES: Explicar cómo cumplen con Ley 1581 -->

**Cumplimiento Ley 1581 (Colombia):**
- [ ] Consentimiento explícito
- [ ] Política de privacidad
- [ ] Encriptación en tránsito (TLS)
- [ ] Encriptación en reposo
- [ ] [Otros]

**Datos sensibles:**
- Placas vehiculares: [Cómo se protegen]
- Datos de pago: [Cómo se manejan - PCI-DSS]

### 6.3 Protección de APIs

| Medida | Implementación |
|--------|----------------|
| **HTTPS** | [Sí/No - cómo] |
| **Rate limiting** | [Cómo - ej: 100 req/min] |
| **Input validation** | [Cómo] |
| **[Otras]** | [Completar] |

---

## 7. DESPLIEGUE E INFRAESTRUCTURA

### 7.1 Ambientes

| Ambiente | Propósito | URL |
|----------|-----------|-----|
| **Development** | [Propósito] | localhost |
| **Staging** | [Propósito] | [URL] |
| **Production** | [Propósito] | [URL] |

### 7.2 Estrategia de Despliegue

<!-- INSTRUCCIONES: Explicar cómo despliegan servicios -->

**Método:** [Blue-Green / Rolling / Canary]

**Proceso:**
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

### 7.3 Configuración de Infraestructura

<!-- INSTRUCCIONES: Especificar configuración de servicios cloud -->

**Ejemplo - ECS Services:**

| Service | Instancias | CPU | RAM |
|---------|-----------|-----|-----|
| [Nombre Servicio 1] | [#] | [vCPU] | [GB] |
| [Nombre Servicio 2] | [#] | [vCPU] | [GB] |

**Base de Datos:**
- Instancia: [Tipo - ej: db.t3.medium]
- Storage: [GB]
- Multi-AZ: [Sí/No]
- Backups: [Configuración]

### 7.4 Monitoreo y Alertas

<!-- INSTRUCCIONES: Definir qué monitorean -->

**Métricas clave:**
- [Métrica 1] - Threshold: [Valor] - Alerta: [Acción]
- [Métrica 2] - Threshold: [Valor] - Alerta: [Acción]

**Herramientas:**
- [Ej: CloudWatch, Grafana, Prometheus]

---

## 8. CALIDAD Y ATRIBUTOS

### 8.1 Mapa de Atributos a Decisiones

<!-- INSTRUCCIONES: Mostrar cómo cada decisión cumple drivers -->

| Atributo | Objetivo (del SRS) | Decisión arquitectural |
|----------|-------------------|------------------------|
| **Performance** | [RNF-XX: Valor] | [ADR-XX: Qué decisión] |
| **Availability** | [RNF-XX: Valor] | [ADR-XX: Qué decisión] |
| **Scalability** | [RNF-XX: Valor] | [ADR-XX: Qué decisión] |
| **Security** | [RNF-XX: Valor] | [Qué decisiones] |
| **Cost** | [RNF-XX: Valor] | [ADR-XX: Qué decisión] |

### 8.2 Tácticas Arquitecturales Aplicadas

<!-- INSTRUCCIONES: Listar tácticas específicas para cada atributo -->

**Para Performance:**
- ✅ [Táctica 1 - ej: Cache de disponibilidad]
- ✅ [Táctica 2]

**Para Availability:**
- ✅ [Táctica 1 - ej: Multi-AZ deployment]
- ✅ [Táctica 2]

**Para [Otro atributo]:**
- ✅ [Completar]

### 8.3 Testing Strategy

| Tipo | Herramienta | Coverage objetivo |
|------|-------------|-------------------|
| **Unit tests** | [Ej: Jest] | [%] |
| **Integration tests** | [Herramienta] | [Alcance] |
| **E2E tests** | [Herramienta] | [Flujos] |
| **Load tests** | [Ej: k6] | [Carga objetivo] |

---

## 9. RIESGOS Y DEUDA TÉCNICA

### 9.1 Riesgos Técnicos Identificados

<!-- INSTRUCCIONES: Listar riesgos que identificaron -->

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|--------------|---------|------------|
| **R-01** | [Descripción del riesgo] | Baja/Media/Alta | Bajo/Medio/Alto | [Cómo mitigan] |
| **R-02** | [Completar] | [Completar] | [Completar] | [Completar] |
| **R-03** | [Completar] | [Completar] | [Completar] | [Completar] |

**Ejemplo:**
| **R-01** | Sistema LPR no documentado bien | Media | Alto | Crear adapter layer, tests extensivos |

### 9.2 Deuda Técnica Aceptada

<!-- INSTRUCCIONES: Listar deuda técnica que aceptan conscientemente -->

| Ítem | Justificación | Plan de resolución |
|------|---------------|-------------------|
| **[Ej: No DB por servicio]** | [Por qué lo aceptan] | [Cuándo/cómo resolverán] |
| **[Otro]** | [Completar] | [Completar] |

### 9.3 Supuestos Críticos

<!-- INSTRUCCIONES: Copiar supuestos del SRS -->

1. [Supuesto 1 - del SRS]
2. [Supuesto 2 - del SRS]
3. [Supuesto 3 - del SRS]

---

## APROBACIONES

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | [Nombre] | __________ | ___/___/___ |
| **Arquitecto** | [Nombre] | __________ | ___/___/___ |
| **Desarrollador 1** | [Nombre] | __________ | ___/___/___ |
| **Desarrollador 2** | [Nombre] | __________ | ___/___/___ |

---

**Fin del Documento SAD**

---

## NOTAS PARA TENER EN CUENTA

### ✅ Checklist de Calidad

- [ ] Referencias correctas a SRS y 3 ADRs
- [ ] Instrucciones claras de cómo ver vistas C4
- [ ] Stack tecnológico completo especificado
- [ ] Costos estimados suman ≤ $2.000.000/mes
- [ ] Mapa de atributos muestra trazabilidad
- [ ] Riesgos identificados con mitigaciones
- [ ] Documento profesional y bien redactado
- [ ] Sin errores ortográficos

### 💡 Tips

1. **Copiar del SRS:** No reescribir requisitos, referenciarlos
2. **Referenciar ADRs:** Resumir brevemente, enlazar al documento completo
3. **Ser específicos:** "React 18" mejor que "React"
4. **Validar costos:** Sumar todos los servicios cloud
5. **Trazabilidad:** Cada decisión debe trazarse a drivers del SRS

### ⚠️ Errores Comunes

❌ No incluir instrucciones de cómo ver vistas C4  
✅ Explicar paso a paso con URL de Structurizr

❌ Copiar texto completo de ADRs  
✅ Resumir brevemente y referenciar

❌ Tecnologías genéricas: "Base de datos"  
✅ Específicas: "PostgreSQL 14 en RDS Multi-AZ"

❌ No validar presupuesto  
✅ Sumar costos y verificar ≤ $2.000.000/mes
