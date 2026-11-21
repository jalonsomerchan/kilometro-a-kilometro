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
| Herramienta | Tab o menú | Menú |
| Pausa | P | Start |

En el menú se puede elegir la velocidad y las herramientas. El estado de las obras se muestra en el inspector. Las reparaciones y mejoras cierran temporalmente el tramo y tienen presupuesto de confirmación.

## Estado y limitaciones

Esta entrega es un **prototipo vertical**, no una versión completa para Steam. Los vehículos pueden atravesar varios tramos y cruzar entre carreteras a nivel; las rutas usan tiempo estimado y evitan obras. En el menú de partida, «Cruces» permite escoger un paso elevado para una obra nueva; se comprueban rampas y la vía inferior queda independiente. Las rutas priorizan el tiempo estimado según velocidad, conservación, nieve, ocupación y STOP. Los vehículos en camino pueden reevaluar en cruces a nivel, con un límite de cálculos por paso. Aún no hay ramales de enlace para conectar niveles ni una simulación detallada de colas en cruces. Para limitar el coste de cálculo, la demanda considera las primeras 24 ciudades conocidas y hasta seis destinos cercanos por ciudad, con un máximo de 300 vehículos simultáneos. Los puentes de agua tienen conservación y reparación propias, aunque su cierre afecta al tramo completo. Las obras se pueden iniciar o programar para el periodo de menor demanda; se revisa el aislamiento antes de iniciarlas. Hay mantenimiento preventivo y señales STOP y ceda por entrada, con una coordinación básica en el cruce. Las autopistas admiten peaje; hay contratos de conexión, un préstamo limitado y desbloqueos por viajes, ciudades conectadas y fiabilidad. Quedan pendientes otros tipos de contrato y una elección de ruta sensible al precio del peaje. Hay eventos básicos de nevada, incendio, crecida, desprendimiento y feria sobre un tramo: todavía no simulan propagación regional, previsión ni todos los efectos detallados del diseño. La vista de tráfico muestra ocupación por tramo; la vista de demanda aún no representa métricas específicas en el mapa. El trazado admite un punto intermedio, pero sigue siendo síncrono y está limitado a 110 casillas por etapa. Las curvas se suavizan dentro de las casillas ocupadas, pero todavía no se validan radios mínimos ni el ancho completo frente al terreno. No se han implementado ajustes persistentes, reasignación de teclas ni escala de interfaz. No hay música ni efectos. La generación de ciudades no comprueba todas las conexiones entre bloques ni la viabilidad global. El modo libre comparte la zona inicial preparada. Las obras dejan salir a los vehículos que ya están en el tramo; los vehículos que encuentran un cierre al cambiar de tramo buscan otra ruta. El análisis de aislamiento comprueba como máximo las primeras doce ciudades conocidas. Estas limitaciones deben resolverse antes de distribuir el juego.

## Obras, señales y punto intermedio

Selecciona **Reparar** o **Mejorar** en el menú, sitúa el cursor sobre una carretera y pulsa confirmar. La ficha muestra el coste y los accesos que quedarían aislados. Puedes iniciar, programar para la última cuarta parte del día o preparar un desvío conservando la obra como borrador. La obra programada se bloquea si empeora el aislamiento o faltan fondos. Desde Reparar se activa el mantenimiento preventivo; al seleccionar una casilla de agua de un puente se ofrece también su reparación. El puente cierra todo su tramo durante la obra.

En un cruce a nivel, selecciona **Señalar** y elige STOP o ceda para el sentido de llegada indicado; el vehículo espera según la señal y la ocupación del cruce. Es una gestión simplificada, no una simulación completa de prioridades y colas.

Para fijar un punto intermedio, marca el origen al construir, mueve el cursor al punto deseado, abre M y elige «Fijar punto intermedio aquí». Continúa hasta el destino.

## Tamaño de ciudades y economía

Las etiquetas muestran población y tamaño: pequeña (menos de 3.000 habitantes), mediana (menos de 10.000) o grande. La demanda aumenta con las poblaciones de origen y destino, por lo que una ciudad grande genera y atrae más viajes.

En «Economía y contratos» se pueden consultar los ingresos y gastos diarios y acumulados, aceptar un contrato de conexión y pedir un único préstamo cuando el saldo es inferior a 3.000 €. El préstamo concede 3.000 € y se devuelven 3.300 € en cuotas de 550 €/día. Las categorías avanzadas se desbloquean mediante viajes completados, ciudades conectadas y fiabilidad; al cambiar de tipo se indica el requisito.

El inspector de una autopista permite fijar el peaje; se acumula al entrar y se ingresa únicamente cuando se completa el viaje. Por ahora los conductores siguen priorizando el tiempo y no valoran el precio al escoger ruta. Los contratos actuales son de conexión entre ciudades; no se han implementado todavía contratos de duración o fiabilidad.

## Tráfico y penalizaciones

Las ciudades generan demanda según su población y distancia; el balance distingue viajes potenciales, iniciados, completados, no atendidos e interrumpidos. Las vías tienen una capacidad que depende de su longitud, categoría, conservación y nieve. Una ocupación alta reduce la velocidad y puede hacer que se elija una alternativa más rápida, aunque sea más larga. Los viajes en curso revisan la ruta al alcanzar un cruce, como máximo cada diez segundos de simulación y con un límite de cálculos por paso. La vista «tráfico» y el inspector muestran el estado y la ocupación.

Por cada unidad completa de ocupación que supere la capacidad se cargan 2,5 € por segundo de simulación, proporcionalmente al exceso. Al completar un viaje se cobran 4 € por cada segundo que exceda 1,6 veces la distancia directa (con un mínimo de 3 segundos), hasta el 80 % del pago de ese viaje. La distancia se mide en casillas y el tiempo en segundos de simulación; las penalizaciones acumuladas y diarias están en «Balance y tráfico». Los parámetros están en `scripts/balance.gd`.

## Comprobación automatizada

Con Godot instalado, desde la carpeta del proyecto:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/zoom_smoke.gd
godot --headless --path . --script res://tests/network_smoke.gd
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
godot --headless --path . --script res://tests/events_smoke.gd
```

Las pruebas comprueban determinismo del terreno, construcción y cobro único, rutas por varios tramos, cruces, cierres, zoom por teclado y reconstrucción del estado serializado. No sustituye a una prueba interactiva de mando ni a una verificación visual.

## Exportación

En Godot, instala las plantillas de exportación de la **misma versión** desde Editor → Manage Export Templates. En Proyecto → Exportar, crea presets para Linux/X11 y Windows Desktop, selecciona arquitectura x86_64 y exporta. Para Steam Deck usa la compilación Linux y prueba también con Proton si distribuyes Windows. Comprueba controles, resolución 1280 × 800, rendimiento, escritura en `user://` y suspensión/reanudación en el dispositivo. La integración de Steamworks, logros y configuración de la tienda son pasos posteriores opcionales; el juego no depende del SDK.
