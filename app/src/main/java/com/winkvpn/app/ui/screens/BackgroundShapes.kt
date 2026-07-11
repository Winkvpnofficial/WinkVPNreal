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
 * Тонкий контур ключа (моно-линия, как в HTML-версии).
 * ВАЖНО: принимает отдельно width и height — форма ключа не квадратная (~1.6:1),
 * раньше передавался один sizeDp и рисовалась квадратная канва, из-за чего
 * ключ визуально сплющивало/растягивало.
 */
@Composable
fun KeyIcon(widthDp: Int, heightDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 6500, amplitude = 10f)
    Canvas(
        modifier = modifier
            .size(width = widthDp.dp, height = heightDp.dp)
            .offset(y = dy.dp)
    ) {
        val strokeWidth = size.height * 0.09f
        val color = Color.Black.copy(alpha = alpha)

        val ringCenter = Offset(size.width * 0.22f, size.height * 0.5f)
        drawCircle(color, radius = size.height * 0.42f, center = ringCenter, style = Stroke(width = strokeWidth, cap = StrokeCap.Round))
        drawCircle(color, radius = size.height * 0.15f, center = ringCenter, style = Stroke(width = strokeWidth * 0.7f, cap = StrokeCap.Round))

        val shaftY = size.height * 0.5f
        drawLine(color, Offset(size.width * 0.41f, shaftY), Offset(size.width * 0.9f, shaftY), strokeWidth, StrokeCap.Round)
        drawLine(color, Offset(size.width * 0.8f, shaftY), Offset(size.width * 0.8f, shaftY + size.height * 0.36f), strokeWidth, StrokeCap.Round)
        drawLine(color, Offset(size.width * 0.66f, shaftY), Offset(size.width * 0.66f, shaftY + size.height * 0.26f), strokeWidth, StrokeCap.Round)
    }
}

/** Тонкий контур подарка с бантом — форма квадратная, тут проблем с пропорциями не было */
@Composable
fun GiftIcon(sizeDp: Int, alpha: Float, modifier: Modifier = Modifier) {
    val dy by rememberFloatOffset(periodMs = 7200, amplitude = 9f)
    Canvas(
        modifier = modifier
            .size(sizeDp.dp)
            .offset(y = dy.dp)
    ) {
        val strokeWidth = size.width * 0.05f
        val stroke = Stroke(width = strokeWidth, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val color = Color.Black.copy(alpha = alpha)
        val w = size.width
        val h = size.height

        drawRoundRect(
            color,
            topLeft = Offset(w * 0.15f, h * 0.42f),
            size = androidx.compose.ui.geometry.Size(w * 0.7f, h * 0.48f),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.03f),
            style = stroke
        )
        drawLine(color, Offset(w * 0.1f, h * 0.325f), Offset(w * 0.9f, h * 0.325f), strokeWidth, StrokeCap.Round)
        drawLine(color, Offset(w * 0.5f, h * 0.325f), Offset(w * 0.5f, h * 0.9f), strokeWidth, StrokeCap.Round)

        val bowPath = Path().apply {
            moveTo(w * 0.35f, h * 0.325f)
            cubicTo(w * 0.2f, h * 0.325f, w * 0.2f, h * 0.15f, w * 0.325f, h * 0.14f)
            cubicTo(w * 0.45f, h * 0.13f, w * 0.5f, h * 0.275f, w * 0.5f, h * 0.325f)
        }
        drawPath(bowPath, color, style = stroke)
        val bowPath2 = Path().apply {
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

/**
 * Нормальная векторная иконка Telegram (бумажный самолётик) вместо emoji-заглушки "✈",
 * которая на некоторых телефонах рендерится системным значком плохого вида.
 */
@Composable
fun TelegramPaperPlaneIcon(sizeDp: Int = 22, tint: Color = Color.White, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(sizeDp.dp)) {
        val w = size.width
        val h = size.height

        val plane = Path().apply {
            moveTo(w * 0.05f, h * 0.55f)
            lineTo(w * 0.95f, h * 0.08f)
            lineTo(w * 0.40f, h * 0.95f)
            lineTo(w * 0.34f, h * 0.63f)
            close()
        }
        drawPath(plane, tint)

        drawLine(
            color = tint.copy(alpha = 0.55f),
            start = Offset(w * 0.34f, h * 0.63f),
            end = Offset(w * 0.60f, h * 0.47f),
            strokeWidth = w * 0.035f,
            cap = StrokeCap.Round
        )
    }
}

