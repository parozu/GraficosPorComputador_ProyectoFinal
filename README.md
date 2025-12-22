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

### ✨ Timothy Henry de Frias Macwhinnie — ¿?
