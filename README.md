# Taller: Documentación Arquitectural - ParkEasy
## Grupo [X]

**Integrantes:**
- [Nombre 1] - [Código] - [Email]
- [Nombre 2] - [Código] - [Email]
- [Nombre 3] - [Código] - [Email]
- [Nombre 4] - [Código] - [Email]

**Fecha de entrega:** [DD/MM/YYYY]

---

## 📋 CONTENIDO DE LA ENTREGA

Este ZIP contiene la documentación arquitectural completa del sistema ParkEasy:

```
├── Taller_README_GrupoX.md                     (Este archivo)
├── Taller_SRS_ParkEasy_GrupoX.md              (Requisitos)
├── Taller_ADR-001_[Nombre]_GrupoX.md          (Decisión arquitectural 1)
├── Taller_ADR-002_[Nombre]_GrupoX.md          (Decisión arquitectural 2)
├── Taller_ADR-003_[Nombre]_GrupoX.md          (Decisión arquitectural 3)
├── Taller_ParkEasy_Architecture_GrupoX.dsl    (Vistas C4)
└── Taller_SAD_ParkEasy_GrupoX.md              (Documento arquitectural)
```

---

## 🎨 CÓMO VISUALIZAR LAS VISTAS C4

### Opción 1: Structurizr Online (RECOMENDADO)

1. Ir a: https://structurizr.com/dsl
2. Abrir el archivo `Taller_ParkEasy_Architecture_GrupoX.dsl`
3. Copiar TODO el contenido
4. Pegar en el editor de Structurizr
5. Click en "Render"
6. Ver las vistas en el menú izquierdo:
   - **SystemContext:** Vista de contexto (C4 Nivel 1)
   - **Containers:** Vista de contenedores (C4 Nivel 2)
   - **Components[...]:** Vista de componentes (C4 Nivel 3)

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

<!-- INSTRUCCIONES: Resumir brevemente las 3 decisiones más importantes -->

### 1. Estilo Arquitectural: [Nombre]

**Decisión:** [Qué eligieron - Monolito/Service-Based/Microservicios]

**Alternativas consideradas:** [Listar brevemente]

**Por qué lo elegimos:** [1-2 líneas]

**Ver:** `Taller_ADR-001_[Nombre]_GrupoX.md`

---

### 2. Base de Datos: [Nombre]

**Decisión:** [Qué eligieron - PostgreSQL/MongoDB/etc.]

**Alternativas consideradas:** [Listar brevemente]

**Por qué lo elegimos:** [1-2 líneas]

**Ver:** `Taller_ADR-002_[Nombre]_GrupoX.md`

---

### 3. [Tercera Decisión]

**Decisión:** [Qué decidieron]

**Alternativas consideradas:** [Listar brevemente]

**Por qué lo elegimos:** [1-2 líneas]

**Ver:** `Taller_ADR-003_[Nombre]_GrupoX.md`

---

## 📊 RESUMEN DE LA ARQUITECTURA

### Estilo Arquitectural

[Nombre del estilo - ej: Service-Based Architecture]

### Componentes Principales

<!-- INSTRUCCIONES: Listar servicios/aplicaciones principales -->

1. **[Nombre Componente 1]** - [Tecnología] - [Responsabilidad breve]
2. **[Nombre Componente 2]** - [Tecnología] - [Responsabilidad breve]
3. **[Nombre Componente 3]** - [Tecnología] - [Responsabilidad breve]
4. [Etc.]

**Ejemplo:**
1. **Web App** - React.js - Interfaz de usuario
2. **Parking Service** - Node.js - Gestión de disponibilidad y reservas
3. **Payment Service** - Node.js - Procesamiento de pagos

### Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | [Ej: React.js 18] |
| **Backend** | [Ej: Node.js 20] |
| **Base de Datos** | [Ej: PostgreSQL 14] |
| **Cache** | [Ej: Redis 7, o "No aplica"] |
| **Cloud** | [Ej: AWS] |

### Integrations Externas

- **[Sistema 1]:** [Ej: Cámaras LPR - API REST]
- **[Sistema 2]:** [Ej: Sistema Legacy - SOAP]
- **[Sistema 3]:** [Ej: Wompi - Pagos]
- [Etc.]

---

## 💰 ESTIMACIÓN DE COSTOS

<!-- INSTRUCCIONES: Sumar costos de todos los servicios cloud -->

| Servicio | Costo mensual |
|----------|---------------|
| [Servicio 1] | $[XXX] |
| [Servicio 2] | $[XXX] |
| [Servicio 3] | $[XXX] |
| **TOTAL** | **$[XXX]/mes** |

**¿Cumple con presupuesto de $2.000.000/mes?** [SÍ / NO]

---

## 🎯 CÓMO CUMPLIMOS LOS DRIVERS

<!-- INSTRUCCIONES: Mostrar cómo la arquitectura cumple drivers clave -->

| Driver | Objetivo                    | Cómo lo cumplimos |
|--------|-----------------------------|-------------------|
| **DR-01: Performance** | [Ej: ≤5 seg entrada/salida] | [Ej: Cache de disponibilidad, DB indexada] |
| **DR-02: Escalabilidad** | [Ej: 450→1,200 espacios]    | [Ej: Auto-scaling en ECS] |
| **DR-03: Presupuesto** | [Ej: ≤$2.000.000/mes]       | [Ej: Costos estimados = $X,XXX] |
| **DR-04: [Otro]** | [Objetivo]                  | [Cómo] |

---

## 📝 SUPUESTOS ASUMIDOS

<!-- INSTRUCCIONES: Listar supuestos que hicieron (del SRS) -->

Se asume lo siguiente para completar el diseño:

1. **[Supuesto 1]:** [Descripción]
2. **[Supuesto 2]:** [Descripción]
3. **[Supuesto 3]:** [Descripción]

**Ejemplo:**
1. **API de LPR:** Se asume que el API tiene uptime ≥99% y latencia <200ms
2. **Crecimiento:** Se asume un crecimiento lineal de 50 espacios por trimestre
3. **Volumen de pagos:** Se supone que un 70% de usuarios pagan con tarjeta, 30% digital

---

## ⚠️ RIESGOS IDENTIFICADOS

<!-- INSTRUCCIONES: Copiar 3 riesgos principales del SAD -->

| Riesgo | Mitigación |
|--------|------------|
| **[Riesgo 1]** | [Cómo lo mitigan] |
| **[Riesgo 2]** | [Cómo lo mitigan] |
| **[Riesgo 3]** | [Cómo lo mitigan] |

---

## 🔄 PROCESO DE TRABAJO DEL GRUPO

<!-- INSTRUCCIONES: Explicar cómo trabajaron en equipo -->

### División de Trabajo

| Integrante | Responsabilidades |
|------------|-------------------|
| [Nombre 1] | [Ej: SRS, ADR-001] |
| [Nombre 2] | [Ej: ADR-002, Vistas C4] |
| [Nombre 3] | [Ej: ADR-003, SAD] |
| [Nombre 4] | [Ej: Revisión, integración] |

### Metodología

[Explicar brevemente cómo trabajaron]

**Ejemplo:**
"Nos reunimos 3 veces por Zoom. Primero analizamos requisitos juntos, luego dividimos ADRs. Usamos Google Docs para colaborar en SRS y SAD. Revisamos el trabajo de cada uno antes de entregar."

---

## 💡 APRENDIZAJES Y REFLEXIONES

<!-- INSTRUCCIONES: Reflexionar sobre el proceso -->

### ¿Qué aprendimos?

[Escribir 2-3 párrafos sobre qué aprendieron con este taller]

**Ejemplo:**
"Aprendimos la importancia de justificar decisiones arquitecturales. Inicialmente queríamos usar microservicios porque 'suenan bien', pero al analizar los trade-offs nos dimos cuenta que Service-Based era más apropiado para un equipo de 4 personas..."

### Desafíos enfrentados

[Explicar 2-3 desafíos que tuvieron]

**Ejemplo:**
"El mayor desafío fue estimar costos de AWS sin experiencia previa. Usamos calculadora de AWS y consultamos ejemplos similares..."

### Si pudiéramos empezar de nuevo...

[Qué harían diferente]

---

## 📚 REFERENCIAS CONSULTADAS

<!-- INSTRUCCIONES: Listar recursos que consultaron -->

- Ejemplo completo: CourtBooker (material del curso)
- Structurizr DSL: https://structurizr.com/help/dsl
- AWS Pricing Calculator: https://calculator.aws/
- C4 model https://c4model.com/
- [Otras referencias]

---

## ✅ VALIDACIÓN FINAL

Antes de entregar, verificamos:

- [x] Todos los archivos están incluidos en el ZIP
- [x] Archivo .dsl renderiza correctamente en Structurizr
- [x] SRS tiene mínimo 6 RF y 5 RNF con métricas
- [x] 3 ADRs completos con alternativas y trade-offs
- [x] SAD referencia correctamente todos los documentos
- [x] Costos suman ≤ $2.000.000/mes
- [x] Documentos profesionales sin errores ortográficos
- [x] README explica claramente el trabajo

---

**Fecha de entrega:** [DD/MM/YYYY]  
**Grupo:** [Número]  
**Curso:** Arquitectura de Software  
**Pontificia Universidad Javeriana**

---

## ANEXO: Estructura de Archivos Detallada

```
GrupoX_Taller_Documentacion_Arquitectural.zip
│
├── Taller_README_GrupoX.md (este archivo)
│   └── Explica todo el trabajo, cómo visualizar, decisiones clave
│
├── Taller_SRS_ParkEasy_GrupoX.md
│   └── Requisitos funcionales y no funcionales
│   └── Drivers arquitecturales identificados
│
├── Taller_ADR-001_[NombreDecision]_GrupoX.md
│   └── Decisión 1 (típicamente: estilo arquitectural)
│
├── Taller_ADR-002_[NombreDecision]_GrupoX.md
│   └── Decisión 2 (típicamente: base de datos)
│
├── Taller_ADR-003_[NombreDecision]_GrupoX.md
│   └── Decisión 3 (otra decisión importante)
│
├── Taller_ParkEasy_Architecture_GrupoX.dsl
│   └── Vistas C4 en Structurizr DSL
│   └── Context, Container, Component
│
└── Taller_SAD_ParkEasy_GrupoX.md
    └── Documento maestro que integra todo
    └── Referencias a SRS, ADRs y vistas C4
```

---

**¡Gracias "Querido Profesor" por revisar nuestro trabajo!**
