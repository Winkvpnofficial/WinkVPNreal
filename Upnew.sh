#!/usr/bin/env bash
# Wink VPN — Upnew.sh: премиальные серые фоновые иконки (ключ/подарок/стрелка/конфетти),
# эффект печатной машинки для текста на сплэше с фиксированной позицией звезды,
# плавные fade/slide-анимации открытия модалок (промокод, ожидание Telegram, подключение).
set -e
echo "Обновляю файлы..."

mkdir -p "app/src/main/java/com/winkvpn/app/ui/screens"

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
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import kotlin.math.sin

/** Базовый "дизайнерский" серый — настоящий серый тон, а не чёрный поверх жёлтого
 * (иначе на жёлтом фоне он читается как грязно-оливковый, а не серый). */
private val DesignGrey = Color(0xFF4A4A4A)

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
 * Ключ — премиальный силуэт: увесистое кольцо + гранёный стержень с тремя зубцами
 * разной длины (как у настоящего ключа). Лёгкая вариация прозрачности между
 * кольцом и стержнем создаёт ощущение глубины, а не плоского пятна.
 */
@Composable
fun KeyIcon(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6500, amplitude = 10f)
    Canvas(
        modifier = modifier
            .size(width = widthDp.dp, height = heightDp.dp)
            .offset(y = dy.dp)
    ) {
        val w = size.width
        val h = size.height

        val ringOuterR = h * 0.42f
        val ringInnerR = h * 0.24f
        val ringCenter = Offset(w * 0.25f, h * 0.5f)

        val ring = Path().apply {
            fillType = PathFillType.EvenOdd
            addOval(Rect(center = ringCenter, radius = ringOuterR))
            addOval(Rect(center = ringCenter, radius = ringInnerR))
        }
        drawPath(ring, DesignGrey.copy(alpha = alpha * 0.9f))

        val shaftTop = h * 0.5f - h * 0.085f
        val shaftBottom = h * 0.5f + h * 0.085f
        val shaft = Path().apply {
            moveTo(ringCenter.x + ringOuterR * 0.58f, shaftTop)
            lineTo(w * 0.94f, shaftTop)
            // три зубца разной длины
            lineTo(w * 0.94f, h * 0.5f + h * 0.36f)
            lineTo(w * 0.845f, h * 0.5f + h * 0.36f)
            lineTo(w * 0.845f, shaftBottom)
            lineTo(w * 0.72f, shaftBottom)
            lineTo(w * 0.72f, h * 0.5f + h * 0.24f)
            lineTo(w * 0.655f, h * 0.5f + h * 0.24f)
            lineTo(w * 0.655f, shaftBottom)
            lineTo(ringCenter.x + ringOuterR * 0.58f, shaftBottom)
            close()
        }
        drawPath(shaft, DesignGrey.copy(alpha = (alpha * 1.1f).coerceAtMost(1f)))
    }
}

/**
 * Подарок — премиальная версия: объёмная коробка с чёткой крышкой, аккуратная
 * лента крест-накрест и пышный бант из двух лепестков + узел по центру.
 * Разные уровни прозрачности между слоями дают эффект лёгкого объёма.
 */
@Composable
fun GiftIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 7200, amplitude = 9f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        drawGiftSilhouette(this, alpha)
    }
}

/** Маленькая версия подарка сплошным цветом — для кнопки "Активировать промокод" */
@Composable
fun GiftGlyph(sizeDp: Int = 22, tint: Color = Color.Black, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(sizeDp.dp)) {
        drawGiftGlyphSolid(this, tint)
    }
}

private fun drawGiftSilhouette(scope: DrawScope, alpha: Float) {
    with(scope) {
        val w = size.width
        val h = size.height
        val ribbonW = w * 0.15f

        val box = Path().apply {
            fillType = PathFillType.EvenOdd
            addRoundRect(
                RoundRect(
                    left = w * 0.13f, top = h * 0.43f, right = w * 0.87f, bottom = h * 0.93f,
                    cornerRadius = CornerRadius(w * 0.045f)
                )
            )
            addRect(Rect(left = w * 0.5f - ribbonW / 2, top = h * 0.43f, right = w * 0.5f + ribbonW / 2, bottom = h * 0.93f))
        }
        drawPath(box, DesignGrey.copy(alpha = alpha * 0.85f))

        val lid = Path().apply {
            addRoundRect(
                RoundRect(
                    left = w * 0.06f, top = h * 0.32f, right = w * 0.94f, bottom = h * 0.45f,
                    cornerRadius = CornerRadius(w * 0.03f)
                )
            )
        }
        drawPath(lid, DesignGrey.copy(alpha = (alpha * 1.05f).coerceAtMost(1f)))

        val leftPetal = Path().apply {
            moveTo(w * 0.5f, h * 0.35f)
            cubicTo(w * 0.5f, h * 0.14f, w * 0.24f, h * 0.04f, w * 0.19f, h * 0.19f)
            cubicTo(w * 0.15f, h * 0.31f, w * 0.34f, h * 0.35f, w * 0.5f, h * 0.35f)
            close()
        }
        drawPath(leftPetal, DesignGrey.copy(alpha = (alpha * 1.15f).coerceAtMost(1f)))
        val rightPetal = Path().apply {
            moveTo(w * 0.5f, h * 0.35f)
            cubicTo(w * 0.5f, h * 0.14f, w * 0.76f, h * 0.04f, w * 0.81f, h * 0.19f)
            cubicTo(w * 0.85f, h * 0.31f, w * 0.66f, h * 0.35f, w * 0.5f, h * 0.35f)
            close()
        }
        drawPath(rightPetal, DesignGrey.copy(alpha = (alpha * 1.15f).coerceAtMost(1f)))

        drawCircle(DesignGrey.copy(alpha = alpha), radius = w * 0.045f, center = Offset(w * 0.5f, h * 0.35f))
    }
}

private fun drawGiftGlyphSolid(scope: DrawScope, tint: Color) {
    with(scope) {
        val w = size.width
        val h = size.height
        val ribbonW = w * 0.16f

        val box = Path().apply {
            fillType = PathFillType.EvenOdd
            addRoundRect(
                RoundRect(
                    left = w * 0.14f, top = h * 0.42f, right = w * 0.86f, bottom = h * 0.92f,
                    cornerRadius = CornerRadius(w * 0.04f)
                )
            )
            addRect(Rect(left = w * 0.5f - ribbonW / 2, top = h * 0.42f, right = w * 0.5f + ribbonW / 2, bottom = h * 0.92f))
        }
        drawPath(box, tint)

        val lid = Path().apply {
            addRoundRect(
                RoundRect(
                    left = w * 0.08f, top = h * 0.32f, right = w * 0.92f, bottom = h * 0.44f,
                    cornerRadius = CornerRadius(w * 0.025f)
                )
            )
        }
        drawPath(lid, tint)

        val leftPetal = Path().apply {
            moveTo(w * 0.5f, h * 0.34f)
            cubicTo(w * 0.5f, h * 0.18f, w * 0.28f, h * 0.1f, w * 0.24f, h * 0.22f)
            cubicTo(w * 0.21f, h * 0.32f, w * 0.36f, h * 0.34f, w * 0.5f, h * 0.34f)
            close()
        }
        drawPath(leftPetal, tint)
        val rightPetal = Path().apply {
            moveTo(w * 0.5f, h * 0.34f)
            cubicTo(w * 0.5f, h * 0.18f, w * 0.72f, h * 0.1f, w * 0.76f, h * 0.22f)
            cubicTo(w * 0.79f, h * 0.32f, w * 0.64f, h * 0.34f, w * 0.5f, h * 0.34f)
            close()
        }
        drawPath(rightPetal, tint)
    }
}

/** Плавная изгибающаяся стрелка — увесистее и заметнее прежней версии */
@Composable
fun CurvedArrow(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(width = widthDp.dp, height = heightDp.dp)) {
        val sw = size.width * 0.075f
        val stroke = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = DesignGrey.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        val path = Path().apply {
            moveTo(w * 0.77f, h * 0.055f)
            cubicTo(w * 1.0f, h * 0.28f, w * 0.92f, h * 0.53f, w * 0.58f, h * 0.69f)
            cubicTo(w * 0.365f, h * 0.8f, w * 0.27f, h * 0.83f, w * 0.26f, h * 0.945f)
        }
        drawPath(path, color, style = stroke)

        val tip = Path().apply {
            moveTo(w * 0.15f, h * 0.885f)
            lineTo(w * 0.26f, h * 0.97f)
            lineTo(w * 0.37f, h * 0.878f)
        }
        drawPath(tip, color, style = stroke)
    }
}

/** Чистая векторная иконка Telegram — сплошной силуэт бумажного самолётика */
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

/** Иконка наушников (поддержка) — сплошной силуэт */
@Composable
fun HeadsetGlyph(sizeDp: Int = 22, tint: Color = Color.Black, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(sizeDp.dp)) {
        val w = size.width
        val h = size.height
        val sw = w * 0.14f

        val headband = Path().apply {
            addArc(Rect(w * 0.12f, h * 0.05f, w * 0.88f, h * 0.85f), startAngleDegrees = 180f, sweepAngleDegrees = 180f)
        }
        drawPath(headband, tint, style = Stroke(width = sw, cap = StrokeCap.Round))

        drawRoundRect(
            tint,
            topLeft = Offset(w * 0.06f, h * 0.55f),
            size = Size(w * 0.22f, h * 0.38f),
            cornerRadius = CornerRadius(w * 0.09f)
        )
        drawRoundRect(
            tint,
            topLeft = Offset(w * 0.72f, h * 0.55f),
            size = Size(w * 0.22f, h * 0.38f),
            cornerRadius = CornerRadius(w * 0.09f)
        )
    }
}

/**
 * "Праздничная" декоративная иконка (в духе 🎉) — плотный конус-хлопушка
 * с разлетающимися конфетти разного размера, для более богатого рисунка.
 */
@Composable
fun PartyIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6800, amplitude = 8f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val w = size.width
        val h = size.height
        val color = DesignGrey.copy(alpha = alpha)

        val cone = Path().apply {
            moveTo(w * 0.09f, h * 0.94f)
            lineTo(w * 0.46f, h * 0.38f)
            lineTo(w * 0.72f, h * 0.64f)
            close()
        }
        drawPath(cone, color.copy(alpha = (alpha * 1.05f).coerceAtMost(1f)))

        val sw = w * 0.05f
        val cap = StrokeCap.Round
        drawLine(color, Offset(w * 0.60f, h * 0.28f), Offset(w * 0.80f, h * 0.12f), sw, cap)
        drawLine(color, Offset(w * 0.80f, h * 0.48f), Offset(w * 1.0f, h * 0.40f), sw, cap)
        drawLine(color, Offset(w * 0.66f, h * 0.70f), Offset(w * 0.88f, h * 0.78f), sw, cap)
        drawCircle(color, radius = w * 0.032f, center = Offset(w * 0.92f, h * 0.22f))
        drawCircle(color, radius = w * 0.024f, center = Offset(w * 0.55f, h * 0.10f))
        drawCircle(color, radius = w * 0.02f, center = Offset(w * 0.30f, h * 0.20f))
        drawCircle(color, radius = w * 0.026f, center = Offset(w * 0.95f, h * 0.62f))
    }
}

WINKVPN_EOF

cat > "app/src/main/java/com/winkvpn/app/ui/screens/SplashScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Text
import com.winkvpn.app.R
import com.winkvpn.app.ui.theme.WinkBlack
import kotlinx.coroutines.delay

/**
 * Сплэш-экран собран из настоящих фигур логотипа (вырезаны из PNG по отдельности:
 * глаз, рот, чек-галочка, звезда) — а не нарисован вручную кривыми, поэтому 1:1
 * повторяет фирменный логотип.
 *
 * Сценарий: лёгкий наезд → глаз подмигивает → лицо (глаз+рот+галочка) исчезает →
 * звезда летит к центру экрана, затем чуть влево, рядом появляется текст "Wink VPN".
 */
@Composable
fun SplashScreen(onFinished: () -> Unit) {
    // ── Геометрия исходного логотипа (посчитана из реальных пикселей PNG) ──
    // Контейнер "лица" (без звезды) — 280×262dp
    val faceW = 280.dp
    val faceH = 262.dp
    val checkmarkOffset = Pair(105.7.dp, (-2.4).dp)
    val checkmarkSize = Pair(124.9.dp, 108.7.dp)
    val eyeOffset = Pair((-2.6).dp, 15.3.dp)
    val eyeSize = Pair(88.5.dp, 161.2.dp)
    val mouthOffset = Pair(21.0.dp, 125.1.dp)
    val mouthSize = Pair(261.4.dp, 139.3.dp)

    // Позиция звезды в исходном лого относительно центра экрана (лого центрировано)
    val starInitial = Pair(97.dp, (-33).dp)
    val starCenter = Pair(0.dp, 0.dp)
    val starFinal = Pair((-97).dp, 0.dp) // финальная позиция летящей звезды (для кроссфейда)

    val logoScale = remember { Animatable(0.82f) }
    val faceAlpha = remember { Animatable(1f) }
    val eyeScaleY = remember { Animatable(1f) }
    val starPhaseA = remember { Animatable(0f) } // логотип → центр
    val starPhaseB = remember { Animatable(0f) } // центр → финальная точка
    val floatingStarAlpha = remember { Animatable(1f) }
    val finalStarAlpha = remember { Animatable(0f) }
    var visibleCharCount by remember { mutableStateOf(0) }
    val fullText = "Wink VPN"

    LaunchedEffect(Unit) {
        // 1. Лёгкий наезд камерой
        logoScale.animateTo(1.05f, tween(420, easing = FastOutSlowInEasing))
        logoScale.animateTo(1f, tween(180, easing = FastOutSlowInEasing))

        // 2. Подмигивание
        eyeScaleY.animateTo(0.1f, tween(90, easing = FastOutSlowInEasing))
        eyeScaleY.animateTo(1f, tween(160, easing = FastOutSlowInEasing))

        delay(200)

        // 3. Лицо исчезает
        faceAlpha.animateTo(0f, tween(380, easing = FastOutSlowInEasing))

        // 4. Звезда летит к центру
        starPhaseA.animateTo(1f, tween(380, easing = FastOutSlowInEasing))

        delay(40)

        // 5. Звезда летит дальше и садится на финальное место
        starPhaseB.animateTo(1f, tween(420, easing = LinearOutSlowInEasing))
        floatingStarAlpha.animateTo(0f, tween(180, easing = FastOutSlowInEasing))
        finalStarAlpha.animateTo(1f, tween(180, easing = FastOutSlowInEasing))

        // 6. Текст печатается по буквам — быстро
        for (i in 1..fullText.length) {
            visibleCharCount = i
            delay(38)
        }

        delay(650)
        onFinished()
    }

    fun lerp(a: Dp, b: Dp, t: Float): Dp = a + (b - a) * t

    val starX: Dp
    val starY: Dp
    if (starPhaseB.value <= 0f) {
        starX = lerp(starInitial.first, starCenter.first, starPhaseA.value)
        starY = lerp(starInitial.second, starCenter.second, starPhaseA.value)
    } else {
        starX = lerp(starCenter.first, starFinal.first, starPhaseB.value)
        starY = lerp(starCenter.second, starFinal.second, starPhaseB.value)
    }

    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {

        // ── Лицо: рот + галочка + глаз (настоящие фигуры из PNG) ──
        Box(
            modifier = Modifier
                .size(faceW, faceH)
                .graphicsLayer {
                    scaleX = logoScale.value
                    scaleY = logoScale.value
                    alpha = faceAlpha.value
                }
        ) {
            Image(
                painter = painterResource(id = R.drawable.logo_mouth),
                contentDescription = null,
                contentScale = ContentScale.FillBounds,
                modifier = Modifier
                    .offset(x = mouthOffset.first, y = mouthOffset.second)
                    .size(mouthSize.first, mouthSize.second)
            )
            Image(
                painter = painterResource(id = R.drawable.logo_checkmark),
                contentDescription = null,
                contentScale = ContentScale.FillBounds,
                modifier = Modifier
                    .offset(x = checkmarkOffset.first, y = checkmarkOffset.second)
                    .size(checkmarkSize.first, checkmarkSize.second)
            )
            Image(
                painter = painterResource(id = R.drawable.logo_eye),
                contentDescription = null,
                contentScale = ContentScale.FillBounds,
                modifier = Modifier
                    .offset(x = eyeOffset.first, y = eyeOffset.second)
                    .size(eyeSize.first, eyeSize.second)
                    .graphicsLayer { scaleY = eyeScaleY.value }
            )
        }

        // ── Летящая звезда (исчезает кроссфейдом в финале) ──
        Image(
            painter = painterResource(id = R.drawable.logo_star),
            contentDescription = null,
            modifier = Modifier
                .size(30.dp)
                .offset(x = starX, y = starY)
                .graphicsLayer { alpha = floatingStarAlpha.value }
        )

        // ── Финальный ряд "★ Wink VPN" — звезда фиксирована, текст печатается по буквам ──
        Row(verticalAlignment = Alignment.CenterVertically) {
            Image(
                painter = painterResource(id = R.drawable.logo_star),
                contentDescription = null,
                modifier = Modifier
                    .size(28.dp)
                    .graphicsLayer { alpha = finalStarAlpha.value }
            )
            Spacer(Modifier.width(10.dp))
            // Фиксированная ширина под весь текст сразу — чтобы во время печати
            // ряд не "рос" и не сдвигал звезду влево-вправо.
            Box(modifier = Modifier.width(190.dp)) {
                Text(
                    fullText.take(visibleCharCount),
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Black,
                    fontStyle = FontStyle.Italic,
                    color = WinkBlack
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
            widthDp = 280, heightDp = 175, alpha = 0.16f,
            modifier = Modifier.align(Alignment.TopStart).offset(x = (-70).dp, y = 90.dp)
        )
        KeyIcon(
            widthDp = 210, heightDp = 131, alpha = 0.11f,
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

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
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
            sizeDp = 220, alpha = 0.16f,
            modifier = Modifier.align(Alignment.TopEnd).offset(x = 45.dp, y = 75.dp)
        )
        GiftIcon(
            sizeDp = 170, alpha = 0.11f,
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

        // Модалка ожидания возврата из Telegram — плавное появление/исчезание
        AnimatedVisibility(
            visible = isWaitingForReturn,
            enter = fadeIn(tween(240, easing = FastOutSlowInEasing)),
            exit = fadeOut(tween(180, easing = FastOutSlowInEasing))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.35f)),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .padding(horizontal = 40.dp)
                        .animateEnterExit(
                            enter = scaleIn(tween(280, easing = FastOutSlowInEasing), initialScale = 0.85f) + fadeIn(tween(240)),
                            exit = scaleOut(tween(180), targetScale = 0.9f) + fadeOut(tween(150))
                        )
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
            widthDp = 220, heightDp = 300, alpha = 0.18f,
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
            sizeDp = 200, alpha = 0.16f,
            modifier = Modifier.align(Alignment.TopEnd).offset(x = 40.dp, y = 80.dp)
        )
        PartyIcon(
            sizeDp = 150, alpha = 0.11f,
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

cat > "app/src/main/java/com/winkvpn/app/ui/screens/MainScreen.kt" << 'WINKVPN_EOF'
package com.winkvpn.app.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
            CurvedArrow(widthDp = 130, heightDp = 170, alpha = 0.09f)
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(top = 48.dp)
        ) {

            // Topbar — только логотип и название, без лишней кнопки
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 26.dp),
                horizontalArrangement = Arrangement.Start,
                verticalAlignment = Alignment.CenterVertically
            ) {
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

            // Connect button — сразу под карточками, а не внизу экрана
            Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(top = 18.dp)) {
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

            Spacer(Modifier.height(16.dp))

            // Три полупрозрачные серые кнопки: промокод / телеграм / поддержка
            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                ActionRowButton(
                    label = "Активировать промокод",
                    icon = { GiftGlyph(sizeDp = 20) },
                    onClick = { promoOpen = true }
                )
                ActionRowButton(
                    label = "Наш Telegram канал",
                    icon = { TelegramPaperPlaneIcon(sizeDp = 19, tint = WinkBlack) },
                    onClick = {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/Winkvpn_official"))
                        context.startActivity(intent)
                    }
                )
                ActionRowButton(
                    label = "Поддержка",
                    icon = { HeadsetGlyph(sizeDp = 20) },
                    onClick = {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/Winkvpn_official"))
                        context.startActivity(intent)
                    }
                )
            }

            Spacer(Modifier.height(24.dp))
            Spacer(Modifier.height(24.dp))
        }

        // Connecting overlay
        AnimatedVisibility(
            visible = connState == ConnState.CONNECTING,
            enter = fadeIn(tween(220, easing = FastOutSlowInEasing)),
            exit = fadeOut(tween(180, easing = FastOutSlowInEasing))
        ) {
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
private fun ActionRowButton(
    label: String,
    icon: @Composable () -> Unit,
    onClick: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(WinkBlack09)
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 15.dp)
    ) {
        icon()
        Spacer(Modifier.width(14.dp))
        Text(label, fontSize = 14.5.sp, fontWeight = FontWeight.Bold, color = WinkBlack)
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
    var input by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }
    var isError by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(tween(260, easing = FastOutSlowInEasing)),
        exit = fadeOut(tween(200, easing = FastOutSlowInEasing))
    ) {
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
                    .animateEnterExit(
                        enter = slideInVertically(
                            animationSpec = tween(340, easing = FastOutSlowInEasing),
                            initialOffsetY = { it }
                        ) + fadeIn(tween(260)),
                        exit = slideOutVertically(
                            animationSpec = tween(220, easing = FastOutSlowInEasing),
                            targetOffsetY = { it }
                        ) + fadeOut(tween(180))
                    )
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
echo "Дальше: git add -A && git commit -m upnew && git push"