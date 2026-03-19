workspace "ParkEasy - Sistema de Gestión de Parqueaderos" "Arquitectura C4 completa para ParkEasy" {

    model {

        # ─── ACTORES EXTERNOS ───────────────────────────────────────────
        conductor     = person "Conductor"     "Persona que busca parquear su vehículo"
        operador      = person "Operador"      "Personal en casetas de entrada/salida"
        administrador = person "Administrador" "Gerente que consulta reportes y configura tarifas"

        # ─── SISTEMAS EXTERNOS ──────────────────────────────────────────
        camarasLPR     = softwareSystem "Cámaras LPR"            "Reconocimiento automático de placas vehiculares" "External"
        sistemaLegacy  = softwareSystem "Sistema de Cobro Legacy" "Software VB6 de cobro existente (SOAP)"         "External"
        pasarelaPagos  = softwareSystem "Wompi"                   "Pasarela de pagos digitales colombiana"          "External"
        notificaciones = softwareSystem "Email/SMS Gateway"       "Envío de notificaciones y facturas"              "External"
        dian           = softwareSystem "DIAN"                    "Facturación electrónica obligatoria Colombia"    "External"

        # ─── SISTEMA PRINCIPAL ──────────────────────────────────────────
        parkEasy = softwareSystem "ParkEasy" "Sistema de gestión digital de parqueaderos" {

            # ── NIVEL 2: CONTENEDORES ────────────────────────────────────
            webApp     = container "Aplicación Web"  "Interfaz para conductores y administradores" "React / Next.js"  "Web Browser"
            mobileApp  = container "App Móvil"       "App para conductores"                        "React Native"     "Mobile App"
            operatorUI = container "Panel Operador"  "Interfaz táctil para casetas"                "React / Electron" "Desktop"

            apiGateway            = container "API Gateway"            "Enruta solicitudes, valida tokens JWT y aplica rate limiting"          "Kong / Express"    "Service"
            authService           = container "Auth Service"           "Autenticación y autorización de usuarios con JWT y roles"              "Node.js / Express" "Service"
            disponibilidadService = container "Disponibilidad Service" "Monitorea y expone ocupación en tiempo real por parqueadero"           "Node.js / Express" "Service"
            pagosService          = container "Pagos Service"          "Procesa pagos digitales (tarjeta, Nequi, Daviplata) y genera facturas" "Node.js / Express" "Service"
            reportesService       = container "Reportes Service"       "Genera dashboards y reportes de ingresos, tiempos y ocupación"         "Node.js / Express" "Service"

            operacionService = container "Operacion Service" "Gestiona reservas, control de acceso e incidentes" "Node.js / Express" "Service" {

                # ── NIVEL 3: COMPONENTES de Operacion Service ────────────

                # Capa de entrada
                operacionRouter      = component "Operacion Router"      "Expone endpoints: /reservas, /acceso/entrada, /acceso/salida, /incidentes" "Express Router"
                operacionMiddleware  = component "Auth Middleware"        "Valida JWT y verifica rol antes de procesar la solicitud"                  "Express Middleware"

                # Controladores
                reservasController   = component "Reservas Controller"   "Gestiona creación, consulta y cancelación de reservas anticipadas"         "Node.js"
                entradaController    = component "Entrada Controller"    "Orquesta el flujo completo de registro de entrada de un vehículo"          "Node.js"
                salidaController     = component "Salida Controller"     "Orquesta el flujo completo de registro de salida de un vehículo"           "Node.js"
                incidentesController = component "Incidentes Controller" "Registra incidentes y actualiza estado de espacios afectados"              "Node.js"

                # Servicios de dominio
                reservasDomain       = component "Reservas Domain"       "Reglas de negocio: ventana de 5 min–2h, límite por conductor, expiración"  "Node.js"
                accesoDomain         = component "Acceso Domain"         "Reglas de negocio: validación de reserva activa y cálculo de estadía"      "Node.js"
                ticketService        = component "Ticket Service"        "Genera y valida tickets de acceso con código único por sesión"              "Node.js"

                # Repositorios
                reservasRepo         = component "Reservas Repository"   "CRUD de reservas en base de datos"                                         "Node.js / Sequelize"
                accesoRepo           = component "Acceso Repository"     "CRUD de registros de entrada/salida en base de datos"                      "Node.js / Sequelize"
                incidentesRepo       = component "Incidentes Repository" "Persistencia de incidentes y su estado de resolución"                      "Node.js / Sequelize"

                # Publicador de eventos
                eventPublisher       = component "Event Publisher"       "Publica eventos de reserva, entrada, salida e incidente en Message Queue"  "Node.js / amqplib"
            }

            cacheService    = container "Cache"                   "Disponibilidad en tiempo real"        "Redis"                     "Database"
            mainDatabase    = container "Base de Datos Principal" "Reservas, vehículos, pagos, usuarios" "PostgreSQL"                "Database"
            reportsDatabase = container "Base de Datos Reportes"  "Históricos y analytics"               "PostgreSQL (Read Replica)" "Database"
            messageQueue    = container "Message Queue"           "Eventos asincrónicos entre servicios" "RabbitMQ"                  "Database"
        }

        # ─── RELACIONES NIVEL 1: Context ────────────────────────────────
        conductor     -> parkEasy       "Consulta disponibilidad, reserva y paga"
        operador      -> parkEasy       "Registra entradas manuales y gestiona incidentes"
        administrador -> parkEasy       "Consulta dashboards y configura tarifas"
        parkEasy      -> camarasLPR     "Lee placas en entrada/salida"
        parkEasy      -> sistemaLegacy  "Sincroniza cobros"
        parkEasy      -> pasarelaPagos  "Procesa pagos digitales"
        parkEasy      -> notificaciones "Envía confirmaciones y facturas"
        parkEasy      -> dian           "Remite facturas electrónicas"

        # ─── RELACIONES NIVEL 2: Container ──────────────────────────────
        conductor     -> webApp     "Consulta disponibilidad y reserva"       "HTTPS"
        conductor     -> mobileApp  "Consulta disponibilidad y reserva"       "HTTPS"
        operador      -> operatorUI "Registra entradas y gestiona incidentes"  "HTTPS"
        administrador -> webApp     "Consulta dashboards y reportes"          "HTTPS"

        webApp     -> apiGateway "Solicitudes REST" "HTTPS/JSON"
        mobileApp  -> apiGateway "Solicitudes REST" "HTTPS/JSON"
        operatorUI -> apiGateway "Solicitudes REST" "HTTPS/JSON"

        apiGateway -> authService           "Valida token JWT"       "HTTPS/JSON"
        apiGateway -> operacionService      "Enruta /reservas, /acceso, /incidentes" "HTTPS/JSON"
        apiGateway -> pagosService          "Enruta /pagos"          "HTTPS/JSON"
        apiGateway -> disponibilidadService "Enruta /disponibilidad" "HTTPS/JSON"
        apiGateway -> reportesService       "Enruta /reportes"       "HTTPS/JSON"

        # Servicios de negocio → otros servicios
        operacionService -> disponibilidadService "Actualiza ocupación al entrar/salir y en incidentes" "HTTPS/JSON"
        operacionService -> notificaciones        "Envía confirmación de reserva"                       "SMTP/API"
        pagosService     -> notificaciones        "Envía factura electrónica al conductor"              "SMTP/API"

        # Servicios → sistemas externos
        operacionService -> camarasLPR    "Solicita lectura de placa"             "REST/HTTP"
        operacionService -> sistemaLegacy "Sincroniza registro de entrada/salida" "SOAP/XML"
        pagosService     -> pasarelaPagos "Procesa transacción de pago"           "HTTPS"
        pagosService     -> sistemaLegacy "Confirma cobro en sistema legacy"      "SOAP/XML"
        pagosService     -> dian          "Remite factura electrónica"            "HTTPS"

        # Servicios → BD y cola
        authService           -> mainDatabase    "Consulta usuarios y roles"         "SQL"
        operacionService      -> mainDatabase    "Lee/escribe reservas y accesos"    "SQL"
        pagosService          -> mainDatabase    "Lee/escribe transacciones"         "SQL"
        disponibilidadService -> cacheService    "Lee/escribe estado de espacios"    "Redis"
        reportesService       -> reportsDatabase "Lee históricos"                    "SQL"
        operacionService      -> messageQueue    "Publica eventos de operación"      "AMQP"
        pagosService          -> messageQueue    "Publica eventos de pago"           "AMQP"
        reportesService       -> messageQueue    "Consume eventos para analytics"    "AMQP"

        # ─── RELACIONES NIVEL 3: Components de operacionService ─────────
        apiGateway -> operacionRouter "GET|POST /reservas, POST /acceso/entrada, POST /acceso/salida, POST /incidentes" "HTTPS/JSON"

        operacionRouter     -> operacionMiddleware   "Intercepta toda solicitud"
        operacionMiddleware -> reservasController    "Solicitudes /reservas (Conductor)"
        operacionMiddleware -> entradaController     "POST /acceso/entrada (Operador/LPR)"
        operacionMiddleware -> salidaController      "POST /acceso/salida (Operador/LPR)"
        operacionMiddleware -> incidentesController  "POST /incidentes (Operador)"

        # Controladores → dominio
        reservasController   -> reservasDomain  "Aplica reglas de reserva"
        entradaController    -> accesoDomain    "Valida reserva activa y autoriza entrada"
        entradaController    -> ticketService   "Genera ticket de acceso"
        salidaController     -> accesoDomain    "Calcula tiempo de estadía"
        salidaController     -> ticketService   "Cierra y valida ticket de sesión"

        # Dominio → repositorios
        reservasDomain -> reservasRepo   "Lee/escribe reservas"
        accesoDomain   -> accesoRepo     "Lee/escribe registros de acceso"
        ticketService  -> accesoRepo     "Lee/escribe tickets activos"
        incidentesController -> incidentesRepo "Lee/escribe incidentes"

        # Controladores → sistemas externos y otros servicios
        entradaController    -> camarasLPR           "Solicita lectura de placa"        "REST/HTTP"
        entradaController    -> disponibilidadService "Notifica reducción de espacio"    "HTTPS/JSON"
        salidaController     -> disponibilidadService "Notifica liberación de espacio"   "HTTPS/JSON"
        salidaController     -> sistemaLegacy         "Sincroniza salida con legacy"     "SOAP/XML"
        reservasController   -> notificaciones        "Envía confirmación de reserva"    "SMTP/API"
        incidentesController -> disponibilidadService "Marca espacio en incidente"       "HTTPS/JSON"

        # Eventos
        entradaController    -> eventPublisher "Publica VehiculoIngresado"
        salidaController     -> eventPublisher "Publica VehiculoSalido"
        reservasController   -> eventPublisher "Publica ReservaCreada"
        incidentesController -> eventPublisher "Publica IncidenteRegistrado"
        eventPublisher       -> messageQueue   "Publica evento"                "AMQP"

        # Repositorios → BD
        reservasRepo   -> mainDatabase "SQL"
        accesoRepo     -> mainDatabase "SQL"
        incidentesRepo -> mainDatabase "SQL"
    }

    views {

        # Vista 1 – Nivel 1: Context
        systemContext parkEasy "C4_L1_Context" {
            include *
            autoLayout lr
            title "C4 Nivel 1 - Diagrama de Contexto - ParkEasy"
        }

        # Vista 2 – Nivel 2: Container
        container parkEasy "C4_L2_Containers" {
            include *
            autoLayout lr
            title "C4 Nivel 2 - Diagrama de Contenedores - ParkEasy"
        }

        # Vista 3 – Nivel 3: Components de Operacion Service
        component operacionService "C4_L3_OperacionService" {
            include *
            autoLayout lr
            title "C4 Nivel 3 - Componentes - Operacion Service"
        }

        styles {
            element "Person" {
                shape Person
                background "#1168BD"
                color "#ffffff"
            }
            element "Software System" {
                background "#1168BD"
                color "#ffffff"
            }
            element "External" {
                background "#999999"
                color "#ffffff"
            }
            element "Container" {
                background "#438DD5"
                color "#ffffff"
            }
            element "Service" {
                background "#438DD5"
                color "#ffffff"
            }
            element "Component" {
                background "#85BBF0"
                color "#000000"
            }
            element "Database" {
                shape Cylinder
                background "#438DD5"
                color "#ffffff"
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Mobile App" {
                shape MobileDeviceLandscape
            }
            element "Desktop" {
                shape RoundedBox
            }
        }
    }
}
