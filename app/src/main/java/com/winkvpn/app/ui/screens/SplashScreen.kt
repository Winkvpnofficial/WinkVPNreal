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

