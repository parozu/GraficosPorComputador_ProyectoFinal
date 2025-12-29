# 🎮 Gráficos Por Computador — Proyecto Final

## 👥 Integrantes (GitHub)
- **Adrián Alejo Molina** → `SentinelPrime2`
- **Joan Martín Bernabé** → *(pendiente)*
- **Pablo Rodriguez Zuriaga** → `parozu` / `HiroPRZ`
- **Timothy Henry de Frias Macwhinnie** → `sinnerbie`

---

## 🧩 Proyectos

### ✨ Adrián Alejo Molina — ¿?
---

### ✨ Joan Martín Bernabé — ¿?
---

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
Muchísimo más simple que la planeta, el sol consiste en un shader que aplica un ruido voronoi al variable de emisión del material. A este ruido se le aplica un deformación y tiempo para crear movimiento y dos colores que ayudan a resaltar el efecto.
<p align="center">
  <img width="1920" height="1040" alt="image" src="https://github.com/user-attachments/assets/f118bb29-aa25-4db5-b701-fbb042640b03" />
</p>

#### ✅ Resultado Final Completo
https://github.com/user-attachments/assets/bf739a05-5922-4328-bfe9-0147838ceac7
