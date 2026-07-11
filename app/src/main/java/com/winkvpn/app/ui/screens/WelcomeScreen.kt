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

