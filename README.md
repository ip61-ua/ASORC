# Administración de Sistemas Operativos y Redes de los Computadores

> [!TIP]
> Recuerda destacar ⭐ el proyecto para dar visibilidad.  

ASORC es una obligatoria de 3º para cualquier itinerario/especialización cuyo objetivo es manejarse con los diferentes sistemas operativos.

Aquí se presentan apuntes, entregas de prácticas que puedan resultar de ayuda para todo aquel que curse esta asignatura o este interesado en conocer en detalle de lo que se vaya a hacer en esta.

La materia va muy dirigida a la administración de sistemas y cómo este de perfiles debería desenvolverse y manejarse entre diferentes sistemas operativos para realizar el mismo propósito.

## *Software*

Trabajaremos con máquinas virtuales (VM) de VirtualBox (VBox). Mi *host* es un Fedora, por lo que si tu usas Windows te jodes por 3: 1) los programas que uso son diferentes (pero FOSS así que igual hay algo compatible), 2) usas windows y 3) suele haber problemas con todo...

Esta es la lista de algunos programas que recuerdo haber usado en mi *host*: VirtualBox, Remmina, FileZilla, ssh, dolphin, smb, mount, touch, rm, Firefox, Chromium, python, spectacle...

## Aviso para navegantes

Esta es una asignatura difícil. Su dificultad no reside en el propio intelecto (como resolver ecuaciones matemáticas complejas o reacciones químicas) sino por su exigencia a la hora de sacarte las castañas como puedas. Y es que el volumen de trabajo exigido por los numerosos ítems no es acompañado por una masticada explicación de estos.

Aquí algunas claves para esta asignatura:

- Esfuérzate y no lo dejes para el último día (la típica). Pero aquí especialmente porque va a depender lo que encuentres por Internet y PC.
- **Obligatorio un portátil** y más si es uno de última generación. El coordinador sugiere como alternativa si tienes una torre pues que se la lleves (Está loco).
- Ve a clase de teoría. Aunque por la normativa no te pueden obligar ir a teoría, todos los años se monta un pollo porque se pone a pasar lista. El motivo no es ir porque sea obligatorio sino porque hay detalles de cómo deberías hacer la práctica y no sale en la documento.
- Cualquier cosa vale. Debes tener el *mindset* de si un ítem está hecho (aunque sea a medias), pases a hacer el siguiente.
- En VBox puedes hacer instancias por si la lías después y así volver a un punto seguro donde todo va bien y tal. Úsala a tu parecer porque puede que te queden sin espacio más rápido.
- Haz instancias cuando todo esté acabado, no haya mucho donde rascar y este todo preparado para presentar. Así es solo pulsar un botón en clase y puedes ir más tranquilo porque no deberías tocar gran cosa.
- Si vas a por nota, sigue haciendo los ítems incluso cuando esté ya entregado. Piensa que es muy poco probable que de 300 alumnos se ponga a leer 100 páginas de memoria de un alumno. Lo que realmente cuenta es lo que le vayas a enseñar en clase. (Creo que el 0,1 de todas las entregas es porque revisa si corresponde a lo has puesto en la memoria, pero ns porque es subjetivo en teoría...)
- No te curres la memoria tanto y ve al grano. Por cada ítem pon una captura de cómo lo has hecho (2 líneas) y fin. Tampoco es necesario que siga un formato tan estricto, solo que no sea un asco verla.
- Trae siempre el cargador del portátil.
- Piensa que por cada entrega necesitas mínimo 100 GB (sí, windows server consume una barbaridad) por lo que si no cuentas con eso te recomiendo comprarte un pen de esos ultrarrápido (sale barato, portable...). 
- Siempre XFCE. Aquí no nos importa probar escritorios como KDE, GNOME, i3... Ignorad si os dicen que tenéis que probar todo tipo de escritorios... Solo quiere que sufráis para que os consuma más recursos y que el portátil explote (muy improbable).
- Si vas limitado de recursos, ponle 1 núcleo y 1 GB de RAM. Para windows darle 2,5 GB de RAM.
- No necesitas pagar Windows, lo descargas con la evaluación para la primera entrega, lo borras y vuelves a solicitar otra evaluación.
- Odiarás FreeBSD, por lo que si funciona algo deberías hacer instantánea.
- Elige Debian GNU/Linux frente a RockyLinux. El coordinador elige el otro porque le mola RedHat y Rocky es lo mejor porque es 1:1 RedHat, bla bla... vamos que lo financia RedHat. Elige Debian, de verás, sin miedo, aunque te mire mal el profesor. Debian tiene más años que un bosque, tiene un chorro de programas en sus repos, todo es muy fácil,  liviano y muy importante COMPATIBLE.
- Para los logs, no los hagas al final del todo, hazlos cuando termines el ítem.
- Para la primera entrega ve sistema por sistema y emplea los programas más comunes de instalar. Para el resto, ve ítem por ítem.
- No te flipes inventando nombre raros ni contraseñas que no vayas a recordar.
- No mires woula porque es cáncer y una pérdida de tiempo además de engañabobos que te obliga a ver 8 anuncios por memoria y en la memoria no hay nada de nada. Ten en cuenta que cada vez hay más AI slop a cambio de pasta. Tengo claro que el woula hay más troll que seguramente sean los mismos profesores que ponen los apuntes mal para conseguir más dinero y que aprendas mal.
- Solo si tienes un 10 te ponen la MH, en cualquier otro el coordinador se niega a otorgar tal acto de reconocimiento.
- Aprovecha las clases de prácticas para preguntar dudas.

## Motivación

Simplemente hago esto por ayudar a otros. Que un mayor número de personas pueda sacarse la MH ;). Por una educación de mayor calidad donde el conocimiento fluya libremente y no sea poseído por tiranos que quieren cobrar a base de publicidad roñosa y explicaciones escuetas. Por un trato justo y de respeto a quienes trabajan en el *software* que es justo con el resto.

## Responsabilidad

¡Ojo! No me hago responsable de detección de copia ni tampoco del debido funcionamiento de las cosas que pone en los documentos. En mi máquina era así y sí funcionaba. Ahora te toca a ti ser responsable de lo que haces o dejas de hacer.


## Desarrollo

Aquí se describe lo que que hace en cada práctica de forma coloquial:

### Práctica 1

Instalar muchos sistemas. Desde Mint hasta LFS (*Linux From Scratch*). Si no vas a por el 10, no merece la pena LFS.

Nota fácil.

### Práctica 2

Instalar servicios. Lo difícil aquí es Windows y en compaginar la asignatura con la asignatura SD. Gran parte se puede hacer usando el server.world.

**Recomendación:** Si tienes poco espacio evita usar a toda costa *flatpak* y *snaps*.

> [!WARNING]
> Los *scripts* que se facilitan están acorde a mi configuración personal. Pueden no hacer lo esperado si no revisas antes su funcionamiento.

> [!WARNING]
> Para ejecutar los *scripts* muchos con de copia y pega directamente en la terminal, o bien ejecutar línea a línea.  

### Práctica 3

Lo mismo que lo anterior. De hecho es complementaria a la 2 porque hay servicios que dependen de los anteriores. Lo difícil aquí es FreeBSD y Windows. Los puntos de *groupware*, wol, pxe son tediosos por la falta de información (información desactualizada de las presentaciones, poca info en internet, IA alucina...).

> [!WARNING]
> Los *scripts* que se facilitan están acorde a mi configuración personal. Pueden no hacer lo esperado si no revisas antes su funcionamiento.

> [!WARNING]
> Para ejecutar los *scripts* muchos con de copia y pega directamente en la terminal, o bien ejecutar línea a línea.  
