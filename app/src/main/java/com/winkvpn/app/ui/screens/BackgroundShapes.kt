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
import androidx.compose.ui.graphics.PathFillType
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
 * Ключ — СПЛОШНОЙ силуэт (заливка, не обводка). Это специально: у линий на стыках
 * появлялись некрасивые наложения/утолщения, а сплошная заливка всегда чистая.
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
        val color = Color.Black.copy(alpha = alpha)

        val ringOuterR = h * 0.40f
        val ringInnerR = h * 0.22f
        val ringCenter = Offset(w * 0.24f, h * 0.5f)

        val path = Path().apply {
            fillType = PathFillType.EvenOdd
            addOval(androidx.compose.ui.geometry.Rect(center = ringCenter, radius = ringOuterR))
            addOval(androidx.compose.ui.geometry.Rect(center = ringCenter, radius = ringInnerR))
        }
        drawPath(path, color)

        // стержень + один зубец — единой заливкой
        val shaftTop = h * 0.5f - h * 0.09f
        val shaftBottom = h * 0.5f + h * 0.09f
        val shaft = Path().apply {
            moveTo(ringCenter.x + ringOuterR * 0.6f, shaftTop)
            lineTo(w * 0.9f, shaftTop)
            lineTo(w * 0.9f, h * 0.5f + h * 0.32f)
            lineTo(w * 0.78f, h * 0.5f + h * 0.32f)
            lineTo(w * 0.78f, shaftBottom)
            lineTo(ringCenter.x + ringOuterR * 0.6f, shaftBottom)
            close()
        }
        drawPath(shaft, color)
    }
}

/**
 * Подарок — сплошной силуэт: коробка + крестовина-вырез + простой бант из двух капель.
 */
@Composable
fun GiftIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 7200, amplitude = 9f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        drawGiftSilhouette(this, Color.Black.copy(alpha = alpha))
    }
}

/** Маленькая версия подарка сплошным чёрным — для кнопки "Активировать промокод" */
@Composable
fun GiftGlyph(sizeDp: Int = 22, tint: Color = Color.Black, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(sizeDp.dp)) {
        drawGiftSilhouette(this, tint)
    }
}

private fun drawGiftSilhouette(scope: androidx.compose.ui.graphics.drawscope.DrawScope, color: Color) {
    with(scope) {
        val w = size.width
        val h = size.height

        val ribbonW = w * 0.16f
        val box = Path().apply {
            fillType = PathFillType.EvenOdd
            addRoundRect(
                androidx.compose.ui.geometry.RoundRect(
                    left = w * 0.14f, top = h * 0.42f, right = w * 0.86f, bottom = h * 0.92f,
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.04f)
                )
            )
            // вертикальный вырез ленты
            addRect(
                androidx.compose.ui.geometry.Rect(
                    left = w * 0.5f - ribbonW / 2, top = h * 0.42f,
                    right = w * 0.5f + ribbonW / 2, bottom = h * 0.92f
                )
            )
        }
        drawPath(box, color)

        // крышка коробки (полоса)
        val lid = Path().apply {
            addRoundRect(
                androidx.compose.ui.geometry.RoundRect(
                    left = w * 0.08f, top = h * 0.32f, right = w * 0.92f, bottom = h * 0.44f,
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.025f)
                )
            )
        }
        drawPath(lid, color)

        // бант — две простые капли-лепестка
        val leftPetal = Path().apply {
            moveTo(w * 0.5f, h * 0.34f)
            cubicTo(w * 0.5f, h * 0.18f, w * 0.28f, h * 0.1f, w * 0.24f, h * 0.22f)
            cubicTo(w * 0.21f, h * 0.32f, w * 0.36f, h * 0.34f, w * 0.5f, h * 0.34f)
            close()
        }
        drawPath(leftPetal, color)
        val rightPetal = Path().apply {
            moveTo(w * 0.5f, h * 0.34f)
            cubicTo(w * 0.5f, h * 0.18f, w * 0.72f, h * 0.1f, w * 0.76f, h * 0.22f)
            cubicTo(w * 0.79f, h * 0.32f, w * 0.64f, h * 0.34f, w * 0.5f, h * 0.34f)
            close()
        }
        drawPath(rightPetal, color)
    }
}

/** Плавная изгибающаяся стрелка (используется только на фоне экрана "Спасибо") */
@Composable
fun CurvedArrow(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(width = widthDp.dp, height = heightDp.dp)) {
        val sw = size.width * 0.06f
        val stroke = androidx.compose.ui.graphics.drawscope.Stroke(
            width = sw,
            cap = androidx.compose.ui.graphics.StrokeCap.Round,
            join = androidx.compose.ui.graphics.StrokeJoin.Round
        )
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

        // дуга оголовья
        val headband = Path().apply {
            addArc(
                androidx.compose.ui.geometry.Rect(w * 0.12f, h * 0.05f, w * 0.88f, h * 0.85f),
                startAngleDegrees = 180f, sweepAngleDegrees = 180f
            )
        }
        drawPath(
            headband, tint,
            style = androidx.compose.ui.graphics.drawscope.Stroke(
                width = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round
            )
        )

        // левая и правая "чашки"
        drawRoundRect(
            tint,
            topLeft = Offset(w * 0.06f, h * 0.55f),
            size = androidx.compose.ui.geometry.Size(w * 0.22f, h * 0.38f),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.09f)
        )
        drawRoundRect(
            tint,
            topLeft = Offset(w * 0.72f, h * 0.55f),
            size = androidx.compose.ui.geometry.Size(w * 0.22f, h * 0.38f),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.09f)
        )
    }
}

/**
 * Декоративная "праздничная" иконка (в духе 🎉) — сплошной силуэт конуса-хлопушки
 * с разлетающимися конфетти-штрихами.
 */
@Composable
fun PartyIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6800, amplitude = 8f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        val cone = Path().apply {
            moveTo(w * 0.10f, h * 0.92f)
            lineTo(w * 0.44f, h * 0.40f)
            lineTo(w * 0.70f, h * 0.62f)
            close()
        }
        drawPath(cone, color)

        val sw = w * 0.045f
        val cap = androidx.compose.ui.graphics.StrokeCap.Round
        drawLine(color, Offset(w * 0.62f, h * 0.30f), Offset(w * 0.80f, h * 0.14f), sw, cap)
        drawLine(color, Offset(w * 0.80f, h * 0.50f), Offset(w * 0.99f, h * 0.42f), sw, cap)
        drawLine(color, Offset(w * 0.68f, h * 0.70f), Offset(w * 0.88f, h * 0.76f), sw, cap)
        drawCircle(color, radius = w * 0.028f, center = Offset(w * 0.90f, h * 0.24f))
        drawCircle(color, radius = w * 0.022f, center = Offset(w * 0.56f, h * 0.12f))
    }
}

