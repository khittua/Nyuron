# Nyuron  
**Juego educativo móvil desarrollado en Godot 4** enfocado en potenciar habilidades cognitivas en niños y niñas a través de minijuegos cortos, atractivos y fáciles de entender. Nyuron nace como un ecosistema de experiencias “rápidas” (tipo arcade) con estética pixel-art submarina/playa y un enfoque claro: **aprender jugando**.

---

## ¿Qué es Nyuron?

Nyuron es un proyecto de videojuego educativo para dispositivos móviles, construido como una colección de minijuegos interconectados, con un sistema base de progreso y recompensas. La idea principal es que cada minijuego estimule una parte específica del desarrollo cognitivo infantil, trabajando aspectos como:

- **Razonamiento lógico**
- **Resolución de problemas**
- **Coordinación visomotora**
- **Atención y memoria**
- **Reconocimiento de patrones**
- **Velocidad de reacción y toma de decisiones**

El juego está diseñado para ser accesible: sesiones cortas, controles simples, retroalimentación inmediata (sonido/animaciones), y dificultad progresiva para adaptarse al aprendizaje.

---

## Objetivo del proyecto

El objetivo de Nyuron es ofrecer una alternativa positiva al uso de pantallas: en vez de contenido pasivo, entregar una experiencia interactiva que promueva habilidades cognitivas mediante:

- Reglas claras y repetibles (aprendizaje por práctica)
- Dificultad gradual (aprendizaje incremental)
- Estímulos visuales y sonoros (reforzamiento inmediato)
- Progreso visible (motivación y constancia)

---

## Fundamentos psicológicos y educativos (Piaget y Vygotsky)

Nyuron no es solo “un juego con minijuegos”: su diseño está inspirado en enfoques clásicos del desarrollo cognitivo que explican **cómo aprenden los niños** y por qué el juego puede ser una herramienta válida para potenciar habilidades como memoria, atención y coordinación.

### Piaget: etapas del desarrollo y tipo de desafío
El proyecto está orientado principalmente a un público infantil (aprox. **3 a 11 años**), rango que se relaciona con etapas descritas por Piaget como **preoperacional**, **operaciones concretas** y el inicio de **operaciones formales**.
Esto guía el tipo de retos que propone Nyuron:

- **Reglas simples y consistentes**, fáciles de internalizar.
- **Aprendizaje por repetición y experiencia directa**, donde el niño “descubre” jugando.
- Desafíos que pasan de lo concreto (reaccionar, asociar, contar, ordenar) a patrones más complejos según progreso.

En otras palabras, los minijuegos se diseñan para que el usuario pueda **entender y mejorar mediante práctica**, manteniendo una dificultad que evoluciona sin volverse frustrante.

### Vygotsky: ZDP y andamiaje (Nyuron como apoyo)
Desde Vygotsky, el aprendizaje ocurre fuertemente en interacción con el entorno y mediante apoyos que actúan como **andamiaje** dentro de la **Zona de Desarrollo Próximo (ZDP)**.
Nyuron se plantea como una herramienta digital que cumple ese rol de andamiaje porque:

- entrega **retroalimentación inmediata** (sonidos, animaciones, puntajes),
- guía el desempeño con **objetivos claros** y repetición controlada,
- ajusta el desafío de forma progresiva para que el niño se mantenga “en el borde” de lo que puede lograr con apoyo.

Bajo esta idea, Nyuron busca convertir el tiempo en pantalla en una actividad con intención educativa, fomentando la práctica de habilidades cognitivas entrenables como atención, memoria y control inhibitorio.

> En síntesis: Nyuron propone minijuegos diseñados para practicar habilidades reales, con dificultad progresiva y feedback constante, alineándose con la idea de aprendizaje por etapas (Piaget) y aprendizaje con apoyo dentro de la ZDP (Vygotsky).

---

## Enfoque educativo y diseño

Nyuron está pensado para un público infantil, por lo que se prioriza:

- **Diseño amigable**: interfaz simple, sin saturación de botones.
- **Feedback constante**: animaciones, sonidos, puntajes, mensajes.
- **Repetición sin frustración**: intentos rápidos, reinicio simple, recompensas frecuentes.
- **Dificultad escalable**: niveles o rondas que aumentan el desafío según desempeño.

---

## Minijuegos incluidos

Nyuron se construye como un ecosistema de minijuegos (cada uno con su escena y lógica independiente), agrupados en categorías cognitivas. Ejemplos de mecánicas implementadas:

### 1) Coordinación visomotora
Minijuegos donde el foco está en mover, reaccionar, esquivar o atrapar elementos a tiempo:
- Spawners de obstáculos/bonus con timers.
- Control simple y responsivo.
- HUD de puntaje, tiempo/vidas y panel de *Game Over*.

### 2) Memoria y atención
Minijuegos donde el reto es recordar patrones, pares o secuencias:
- Mecánicas tipo “memorice” con animaciones (abrir/cerrar).
- Penalizaciones/recompensas según acierto/error.
- Refuerzo audiovisual para consolidar el aprendizaje.

### 3) Lógica y patrones
Minijuegos que trabajan secuencias, conteo, elección correcta y toma de decisiones:
- Secuencias tipo “Simon dice” (colores/ritmos).
- Conteo de objetivos por ronda.
- Dificultad dinámica basada en rachas, rondas completadas o desempeño.

> Cada minijuego está pensado para durar poco y poder repetirse muchas veces, convirtiéndose en una “rutina” de práctica.

---

## Sistema de progreso y recompensas

Nyuron incorpora elementos de progresión para motivar la repetición:

- **Puntajes por minijuego** y máximos.
- **Monedas/recompensas** obtenidas al jugar.
- **Tienda / ítems** (según el alcance del proyecto) para dar un sentido de avance.
- **Dificultad progresiva**: el juego no se queda estático; mejora el desafío mientras el jugador avanza.

Esto permite que Nyuron funcione como un ecosistema: jugar un minijuego aporta al progreso general, no es solo “jugar por jugar”.

---

## Tecnologías y herramientas

- **Motor:** Godot Engine 4.x
- **Lenguaje:** GDScript
- **Estilo:** 2D pixel-art
- **Arquitectura de escenas:** escenas independientes por minijuego + UI/HUD + controladores (timers/spawners/panels).
- **Enfoque móvil:** adaptación de resolución/orientación, UI escalable, controles simples.

---

## Estructura general del proyecto

A nivel de organización, Nyuron se plantea como un conjunto de escenas reutilizables:

- Menú / selección de minijuegos
- Escenas por minijuego (cada una con su:
  - controlador principal (`main.gd`)
  - UI (CanvasLayer / HUD)
  - spawners / timers
  - paneles de introducción y *game over*
  - sonidos y música)
- Recursos compartidos:
  - sprites / animaciones
  - efectos de sonido (SFX)
  - música de fondo (BGM)
  - utilidades comunes (si aplica)

La prioridad es que cada minijuego sea modular: poder mantenerlo, iterarlo y probarlo sin romper el resto.

---

## Estado del proyecto

Nyuron se encuentra desarrollado como prototipo funcional (MVP) con múltiples minijuegos implementados, integrados bajo un mismo concepto visual y con mecánicas consistentes:

- HUD, puntajes y paneles de finalización
- Sistemas de spawn y timers
- Feedback audiovisual
- Ajustes de escalado y orientación para móvil
- Iteración sobre dificultad y experiencia de usuario

