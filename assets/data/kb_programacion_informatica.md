# Base de Conocimiento: Programación e Informática

> Nivel introductorio. Entradas cortas y densas, pensadas para recuperación (RAG).
> Cada sección con `##` es un tema; cada `###` es un concepto autocontenido.

---

## Conceptos fundamentales de informática

### Informática
Disciplina que estudia el tratamiento automático de la información mediante computadoras. Abarca hardware, software, redes y datos.

### Dato vs. información
Un **dato** es un valor en bruto sin contexto (ej. "42"). La **información** es el dato procesado y con significado (ej. "42 años de edad").

### Bit y byte
El **bit** es la unidad mínima de información: vale 0 o 1. Un **byte** son 8 bits y puede representar 256 valores distintos (2⁸).

### Sistema binario
Sistema numérico de base 2 que usa solo 0 y 1. Es la forma en que las computadoras representan toda la información internamente.

### Sistema hexadecimal
Sistema de base 16 (0-9 y A-F). Se usa para representar de forma compacta valores binarios, como colores (#FF0000) o direcciones de memoria.

### Código ASCII
Estándar que asigna un número a cada carácter (letras, dígitos, símbolos). Por ejemplo, la 'A' es el 65. Permite representar texto en binario.

### Unicode y UTF-8
**Unicode** asigna un número único a cada carácter de casi todos los idiomas. **UTF-8** es la codificación más usada para representarlo, compatible con ASCII.

### Hardware y software
**Hardware** es la parte física de la computadora (procesador, memoria, disco). **Software** es el conjunto de programas e instrucciones que la hacen funcionar.

### CPU
Unidad Central de Procesamiento. Ejecuta las instrucciones de los programas. Se compone principalmente de la unidad de control y la unidad aritmético-lógica (ALU).

### GPU
Unidad de Procesamiento Gráfico. Especializada en cálculos paralelos, ideal para gráficos, videojuegos y entrenamiento de modelos de IA.

### Memoria RAM
Memoria de acceso aleatorio. Almacena temporalmente datos y programas en ejecución. Es volátil: pierde su contenido al apagar el equipo.

### Memoria caché
Memoria muy rápida y pequeña entre la CPU y la RAM. Guarda datos de uso frecuente para acelerar el acceso.

### Almacenamiento
Guarda datos de forma persistente (no se borran al apagar). Ejemplos: disco duro (HDD), unidad de estado sólido (SSD).

### Sistema operativo
Software que gestiona el hardware y sirve de intermediario entre el usuario y la máquina. Ejemplos: Windows, Linux, macOS, Android.

### Kernel
Núcleo del sistema operativo. Gestiona los recursos del hardware (memoria, procesos, dispositivos) y controla el acceso a ellos.

### Proceso e hilo
Un **proceso** es un programa en ejecución con sus propios recursos. Un **hilo** (thread) es una unidad de ejecución dentro de un proceso; varios hilos comparten recursos.

---

## Programación: conceptos base

### Programación
Proceso de escribir instrucciones (código) que una computadora ejecuta para resolver un problema o realizar una tarea.

### Algoritmo
Secuencia finita y ordenada de pasos para resolver un problema. Debe ser preciso, finito y tener entradas y salidas definidas.

### Pseudocódigo
Descripción de un algoritmo en lenguaje natural estructurado, sin la sintaxis estricta de un lenguaje de programación. Sirve para diseñar antes de codificar.

### Lenguaje de programación
Conjunto de reglas y símbolos para escribir programas. Ejemplos: Python, Java, C, JavaScript, Go.

### Lenguaje de alto y bajo nivel
**Alto nivel**: cercano al lenguaje humano, fácil de leer (Python, Java). **Bajo nivel**: cercano a la máquina (ensamblador, código máquina).

### Código fuente
Texto escrito por el programador en un lenguaje de programación, antes de ser traducido a algo que la máquina pueda ejecutar.

### Compilador vs. intérprete
Un **compilador** traduce todo el código fuente a lenguaje máquina antes de ejecutarlo (ej. C, Go). Un **intérprete** traduce y ejecuta línea por línea (ej. Python).

### Sintaxis y semántica
La **sintaxis** son las reglas de escritura de un lenguaje. La **semántica** es el significado de las instrucciones. Un error de sintaxis impide ejecutar; uno de semántica produce resultados incorrectos.

### Variable
Espacio en memoria con un nombre que almacena un valor que puede cambiar durante la ejecución del programa.

### Tipo de dato
Clasificación que define qué valores puede tener una variable y qué operaciones admite. Ejemplos: entero (int), decimal (float), texto (string), booleano (bool).

### Constante
Valor que no cambia durante la ejecución del programa, a diferencia de una variable.

### Operador
Símbolo que realiza una operación sobre valores. Tipos: aritméticos (+, -, *, /), de comparación (==, <, >), lógicos (AND, OR, NOT).

### Comentario
Texto en el código que el programa ignora al ejecutarse. Sirve para explicar qué hace el código a otros programadores.

### Entrada y salida (I/O)
La **entrada** son los datos que recibe el programa (teclado, archivo). La **salida** es lo que produce (pantalla, archivo).

---

## Estructuras de control

### Estructura secuencial
Las instrucciones se ejecutan una tras otra, en el orden en que están escritas.

### Condicional (if/else)
Permite ejecutar distintos bloques de código según se cumpla o no una condición.

### Switch / case
Estructura que selecciona un bloque de código a ejecutar entre varios, según el valor de una variable.

### Bucle (loop)
Repite un bloque de código varias veces. Tipos comunes: `for` (número conocido de repeticiones) y `while` (mientras se cumpla una condición).

### Break y continue
**Break** sale inmediatamente de un bucle. **Continue** salta a la siguiente iteración sin terminar la actual.

### Función
Bloque de código con nombre que realiza una tarea específica y puede reutilizarse. Recibe parámetros (entradas) y puede devolver un valor (salida).

### Parámetro y argumento
Un **parámetro** es la variable declarada en la definición de una función. Un **argumento** es el valor real que se le pasa al llamarla.

### Recursividad
Técnica en la que una función se llama a sí misma para resolver un problema dividiéndolo en casos más pequeños.

### Ámbito (scope)
Región del programa donde una variable es accesible. Puede ser local (dentro de una función) o global (en todo el programa).

---

## Estructuras de datos

### Estructura de datos
Forma de organizar y almacenar datos para usarlos eficientemente.

### Arreglo (array)
Colección de elementos del mismo tipo, ordenados y accesibles por un índice numérico que empieza en 0.

### Lista
Colección ordenada de elementos que puede crecer o reducirse. Permite agregar y quitar elementos.

### Lista enlazada
Estructura donde cada elemento (nodo) apunta al siguiente. Permite inserciones y borrados eficientes, pero no acceso directo por índice.

### Pila (stack)
Estructura LIFO (Last In, First Out): el último elemento en entrar es el primero en salir. Como una pila de platos.

### Cola (queue)
Estructura FIFO (First In, First Out): el primer elemento en entrar es el primero en salir. Como una fila de personas.

### Diccionario (mapa)
Colección de pares clave-valor. Permite buscar un valor a partir de su clave de forma rápida.

### Conjunto (set)
Colección de elementos únicos sin orden. No permite duplicados.

### Árbol
Estructura jerárquica con un nodo raíz del que se desprenden ramas. Cada nodo puede tener nodos hijos. Ejemplo: árbol binario.

### Grafo
Estructura de nodos (vértices) conectados por aristas. Modela relaciones, como redes sociales o mapas.

### Hash
Función que convierte datos de cualquier tamaño en un valor de tamaño fijo. Base de las tablas hash y de la verificación de integridad.

---

## Algoritmos comunes

### Complejidad algorítmica (Big O)
Mide cómo crece el tiempo o la memoria de un algoritmo según el tamaño de la entrada. Ejemplos: O(1) constante, O(n) lineal, O(n²) cuadrático.

### Búsqueda lineal
Recorre los elementos uno por uno hasta encontrar el buscado. Simple pero lenta para grandes volúmenes: O(n).

### Búsqueda binaria
Busca en una lista **ordenada** dividiéndola a la mitad repetidamente. Muy eficiente: O(log n).

### Ordenamiento (sorting)
Proceso de organizar elementos según un criterio. Algoritmos comunes: burbuja (simple), quicksort y mergesort (eficientes).

### Algoritmo de fuerza bruta
Resuelve un problema probando todas las posibilidades. Simple pero costoso en tiempo.

---

## Paradigmas de programación

### Paradigma de programación
Estilo o enfoque para estructurar y escribir programas.

### Programación estructurada
Paradigma basado en secuencia, condicionales y bucles, evitando saltos arbitrarios (como `goto`).

### Programación orientada a objetos (POO)
Organiza el código en **objetos** que combinan datos (atributos) y comportamiento (métodos). Conceptos clave: clase, objeto, herencia, encapsulamiento, polimorfismo.

### Clase y objeto
Una **clase** es una plantilla que define atributos y métodos. Un **objeto** es una instancia concreta de una clase.

### Herencia
Mecanismo por el que una clase hija recibe atributos y métodos de una clase padre, permitiendo reutilizar código.

### Encapsulamiento
Principio de ocultar los detalles internos de un objeto y exponer solo lo necesario mediante una interfaz pública.

### Polimorfismo
Capacidad de que un mismo método se comporte de forma distinta según el objeto que lo use.

### Programación funcional
Paradigma que trata el cómputo como evaluación de funciones, evitando cambiar el estado y los datos mutables.

### Programación declarativa vs. imperativa
**Imperativa**: se describe *cómo* hacer algo paso a paso. **Declarativa**: se describe *qué* se quiere obtener (ej. SQL).

---

## Bases de datos

### Base de datos
Conjunto organizado de datos almacenados para ser consultados y gestionados eficientemente.

### Base de datos relacional
Organiza los datos en tablas con filas y columnas, relacionadas entre sí. Se consultan con SQL. Ejemplos: PostgreSQL, MySQL.

### SQL
Lenguaje estándar para consultar y manipular bases de datos relacionales. Comandos básicos: SELECT, INSERT, UPDATE, DELETE.

### Tabla, fila y columna
Una **tabla** almacena datos de un tipo de entidad. Cada **fila** (registro) es una entrada; cada **columna** (campo) es un atributo.

### Clave primaria
Campo (o conjunto de campos) que identifica de forma única cada fila de una tabla.

### Clave foránea
Campo que referencia la clave primaria de otra tabla, estableciendo una relación entre ambas.

### Índice
Estructura que acelera las búsquedas en una tabla, a costa de más espacio y escrituras más lentas.

### Normalización
Proceso de organizar una base de datos para reducir la redundancia y evitar inconsistencias.

### Transacción
Conjunto de operaciones que se ejecutan como una sola unidad: o se completan todas, o ninguna (propiedades ACID).

### Base de datos NoSQL
Bases de datos no relacionales, flexibles para datos no estructurados. Ejemplos: MongoDB (documentos), Redis (clave-valor).

---

## Redes e internet

### Red de computadoras
Conjunto de dispositivos conectados que comparten datos y recursos.

### Internet
Red global de redes interconectadas que se comunican mediante el protocolo TCP/IP.

### Protocolo
Conjunto de reglas que definen cómo se comunican los dispositivos en una red. Ejemplos: HTTP, TCP/IP, FTP.

### TCP/IP
Conjunto de protocolos base de internet. **TCP** garantiza la entrega ordenada de datos; **IP** se encarga del direccionamiento y enrutamiento.

### HTTP y HTTPS
**HTTP** es el protocolo para transferir páginas web. **HTTPS** es su versión segura, que cifra la comunicación con TLS/SSL.

### Dirección IP
Identificador numérico único de un dispositivo en una red. Ejemplo: 192.168.1.1.

### DNS
Sistema de Nombres de Dominio. Traduce nombres legibles (google.com) en direcciones IP que las máquinas entienden.

### Cliente-servidor
Modelo donde el **cliente** solicita servicios o datos y el **servidor** los provee.

### API
Interfaz de Programación de Aplicaciones. Conjunto de reglas que permite que dos programas se comuniquen entre sí.

### API REST
Estilo de API que usa los métodos HTTP (GET, POST, PUT, DELETE) para operar sobre recursos identificados por URLs.

### JSON
Formato ligero de intercambio de datos basado en pares clave-valor. Muy usado en APIs por ser legible y fácil de procesar.

### Ancho de banda y latencia
El **ancho de banda** es la cantidad de datos que se pueden transmitir por unidad de tiempo. La **latencia** es el retraso en la transmisión.

---

## Desarrollo de software

### Frontend y backend
El **frontend** es la parte visible con la que interactúa el usuario. El **backend** es la lógica del servidor y el acceso a datos, que el usuario no ve.

### Control de versiones
Sistema que registra los cambios en el código a lo largo del tiempo. La herramienta más usada es **Git**.

### Git y repositorio
**Git** es un sistema de control de versiones distribuido. Un **repositorio** es el almacén donde se guarda el historial de un proyecto.

### Bug
Error o fallo en un programa que produce un comportamiento incorrecto.

### Depuración (debugging)
Proceso de encontrar y corregir errores en el código.

### Framework
Conjunto de herramientas y librerías que dan una estructura base para desarrollar software más rápido. Ejemplos: Flutter, React, Django.

### Librería (biblioteca)
Conjunto de código reutilizable que resuelve tareas específicas y se integra en un proyecto.

### IDE
Entorno de Desarrollo Integrado. Programa que reúne editor, compilador y depurador en una sola herramienta. Ejemplos: VS Code, IntelliJ.

### Compilación vs. ejecución
La **compilación** traduce el código a un formato ejecutable. La **ejecución** es cuando el programa realmente corre.

### Testing (pruebas)
Proceso de verificar que el software funciona correctamente. Tipos: pruebas unitarias, de integración y de sistema.

### Metodología ágil
Enfoque de desarrollo iterativo e incremental, con entregas frecuentes y adaptación al cambio. Ejemplo: Scrum.

---

## Inteligencia artificial (introducción)

### Inteligencia artificial (IA)
Rama de la informática que busca crear sistemas capaces de realizar tareas que requieren inteligencia humana.

### Machine learning
Subcampo de la IA donde los sistemas aprenden patrones a partir de datos, sin ser programados explícitamente para cada tarea.

### Red neuronal
Modelo de IA inspirado en el cerebro, formado por capas de "neuronas" conectadas que procesan información.

### Datos de entrenamiento
Conjunto de ejemplos con los que un modelo de machine learning aprende a hacer predicciones.

### Modelo de lenguaje (LLM)
Sistema de IA entrenado con grandes cantidades de texto para entender y generar lenguaje natural. Ejemplos: GPT, Qwen.

---

## Conceptos de seguridad

### Ciberseguridad
Conjunto de prácticas para proteger sistemas, redes y datos de ataques digitales.

### Cifrado (encriptación)
Proceso de convertir información en un formato ilegible para protegerla, que solo puede revertirse con una clave.

### Malware
Software malicioso diseñado para dañar o infiltrarse en un sistema. Tipos: virus, troyano, ransomware.

### Phishing
Técnica de engaño que suplanta a una entidad confiable para robar datos como contraseñas o tarjetas.

### Autenticación y autorización
La **autenticación** verifica quién eres (usuario y contraseña). La **autorización** define qué puedes hacer una vez autenticado.

### Firewall
Sistema que controla el tráfico de red entrante y saliente según reglas de seguridad.

### Vulnerabilidad
Debilidad en un sistema que puede ser aprovechada por un atacante para comprometerlo.
