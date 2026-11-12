# Isla Sin Salida

Un juego de Roblox de obstáculos **muy difícil**: despiertas en una prisión en medio de una isla y tienes que escapar hasta un barco. Todas las ideas, nombres y niveles son nuestros.

## Los niveles

1. **La prisión**: empiezas aquí. Sal por el hueco del muro.
2. **El volcán**: salta de piedra en piedra sobre la lava. Algunas piedras son más pequeñas.
3. **Hielo frágil**: las plataformas se rompen poco después de pisarlas. ¡No te detengas!
4. **El puente de las barras**: un puente estrecho con 4 barras rojas que giran. Si te tocan, pierdes.
5. **Las balsas**: balsas que se mueven de lado a lado sobre el mar. Hay que calcular bien el salto.
6. **El faro**: sube la escalera en espiral mientras la marea mortal sube detrás de ti.
7. **El barco**: da el último salto desde la cima del faro hasta el barco para escapar.

El mar está lleno de tiburones: si te caes, vuelves al último punto de control. **Solo hay 2 puntos de control** (las banderas rojas), por eso es tan difícil.

La tabla de jugadores muestra tus **Escapes** y tus **Muertes**. Al ganar ves tu tiempo.

## Cómo ponerlo en Roblox Studio

1. Abre Roblox Studio y crea un juego nuevo con la plantilla **Baseplate**.
2. En el **Explorer**, borra la pieza `Baseplate` que está dentro de `Workspace`.
3. Haz clic derecho en **ServerScriptService** → **Insert Object** → **Script**.
4. Abre el archivo [`src/IslaSinSalida.server.lua`](src/IslaSinSalida.server.lua), copia todo el código y pégalo en ese Script.
5. Pulsa **Play**. El mapa se construye solo.

## Cambiar la dificultad

Al principio del script hay una sección `CONFIGURACIÓN`. Por ejemplo:

- `VelocidadBarras`: más alto = las barras giran más rápido.
- `TiempoAntesDeCaer`: más bajo = el hielo se rompe antes.
- `VelocidadMarea`: más alto = la marea del faro sube más rápido.
