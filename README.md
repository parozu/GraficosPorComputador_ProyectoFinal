# 🎮 Gráficos Por Computador — Proyecto Final

## 👥 Integrantes (GitHub)
- **Adrián Alejo Molina** → `SentinelPrime2`
- **Joan Martín Bernabé** → `JoanFlorida`
- **Pablo Rodriguez Zuriaga** → `parozu` / `HiroPRZ`
- **Timothy Henry de Frias Macwhinnie** → `sinnerbie`

---

## 🧩 Proyectos

### ✨ Adrián Alejo Molina — Sci Fi Force Barrier
# Force Barrier Shader (Unity URP)

## Descripción
**Force Barrier** es un shader creado en Unity utilizando **Shader Graph** y diseñado para el **Universal Render Pipeline (URP)**. Su objetivo es generar un efecto visual de barrera de energía estilo ciencia ficción, basado en la representación de patrones de puntos animados mediante ruido procedural y control de máscara para definir el contorno de la barrera.

Este shader está pensado para objetos estáticos o dinámicos que requieran un efecto de escudo, campo de fuerza, domo de protección o cualquier tipo de barrera energética con estética futurista.

---

## Características principales
- Desarrollado íntegramente con **Shader Graph**.
- Compatible con **URP**.
- Efecto visual de red de puntos animados que simulan energía en constante vibración.
- Control del contorno mediante máscara configurable.
- Colores personalizables para puntos y borde.
- Animación basada en ruido con escala y velocidad ajustables.
- Fácil integración: solo requiere aplicar el material al objeto.

---

## Parámetros configurables

| Parámetro              | Descripción |
|------------------------|-------------|
| **Dot Size**           | Controla el tamaño de los puntos que conforman la barrera. |
| **Dot Color**          | Define el color principal de los puntos energéticos. |
| **Dot Tiling**         | Ajusta la repetición del patrón de puntos sobre la malla. |
| **Dot Noise**          | Nivel de distorsión aplicado al patrón. |
| **Noise Scale**        | Escala general del ruido procedural. |
| **Noise Speed**        | Velocidad de animación del ruido para simular vibración. |
| **Mask Power**         | Control sobre qué zonas se muestran o se ocultan mediante máscara. |
| **Border Color**       | Color del borde de la barrera. |
| **Border Mask**        | Ajusta intensidad y distribución del borde. |


<img width="1993" height="1025" alt="Captura de pantalla 2026-01-12 084651" src="https://github.com/user-attachments/assets/84b64848-1be4-47ca-9f60-9ec163531edf" />



https://github.com/user-attachments/assets/3bd63ffe-5dbc-49cc-aa72-29f4bc086e12



---

## Requisitos
- Unity con **URP** configurado.
- Shader Graph habilitado en el proyecto.
- No requiere configuración adicional más allá de aplicar el material.

---

## Uso
1. Crea un nuevo **Material** en Unity.
2. Selecciona el shader **Force Barrier** en el menú desplegable.
3. Aplica el material al objeto en escena.
4. Ajusta los parámetros según tu necesidad:
   - Tamaño y color de puntos.
   - Tiling del patrón.
   - Noise (intensidad, escala y velocidad).
   - Máscara y borde.

### ✨ Joan Martín Bernabé — Acuarelas

#### 💡 Idea

Se propone intentar simular un efecto visual de acuarela sobre assets 3D, tratando de mantenerme lo más fiel posible a cómo funciona la acuarela en  el mundo real.

#### 🎞️ Inspiraciones / Referencias

La idea original surge del siguiente vídeo de YouTube: https://youtu.be/YMp7VaXuB5A
Sin embargo, he adaptado mi shader a mis conocimientos y nivel actuales.

Mi objetivo era cumplir con tres características fundamentales de la acuarela: la transparencia de ésta, la distribución de la pintura por capas sustractivas, y el reborde irregular que se forma alrededor de cada "bloque" de pintura. Me hubiera gustado que estos mismos rebordes hubieran surgido entre las distintas capas para simular un efecto de pincelada con abundante agua, pero tras varias pruebas, no he sido capaz de llevarlo a cabo correctamente, por lo que lo he descartado.

#### 🛠️ Proceso de Implementación

- **WatercolorLitURP.shader** → El primer shader que hice. Se añaden dos texturas aleatorias, no queda bien ninguna. Aún no se añade outline.

<p align="center">
  <img width="1092" height="528" alt="Captura de pantalla 2026-01-09 130516" src="https://github.com/user-attachments/assets/aa81f880-5d71-47f9-a243-4a4f447cb36b" />
 </p>
 
- **WatercolorOutlineURP.shader** → Shader para hacer un "outline" ajustable a partir de las normales del objeto. Sin embargo, es un contorno demasiado regular.

<p align="center">
  <img width="1048" height="528" alt="Captura de pantalla 2026-01-09 130607" src="https://github.com/user-attachments/assets/ed31ea60-7308-4f5e-9263-7fb17c90e445" />
</p>

- **WatercolorSimpleURP.shader** → Segunda prueba de shader. Se parte de un base color en lugar de las texturas, me convence mucho más el resultado. Sin embargo, la escala del ruido hace que se vea sucio. Primer prototipo que cuenta con el outline regular.

<p align="center">
  <img width="1070" height="555" alt="Captura de pantalla 2026-01-09 130652" src="https://github.com/user-attachments/assets/26973d0c-f56e-4520-820c-fca088be061f" />
</p>

- **WatercolorArtURP.shader** → Tercer y final shader creado. Se ve mucho más limpio que el anterior, y cumple con casi todos los objetivos (no cuenta con contornos de capas irregulares).
- **WatercolorOutlineIrregular.shader** → Shader que parte del concepto del contorno anterior, pero con irregularidad ajustable pra que el efecto sea más convincente, y además evoque a un trazo más tradicional.

<p align="center">
  <img width="1114" height="672" alt="Captura de pantalla 2026-01-09 131005" src="https://github.com/user-attachments/assets/e36bec6c-2c0a-435f-a243-7b35c4bf54fd" />
</p>

* Todos los shaders de acuarelas cuentan con una textura de Perlin Noise, y una de un escaneado de un folio, para simular la textura del papel.

Cabe destacar que, durante el proceso, se ha intentado realizar lo mismo a través de Shader Graph, pero lo he descartado al no lograr familiarizarme con el software a tiempo para crear algo convincente. También he intentado crear un shader que combinara tanto el efecto de acuarela como el contorno en uno solo, pero no ha dado resultado.

✅ **Pipeline utilizado:** URP (Universal Render Pipeline)
---
#### ✅ Resultado Final

<p align="center">
  <img width="1494" height="834" alt="Captura de pantalla 2026-01-09 132943" src="https://github.com/user-attachments/assets/b5c30578-d39b-4264-813b-df5d71272b97" />
</p>

### ✨ Pablo Rodriguez Zuriaga — Portal Mágico de Teletransporte

#### 💡 Idea
Este proyecto consiste en crear un **efecto de hechizo mágico** similar al que aparece en series/animes cuando un mago invoca magia en el suelo.  
Además, se simula un **teletransporte** haciendo que el jugador **desaparezca** (dissolve) y, tras unos segundos, **vuelva a aparecer** junto al hechizo.

#### 🎞️ Inspiraciones / Referencias
Hechizo del anime **Sousou no Frieren** y cómo lo usan:

<p align="center">
  <img src="https://github.com/user-attachments/assets/24d617a4-a349-41a8-9041-9d71265d94d3" width="420" alt="Referencia 1" />
  <img src="https://github.com/user-attachments/assets/5eb708dc-4c79-4f84-b6ba-18ac3be2eca3" width="420" alt="Referencia 2" />
</p>

---

#### 🛠️ Proceso de Implementación

##### 🧱 Sistema compuesto por:
- **TP_Magic.shader** → Shader que genera el hechizo del suelo (círculos/cuadrados + emisión + animación).
- **TP_PlayerDisappear.shader** → Shader para hacer aparecer/desaparecer al jugador (dissolve + borde/edge en los materiales).
- **MagicManager.cs** → Controlador que coordina la secuencia y sincroniza las animaciones de ambos shaders.

##### 📌 Orden de Implementación
1. **✨ TP_Magic.shader**
   - Se construyeron los **4 niveles** del hechizo (cada nivel está formado por un círculo con un cuadrado dentro).
   - Se animó la **rotación**: los niveles impares rotan en un sentido y los pares en el contrario.

2. **💙 Emisión y transición visual**
   - Se añadió **emisión** a las líneas para reforzar el efecto mágico y hacer que el cambio de color sea más suave y menos brusco.

3. **🫥 TP_PlayerDisappear.shader**
   - Se creó el shader de desaparición para el Player usando los **SkinnedMeshRenderer**.
   - El jugador se “disuelve” mediante un efecto de **dissolve con borde (edge)** para remarcar la transición.

4. **🎛️ MagicManager.cs**
   - Se implementó la coordinación de la secuencia completa:
     - el hechizo aparece y se anima,
     - el jugador desaparece,
     - se mantiene fuera un tiempo,
     - reaparece con el hechizo.
   - También se añadió **Fade-Out y Fade-In del hechizo** modificando parámetros del material del shader (por ejemplo, intensidad de emisión / grosor).

✅ **Pipeline utilizado:** URP (Universal Render Pipeline)
---
#### ✅ Resultado Final
<p align="center">
  <img src="https://github.com/user-attachments/assets/6fbb7129-b32c-46a9-8de7-fc052de921ad" alt="PabloRodriguezZuriaga_GPC_ProyectoFinal" width="700" />
</p>

---

### ✨ Timothy Henry de Frias Macwhinnie — Escena Extraterrestre

#### 💡 Idea

El objetivo de este proyecto es crear una escena espacial en Unity mediante el uso combinado de código y los shader graphs del Universal Render Pipeline de Unity.

#### 🎞️ Inspiraciones / Referencias

He creado este esbozo en Adobe Photoshop para plantear la composición de la escena y averiguar que trabajo se necesitará realizar:

<p align="center">
  <img src = "https://github.com/user-attachments/assets/9b039cc1-0a9f-4f9c-a2a6-e6b4c1ded20b"/>
</p>

Este canal de YouTube ha servido cómo un buen recurso de apoyo para el desarrollo de este proyecto: [https://www.youtube.com/@SebastianLague](url)

---

#### 🛠️ Proceso de Implementación
Para realizar este proyecto era necesario crear dos sistemas:
1. Un shader de sol. Y, lo más ambicioso:
2. Una sistema de generar planetas de manera procedural

##### 🧱 Sistema compuesto por:
1. **Planet** Un script MonoBehaviour que llama a varias otras para generar la geometría y colores de la planeta.
2. **PlanetShader** Un shader que asigna colores de dos gradientes a la textura de la planeta para mostrar diferenciar los oceanos con masas de tierra.
3. **SunShader** Un shader que utiliza ruido voronoi para simular la superficie de un sol.

##### 📌 Orden de Implementación
**Planeta**
1. Para evitar que la geometría de la planeta se desforma a los polos, había que generar una esféra que no tenía polos en su topología. El script de ShapeGenerator genera 6 planos al que se apliquen subdivisiones normalizadas para generar una esfera.
2. Para crear tierra y montañas se crean capas de ruido que cambian la altura de los vertices de la malla.
3. El script de ColorGenerator utiliza dos gradientes para crear los colores del oceano y la tierra. Que color se aplica a las texturas se basa en la altura de los vertices de la malla.

#### ✅ Resultado Final Planeta
<p align="center">
  <img src="https://github.com/user-attachments/assets/0f6cf6ef-9521-46c2-a7d3-58a87c2a6db9">
</p>

---

**Sol**
Muchísimo más simple que la planeta, el sol consiste en un shader que aplica un ruido voronoi al variable de emisión del material. A este ruido se le aplica un deformación radial y de tiempo para crear movimiento y dos colores que ayudan a resaltar el efecto.
<p align="center">
  <img width="1920" height="1040" alt="image" src="https://github.com/user-attachments/assets/f118bb29-aa25-4db5-b701-fbb042640b03" />
</p>

#### ✅ Resultado Final Completo
https://github.com/user-attachments/assets/bf739a05-5922-4328-bfe9-0147838ceac7
