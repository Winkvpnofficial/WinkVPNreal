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

