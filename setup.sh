#!/usr/bin/env bash
# Wink VPN — автосоздание всей структуры проекта одной командой.
# Использование: bash setup.sh
set -e
echo "Создаю структуру проекта Wink VPN..."

mkdir -p ".github/workflows"
mkdir -p "app"
mkdir -p "app/src/main"
mkdir -p "app/src/main/java/com/winkvpn/app"
mkdir -p "app/src/main/java/com/winkvpn/app/ui/screens"
mkdir -p "app/src/main/java/com/winkvpn/app/ui/theme"
mkdir -p "app/src/main/java/com/winkvpn/app/vpn"
mkdir -p "app/src/main/res/drawable"
mkdir -p "app/src/main/res/values"
mkdir -p "gradle/wrapper"

cat > "settings.gradle.kts" << 'WINKVPN_EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "WinkVPN"
include(":app")

WINKVPN_EOF

cat > "build.gradle.kts" << 'WINKVPN_EOF'
// Top-level build file
plugins {
    id("com.android.application") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

WINKVPN_EOF

cat > "gradle.properties" << 'WINKVPN_EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official

WINKVPN_EOF

cat > ".gitignore" << 'WINKVPN_EOF'
*.iml
.gradle
/local.properties
.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties

WINKVPN_EOF

cat > "gradle/wrapper/gradle-wrapper.properties" << 'WINKVPN_EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists

WINKVPN_EOF

cat > ".github/workflows/android-build.yml" << 'WINKVPN_EOF'
name: Build Android APK

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v3
        with:
          gradle-version: 8.7

      - name: Build debug APK
        run: gradle assembleDebug --no-daemon

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: wink-vpn-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk

WINKVPN_EOF

cat > "app/build.gradle.kts" << 'WINKVPN_EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.winkvpn.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.winkvpn.app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0-alpha"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.1")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.1")

    // Куда позже добавим:
    // implementation("com.wireguard.android:tunnel:1.0.20230706") // реальный WireGuard туннель
}

WINKVPN_EOF

cat > "app/src/main/AndroidManifest.xml" << 'WINKVPN_EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <application
        android:allowBackup="true"
        android:icon="@drawable/logo_wink"
        android:label="Wink VPN"
        android:roundIcon="@drawable/logo_wink"
        android:theme="@android:style/Theme.Material.Light.NoActionBar"
        android:supportsRtl="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@android:style/Theme.Material.Light.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!--
            Заготовка VPN-сервиса.
            Система Android требует явного объявления сервиса с этим intent-filter,
            чтобы приложение вообще могло запросить право быть VPN-клиентом.
            Реальный туннель (WireGuard/OpenVPN) подключим сюда позже.
        -->
        <service
            android:name=".vpn.WinkVpnService"
            android:permission="android.permission.BIND_VPN_SERVICE"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>

    </application>
</manifest>

WINKVPN_EOF

cat > "app/src/main/res/values/strings.xml" << 'WINKVPN_EOF'
<resources>
    <string name="app_name">Wink VPN</string>
</resources>

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/AppState.kt" << 'WINKVPN_EOF'
package com.winkvpn.app

enum class Screen { SPLASH, WELCOME, TELEGRAM, THANKS, MAIN }

data class VpnServer(
    val flag: String,
    val name: String,
    val ping: String,
    val ipPrefix: String,
    val speed: String
)

val servers = listOf(
    VpnServer("🇩🇪", "Германия", "11 мс", "185.220.10.", "92"),
    VpnServer("🇳🇱", "Нидерланды", "9 мс", "194.165.22.", "105"),
    VpnServer("🇫🇮", "Финляндия", "14 мс", "37.120.48.", "78"),
    VpnServer("🇸🇪", "Швеция", "13 мс", "46.166.18.", "88"),
)

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/MainActivity.kt" << 'WINKVPN_EOF'
package com.winkvpn.app

import android.content.Intent
import android.net.Uri
import android.net.VpnService
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.winkvpn.app.ui.screens.*
import com.winkvpn.app.ui.theme.WinkYellow

class MainActivity : ComponentActivity() {

    // Системный запрос "Разрешить Wink VPN настраивать VPN-соединения".
    // Пока за этим не следует реальное подключение — только UI-состояние (см. MainScreen).
    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { /* результат обработаем, когда подключим настоящий туннель */ }

    private fun requestVpnPermissionIfNeeded() {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            vpnPermissionLauncher.launch(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Surface(modifier = Modifier.fillMaxSize().background(WinkYellow)) {
                var screen by remember { mutableStateOf(Screen.SPLASH) }

                AnimatedContent(
                    targetState = screen,
                    transitionSpec = {
                        (slideInHorizontally(tween(450)) { it / 3 } + fadeIn(tween(450))) togetherWith
                            (slideOutHorizontally(tween(450)) { -it / 3 } + fadeOut(tween(450)))
                    },
                    label = "screenTransition"
                ) { current ->
                    when (current) {
                        Screen.SPLASH -> SplashScreen(onFinished = { screen = Screen.WELCOME })

                        Screen.WELCOME -> WelcomeScreen(
                            onGoogleLogin = {
                                // TODO: интегрировать Google Sign-In SDK
                                screen = Screen.TELEGRAM
                            },
                            onSkip = { screen = Screen.TELEGRAM }
                        )

                        Screen.TELEGRAM -> TelegramScreen(
                            onJoin = {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/Winkvpn_official"))
                                startActivity(intent)
                                screen = Screen.THANKS
                            },
                            onSkip = { screen = Screen.THANKS }
                        )

                        Screen.THANKS -> ThanksScreen(
                            onStart = {
                                requestVpnPermissionIfNeeded()
                                screen = Screen.MAIN
                            }
                        )

                        Screen.MAIN -> MainScreen()
                    }
                }
            }
        }
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/vpn/WinkVpnService.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.vpn

import android.net.VpnService
import android.content.Intent
import android.os.ParcelFileDescriptor

/**
 * ЗАГОТОВКА VPN-СЕРВИСА.
 *
 * Это НЕ рабочий VPN. Здесь только скелет с правильной архитектурой Android VpnService,
 * чтобы приложение уже сейчас могло:
 *  1) корректно запросить у системы разрешение "Разрешить Wink VPN настраивать VPN-соединения"
 *  2) быть точкой, куда позже подключим настоящий туннель (например через WireGuard)
 *
 * Что нужно добавить для реальной работы:
 *  - зависимость com.wireguard.android:tunnel (или свой userspace WireGuard на основе wireguard-go через JNI)
 *  - конфиг сервера (публичный ключ, endpoint, allowed IPs) — обычно приходит с бэкенда после авторизации
 *  - Builder().addAddress(...).addRoute(...).addDnsServer(...).establish() — создание TUN-интерфейса
 *  - цикл чтения/записи пакетов между TUN-интерфейсом и WireGuard-туннелем
 *
 * Сейчас сервис только регистрируется в системе и ничего не подключает по-настоящему —
 * вся "имитация подключения" происходит в UI (MainScreen.kt), как было в HTML-прототипе.
 */
class WinkVpnService : VpnService() {

    private var tunInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO: здесь будет реальная установка туннеля через Builder(), когда подключим WireGuard
        // val builder = Builder()
        //     .addAddress("10.0.0.2", 32)
        //     .addRoute("0.0.0.0", 0)
        //     .addDnsServer("1.1.1.1")
        // tunInterface = builder.establish()

        return START_STICKY
    }

    override fun onDestroy() {
        tunInterface?.close()
        tunInterface = null
        super.onDestroy()
    }

    override fun onRevoke() {
        // Система (или пользователь в настройках) отозвала право на VPN
        tunInterface?.close()
        stopSelf()
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/theme/Theme.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.theme

import androidx.compose.ui.graphics.Color

// Единые цвета бренда — совпадают с HTML-версией
val WinkYellow = Color(0xFFFFDA1A)
val WinkBlack = Color(0xFF111111)
val WinkWhite = Color(0xFFFFFFFF)
val WinkGreen = Color(0xFF16A34A)

val WinkBlack10 = Color(0x1A111111) // rgba(0,0,0,.1)
val WinkBlack07 = Color(0x12111111)
val WinkBlack09 = Color(0x17111111)
val WinkBlack38 = Color(0x61111111)
val WinkBlack50 = Color(0x80111111)

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/Common.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.winkvpn.app.R
import com.winkvpn.app.ui.theme.WinkBlack
import com.winkvpn.app.ui.theme.WinkBlack10
import com.winkvpn.app.ui.theme.WinkWhite

/** Логотип + название "Wink VPN" — переиспользуется на всех экранах онбординга */
@Composable
fun BrandBlock(logoSize: Int = 72, textSize: Int = 26) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Image(
            painter = painterResource(id = R.drawable.logo_wink),
            contentDescription = null,
            modifier = Modifier.height(logoSize.dp)
        )
        Spacer(Modifier.height(10.dp))
        Text(
            "Wink VPN",
            fontSize = textSize.sp,
            fontWeight = FontWeight.Black,
            fontStyle = FontStyle.Italic,
            color = WinkBlack
        )
    }
}

/** Заголовок + подзаголовок по центру */
@Composable
fun ScreenCopy(title: String, subtitle: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(horizontal = 30.dp)
    ) {
        Text(
            title,
            fontSize = 25.sp,
            fontWeight = FontWeight.Black,
            color = WinkBlack,
            textAlign = TextAlign.Center,
            lineHeight = 29.sp
        )
        Spacer(Modifier.height(12.dp))
        Text(
            subtitle,
            fontSize = 14.5.sp,
            fontWeight = FontWeight.Medium,
            color = WinkBlack.copy(alpha = 0.5f),
            textAlign = TextAlign.Center,
            lineHeight = 21.sp
        )
    }
}

/** Основная чёрная кнопка с белым текстом — как на регистрации */
@Composable
fun PrimaryButton(
    text: String,
    modifier: Modifier = Modifier,
    leadingIcon: (@Composable () -> Unit)? = null,
    onClick: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(100.dp))
            .background(WinkBlack)
            .clickable(onClick = onClick)
            .padding(vertical = 18.dp)
    ) {
        leadingIcon?.invoke()
        if (leadingIcon != null) Spacer(Modifier.width(10.dp))
        Text(text, color = WinkWhite, fontSize = 16.sp, fontWeight = FontWeight.Black)
    }
}

/** Второстепенная кнопка "Пропустить" — полупрозрачная */
@Composable
fun GhostButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(100.dp))
            .background(WinkBlack10)
            .clickable(onClick = onClick)
            .padding(vertical = 18.dp)
    ) {
        Text(text, color = WinkBlack, fontSize = 16.sp, fontWeight = FontWeight.Black)
    }
}

/** Точки-индикатор прогресса онбординга (3 экрана) */
@Composable
fun StepDots(activeIndex: Int, total: Int = 3) {
    Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
        repeat(total) { i ->
            Box(
                modifier = Modifier
                    .height(6.dp)
                    .width(if (i == activeIndex) 22.dp else 6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(if (i == activeIndex) WinkBlack else WinkBlack.copy(alpha = 0.2f))
            )
        }
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/BackgroundShapes.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import kotlin.math.sin

/** Плавное floating-покачивание для фоновых декоративных фигур */
@Composable
private fun rememberFloatOffset(periodMs: Int, amplitude: Float): androidx.compose.runtime.State<Float> {
    val transition = rememberInfiniteTransition(label = "float")
    val phase by transition.animateFloat(
        initialValue = 0f,
        targetValue = (2 * Math.PI).toFloat(),
        animationSpec = infiniteRepeatable(tween(periodMs, easing = LinearEasing), RepeatMode.Restart),
        label = "floatPhase"
    )
    return androidx.compose.runtime.remember {
        androidx.compose.runtime.derivedStateOf { sin(phase.toDouble()).toFloat() * amplitude }
    }
}

/** Тонкий контур ключа (моно-линия, как в HTML-версии) */
@Composable
fun KeyIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6500, amplitude = 10f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val strokeWidth = size.width * 0.045f
        val stroke = Stroke(width = strokeWidth, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)

        val ringCenter = Offset(size.width * 0.25f, size.height * 0.5f)
        drawCircle(color, radius = size.width * 0.17f, center = ringCenter, style = stroke)
        drawCircle(color, radius = size.width * 0.06f, center = ringCenter, style = stroke)

        val shaftY = size.height * 0.5f
        drawLine(color, Offset(size.width * 0.41f, shaftY), Offset(size.width * 0.88f, shaftY), strokeWidth, StrokeCap.Round)
        drawLine(color, Offset(size.width * 0.78f, shaftY), Offset(size.width * 0.78f, shaftY + size.height * 0.18f), strokeWidth, StrokeCap.Round)
        drawLine(color, Offset(size.width * 0.67f, shaftY), Offset(size.width * 0.67f, shaftY + size.height * 0.13f), strokeWidth, StrokeCap.Round)
    }
}

/** Тонкий контур подарка с бантом */
@Composable
fun GiftIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 7200, amplitude = 9f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val strokeWidth = size.width * 0.055f
        val stroke = Stroke(width = strokeWidth, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        // коробка
        drawRoundRect(
            color,
            topLeft = Offset(w * 0.15f, h * 0.42f),
            size = androidx.compose.ui.geometry.Size(w * 0.7f, h * 0.48f),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.03f),
            style = stroke
        )
        // крышка (горизонтальная лента)
        drawLine(color, Offset(w * 0.1f, h * 0.325f), Offset(w * 0.9f, h * 0.325f), strokeWidth, StrokeCap.Round)
        // вертикальная лента
        drawLine(color, Offset(w * 0.5f, h * 0.325f), Offset(w * 0.5f, h * 0.9f), strokeWidth, StrokeCap.Round)
        // бант — два лепестка кривыми
        val bowPath = androidx.compose.ui.graphics.Path().apply {
            moveTo(w * 0.35f, h * 0.325f)
            cubicTo(w * 0.2f, h * 0.325f, w * 0.2f, h * 0.15f, w * 0.325f, h * 0.14f)
            cubicTo(w * 0.45f, h * 0.13f, w * 0.5f, h * 0.275f, w * 0.5f, h * 0.325f)
        }
        drawPath(bowPath, color, style = stroke)
        val bowPath2 = androidx.compose.ui.graphics.Path().apply {
            moveTo(w * 0.65f, h * 0.325f)
            cubicTo(w * 0.8f, h * 0.325f, w * 0.8f, h * 0.15f, w * 0.675f, h * 0.14f)
            cubicTo(w * 0.55f, h * 0.13f, w * 0.5f, h * 0.275f, w * 0.5f, h * 0.325f)
        }
        drawPath(bowPath2, color, style = stroke)
    }
}

/** Плавная изгибающаяся стрелка, указывающая вниз (для экрана "Спасибо") */
@Composable
fun CurvedArrow(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(width = widthDp.dp, height = heightDp.dp)) {
        val strokeWidth = size.width * 0.06f
        val stroke = Stroke(width = strokeWidth, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        val path = androidx.compose.ui.graphics.Path().apply {
            moveTo(w * 0.77f, h * 0.055f)
            cubicTo(w * 1.0f, h * 0.28f, w * 0.92f, h * 0.53f, w * 0.58f, h * 0.69f)
            cubicTo(w * 0.365f, h * 0.8f, w * 0.27f, h * 0.83f, w * 0.26f, h * 0.945f)
        }
        drawPath(path, color, style = stroke)

        // наконечник
        val tip = androidx.compose.ui.graphics.Path().apply {
            moveTo(w * 0.17f, h * 0.895f)
            lineTo(w * 0.26f, h * 0.965f)
            lineTo(w * 0.355f, h * 0.888f)
        }
        drawPath(tip, color, style = stroke)
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/SplashScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Text
import com.winkvpn.app.R
import com.winkvpn.app.ui.theme.WinkBlack
import com.winkvpn.app.ui.theme.WinkBlack10
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(onFinished: () -> Unit) {
    var scale by remember { mutableFloatStateOf(0.65f) }
    var alpha by remember { mutableFloatStateOf(0f) }
    var loaderProgress by remember { mutableFloatStateOf(0f) }

    val animScale by animateFloatAsState(
        targetValue = scale,
        animationSpec = spring(dampingRatio = 0.55f, stiffness = 220f),
        label = "splashScale"
    )
    val animAlpha by animateFloatAsState(targetValue = alpha, animationSpec = tween(400), label = "splashAlpha")
    val animLoader by animateFloatAsState(
        targetValue = loaderProgress,
        animationSpec = tween(750, easing = FastOutSlowInEasing),
        label = "loader"
    )

    LaunchedEffect(Unit) {
        scale = 1f
        alpha = 1f
        delay(350)
        loaderProgress = 1f
        delay(750)
        onFinished()
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.graphicsLayer(
                scaleX = animScale, scaleY = animScale, alpha = animAlpha
            )
        ) {
            Image(
                painter = painterResource(id = R.drawable.logo_wink),
                contentDescription = null,
                modifier = Modifier.size(width = 118.dp, height = 110.dp)
            )
            Spacer(Modifier.height(16.dp))
            Text(
                "Wink VPN",
                fontSize = 32.sp,
                fontWeight = FontWeight.Black,
                fontStyle = FontStyle.Italic,
                color = WinkBlack
            )
            Spacer(Modifier.height(34.dp))
            Box(
                modifier = Modifier
                    .width(54.dp)
                    .height(5.dp)
                    .clip(RoundedCornerShape(99.dp))
                    .background(WinkBlack10)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(animLoader)
                        .clip(RoundedCornerShape(99.dp))
                        .background(WinkBlack)
                )
            }
        }
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/WelcomeScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp

@Composable
fun WelcomeScreen(
    onGoogleLogin: () -> Unit,
    onSkip: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Фоновые ключи — тонкие моно-линии, не перекрывают контент
        KeyIcon(
            sizeDp = 260, alpha = 0.09f,
            modifier = Modifier.align(Alignment.TopStart).offset(x = (-70).dp, y = 90.dp)
        )
        KeyIcon(
            sizeDp = 190, alpha = 0.06f,
            modifier = Modifier.align(Alignment.BottomEnd).offset(x = 55.dp, y = (-130).dp)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp, bottom = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                BrandBlock()
                Spacer(Modifier.height(30.dp))
                ScreenCopy(
                    title = "Добро пожаловать\nв Wink VPN!",
                    subtitle = "Вы можете войти в аккаунт, это поможет сохранить ваши бонусы!"
                )
                Spacer(Modifier.height(34.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 28.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    PrimaryButton(
                        text = "Войти через Google",
                        leadingIcon = { GoogleGlyph() },
                        onClick = onGoogleLogin
                    )
                    GhostButton(text = "Пропустить →", onClick = onSkip)
                }
            }
            StepDots(activeIndex = 0)
        }
    }
}

/** Простая монохромная "G" — полноценную многоцветную Google-иконку вставим позже как drawable */
@Composable
private fun GoogleGlyph() {
    Box(
        modifier = Modifier.size(22.dp),
        contentAlignment = Alignment.Center
    ) {
        Text("G", color = Color.White, fontWeight = androidx.compose.ui.text.font.FontWeight.Black)
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/TelegramScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun TelegramScreen(
    onJoin: () -> Unit,
    onSkip: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        GiftIcon(
            sizeDp = 220, alpha = 0.09f,
            modifier = Modifier.align(Alignment.TopEnd).offset(x = 45.dp, y = 75.dp)
        )
        GiftIcon(
            sizeDp = 170, alpha = 0.06f,
            modifier = Modifier.align(Alignment.BottomStart).offset(x = (-40).dp, y = (-110).dp)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp, bottom = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                BrandBlock()
                Spacer(Modifier.height(30.dp))
                ScreenCopy(
                    title = "Присоединяйтесь к нашему Telegram каналу!",
                    subtitle = "Будьте в курсе новостей и получайте секретные промокоды!"
                )
                Spacer(Modifier.height(34.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 28.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    PrimaryButton(
                        text = "Присоединиться",
                        leadingIcon = { TelegramGlyph() },
                        onClick = onJoin
                    )
                    GhostButton(text = "Пропустить →", onClick = onSkip)
                }
            }
            StepDots(activeIndex = 1)
        }
    }
}

@Composable
private fun TelegramGlyph() {
    Box(
        modifier = androidx.compose.ui.Modifier.size(22.dp),
        contentAlignment = Alignment.Center
    ) {
        Text("✈", color = Color.White, fontWeight = FontWeight.Black)
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/ThanksScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun ThanksScreen(onStart: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        CurvedArrow(
            widthDp = 220, heightDp = 300, alpha = 0.12f,
            modifier = Modifier.align(Alignment.BottomCenter).offset(y = (-70).dp)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp, bottom = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                BrandBlock()
                Spacer(Modifier.height(30.dp))
                ScreenCopy(
                    title = "Спасибо, что начали использовать Wink VPN!",
                    subtitle = "Начинай пользоваться уже — жми кнопку!"
                )
                Spacer(Modifier.height(34.dp))
                Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp)) {
                    PrimaryButton(text = "Начать! →", onClick = onStart)
                }
            }
            StepDots(activeIndex = 2)
        }
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/MainScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.winkvpn.app.R
import com.winkvpn.app.VpnServer
import com.winkvpn.app.servers
import com.winkvpn.app.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random

private enum class ConnState { OFF, CONNECTING, ON }

@Composable
fun MainScreen() {
    var connState by remember { mutableStateOf(ConnState.OFF) }
    var serverIdx by remember { mutableIntStateOf(0) }
    var trafficMb by remember { mutableFloatStateOf(0f) }
    var connectingStepText by remember { mutableStateOf("Поиск сервера…") }
    var promoOpen by remember { mutableStateOf(false) }
    var confettiTrigger by remember { mutableIntStateOf(0) }

    val server = servers[serverIdx]
    val scope = rememberCoroutineScope()

    // Счётчик трафика, пока подключено (имитация — как в HTML)
    LaunchedEffect(connState) {
        if (connState == ConnState.ON) {
            trafficMb = 0f
            while (true) {
                delay(1000)
                trafficMb += 0.21f
            }
        }
    }

    fun startConnecting() {
        connState = ConnState.CONNECTING
        scope.launch {
            val steps = listOf("Поиск сервера…", "Шифрование…", "Установка туннеля…")
            for (s in steps) {
                connectingStepText = s
                delay(450)
            }
            connState = ConnState.ON
        }
    }

    fun disconnect() {
        connState = ConnState.OFF
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // фоновые тонкие стрелки
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .offset(x = 10.dp, y = (-20).dp)
        ) {
            CurvedArrow(widthDp = 130, heightDp = 170, alpha = 0.05f)
        }

        Column(modifier = Modifier.fillMaxSize().padding(top = 48.dp)) {

            // Topbar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 26.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Image(
                        painter = painterResource(id = R.drawable.logo_wink),
                        contentDescription = null,
                        modifier = Modifier.height(26.dp)
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        "Wink VPN",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Black,
                        fontStyle = FontStyle.Italic,
                        color = WinkBlack
                    )
                }
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(99.dp))
                        .background(WinkBlack)
                        .clickable { promoOpen = true }
                        .padding(horizontal = 16.dp, vertical = 9.dp)
                ) {
                    Text("Активировать промокод", color = WinkWhite, fontSize = 12.5.sp, fontWeight = FontWeight.Black)
                }
            }

            Spacer(Modifier.height(14.dp))

            // Status pill
            Box(modifier = Modifier.padding(start = 26.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(99.dp))
                        .background(WinkBlack09)
                        .padding(horizontal = 18.dp, vertical = 9.dp)
                ) {
                    val dotColor by animateColorAsState(
                        if (connState == ConnState.ON) WinkGreen else Color(0xFF888888),
                        label = "dotColor"
                    )
                    Box(
                        modifier = Modifier
                            .size(9.dp)
                            .clip(CircleShape)
                            .background(dotColor)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        if (connState == ConnState.ON) "Подключено" else "Не подключено",
                        fontSize = 13.sp, fontWeight = FontWeight.Bold, color = WinkBlack
                    )
                }
            }

            Spacer(Modifier.height(18.dp))

            // Power button
            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                PowerButton(
                    connected = connState == ConnState.ON,
                    connecting = connState == ConnState.CONNECTING,
                    onClick = {
                        when (connState) {
                            ConnState.OFF -> startConnecting()
                            ConnState.ON -> disconnect()
                            ConnState.CONNECTING -> {}
                        }
                    }
                )
            }

            Spacer(Modifier.height(18.dp))

            // Country selector
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 22.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(99.dp))
                        .background(WinkBlack09)
                        .clickable { serverIdx = (serverIdx + 1) % servers.size }
                        .padding(horizontal = 16.dp, vertical = 11.dp)
                ) {
                    Text(server.flag, fontSize = 18.sp)
                    Spacer(Modifier.width(8.dp))
                    Text(server.name, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = WinkBlack, modifier = Modifier.weight(1f))
                    Text("▼", fontSize = 12.sp, color = WinkBlack.copy(alpha = 0.35f))
                }
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .clip(RoundedCornerShape(18.dp))
                        .background(WinkBlack09)
                        .padding(horizontal = 14.dp, vertical = 11.dp)
                ) {
                    Text(
                        if (connState == ConnState.ON) server.speed else "—",
                        fontSize = 15.sp, fontWeight = FontWeight.Black, color = WinkBlack
                    )
                    Text("МБ/С", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = WinkBlack.copy(alpha = 0.35f))
                }
            }

            Spacer(Modifier.height(16.dp))

            // Info cards
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                InfoCard("Пинг", if (connState == ConnState.ON) server.ping else "—", Modifier.weight(1f))
                InfoCard("Трафик", if (connState == ConnState.ON) "${"%.1f".format(trafficMb)} МБ" else "—", Modifier.weight(1f))
                InfoCard("IP", if (connState == ConnState.ON) "${server.ipPrefix}${Random.nextInt(10, 99)}" else "—", Modifier.weight(1f), fontSize = 12)
            }

            Spacer(Modifier.weight(1f))

            // Connect button
            Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 22.dp)) {
                val btnColor by animateColorAsState(
                    if (connState == ConnState.ON) Color(0xFF222222) else WinkBlack,
                    label = "connBtnColor"
                )
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(100.dp))
                        .background(btnColor)
                        .clickable {
                            when (connState) {
                                ConnState.OFF -> startConnecting()
                                ConnState.ON -> disconnect()
                                ConnState.CONNECTING -> {}
                            }
                        }
                        .padding(vertical = 18.dp)
                ) {
                    Text(
                        if (connState == ConnState.ON) "Отключиться" else "Подключиться",
                        color = WinkWhite, fontSize = 16.sp, fontWeight = FontWeight.Black
                    )
                }
            }
        }

        // Connecting overlay
        if (connState == ConnState.CONNECTING) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(WinkYellow.copy(alpha = 0.94f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    SpinnerRing()
                    Spacer(Modifier.height(18.dp))
                    Text("Подключение…", fontSize = 18.sp, fontWeight = FontWeight.Black, color = WinkBlack)
                    Spacer(Modifier.height(4.dp))
                    Text(connectingStepText, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = WinkBlack.copy(alpha = 0.45f))
                }
            }
        }

        // Promo modal
        PromoModal(
            visible = promoOpen,
            onDismiss = { promoOpen = false },
            onSuccess = {
                confettiTrigger++
            }
        )

        // Confetti overlay
        ConfettiOverlay(trigger = confettiTrigger)
    }
}

@Composable
private fun PowerButton(connected: Boolean, connecting: Boolean, onClick: () -> Unit) {
    val infinite = rememberInfiniteTransition(label = "breathe")
    val glowAlpha by infinite.animateFloat(
        initialValue = 0.35f, targetValue = 0.5f,
        animationSpec = infiniteRepeatable(tween(1500, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "glowAlpha"
    )

    val ringOuterColor by animateColorAsState(
        if (connected) WinkGreen.copy(alpha = 0.35f) else WinkBlack.copy(alpha = 0.07f),
        animationSpec = tween(700), label = "ringOuter"
    )
    val ringMidColor by animateColorAsState(
        if (connected) WinkGreen.copy(alpha = 0.4f) else WinkBlack.copy(alpha = 0.1f),
        animationSpec = tween(700), label = "ringMid"
    )

    val spinAnim = remember { Animatable(0f) }
    LaunchedEffect(connecting) {
        if (connecting) {
            spinAnim.snapTo(0f)
            spinAnim.animateTo(360f, animationSpec = tween(500, easing = FastOutSlowInEasing))
        }
    }

    Box(
        modifier = Modifier
            .size(216.dp)
            .border(2.dp, ringOuterColor, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(182.dp)
                .border(2.dp, ringMidColor, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(148.dp)
                    .clip(CircleShape)
                    .background(WinkYellow)
                    .let {
                        if (connected)
                            it.graphicsLayer {
                                shadowElevation = 0f
                            }
                        else it
                    }
                    .clickable(onClick = onClick),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(id = R.drawable.logo_wink),
                    contentDescription = null,
                    modifier = Modifier
                        .height(76.dp)
                        .graphicsLayer {
                            rotationZ = spinAnim.value
                        }
                )
            }
        }
    }
}

@Composable
private fun InfoCard(label: String, value: String, modifier: Modifier = Modifier, fontSize: Int = 16) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(WinkBlack09)
            .padding(horizontal = 13.dp, vertical = 12.dp)
    ) {
        Text(label.uppercase(), fontSize = 10.sp, fontWeight = FontWeight.Black, color = WinkBlack38)
        Spacer(Modifier.height(4.dp))
        Text(value, fontSize = fontSize.sp, fontWeight = FontWeight.Black, color = WinkBlack)
    }
}

@Composable
private fun SpinnerRing() {
    val infinite = rememberInfiniteTransition(label = "spin")
    val rotation by infinite.animateFloat(
        0f, 360f,
        animationSpec = infiniteRepeatable(tween(750, easing = LinearEasing)),
        label = "rot"
    )
    Canvas(modifier = Modifier.size(52.dp).graphicsLayer { rotationZ = rotation }) {
        drawArc(
            color = WinkBlack,
            startAngle = 0f,
            sweepAngle = 90f,
            useCenter = false,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4.dp.toPx(), cap = androidx.compose.ui.graphics.StrokeCap.Round)
        )
        drawArc(
            color = WinkBlack.copy(alpha = 0.12f),
            startAngle = 90f,
            sweepAngle = 270f,
            useCenter = false,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4.dp.toPx(), cap = androidx.compose.ui.graphics.StrokeCap.Round)
        )
    }
}

@Composable
private fun PromoModal(
    visible: Boolean,
    onDismiss: () -> Unit,
    onSuccess: () -> Unit
) {
    if (!visible) return
    var input by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }
    var isError by remember { mutableStateOf(false) }
    var isSuccess by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.45f))
            .clickable(onClick = onDismiss)
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp))
                .background(WinkYellow)
                .clickable(enabled = false) {}
                .padding(horizontal = 26.dp, vertical = 24.dp)
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .width(38.dp).height(4.dp)
                        .clip(RoundedCornerShape(99.dp))
                        .background(WinkBlack.copy(alpha = 0.2f))
                )
                Spacer(Modifier.height(22.dp))
                Text("Активация промокода", fontSize = 21.sp, fontWeight = FontWeight.Black, color = WinkBlack)
                Spacer(Modifier.height(8.dp))
                Text(
                    "Есть промокод? Активируйте ниже!",
                    fontSize = 14.sp, color = WinkBlack.copy(alpha = 0.5f),
                    fontWeight = FontWeight.Medium, textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(22.dp))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(18.dp))
                        .background(WinkBlack.copy(alpha = 0.08f))
                        .padding(horizontal = 18.dp, vertical = 16.dp)
                ) {
                    if (input.isEmpty()) {
                        Text(
                            "Введите промокод",
                            color = WinkBlack.copy(alpha = 0.3f),
                            fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center
                        )
                    }
                    BasicTextField(
                        value = input,
                        onValueChange = { input = it.uppercase() },
                        singleLine = true,
                        textStyle = TextStyle(
                            color = WinkBlack, fontSize = 16.sp, fontWeight = FontWeight.Black,
                            textAlign = TextAlign.Center
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                Spacer(Modifier.height(10.dp))
                if (message.isNotEmpty()) {
                    Text(
                        message,
                        fontSize = 13.sp, fontWeight = FontWeight.Bold,
                        color = if (isError) Color(0xFFC62828) else Color(0xFF1B8A3D)
                    )
                    Spacer(Modifier.height(6.dp))
                }

                PrimaryButton(text = "Активировать") {
                    if (input.trim().equals("test", ignoreCase = true)) {
                        message = "Промокод активирован! 🎉"
                        isError = false
                        isSuccess = true
                        onSuccess()
                        scope.launch {
                            delay(1400)
                            onDismiss()
                        }
                    } else {
                        message = "Такой промокод не найден"
                        isError = true
                    }
                }

                Spacer(Modifier.height(20.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        "Новый промокод уже в нашем Telegram  ",
                        fontSize = 12.5.sp, color = WinkBlack.copy(alpha = 0.55f), fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        "Перейти",
                        fontSize = 12.5.sp, color = WinkBlack, fontWeight = FontWeight.Black
                    )
                }
            }
        }
    }
}

private data class ConfettiPiece(
    val startX: Float,
    val color: Color,
    val delayMs: Int,
    val durationMs: Int,
    val rotationStart: Float,
    val isCircle: Boolean
)

@Composable
private fun ConfettiOverlay(trigger: Int) {
    if (trigger == 0) return
    var pieces by remember(trigger) {
        mutableStateOf(
            List(60) {
                ConfettiPiece(
                    startX = Random.nextFloat(),
                    color = listOf(WinkBlack, WinkYellow, WinkWhite, Color(0xFF333333)).random(),
                    delayMs = Random.nextInt(0, 400),
                    durationMs = Random.nextInt(2000, 3200),
                    rotationStart = Random.nextFloat() * 360f,
                    isCircle = Random.nextBoolean()
                )
            }
        )
    }
    var active by remember(trigger) { mutableStateOf(true) }
    LaunchedEffect(trigger) {
        active = true
        delay(3600)
        active = false
    }
    if (!active) return

    val density = LocalDensity.current
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val heightPx = with(density) { maxHeight.toPx() }
        pieces.forEach { piece ->
            key(piece) {
                val progress = remember { Animatable(0f) }
                LaunchedEffect(piece) {
                    delay(piece.delayMs.toLong())
                    progress.animateTo(1f, animationSpec = tween(piece.durationMs, easing = LinearEasing))
                }
                val yOffsetPx = progress.value * heightPx
                val alpha = 1f - progress.value
                val rotation = piece.rotationStart + progress.value * 540f

                Box(
                    modifier = Modifier
                        .offset {
                            androidx.compose.ui.unit.IntOffset(
                                x = (piece.startX * (with(density) { maxWidth.toPx() })).toInt(),
                                y = yOffsetPx.toInt() - with(density) { 20.dp.toPx() }.toInt()
                            )
                        }
                        .size(width = 9.dp, height = 14.dp)
                        .graphicsLayer {
                            this.alpha = alpha.coerceIn(0f, 1f)
                            rotationZ = rotation
                        }
                        .clip(if (piece.isCircle) CircleShape else RoundedCornerShape(2.dp))
                        .background(piece.color)
                )
            }
        }
    }
}

WINKVPN_EOF

cat > "README.md" << 'WINKVPN_EOF'
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

WINKVPN_EOF

cat > "app/src/main/res/drawable/logo_wink.png.b64" << 'WINKVPN_EOF'
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
WINKVPN_EOF
base64 -d "app/src/main/res/drawable/logo_wink.png.b64" > "app/src/main/res/drawable/logo_wink.png"
rm "app/src/main/res/drawable/logo_wink.png.b64"

echo "Готово! Все файлы созданы."
echo "Дальше: git add -A && git commit -m 'init' && git push"