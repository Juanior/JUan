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

## Cómo ponerlo en Roblox Studio (la forma fácil)

1. Descarga el archivo [`IslaSinSalida.rbxlx`](IslaSinSalida.rbxlx).
2. Abre Roblox Studio y elige **File → Open from File…** (o haz doble clic en el archivo).
3. Pulsa **Play**. El mapa se construye solo y ya tiene todo: cámara, cronómetro, ranking y el gran final.

Para guardarlo como tu juego: **File → Publish to Roblox**.

<details>
<summary>La forma manual (copiando los scripts)</summary>

1. En un juego nuevo, borra la pieza `Baseplate` de `Workspace`.
2. En **ServerScriptService** crea un **Script** y pega [`src/IslaSinSalida.server.lua`](src/IslaSinSalida.server.lua).
3. En **StarterPlayer → StarterPlayerScripts** crea dos **LocalScript** y pega [`src/Pantalla.client.lua`](src/Pantalla.client.lua) en uno y [`src/CamaraConRaton.client.lua`](src/CamaraConRaton.client.lua) en el otro.

Si cambias algo en `src/`, vuelve a crear el archivo con `python3 herramientas/construir_rbxlx.py`.
</details>

## La pantalla

Arriba en el centro hay un panel con el cronómetro, tu récord y el nombre de la zona en la que estás. Debajo, una barra de progreso con el icono de cada zona te dice cuánto te falta para llegar al barco ⛵. Cada zona tiene además un cartel flotante con su nombre, y hay farolillos a los lados del camino.

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
