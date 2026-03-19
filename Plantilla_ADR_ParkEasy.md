# ADR-00X: [Título de la Decisión]

<!-- INSTRUCCIONES:
- Reemplazar "00X" con 001, 002, 003
- Título debe ser acción + decisión. Ejemplo: "Adoptar Service-Based Architecture"
- Completar TODAS las secciones
- Ser específicos y justificar con drivers del SRS
-->

**Estado:** Propuesto | Aceptado | Rechazado  
**Fecha:** [DD/MM/YYYY]  
**Decisores:** [Nombres de integrantes del grupo]  
**Relacionado con:** [IDs de requisitos del SRS. Ej: RF-01, RNF-02, DR-03]  
**Grupo:** [Número de grupo]

---

## Contexto y Problema

<!-- INSTRUCCIONES:
- Explicar QUÉ problema estamos resolviendo
- Por QUÉ necesitamos tomar esta decisión
- Cuál es el CONTEXTO (restricciones, requisitos)
- Escribir 2-4 párrafos
-->

[Describir el problema aquí]

**Ejemplo:**
"Necesitamos decidir el estilo arquitectural para ParkEasy. El sistema debe soportar 1,200 entradas/salidas por día con picos de 80 vehículos/hora, integrarse con sistemas legacy, y ser mantenible por un equipo de 4 desarrolladores..."

---

## Drivers de Decisión

<!-- INSTRUCCIONES:
- Listar los factores que influyen en esta decisión
- Referenciar drivers del SRS (DR-XX)
- Incluir restricciones técnicas y de negocio
- Priorizar: Alta, Media, Baja
-->

- **DR-XX:** [Nombre del driver] - [Valor/Métrica] (Prioridad: Alta/Media/Baja)
- **DR-XX:** [Nombre del driver] - [Valor/Métrica] (Prioridad: Alta/Media/Baja)
- **DR-XX:** [Nombre del driver] - [Valor/Métrica] (Prioridad: Alta/Media/Baja)

**Ejemplo:**
- **DR-01:** Performance entrada/salida ≤ 5 seg (Alta prioridad)
- **DR-03:** Presupuesto ≤ $2.000.000/mes (Hard constraint)

---

## Alternativas Consideradas

<!-- INSTRUCCIONES:
- Documentar MÍNIMO 2 alternativas (además de la que eligen)
- Para cada alternativa, explicar brevemente qué es
- Listar pros y contras de cada una
-->

### Alternativa 1: [Nombre de la alternativa]

**Descripción:**
[Breve descripción de esta alternativa]

**Pros:**
- ✅ [Ventaja 1]
- ✅ [Ventaja 2]
- ✅ [Ventaja 3]

**Contras:**
- ❌ [Desventaja 1]
- ❌ [Desventaja 2]
- ❌ [Desventaja 3]

---

### Alternativa 2: [Nombre de la alternativa]

**Descripción:**
[Breve descripción de esta alternativa]

**Pros:**
- ✅ [Ventaja 1]
- ✅ [Ventaja 2]
- ✅ [Ventaja 3]

**Contras:**
- ❌ [Desventaja 1]
- ❌ [Desventaja 2]
- ❌ [Desventaja 3]

---

### Alternativa 3: [Nombre de la alternativa] (OPCIONAL - si hay más)

**Descripción:**
[Breve descripción]

**Pros:**
- ✅ [Ventaja 1]
- ✅ [Ventaja 2]

**Contras:**
- ❌ [Desventaja 1]
- ❌ [Desventaja 2]

---

## Decisión

<!-- INSTRUCCIONES:
- Declarar claramente QUÉ decidieron
- Explicar CÓMO se implementará
- Ser específicos (no vago)
-->

[Escribir la decisión aquí]

**Ejemplo:**
"Adoptamos **Service-Based Architecture** con 4 servicios independientes:
1. Parking Service (disponibilidad y reservas)
2. Payment Service (cobros y facturación)
3. Integration Service (cámaras LPR y legacy)
4. Admin Service (reportes)

Cada servicio se desplegará independientemente en AWS ECS, compartirán base de datos PostgreSQL..."

---

## Justificación

<!-- INSTRUCCIONES:
- Explicar POR QUÉ eligieron esta opción
- Referenciar drivers del SRS
- Comparar con alternativas descartadas
- Explicar trade-offs aceptados
- Escribir 3-5 párrafos
-->

### Por qué esta opción (y no las otras):

[Explicar aquí]

**Ejemplo:**
"Elegimos Service-Based sobre Monolito porque necesitamos escalar servicios independientemente (DR-02). El Parking Service recibirá más carga que Admin Service, y con Service-Based podemos escalar solo lo necesario.

Elegimos Service-Based sobre Microservicios porque nuestro equipo es pequeño (4 devs) y el overhead operacional de microservicios excede nuestra capacidad (DR-04)..."

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-XX | [Explicación] |
| DR-XX | [Explicación] |

---

## Consecuencias

<!-- INSTRUCCIONES:
- Listar consecuencias POSITIVAS
- Listar consecuencias NEGATIVAS (trade-offs)
- Para negativas, explicar cómo las mitigan
- Ser honestos - toda decisión tiene costos
-->

### ✅ Positivas:

1. **[Consecuencia positiva 1]:** [Explicación]
2. **[Consecuencia positiva 2]:** [Explicación]
3. **[Consecuencia positiva 3]:** [Explicación]

**Ejemplo:**
1. **Escalabilidad selectiva:** Podemos escalar Parking Service sin escalar Admin Service
2. **Despliegues independientes:** Bug en Payment Service no requiere redesplegar todo

### ⚠️ Negativas (y mitigaciones):

1. **[Consecuencia negativa 1]**
   - **Riesgo:** [Explicar el riesgo]
   - **Mitigación:** [Cómo lo mitigan]

2. **[Consecuencia negativa 2]**
   - **Riesgo:** [Explicar el riesgo]
   - **Mitigación:** [Cómo lo mitigan]

**Ejemplo:**
1. **Base de datos compartida crea acoplamiento**
   - **Riesgo:** Cambios en schema pueden afectar múltiples servicios
   - **Mitigación:** Usar schemas separados por servicio, code reviews de cambios de BD

---

## Alternativas Descartadas (Detalle)

<!-- INSTRUCCIONES:
- Para cada alternativa NO elegida, explicar POR QUÉ fue descartada
- Explicar en qué escenarios SÍ sería mejor
-->

### Por qué se descartó [Alternativa 1]:

[Explicación de 2-3 párrafos]

**Cuándo sería mejor:**
- [Escenario donde esta opción sería la correcta]
- [Ejemplo: "Si el equipo tuviera 10+ developers"]

### Por qué se descartó [Alternativa 2]:

[Explicación de 2-3 párrafos]

**Cuándo sería mejor:**
- [Escenario donde esta opción sería la correcta]

---

## Validación

<!-- INSTRUCCIONES:
- Verificar que la decisión cumple cada driver
- Usar checkboxes
-->

- [ ] Cumple con DR-01: [Explicar cómo]
- [ ] Cumple con DR-02: [Explicar cómo]
- [ ] Cumple con DR-03: [Explicar cómo]
- [ ] Cumple con DR-XX: [Explicar cómo]

---

## Notas Adicionales

<!-- OPCIONAL: Información adicional relevante -->

[Si hay notas adicionales, agregarlas aquí]

**Ejemplos:**
- "Esta decisión se revisará en el Mes 6 cuando evaluemos carga real"
- "Si el sistema crece a > 2,000 espacios, consideraremos migrar a microservicios"

---

## Referencias

<!-- Listar documentos o recursos consultados -->

- [SRS] Software Requirements Specification - ParkEasy
- [Referencia 2]
- [Referencia 3]

---

**Estado final:** ACEPTADO ✅ / RECHAZADO ❌

**Firmas del equipo:**
- [Nombre 1]: __________ - Fecha: ___/___/___
- [Nombre 2]: __________ - Fecha: ___/___/___
- [Nombre 3]: __________ - Fecha: ___/___/___
- [Nombre 4]: __________ - Fecha: ___/___/___

---

## NOTAS PARA TENER EN CUENTA

### ✅ Checklist de Calidad del ADR

Antes de entregar, verificar:

- [ ] Título claro y acción específica
- [ ] Contexto bien explicado (2-4 párrafos)
- [ ] Mínimo 2 alternativas documentadas con pros/contras
- [ ] Decisión claramente declarada
- [ ] Justificación referencia drivers del SRS
- [ ] Trade-offs explícitos (consecuencias negativas)
- [ ] Validación contra cada driver relevante
- [ ] Explicación de por qué descartaron otras opciones

### 💡 Tips

1. **No hay decisión "correcta" única:** Lo importante es la JUSTIFICACIÓN
2. **Referenciar el SRS:** Cada ADR debe conectar con drivers (DR-XX)
3. **Ser honestos con trade-offs:** Toda decisión tiene costos - documentarlos
4. **Pensar en alternativas reales:** No inventar strawman solo para descartarlos
5. **Cuantificar cuando sea posible:** "Reduce latencia 40%" mejor que "mejora latencia"

### 📋 ADRs Sugeridos para ParkEasy

**ADR-001:** Estilo arquitectural
- Opciones: Monolito, Service-Based, Microservicios
- Drivers: DR-02 (equipo), DR-03 (costo), DR-04 (escalabilidad)

**ADR-002:** Base de datos
- Opciones: PostgreSQL, MongoDB, DynamoDB, MySQL
- Drivers: DR-01 (performance), DR-05 (disponibilidad), DR-03 (costo)

**ADR-003:** Integración con sistema legacy
- Opciones: Adapter pattern, Anti-corruption layer, API Gateway
- Drivers: Restricción técnica (SOAP legacy), DR-05 (disponibilidad)

**ADR-003 (alternativa):** Estrategia de cache
- Opciones: Redis, Memcached, No cache
- Drivers: DR-01 (performance), DR-03 (costo)

### ⚠️ Errores Comunes a Evitar

❌ No justificar la decisión  
✅ Explicar por qué con base en drivers

❌ Solo listar pros de la opción elegida  
✅ Documentar trade-offs (qué sacrificamos)

❌ Alternativas inventadas que nadie usaría  
✅ Alternativas reales que se usan en la industria

❌ No referenciar el SRS  
✅ Conectar cada decisión con drivers (DR-XX)

❌ Justificación vaga: "Es mejor"  
✅ Justificación específica: "Reduce costo 40% vs Alternativa X"
