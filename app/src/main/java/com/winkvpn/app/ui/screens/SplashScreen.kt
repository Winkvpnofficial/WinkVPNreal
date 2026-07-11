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

