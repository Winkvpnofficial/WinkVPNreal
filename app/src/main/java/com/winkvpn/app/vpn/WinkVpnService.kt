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

