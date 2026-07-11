# Wink VPN — Android заготовка (Kotlin + Jetpack Compose)

Это повтор HTML-прототипа в виде настоящего Android-проекта. Все 5 экранов
(Splash → Welcome → Telegram → Thanks → Main) работают, дизайн и анимации
максимально близки к HTML-версии.

**Важно:** реального VPN-туннеля пока нет. Кнопка "Подключиться" на главном
экране — имитация (как и в HTML), с той же длительностью и шагами подключения.
Зато Android-разрешение "Разрешить Wink VPN настраивать VPN-соединения" уже
запрашивается по-настоящему (это системный диалог Android VpnService) —
дальше туда нужно подключить настоящий туннель (см. `vpn/WinkVpnService.kt`).

## Как собрать APK, если под рукой только телефон

Здесь не нужен компьютер — сборка происходит в облаке через **GitHub Actions**,
на телефон прилетает уже готовый `.apk`.

### Шаг 1. Залей проект на GitHub

1. Открой [github.com](https://github.com) в браузере телефона, зарегистрируйся
   (если аккаунта ещё нет) — это бесплатно.
2. Нажми **New repository** → дай имя, например `wink-vpn-android` → **Create repository**.
3. На странице репозитория: **Add file → Upload files**.
4. Попробуй загрузить сразу всю распакованную папку `WinkVPN` целиком
   (в файловом менеджере телефона выбери "загрузить папку" — на Android
   через Chrome это обычно работает). Если браузер позволяет выбрать только
   отдельные файлы без сохранения структуры папок — см. `ALL_FILES.md` в архиве:
   там собраны все файлы с указанием точного пути, создавай их через
   **Add file → Create new file**, вписывая путь целиком (например
   `app/src/main/java/com/winkvpn/app/MainActivity.kt`) — GitHub сам создаст
   нужные папки.
5. Внизу страницы жми **Commit changes**.

### Шаг 2. Сборка запустится сама

Как только файлы загружены (особенно `.github/workflows/android-build.yml`),
GitHub Actions автоматически начнёт сборку.

1. Открой вкладку **Actions** в репозитории.
2. Увидишь запущенный workflow "Build Android APK" — тапни на него.
3. Подожди 3-6 минут, пока идёт сборка (статус сменится на зелёную галочку).
4. Внизу страницы workflow найди раздел **Artifacts** → `wink-vpn-debug-apk` →
   тапни, чтобы скачать. Прилетит `.zip`.

### Шаг 3. Установка на телефон

1. Открой скачанный `.zip` через файловый менеджер (встроенные "Файлы" на
   Android умеют распаковывать, либо поставь ZArchiver).
2. Внутри будет `app-debug.apk` — тапни по нему.
3. Android спросит разрешение "Установить из этого источника" — разреши.
4. Установи и открой — приложение готово к проверке.

---

## Как собрать через компьютер (если он всё же появится под рукой)

### Вариант 1 — Android Studio (проще всего)

1. Установи [Android Studio](https://developer.android.com/studio) (последняя версия).
2. Открой Android Studio → **Open** → выбери папку `WinkVPN` (эту, с файлом `settings.gradle.kts`).
3. Дай Android Studio скачать Gradle и зависимости (первый раз — 3-7 минут).
4. Подключи телефон по USB с включённой "Отладкой по USB" (Developer Options),
   или запусти любой эмулятор через **Device Manager** в Android Studio.
5. Нажми зелёную кнопку **Run ▶** (или `Shift+F10`).
6. Приложение соберётся и установится на устройство/эмулятор автоматически.

### Вариант 2 — через терминал (если Android Studio не нужен)

Требуется установленный Android SDK и переменная `ANDROID_HOME`.

```bash
cd WinkVPN
./gradlew assembleDebug
```

Готовый APK появится в:
```
app/build/outputs/apk/debug/app-debug.apk
```

Установить на подключённый телефон:
```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Структура проекта

```
WinkVPN/
├── app/
│   ├── build.gradle.kts          — зависимости (Compose, Material3)
│   └── src/main/
│       ├── AndroidManifest.xml   — разрешения + регистрация VPN-сервиса
│       ├── java/com/winkvpn/app/
│       │   ├── MainActivity.kt   — точка входа, переключение экранов
│       │   ├── AppState.kt       — список серверов, enum экранов
│       │   ├── vpn/
│       │   │   └── WinkVpnService.kt   — заготовка VpnService (без туннеля)
│       │   └── ui/
│       │       ├── theme/Theme.kt      — цвета бренда
│       │       └── screens/
│       │           ├── SplashScreen.kt
│       │           ├── WelcomeScreen.kt
│       │           ├── TelegramScreen.kt
│       │           ├── ThanksScreen.kt
│       │           ├── MainScreen.kt   — экран с кругом VPN, промокодом, конфетти
│       │           ├── BackgroundShapes.kt  — ключ/подарок/стрелка (Canvas)
│       │           └── Common.kt       — переиспользуемые кнопки/тексты
│       └── res/drawable/logo_wink.png  — логотип (прозрачный фон)
```

## Что дальше — подключение реального VPN

Сейчас самое реалистичное решение — **WireGuard**:

1. Добавить зависимость `com.wireguard.android:tunnel` в `app/build.gradle.kts`.
2. На бэкенде (отдельный сервис, не в этом репозитории) сгенерировать пару
   ключей WireGuard для пользователя и отдать конфиг (публичный ключ сервера,
   endpoint, allowed IPs) через API после авторизации.
3. В `WinkVpnService.kt` в методе `onStartCommand` создать `Tunnel` из
   WireGuard SDK, передать туда конфиг, вызвать `establish()`.
4. Связать реальное состояние туннеля (`Tunnel.State`) с UI в `MainScreen.kt`
   вместо текущей имитации через `delay()`.

Сервер для WireGuard поднимается отдельно — это может быть обычный Linux-сервер
с установленным `wireguard-tools`, либо самописный control-plane на Go/Python,
который генерирует конфиги и управляет пирами.

