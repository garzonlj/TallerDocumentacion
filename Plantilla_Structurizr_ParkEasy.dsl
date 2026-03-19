workspace "ParkEasy - Sistema de Gestión de Parqueaderos" "Arquitectura del sistema ParkEasy - Grupo [X]" {

    /*
    ============================================================================
    INSTRUCCIONES
    ============================================================================
    
    Este archivo define las vistas arquitecturales C4 de ParkEasy usando Structurizr DSL.
    
    CÓMO VISUALIZAR:
    1. Ir a https://structurizr.com/dsl
    2. Copiar TODO este archivo y pegarlo
    3. Click en "Render"
    4. Ver las vistas en el menú izquierdo
    
    CÓMO COMPLETAR:
    1. Reemplazar [COMPLETAR] con información real
    2. Agregar servicios/contenedores según su diseño
    3. Definir relaciones entre componentes
    4. Especificar tecnologías
    
    VISTAS REQUERIDAS:
    - ✅ Context (Nivel 1 C4): Sistema + Usuarios + Sistemas externos
    - ✅ Container (Nivel 2 C4): Aplicaciones y servicios internos
    - ✅ Component (Nivel 3 C4): Componentes de al menos 1 contenedor
    
    FORMATO:
    - Comentarios en /* ... */ o // ...
    - Elementos: persona, softwareSystem, container, component
    - Relaciones: ->
    - Tecnología entre comillas
    
    ============================================================================
    */

    model {
        # =================================================================
        # NIVEL 1: PERSONAS (USUARIOS EXTERNOS)
        # =================================================================
        
        /*
        Definir los 3 tipos de usuarios de ParkEasy.
        Sintaxis: nombre = person "Nombre visible" "Descripción"
        */
        
        driver = person "Conductor" "Persona que busca parquear su vehículo en uno de los parqueaderos"
        
        operator = person "Operador" "Personal en casetas que [COMPLETAR descripción]"
        
        administrator = person "Administrador" "Gerente que [COMPLETAR descripción]"
        
        # =================================================================
        # SISTEMAS EXTERNOS
        # =================================================================
        
        /*
        Definir sistemas externos con los que ParkEasy se integra.
        Sintaxis: nombre = softwareSystem "Nombre" "Descripción" "External System"
        */
        
        lprSystem = softwareSystem "Sistema de Cámaras LPR" "Sistema de reconocimiento de placas vehiculares con API REST" "External System"
        
        legacyBilling = softwareSystem "Sistema de Cobro Legacy" "[COMPLETAR: Descripción del sistema VB6]" "External System"
        
        paymentGateway = softwareSystem "[COMPLETAR: Nombre pasarela]" "[COMPLETAR: Descripción - ej: Wompi, PSE]" "External System"
        
        notificationService = softwareSystem "[COMPLETAR: Sistema de notificaciones]" "[COMPLETAR: Descripción - SMS/Email]" "External System"
        
        # OPCIONAL: Agregar más sistemas externos si es necesario
        # [otroSistema] = softwareSystem "..." "..." "External System"
        
        # =================================================================
        # SISTEMA PRINCIPAL: PARKEASY
        # =================================================================
        
        parkEasy = softwareSystem "ParkEasy" "Sistema de gestión de parqueaderos que permite reservas, pagos y administración" {
            
            # =============================================================
            # NIVEL 2: CONTAINERS (APLICACIONES/SERVICIOS)
            # =============================================================
            
            /*
            Definir los contenedores (aplicaciones, servicios, bases de datos) de ParkEasy.
            
            TIPOS DE CONTENEDORES:
            - Web App: Interfaz de usuario
            - API Gateway: Punto de entrada
            - Services: Servicios backend
            - Database: Bases de datos
            - Cache: Redis, Memcached
            - Message Queue: RabbitMQ, Kafka, SQS
            
            Sintaxis: nombre = container "Nombre" "Descripción" "Tecnología" "Tipo"
            */
            
            # WEB APPLICATION
            webApp = container "Aplicación Web" "Interfaz de usuario para conductores y administradores" "React.js / Vue.js / Angular" "Web Browser"
            
            # API GATEWAY (OPCIONAL - si su diseño lo incluye)
            # apiGateway = container "API Gateway" "[COMPLETAR]" "Kong / Nginx / AWS API Gateway" "Infrastructure"
            
            # SERVICIOS BACKEND
            /*
            IMPORTANTE: Definir servicios según SU decisión arquitectural:
            - Monolito: 1 solo servicio
            - Service-Based: 3-5 servicios
            - Microservicios: 10+ servicios
            
            Ejemplo de servicio:
            parkingService = container "Parking Service" "Gestiona disponibilidad y reservas" "Node.js + Express" "Service"
            */
            
            # AGREGAR SUS SERVICIOS AQUÍ:
            service1 = container "[NOMBRE SERVICIO 1]" "[COMPLETAR: Descripción]" "[COMPLETAR: Tecnología]" "Service"
            
            service2 = container "[NOMBRE SERVICIO 2]" "[COMPLETAR: Descripción]" "[COMPLETAR: Tecnología]" "Service"
            
            # service3 = container "[NOMBRE SERVICIO 3]" "[COMPLETAR]" "[COMPLETAR]" "Service"
            
            # AGREGAR MÁS SERVICIOS SI ES NECESARIO
            
            # BASE DE DATOS
            /*
            Definir base(s) de datos según su ADR-002.
            Si tienen DB compartida: 1 container
            Si tienen DB por servicio: múltiples containers
            */
            
            database = container "Base de Datos Principal" "[COMPLETAR: Qué almacena]" "PostgreSQL / MySQL / MongoDB" "Database"
            
            # Si tienen múltiples DBs:
            # database2 = container "..." "..." "..." "Database"
            
            # CACHE (OPCIONAL - si su diseño lo incluye)
            # cache = container "Cache" "Cache de disponibilidad y sesiones" "Redis / Memcached" "Cache"
            
            # MESSAGE QUEUE (OPCIONAL - si su diseño lo incluye)
            # messageQueue = container "Message Queue" "[COMPLETAR]" "RabbitMQ / Kafka / AWS SQS" "Message Queue"
            
            # =============================================================
            # NIVEL 3: COMPONENTS (DENTRO DE UN SERVICIO)
            # =============================================================
            
            /*
            INSTRUCCIONES:
            - Definir componentes de AL MENOS 1 servicio
            - Sugerencia: El servicio más importante (ej: Parking Service)
            - Componentes típicos: Controllers, Services, Repositories, Clients
            
            SOLO descomentar si definen componentes:
            */
            
            /*
            # Ejemplo: Componentes dentro de service1
            # (Reemplazar service1 con el nombre de su servicio)
            
            component1 = component "[NOMBRE COMPONENTE]" "[Descripción]" "[Tipo: Controller/Service/Repository]" {
                # Este componente está dentro de service1
            }
            
            component2 = component "[NOMBRE COMPONENTE]" "[Descripción]" "[Tipo]"
            
            # Agregar más componentes según necesiten
            */
            
        }
        
        # =================================================================
        # RELACIONES - NIVEL 1 (CONTEXT)
        # =================================================================
        
        /*
        Definir cómo los usuarios y sistemas externos interactúan con ParkEasy.
        Sintaxis: origen -> destino "Descripción" "Protocolo"
        */
        
        driver -> parkEasy "Busca disponibilidad, hace reservas, paga" "HTTPS"
        operator -> parkEasy "[COMPLETAR: Qué hace el operador]" "HTTPS"
        administrator -> parkEasy "[COMPLETAR: Qué hace el admin]" "HTTPS"
        
        parkEasy -> lprSystem "Lee placas de vehículos" "REST/JSON"
        parkEasy -> legacyBilling "[COMPLETAR: Qué hace con sistema legacy]" "SOAP/XML"
        parkEasy -> paymentGateway "[COMPLETAR: Procesa pagos]" "REST/JSON"
        parkEasy -> notificationService "[COMPLETAR: Envía notificaciones]" "REST/JSON"
        
        # =================================================================
        # RELACIONES - NIVEL 2 (CONTAINER)
        # =================================================================
        
        /*
        Definir cómo los usuarios interactúan con containers específicos
        y cómo los containers se comunican entre sí.
        */
        
        # Usuario -> Web App
        driver -> webApp "Usa para reservar y pagar" "HTTPS"
        operator -> webApp "[COMPLETAR]" "HTTPS"
        administrator -> webApp "[COMPLETAR]" "HTTPS"
        
        # Web App -> Servicios
        # IMPORTANTE: Ajustar según sus servicios definidos arriba
        webApp -> service1 "[COMPLETAR: Qué operación]" "HTTP/JSON"
        webApp -> service2 "[COMPLETAR: Qué operación]" "HTTP/JSON"
        
        # Servicios -> Base de Datos
        service1 -> database "[COMPLETAR: Lee/Escribe qué]" "TCP/PostgreSQL"
        service2 -> database "[COMPLETAR: Lee/Escribe qué]" "TCP/PostgreSQL"
        
        # Servicios -> Sistemas Externos
        # AJUSTAR según qué servicio se integra con qué sistema externo
        service1 -> lprSystem "[COMPLETAR]" "HTTP/JSON"
        service2 -> paymentGateway "[COMPLETAR]" "HTTP/JSON"
        
        # Si tienen API Gateway, agregar relaciones:
        # webApp -> apiGateway "..." "HTTPS"
        # apiGateway -> service1 "..." "HTTP"
        
        # Si tienen Cache:
        # service1 -> cache "..." "TCP/Redis"
        
        # Si tienen Message Queue:
        # service1 -> messageQueue "Publica eventos" "AMQP"
        # service2 -> messageQueue "Consume eventos" "AMQP"
        
        # =================================================================
        # RELACIONES - NIVEL 3 (COMPONENT)
        # =================================================================
        
        /*
        SOLO si definieron componentes arriba, descomentar y completar:
        
        # Ejemplo: Relaciones entre componentes dentro de service1
        # component1 -> component2 "Llama a" "Method Call"
        # component2 -> database "Consulta datos" "SQL"
        */
        
        # =================================================================
        # DEPLOYMENT (OPCIONAL PERO RECOMENDADO)
        # =================================================================
        
        /*
        Definir cómo se despliega el sistema en la infraestructura.
        SOLO si quieren incluir vista de deployment.
        */
        
        /*
        deploymentEnvironment "AWS" {
            deploymentNode "CloudFront CDN" "" "AWS CloudFront" {
                containerInstance webApp
            }
            
            deploymentNode "Application Load Balancer" "" "AWS ALB" {
                infrastructureNode alb "ALB" "" "Load Balancer"
            }
            
            deploymentNode "ECS Cluster" "" "AWS ECS Fargate" {
                deploymentNode "[Nombre Servicio 1]" "" "ECS Task ([X] instances)" {
                    containerInstance service1
                }
                
                deploymentNode "[Nombre Servicio 2]" "" "ECS Task ([X] instances)" {
                    containerInstance service2
                }
            }
            
            deploymentNode "[DB Name]" "" "AWS RDS" {
                containerInstance database
            }
        }
        */
    }

    # =====================================================================
    # VIEWS (VISTAS)
    # =====================================================================
    
    views {
        # =================================================================
        # VISTA 1: CONTEXT (NIVEL 1 C4) - OBLIGATORIA
        # =================================================================
        
        systemContext parkEasy "SystemContext" "Diagrama de contexto del sistema ParkEasy" {
            include *
            autoLayout lr
        }
        
        # =================================================================
        # VISTA 2: CONTAINER (NIVEL 2 C4) - OBLIGATORIA
        # =================================================================
        
        container parkEasy "Containers" "Diagrama de contenedores de ParkEasy" {
            include *
            autoLayout lr
        }
        
        # =================================================================
        # VISTA 3: COMPONENT (NIVEL 3 C4) - OBLIGATORIA (mínimo 1)
        # =================================================================
        
        /*
        Crear vista de componentes del servicio más importante.
        SOLO descomentar si definieron componentes arriba.
        Reemplazar "service1" con el nombre real de su servicio.
        */
        
        /*
        component service1 "Components[NombreServicio]" "Componentes de [Nombre del Servicio]" {
            include *
            autoLayout lr
        }
        */
        
        # Si documentaron componentes de más servicios:
        # component service2 "Components[Servicio2]" "..." {
        #     include *
        #     autoLayout lr
        # }
        
        # =================================================================
        # VISTA 4: DEPLOYMENT (OPCIONAL)
        # =================================================================
        
        /*
        SOLO si definieron deployment arriba:
        
        deployment parkEasy "AWS" "Deployment" "Despliegue en AWS" {
            include *
            autoLayout lr
        }
        */
        
        # =================================================================
        # ESTILOS (COLORES Y FORMAS)
        # =================================================================
        
        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            
            element "External System" {
                background #999999
                color #ffffff
            }
            
            element "Service" {
                background #1168bd
                color #ffffff
            }
            
            element "Web Browser" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }
            
            element "Database" {
                shape Cylinder
                background #438dd5
                color #ffffff
            }
            
            element "Cache" {
                shape Cylinder
                background #ff6b6b
                color #ffffff
            }
            
            element "Message Queue" {
                shape Pipe
                background #f4a261
                color #000000
            }
            
            element "Infrastructure" {
                background #a9a9a9
                color #ffffff
            }
        }
        
        theme default
    }
}

/*
================================================================================
NOTAS FINALES
================================================================================

CHECKLIST ANTES DE ENTREGAR:
- [ ] Reemplazaron TODOS los [COMPLETAR]
- [ ] Definieron al menos 3 servicios/contenedores (o 1 si es monolito)
- [ ] Todas las relaciones tienen descripción y protocolo
- [ ] Tecnologías especificadas (ej: "Node.js", "PostgreSQL", no "TBD")
- [ ] Probaron el archivo en https://structurizr.com/dsl
- [ ] Las 3 vistas se visualizan correctamente
- [ ] Guardaron el archivo como .dsl

ERRORES COMUNES:
❌ Olvidar cerrar llaves { }
❌ Usar ' en vez de " para strings
❌ No especificar tecnologías
❌ Relaciones sin descripción
❌ No probar en Structurizr antes de entregar

TIPS:
💡 Empiecen simple: Context → Container → Component
💡 Prueben frecuentemente en Structurizr
💡 Si algo no funciona, revisen sintaxis de ejemplos
💡 autoLayout lr = layout izquierda-derecha (pueden usar tb = top-bottom)
💡 include * = incluir todos los elementos

¿DUDAS?
- Documentación oficial: https://structurizr.com/help/dsl
- Ver ejemplo de Court Booker para referencia

================================================================================
*/
