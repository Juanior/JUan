# Isla Sin Salida

Un juego de Roblox de obstáculos **muy difícil**: despiertas en una prisión en medio de una isla y tienes que escapar hasta un barco. Todas las ideas, nombres y niveles son nuestros.

## Los niveles

1. **La prisión**: empiezas aquí. Sal por el hueco del muro.
2. **El volcán**: salta de piedra en piedra sobre la lava. Algunas piedras son más pequeñas.
3. **Hielo frágil**: las plataformas se rompen poco después de pisarlas. ¡No te detengas!
4. **El puente de las barras**: un puente estrecho con 4 barras rojas que giran. Si te tocan, pierdes.
5. **Las balsas**: balsas que se mueven de lado a lado sobre el mar. Hay que calcular bien el salto.
6. **El faro**: sube la escalera en espiral mientras la marea mortal sube detrás de ti.
7. **El barco**: da el último salto desde la cima del faro hasta el barco. Al llegar, el barco baja al mar y zarpa contigo encima hacia el horizonte, con fuegos artificiales, confeti y la cámara dando vueltas a tu alrededor.

El mar está lleno de tiburones: si te caes, vuelves al último punto de control. **Solo hay 2 puntos de control** (las banderas rojas), por eso es tan difícil.

La tabla de jugadores muestra tus **Escapes** y tus **Muertes**. Al ganar ves tu tiempo.

## El paisaje

Alrededor del camino hay un atardecer tropical, islotes con palmeras y rocas, un gran volcán que echa humo con ríos de lava, un barco hundido con barriles, torres de vigilancia con focos que barren la playa, la luz giratoria del faro, nubes, gaviotas volando y aletas de tiburón en el mar. Todo es decoración: no se puede tocar, así que no estorba en los saltos.

## Cómo ponerlo en Roblox Studio

1. Abre Roblox Studio y crea un juego nuevo con la plantilla **Baseplate**.
2. En el **Explorer**, borra la pieza `Baseplate` que está dentro de `Workspace`.
3. Haz clic derecho en **ServerScriptService** → **Insert Object** → **Script**.
4. Abre el archivo [`src/IslaSinSalida.server.lua`](src/IslaSinSalida.server.lua), copia todo el código y pégalo en ese Script.
5. Abre **StarterPlayer**, haz clic derecho en **StarterPlayerScripts** → **Insert Object** → **LocalScript**.
6. Copia todo el código de [`src/CamaraConRaton.client.lua`](src/CamaraConRaton.client.lua) y pégalo en ese LocalScript.
7. Crea otro **LocalScript** en **StarterPlayerScripts** y pega el código de [`src/Cronometro.client.lua`](src/Cronometro.client.lua).
8. Pulsa **Play**. El mapa se construye solo.

## Cronómetro y ranking

Arriba en la pantalla hay un cronómetro que empieza cada vez que apareces en la prisión y se para al llegar al barco. Si mueres después de un punto de control, el tiempo sigue corriendo. En la playa, junto a la salida de la prisión, hay un tablero con **los 10 más rápidos en escapar**, y la tabla de jugadores muestra tu **Mejor tiempo**.

Para que el ranking se guarde para siempre: publica el juego (**File → Publish to Roblox**) y en **Game Settings → Security** activa **Enable Studio Access to API Services**. Sin eso, el ranking funciona igual pero se borra al cerrar el servidor.

## La cámara

La cámara gira solo con mover el ratón (no hace falta mantener el clic derecho) y tu personaje mira hacia donde apuntas. Un punto blanco en el centro te dice hacia dónde miras. El ratón queda siempre bloqueado en el centro: no se puede soltar. En celular y tablet la cámara se sigue girando con el dedo, como siempre.

## Cambiar la dificultad

Al principio del script hay una sección `CONFIGURACIÓN`. Por ejemplo:

- `VelocidadBarras`: más alto = las barras giran más rápido.
- `TiempoAntesDeCaer`: más bajo = el hielo se rompe antes.
- `VelocidadMarea`: más alto = la marea del faro sube más rápido.

## Derechos de autor

© 2026 Juan. Todos los derechos reservados. Mira el archivo [LICENSE](LICENSE).
