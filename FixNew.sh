#!/usr/bin/env bash
# Wink VPN — глобальный патч: новый сплэш с подмигиванием, чище фоновые иконки,
# кольцо кнопки VPN одной полоской, кнопка Подключиться выше, нормальная иконка Telegram,
# без стрелок в кнопках, ожидание возврата из Telegram + новый экран благодарности,
# без белой вспышки при запуске.
set -e
echo "Обновляю файлы..."

mkdir -p "app/src/main"
mkdir -p "app/src/main/java/com/winkvpn/app"
mkdir -p "app/src/main/java/com/winkvpn/app/ui/screens"
mkdir -p "app/src/main/res/values"

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
        android:theme="@style/Theme.WinkVpn"
        android:supportsRtl="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.WinkVpn">
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

cat > "app/src/main/res/values/colors.xml" << 'WINKVPN_EOF'
<resources>
    <color name="wink_yellow">#FFFFDA1A</color>
</resources>

WINKVPN_EOF

cat > "app/src/main/res/values/themes.xml" << 'WINKVPN_EOF'
<resources>
    <style name="Theme.WinkVpn" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/wink_yellow</item>
        <item name="android:colorBackground">@color/wink_yellow</item>
        <item name="android:windowDisablePreview">false</item>
    </style>
</resources>

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/AppState.kt" << 'WINKVPN_EOF'
package com.winkvpn.app

enum class Screen { SPLASH, WELCOME, TELEGRAM, TELEGRAM_THANKS, THANKS, MAIN }

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
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
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
            Surface(modifier = Modifier.fillMaxSize(), color = WinkYellow) {
                var screen by remember { mutableStateOf(Screen.SPLASH) }

                // Ждём ли мы возвращения пользователя из внешнего Telegram-приложения/браузера
                var waitingForTelegramReturn by remember { mutableStateOf(false) }
                var hasPausedSinceWaiting by remember { mutableStateOf(false) }

                val lifecycleOwner = LocalLifecycleOwner.current
                DisposableEffect(waitingForTelegramReturn) {
                    if (!waitingForTelegramReturn) return@DisposableEffect onDispose {}
                    hasPausedSinceWaiting = false
                    val observer = LifecycleEventObserver { _, event ->
                        when (event) {
                            Lifecycle.Event.ON_PAUSE -> hasPausedSinceWaiting = true
                            Lifecycle.Event.ON_RESUME -> {
                                if (hasPausedSinceWaiting) {
                                    waitingForTelegramReturn = false
                                    screen = Screen.TELEGRAM_THANKS
                                }
                            }
                            else -> {}
                        }
                    }
                    lifecycleOwner.lifecycle.addObserver(observer)
                    onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
                }

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
                            isWaitingForReturn = waitingForTelegramReturn,
                            onJoin = {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/Winkvpn_official"))
                                startActivity(intent)
                                waitingForTelegramReturn = true
                            },
                            onSkip = { screen = Screen.THANKS }
                        )

                        Screen.TELEGRAM_THANKS -> TelegramThanksScreen(
                            onContinue = { screen = Screen.THANKS }
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
        if (subtitle.isNotBlank()) {
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

cat > "app/src/main/java/com/winkvpn/app/ui/screens/SplashScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Text
import com.winkvpn.app.ui.theme.WinkBlack
import kotlinx.coroutines.launch

/**
 * Сплэш-экран: логотип на весь экран, лёгкий наезд камерой, подмигивание глаза,
 * затем смайлик исчезает и звёздочка "улетает" влево-по-центру, а следом,
 * двигаясь слева направо, появляется текст "Wink VPN".
 */
@Composable
fun SplashScreen(onFinished: () -> Unit) {
    // Общий масштаб всего лого при появлении
    val logoScale = remember { Animatable(0.82f) }
    // Прозрачность "лица" (глаз + рот) — то, что исчезнет после подмигивания
    val faceAlpha = remember { Animatable(1f) }
    // Вертикальное сжатие глаза для эффекта подмигивания
    val eyeScaleY = remember { Animatable(1f) }
    // Позиция звезды: 0 = исходное место у "чек-галочки", 1 = финальная позиция по центру
    val starProgress = remember { Animatable(0f) }
    // Второй проход — звезда едет чуть правее, текст догоняет её
    val starSlide = remember { Animatable(0f) }
    val textAlpha = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        // 1. Лёгкий наезд камерой
        logoScale.animateTo(1.05f, tween(420, easing = FastOutSlowInEasing))
        logoScale.animateTo(1f, tween(180, easing = FastOutSlowInEasing))

        // 2. Подмигивание — глаз быстро сжимается и разжимается
        eyeScaleY.animateTo(0.1f, tween(90, easing = FastOutSlowInEasing))
        eyeScaleY.animateTo(1f, tween(160, easing = FastOutSlowInEasing))

        // небольшая пауза, чтобы подмигивание "прочиталось"
        kotlinx.coroutines.delay(200)

        // 3. Лицо (глаз + рот) плавно исчезает, звезда остаётся
        faceAlpha.animateTo(0f, tween(380, easing = FastOutSlowInEasing))

        // 4. Звезда едет к центру
        starProgress.animateTo(1f, tween(420, easing = FastOutSlowInEasing))

        kotlinx.coroutines.delay(60)

        // 5. Звезда едет дальше слева направо, следом проявляется текст "Wink VPN"
        launch { starSlide.animateTo(1f, tween(650, easing = LinearOutSlowInEasing)) }
        launch {
            kotlinx.coroutines.delay(120)
            textAlpha.animateTo(1f, tween(500, easing = FastOutSlowInEasing))
        }

        kotlinx.coroutines.delay(900)
        onFinished()
    }

    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {

        // ── Лицо: глаз + рот + чек-галочка (исчезают после подмигивания) ──
        Box(
            modifier = Modifier
                .size(280.dp)
                .graphicsLayer {
                    scaleX = logoScale.value
                    scaleY = logoScale.value
                    alpha = faceAlpha.value
                },
            contentAlignment = Alignment.Center
        ) {
            // Рот + чек-галочка одним Canvas
            Canvas(modifier = Modifier.fillMaxSize()) {
                val w = size.width
                val h = size.height
                val black = WinkBlack

                // рот — широкий полумесяц снизу
                val mouth = Path().apply {
                    moveTo(w * 0.20f, h * 0.66f)
                    lineTo(w * 0.86f, h * 0.50f)
                    cubicTo(w * 0.90f, h * 0.72f, w * 0.72f, h * 0.92f, w * 0.50f, h * 0.90f)
                    cubicTo(w * 0.33f, h * 0.89f, w * 0.21f, h * 0.78f, w * 0.20f, h * 0.66f)
                    close()
                }
                drawPath(mouth, black)

                // чек-галочка сверху справа
                val checkStroke = androidx.compose.ui.graphics.drawscope.Stroke(
                    width = w * 0.055f,
                    cap = androidx.compose.ui.graphics.StrokeCap.Round,
                    join = androidx.compose.ui.graphics.StrokeJoin.Round
                )
                val check = Path().apply {
                    moveTo(w * 0.56f, h * 0.20f)
                    cubicTo(w * 0.72f, h * 0.24f, w * 0.80f, h * 0.34f, w * 0.76f, h * 0.46f)
                    lineTo(w * 0.62f, h * 0.42f)
                }
                drawPath(check, black, style = checkStroke)
            }

            // Глаз — отдельный Canvas, чтобы независимо анимировать вертикальное сжатие (моргание)
            Canvas(
                modifier = Modifier
                    .size(width = 70.dp, height = 118.dp)
                    .offset(x = (-58).dp, y = (-18).dp)
                    .graphicsLayer { scaleY = eyeScaleY.value }
            ) {
                drawOval(
                    color = WinkBlack,
                    topLeft = Offset.Zero,
                    size = this.size
                )
            }
        }

        // ── Звезда — не исчезает, а "путешествует" по экрану ──
        val starOffsetX = (-30).dp + (30.dp) * starProgress.value + (140.dp) * starSlide.value
        val starOffsetY = 26.dp - (26.dp) * starProgress.value
        Canvas(
            modifier = Modifier
                .size(30.dp)
                .offset(x = starOffsetX, y = starOffsetY)
        ) {
            drawPath(fivePointedStar(size.width, size.height), WinkBlack)
        }

        // ── Текст "Wink VPN", проявляется и "догоняет" звезду ──
        Box(
            modifier = Modifier.offset(x = (166.dp) * starSlide.value)
        ) {
            Text(
                "Wink VPN",
                fontSize = 34.sp,
                fontWeight = FontWeight.Black,
                fontStyle = FontStyle.Italic,
                color = WinkBlack.copy(alpha = textAlpha.value)
            )
        }
    }
}

private fun fivePointedStar(w: Float, h: Float): Path {
    val cx = w / 2f
    val cy = h / 2f
    val outerR = w / 2f
    val innerR = outerR * 0.42f
    val path = Path()
    for (i in 0 until 10) {
        val angle = Math.PI / 5 * i - Math.PI / 2
        val r = if (i % 2 == 0) outerR else innerR
        val x = cx + (r * kotlin.math.cos(angle)).toFloat()
        val y = cy + (r * kotlin.math.sin(angle)).toFloat()
        if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
    }
    path.close()
    return path
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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
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

/**
 * Ключ — простой, чистый силуэт одной толщины линии: кольцо + прямой стержень + один зубец.
 * Минимум деталей — так аккуратнее смотрится мелким и полупрозрачным на фоне.
 */
@Composable
fun KeyIcon(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6500, amplitude = 10f)
    Canvas(
        modifier = modifier
            .size(width = widthDp.dp, height = heightDp.dp)
            .offset(y = dy.dp)
    ) {
        val sw = size.height * 0.1f
        val color = Color.Black.copy(alpha = alpha)
        val stroke = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round)

        val ringCenter = Offset(size.width * 0.24f, size.height * 0.5f)
        val ringRadius = size.height * 0.38f
        drawCircle(color, radius = ringRadius, center = ringCenter, style = stroke)

        val shaftStartX = ringCenter.x + ringRadius * 0.72f
        val shaftY = size.height * 0.5f
        drawLine(color, Offset(shaftStartX, shaftY), Offset(size.width * 0.92f, shaftY), sw, StrokeCap.Round)
        drawLine(color, Offset(size.width * 0.78f, shaftY), Offset(size.width * 0.78f, shaftY + size.height * 0.3f), sw, StrokeCap.Round)
    }
}

/**
 * Подарок — упрощённый: коробка + крест-лента + один аккуратный бант сверху.
 */
@Composable
fun GiftIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 7200, amplitude = 9f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val sw = size.width * 0.045f
        val stroke = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        drawRoundRect(
            color,
            topLeft = Offset(w * 0.17f, h * 0.44f),
            size = androidx.compose.ui.geometry.Size(w * 0.66f, h * 0.44f),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.035f),
            style = stroke
        )
        drawLine(color, Offset(w * 0.12f, h * 0.36f), Offset(w * 0.88f, h * 0.36f), sw, StrokeCap.Round)
        drawLine(color, Offset(w * 0.5f, h * 0.36f), Offset(w * 0.5f, h * 0.88f), sw, StrokeCap.Round)

        val bow = Path().apply {
            moveTo(w * 0.5f, h * 0.36f)
            cubicTo(w * 0.5f, h * 0.2f, w * 0.34f, h * 0.14f, w * 0.32f, h * 0.24f)
            cubicTo(w * 0.3f, h * 0.34f, w * 0.42f, h * 0.36f, w * 0.5f, h * 0.36f)
            cubicTo(w * 0.58f, h * 0.36f, w * 0.7f, h * 0.34f, w * 0.68f, h * 0.24f)
            cubicTo(w * 0.66f, h * 0.14f, w * 0.5f, h * 0.2f, w * 0.5f, h * 0.36f)
            close()
        }
        drawPath(bow, color, style = stroke)
    }
}

/** Плавная изгибающаяся стрелка (используется только на фоне, не в кнопках) */
@Composable
fun CurvedArrow(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(width = widthDp.dp, height = heightDp.dp)) {
        val sw = size.width * 0.06f
        val stroke = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        val path = Path().apply {
            moveTo(w * 0.77f, h * 0.055f)
            cubicTo(w * 1.0f, h * 0.28f, w * 0.92f, h * 0.53f, w * 0.58f, h * 0.69f)
            cubicTo(w * 0.365f, h * 0.8f, w * 0.27f, h * 0.83f, w * 0.26f, h * 0.945f)
        }
        drawPath(path, color, style = stroke)

        val tip = Path().apply {
            moveTo(w * 0.17f, h * 0.895f)
            lineTo(w * 0.26f, h * 0.965f)
            lineTo(w * 0.355f, h * 0.888f)
        }
        drawPath(tip, color, style = stroke)
    }
}

/** Чистая векторная иконка Telegram — сплошной силуэт бумажного самолётика, без лишних деталей */
@Composable
fun TelegramPaperPlaneIcon(sizeDp: Int = 22, tint: Color = Color.White, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(sizeDp.dp)) {
        val w = size.width
        val h = size.height
        val plane = Path().apply {
            moveTo(w * 0.06f, h * 0.52f)
            lineTo(w * 0.94f, h * 0.10f)
            lineTo(w * 0.62f, h * 0.92f)
            lineTo(w * 0.47f, h * 0.60f)
            close()
        }
        drawPath(plane, tint)
    }
}

/**
 * Декоративная "праздничная" иконка (в духе 🎉) для экрана благодарности за подписку —
 * тот же чистый монолинейный чёрный стиль, что и у ключа/подарка.
 */
@Composable
fun PartyIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6800, amplitude = 8f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val sw = size.width * 0.045f
        val stroke = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        // конус хлопушки
        val cone = Path().apply {
            moveTo(w * 0.12f, h * 0.9f)
            lineTo(w * 0.42f, h * 0.42f)
            lineTo(w * 0.68f, h * 0.6f)
            close()
        }
        drawPath(cone, color, style = stroke)

        // разлетающиеся конфетти-штрихи
        drawLine(color, Offset(w * 0.62f, h * 0.32f), Offset(w * 0.78f, h * 0.18f), sw, StrokeCap.Round)
        drawLine(color, Offset(w * 0.78f, h * 0.5f), Offset(w * 0.97f, h * 0.42f), sw, StrokeCap.Round)
        drawLine(color, Offset(w * 0.68f, h * 0.68f), Offset(w * 0.86f, h * 0.74f), sw, StrokeCap.Round)
        drawCircle(color, radius = w * 0.025f, center = Offset(w * 0.88f, h * 0.24f))
        drawCircle(color, radius = w * 0.02f, center = Offset(w * 0.55f, h * 0.14f))
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
            widthDp = 280, heightDp = 175, alpha = 0.09f,
            modifier = Modifier.align(Alignment.TopStart).offset(x = (-70).dp, y = 90.dp)
        )
        KeyIcon(
            widthDp = 210, heightDp = 131, alpha = 0.06f,
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
                    GhostButton(text = "Пропустить", onClick = onSkip)
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

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.winkvpn.app.ui.theme.WinkBlack
import com.winkvpn.app.ui.theme.WinkYellow

@Composable
fun TelegramScreen(
    isWaitingForReturn: Boolean,
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
                        leadingIcon = { TelegramPaperPlaneIcon(sizeDp = 20) },
                        onClick = onJoin
                    )
                    GhostButton(text = "Пропустить", onClick = onSkip)
                }
            }
            StepDots(activeIndex = 1)
        }

        // Модалка ожидания возврата из Telegram
        if (isWaitingForReturn) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.35f)),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .padding(horizontal = 40.dp)
                        .background(WinkYellow, shape = androidx.compose.foundation.shape.RoundedCornerShape(24.dp))
                        .padding(horizontal = 28.dp, vertical = 26.dp)
                ) {
                    Text(
                        "Перенаправление, ожидаем возвращения!",
                        color = WinkBlack,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Black,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/TelegramThanksScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun TelegramThanksScreen(onContinue: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        PartyIcon(
            sizeDp = 200, alpha = 0.09f,
            modifier = Modifier.align(Alignment.TopEnd).offset(x = 40.dp, y = 80.dp)
        )
        PartyIcon(
            sizeDp = 150, alpha = 0.06f,
            modifier = Modifier.align(Alignment.BottomStart).offset(x = (-30).dp, y = (-100).dp)
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
                    title = "Спасибо за присоединение! Давайте продолжим",
                    subtitle = ""
                )
                Spacer(Modifier.height(34.dp))
                Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp)) {
                    PrimaryButton(text = "Продолжить", onClick = onContinue)
                }
            }
        }
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
                    PrimaryButton(text = "Начать!", onClick = onStart)
                }
            }
            StepDots(activeIndex = 2)
        }
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/MainScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
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
    val context = androidx.compose.ui.platform.LocalContext.current

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
            Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(top = 22.dp, bottom = 42.dp)) {
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
            },
            onOpenTelegram = {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/Winkvpn_official"))
                context.startActivity(intent)
            }
        )

        // Confetti overlay
        ConfettiOverlay(trigger = confettiTrigger)
    }
}

@Composable
private fun PowerButton(connected: Boolean, connecting: Boolean, onClick: () -> Unit) {
    val ringColor by animateColorAsState(
        if (connected) WinkGreen else WinkBlack,
        animationSpec = tween(650), label = "ringColor"
    )

    val infinite = rememberInfiniteTransition(label = "glow")
    val glowPulse by infinite.animateFloat(
        initialValue = 0.14f, targetValue = 0.24f,
        animationSpec = infiniteRepeatable(tween(1600, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "glowPulse"
    )

    val spinAnim = remember { Animatable(0f) }
    LaunchedEffect(connecting) {
        if (connecting) {
            spinAnim.snapTo(0f)
            spinAnim.animateTo(360f, animationSpec = tween(500, easing = FastOutSlowInEasing))
        }
    }

    Box(
        modifier = Modifier.size(196.dp),
        contentAlignment = Alignment.Center
    ) {
        // мягкое зелёное свечение позади кольца, видно только при подключении
        if (connected) {
            Box(
                modifier = Modifier
                    .size(196.dp)
                    .clip(CircleShape)
                    .background(WinkGreen.copy(alpha = glowPulse))
            )
        }

        // единственное кольцо — просто чёрная полоска, зелёная при подключении
        Box(
            modifier = Modifier
                .size(168.dp)
                .border(width = 6.dp, color = ringColor, shape = CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(148.dp)
                    .clip(CircleShape)
                    .background(WinkYellow)
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
    onSuccess: () -> Unit,
    onOpenTelegram: () -> Unit
) {
    if (!visible) return
    var input by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }
    var isError by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.45f))
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = onDismiss
            )
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp))
                .background(WinkYellow)
                .clickable(
                    indication = null,
                    interactionSource = remember { MutableInteractionSource() },
                    onClick = {} // перехватывает тап, чтобы не закрывать модалку при клике внутри
                )
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

                TextField(
                    value = input,
                    onValueChange = { input = it.uppercase() },
                    singleLine = true,
                    placeholder = {
                        Text(
                            "Введите промокод",
                            color = WinkBlack.copy(alpha = 0.3f),
                            fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center
                        )
                    },
                    textStyle = TextStyle(
                        color = WinkBlack, fontSize = 16.sp, fontWeight = FontWeight.Black,
                        textAlign = TextAlign.Center
                    ),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = WinkBlack.copy(alpha = 0.08f),
                        unfocusedContainerColor = WinkBlack.copy(alpha = 0.08f),
                        disabledContainerColor = WinkBlack.copy(alpha = 0.08f),
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        disabledIndicatorColor = Color.Transparent,
                        cursorColor = WinkBlack
                    ),
                    shape = RoundedCornerShape(18.dp),
                    modifier = Modifier.fillMaxWidth()
                )

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
                        fontSize = 12.5.sp, color = WinkBlack, fontWeight = FontWeight.Black,
                        modifier = Modifier.clickable(
                            indication = null,
                            interactionSource = remember { MutableInteractionSource() },
                            onClick = onOpenTelegram
                        )
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

echo "Готово! Все файлы обновлены."
echo "Дальше: git add -A && git commit -m global_fix && git push"