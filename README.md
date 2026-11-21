# Kilómetro a Kilómetro

Prototipo jugable de gestión de carreteras para Godot 4.7, con renderizador Compatibility. No necesita Steam ni cuenta para arrancar. La interfaz y los gráficos son originales y están dibujados en Godot.

## Abrir y jugar

1. Abre `project.godot` con Godot 4.7 y ejecuta el proyecto (F6/F5).
2. Elige **Nueva partida** y **Comenzar**. El nombre y la semilla tienen valores automáticos.
3. Sitúa el cursor sobre Valdeprado, pulsa Intro; muévelo hasta Los Olmos y pulsa Intro. Revisa el presupuesto y confirma. Espera a que termine la obra: los puntos representan vehículos y cada llegada paga una vez.
4. Con M puedes pausar, cambiar la velocidad, guardar o volver al menú. I abre el inspector; Tab cambia de herramienta. La partida continúa después de la primera conexión.

El terreno se calcula con coordenadas globales y semilla; las ciudades aparecen al explorar. Se guardan las zonas descubiertas, ciudades, carreteras, obras y vehículos. Guardado manual y tres autoguardados rotativos se almacenan en `user://saves`; el archivo anterior se conserva como copia `.bak`. Cada nombre tiene su guardado manual y sus propios autoguardados.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Mover | Flechas / WASD | Cruceta / stick izquierdo |
| Aceptar / marcar | Intro / Espacio | A |
| Cancelar / demoler | Esc / Supr | B |
| Inspector | I | Y |
| Menú | M | X |
| Tipo de vía | Q / E | LB / RB |
| Zoom | − / + | LT / RT |
| Herramienta anterior / siguiente | F8 / Tab | L5 / R5; también LB + RB para avanzar |
| Pausa | P | Start |
| Ir al tramo del aviso visible | F6 | R4 |
| Descartar aviso visible | F7 | L4 |

El cursor se mueve una casilla por pulsación o inclinación; al mantener la dirección, espera un instante y repite de forma gradual. La cámara sigue al cursor solo cerca de los bordes. En Opciones → Velocidad del cursor puedes elegir precisa, normal o rápida. La cruceta y el stick también repiten en los menús.

En el menú se puede elegir la velocidad y las herramientas. El estado de las obras se muestra en el inspector. Las reparaciones y mejoras cierran temporalmente el tramo y tienen presupuesto de confirmación.

## Estado y limitaciones

Esta entrega es un **prototipo vertical**, no una versión completa para Steam. Los vehículos pueden atravesar varios tramos y cruzar entre carreteras a nivel; las rutas usan tiempo estimado y evitan obras. En el menú de partida, «Paso sobre carreteras» permite escoger un paso elevado para una obra nueva; se comprueban las rampas y la vía inferior queda independiente. Las rutas priorizan el tiempo estimado según velocidad, conservación, nieve, ocupación y STOP. Los vehículos en camino pueden reevaluar en cruces a nivel, con un límite de cálculos por paso. Los cruces tienen colas y capacidad limitada; las señales y las rotondas mejoran el paso. La rotonda se simula como un nodo de circulación compartido, sin modelar físicamente cada carril circular. Aún no hay ramales de enlace para conectar niveles. Para limitar el coste de cálculo, la demanda considera las primeras 24 ciudades conocidas y hasta seis destinos cercanos por ciudad, con un máximo de 300 vehículos simultáneos. Los puentes de agua tienen conservación y reparación propias, aunque su cierre afecta al tramo completo. Las obras se pueden iniciar o programar para el periodo de menor demanda; se revisa el aislamiento antes de iniciarlas. Hay mantenimiento preventivo y señales STOP y ceda por entrada, con una coordinación básica en el cruce. Las autopistas admiten peaje y los conductores equilibran su coste con el tiempo estimado (3 € equivalen a un segundo de viaje). Hay contratos de conexión, duración y fiabilidad, además de un préstamo limitado y desbloqueos por viajes, ciudades conectadas y fiabilidad. Hay eventos regionales de nevada, incendio, crecida, desprendimiento y feria; la simulación de su propagación y gravedad sigue siendo simplificada. Las vistas de tráfico, conservación y demanda muestran información y leyendas. El trazado admite un punto intermedio, pero sigue siendo síncrono y está limitado a 110 casillas por etapa. Las curvas se suavizan dentro de las casillas ocupadas, pero todavía no se validan radios mínimos ni el ancho completo frente al terreno. Los ajustes de pantalla, cuadrícula, escala y teclado se guardan por separado; todavía no hay ajustes de música o efectos porque no hay audio. No hay música ni efectos. La generación de ciudades no comprueba todas las conexiones entre bloques ni la viabilidad global. El modo libre comparte la zona inicial preparada. Las obras dejan salir a los vehículos que ya están en el tramo; los vehículos que encuentran un cierre al cambiar de tramo buscan otra ruta. El análisis de aislamiento comprueba como máximo las primeras doce ciudades conocidas. Estas limitaciones deben resolverse antes de distribuir el juego.

## Nombres de los tramos

Cada tramo recibe un identificador pequeño junto a la vía y en su inspector: C para caminos, CR para carriles rurales, S para secundarias, P para principales, VR para vías rápidas, A para autovías y AP para autopistas. La numeración es independiente por categoría y se conserva al guardar; al cambiar de categoría se asigna el siguiente número de la nueva categoría. Las partidas anteriores reciben identificadores al cargarse.

## Puentes sobre carreteras

1. Con la herramienta Construir, abre el menú con **M** o **X** y cambia «Paso sobre carreteras» a **elevado**. Vuelve al mapa.
2. Marca origen y destino a ambos lados de la carretera existente. La vista previa resalta el tablero y las rampas; un marcador rojo indica un conflicto si falta espacio o terreno firme.
3. Revisa coste, longitud de las rampas y duración, y confirma la obra. La carretera inferior permanece abierta. El paso y la vía inferior se cruzan a distinta altura y no permiten cambiar de una a otra sin un enlace.

Se detectan cruces en una casilla y cruces entre diagonales. Se puede combinar un puente sobre agua y un paso sobre carretera en una obra si las rampas son viables. Todavía no se pueden construir enlaces entre niveles ni reparar el paso elevado como estructura independiente.

## Cerrar y abrir una carretera

Abre el menú con **M** o **X** y selecciona **Cerrar/Abrir**; también puedes llegar a esa herramienta con Tab, F8, R5 o L5. Sitúa el cursor sobre la carretera y pulsa **Intro / A**. La pantalla muestra las conexiones que podrían quedar aisladas: puedes volver para preparar un desvío o confirmar el cierre. El cierre afecta al tramo completo y no tiene coste.

Para reabrirla, vuelve a seleccionar el tramo con la misma herramienta y confirma la apertura. También puedes cerrar o abrir desde el inspector (**I / Y**). Si hay varios tramos en una casilla, usa «Siguiente elemento» en el inspector para escoger el que quieres. Los vehículos ya presentes pueden salir; los nuevos buscan otra ruta. Quitar un cierre manual no anula una obra, un evento ni un cierre por deterioro.

## Obras, señales y punto intermedio

Selecciona **Reparar** o **Mejorar** en el menú, sitúa el cursor sobre una carretera y pulsa confirmar. La ficha muestra el coste y los accesos que quedarían aislados. Puedes iniciar, programar para la última cuarta parte del día o preparar un desvío conservando la obra como borrador. La obra programada se bloquea si empeora el aislamiento o faltan fondos. Desde Reparar se activa el mantenimiento preventivo; al seleccionar una casilla de agua de un puente se ofrece también su reparación. El puente cierra todo su tramo durante la obra.

En un cruce a nivel, selecciona **Señalar** y elige STOP o ceda para el sentido de llegada indicado; los vehículos forman una cola y esperan turno. También puedes elegir «Construir rotonda»: cuesta 1.400 €, tarda 12 segundos de simulación y aumenta la capacidad al terminar. Las señales quedan en reserva y vuelven a actuar si retiras la rotonda. El inspector muestra vehículos esperando y tiempo entre pasos. La prioridad y el paso por la rotonda son modelos simplificados, no una simulación física de carriles.

Para fijar un punto intermedio, marca el origen al construir, mueve el cursor al punto deseado, abre M y elige «Fijar punto intermedio aquí». Continúa hasta el destino.

## Tamaño de ciudades y economía

Las etiquetas muestran población y tamaño: pequeña (menos de 3.000 habitantes), mediana (menos de 10.000) o grande. La demanda aumenta con las poblaciones de origen y destino, por lo que una ciudad grande genera y atrae más viajes.

En «Economía y contratos» se pueden consultar los ingresos y gastos diarios y acumulados, aceptar contratos de conexión, duración o fiabilidad, y pedir un único préstamo cuando el saldo es inferior a 3.000 €. El préstamo concede 3.000 € y se devuelven 3.300 € en cuotas de 550 €/día. Las categorías avanzadas se desbloquean mediante viajes completados, ciudades conectadas y fiabilidad; al cambiar de tipo se indica el requisito.

El inspector de una autopista permite fijar el peaje; se acumula al entrar y se ingresa únicamente cuando se completa el viaje. Los conductores valoran el precio junto al tiempo estimado, convirtiendo 3 € de peaje en un segundo de viaje. El contrato de conexión recompensa unir ciudades; el de duración paga por mantener la conexión durante dos días simulados dentro de un plazo de cuatro; el de fiabilidad exige cinco viajes, con al menos cuatro puntuales, también dentro de cuatro días.

## Tráfico y penalizaciones

Las ciudades generan demanda según su población y distancia; el balance distingue viajes potenciales, iniciados, completados, no atendidos e interrumpidos. Las vías tienen una capacidad que depende de su longitud, categoría, conservación y nieve. Una ocupación alta reduce la velocidad y puede hacer que se elija una alternativa más rápida, aunque sea más larga. Los viajes en curso revisan la ruta al alcanzar un cruce, como máximo cada diez segundos de simulación y con un límite de cálculos por paso. La vista «tráfico» y el inspector muestran el estado y la ocupación.

Por cada unidad completa de ocupación que supere la capacidad se cargan 2,5 € por segundo de simulación, proporcionalmente al exceso. En cada cruce también se cobran 0,6 € por segundo por cada vehículo que espere a partir del tercero; esta cantidad figura incluida en las penalizaciones por atasco. Al completar un viaje se cobran 4 € por cada segundo que exceda 1,6 veces la distancia directa (con un mínimo de 3 segundos), hasta el 80 % del pago de ese viaje. La distancia se mide en casillas y el tiempo en segundos de simulación; las penalizaciones acumuladas y diarias están en «Balance y tráfico». Los parámetros están en `scripts/balance.gd`.

## Eventos y opciones

Las nevadas, crecidas y ferias pueden anunciarse antes de empezar. Los sucesos afectan a una zona de carreteras; los incendios pueden extenderse a vías forestales cercanas. En «Avisos y eventos» se pueden consultar las consecuencias, ir al tramo afectado y pagar para despejar de forma individual tramos con nieve o desprendimientos. Mientras aparece un aviso, R4 (F6 en teclado) lleva al tramo asociado y L4 (F7) oculta el aviso sin cancelar el evento. Si Steam Input no expone los botones traseros, asigna R4 a F6 y L4 a F7 en la configuración del mando de Steam. Una feria incrementa la demanda hacia la ciudad más próxima.

Las opciones están disponibles desde el menú principal y durante la partida. Permiten cambiar pantalla, cuadrícula y escala, reasignar teclas y restaurar los controles predeterminados. Los ajustes se guardan en `user://settings.cfg`. En mando, L5 y R5 cambian de herramienta hacia atrás y hacia delante; LB + RB también avanza y una pulsación individual de LB o RB cambia el tipo de vía. Si Steam Input no expone L5 o R5, asígnalos a F8 y Tab respectivamente.

## Comprobación automatizada

Con Godot instalado, desde la carpeta del proyecto:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/road_names_smoke.gd
godot --headless --path . --script res://tests/manual_closure_smoke.gd
godot --headless --path . --script res://tests/manual_closure_ui_smoke.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/zoom_smoke.gd
godot --headless --path . --script res://tests/network_smoke.gd
godot --headless --path . --script res://tests/junction_traffic_smoke.gd
godot --headless --path . --script res://tests/junction_fairness_smoke.gd
godot --headless --path . --script res://tests/roundabout_ui_smoke.gd
godot --headless --path . --script res://tests/journey_smoke.gd
godot --headless --path . --script res://tests/economy_smoke.gd
godot --headless --path . --script res://tests/economy_ui_smoke.gd
godot --headless --path . --script res://tests/traffic_smoke.gd
godot --headless --path . --script res://tests/fastest_route_smoke.gd
godot --headless --path . --script res://tests/traffic_ui_smoke.gd
godot --headless --path . --script res://tests/geometry_smoke.gd
godot --headless --path . --script res://tests/works_signals_smoke.gd
godot --headless --path . --script res://tests/bridge_works_smoke.gd
godot --headless --path . --script res://tests/overpass_smoke.gd
godot --headless --path . --script res://tests/overpass_full_smoke.gd
godot --headless --path . --script res://tests/overpass_ui_smoke.gd
godot --headless --path . --script res://tests/events_smoke.gd
godot --headless --path . --script res://tests/regional_events_smoke.gd
godot --headless --path . --script res://tests/fire_spread_smoke.gd
godot --headless --path . --script res://tests/settings_smoke.gd
godot --headless --path . --script res://tests/navigation_events_ui_smoke.gd
godot --headless --path . --script res://tests/controller_combo_smoke.gd
godot --headless --path . --script res://tests/cursor_motion_smoke.gd
godot --headless --path . --script res://tests/cursor_input_integration_smoke.gd
godot --headless --path . --script res://tests/menu_repeat_smoke.gd
godot --headless --path . --script res://tests/notice_smoke.gd
```

Las pruebas comprueban determinismo del terreno, construcción y cobro único, rutas por varios tramos, cruces, cierres, zoom por teclado y reconstrucción del estado serializado. No sustituye a una prueba interactiva de mando ni a una verificación visual.

## Exportación

En Godot, instala las plantillas de exportación de la **misma versión** desde Editor → Manage Export Templates. En Proyecto → Exportar, crea presets para Linux/X11 y Windows Desktop, selecciona arquitectura x86_64 y exporta. Para Steam Deck usa la compilación Linux y prueba también con Proton si distribuyes Windows. Comprueba controles, resolución 1280 × 800, rendimiento, escritura en `user://` y suspensión/reanudación en el dispositivo. La integración de Steamworks, logros y configuración de la tienda son pasos posteriores opcionales; el juego no depende del SDK.
