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

