# Introducción móvil

Android e iOS muestran cuatro pantallas antes de `/welcome` cuando no hay sesión
y todavía no se ha completado la introducción en ese dispositivo. La web y las
sesiones autenticadas conservan su entrada habitual.

El orden es: Tu ciudad también crea (Hero1), Descubre nuevos lugares (Hero2),
Conecta talento local (Hero3) y Vive experiencias reales (Hero4). Se puede navegar
con la flecha, los indicadores o deslizando. Saltar y completar muestran la
bienvenida existente con registro e inicio de sesión.

`SharedPreferencesMobileIntroStore` guarda `marea.mobile_intro.seen`. La preferencia
se resuelve antes de mostrar botones; si el almacenamiento falla, la introducción
se puede terminar igualmente. No se guarda una visita incompleta. El estado es
local e independiente de la cuenta y del onboarding obligatorio de perfil.

Los recursos originales están en `assets/onboarding/`. `IntroWavesPainter` conserva
los trazados del SVG suministrado y los dibuja nativamente. Tarjetas, categorías y
pines son ilustraciones, sin consultas ni navegación al backend. Se mantiene el
logotipo actual de la aplicación.

Las páginas cambian en 400 ms. Los elementos flotan con desfases en un ciclo de
5 segundos y la imagen tiene un movimiento sutil. Los controladores se detienen
en páginas inactivas y en segundo plano; reducción de movimiento presenta una
composición estática. Con texto grande, la página puede desplazarse verticalmente
mientras los controles de navegación permanecen visibles.

Verificación:

```sh
flutter test test/features/auth/mobile_intro_test.dart test/features/auth/mobile_intro_experience_test.dart
flutter test --platform chrome test/features/auth/mobile_intro_web_test.dart
flutter analyze
```
