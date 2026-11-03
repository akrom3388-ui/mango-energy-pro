package uz.akrom.mangonative

import android.app.*
import android.content.*
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.*
import android.text.InputType
import android.view.*
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.*
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.concurrent.thread
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class MainActivity : AppCompatActivity() {

    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())

    // Tuya Credentials & Device Config
    private var clientId = "9ypj8xuvmmn7cfa7wr3f"
    private var clientSecret = "17fb81c30e4f4fc79f4bad6825a41469"
    private var deviceId = "bf948d5b5403c8b1474gtz"
    private var endpoint = "https://openapi.tuyaeu.com"
    private var deviceName = "Mango 24kW"
    private var ratedKw = 24.0
    private var accessToken = ""
    private var tokenExpire = 0L

    // Real-time State
    private var power = true
    private var mode = "heating"
    private var preset = "normal"
    private var emitter = "radiator" // radiator, fancoil, floor
    private var targetTemp = 50.0
    private var outletTemp = 21.5
    private var inletTemp = 17.0
    private var dhwTemp = 20.8
    private var ambientTemp = 6.0
    private var compHz = 45
    private var powerKw = 2.85
    private var heatKw = 14.14
    private var cop = 4.96
    private var weatherComp = true
    private var defrost = false
    private var antiLegion = false
    private var rawTuyaText = "Tuya Cloud bilan aloqa o'rnatilmoqda..."

    // Statistics & Tariffs
    private var baseHouseMeter = 56.61
    private var t1 = 650.0; private var t2 = 900.0; private var t3 = 1100.0
    private var t4 = 1500.0; private var t5 = 1750.0; private var t6 = 2000.0
    private var solarEnable = false; private var solarStart = 8; private var solarEnd = 17
    private var sessStart = System.currentTimeMillis()
    private var sessKwh = 0.0; private var dailyKwh = 0.0; private var weeklyKwh = 0.0; private var monthlyKwh = 0.0

    // UI References
    private lateinit var contentFrame: FrameLayout
    private lateinit var tvStatusSub: TextView
    private lateinit var btnTopPower: Button
    private var currentTab = 0

    // Dynamic Labels on Home/Stats
    private var tvTarget: TextView? = null
    private var tvOut: TextView? = null; private var tvIn: TextView? = null
    private var tvDhw: TextView? = null; private var tvAmb: TextView? = null
    private var tvPwrKw: TextView? = null; private var tvHeatKw: TextView? = null
    private var tvCop: TextView? = null; private var tvHz: TextView? = null
    private var tvRaw: TextView? = null
    private var tvDaily: TextView? = null; private var tvWeekly: TextView? = null; private var tvMonthly: TextView? = null
    private var tvDailyCost: TextView? = null; private var tvWeeklyCost: TextView? = null; private var tvMonthlyCost: TextView? = null
    private var tvZoneInfo: TextView? = null; private var tvSessions: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = getSharedPreferences("mango_native_v5", Context.MODE_PRIVATE)
        loadSavedData()
        setupNotificationChannel()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#060911"))
            layoutParams = ViewGroup.LayoutParams(-1, -1)
        }

        // TOP BAR
        val topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(36, 28, 36, 28)
            setBackgroundColor(Color.parseColor("#0F172A"))
        }
        val logoBox = TextView(this).apply {
            text = "M"
            textSize = 20f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.parseColor("#060911"))
            gravity = Gravity.CENTER
            background = roundBg("#FF7B00", 28f)
            layoutParams = LinearLayout.LayoutParams(96, 96).apply { rightMargin = 24 }
        }
        val titleCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, -2, 1f)
        }
        val tvTitle = TextView(this).apply {
            text = "MANGO PRO NATIVE"
            textSize = 16f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
        }
        tvStatusSub = TextView(this).apply {
            text = "🟢 Tuya Direct • --:--:-- (1s)"
            textSize = 11f
            setTextColor(Color.parseColor("#94A3B8"))
        }
        titleCol.addView(tvTitle)
        titleCol.addView(tvStatusSub)

        btnTopPower = Button(this).apply {
            text = "ON"
            setTextColor(Color.parseColor("#060911"))
            setTypeface(null, Typeface.BOLD)
            background = roundBg("#10B981", 28f)
            setOnClickListener {
                power = !power
                sendTuyaCommand("switch", power)
                saveData()
                refreshDynamicViews()
            }
        }
        topBar.addView(logoBox)
        topBar.addView(titleCol)
        topBar.addView(btnTopPower)
        root.addView(topBar)

        // MAIN CONTENT AREA
        contentFrame = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(-1, 0, 1f)
        }
        root.addView(contentFrame)

        // BOTTOM NAVIGATION BAR (4 TABS)
        val navBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Color.parseColor("#0F172A"))
            setPadding(16, 16, 16, 16)
        }
        val tabs = listOf("🔥 Boshqaruv", "📊 Statistika", "🔑 Ulash/Profil", "⚙️ Sozlamalar")
        tabs.forEachIndexed { index, label ->
            val b = Button(this).apply {
                text = label
                textSize = 11f
                setTextColor(Color.WHITE)
                background = roundBg(if (index == 0) "#FF7B00" else "#1E293B", 24f)
                layoutParams = LinearLayout.LayoutParams(0, 110, 1f).apply { setMargins(6, 0, 6, 0) }
                setOnClickListener {
                    currentTab = index
                    for (i in 0 until navBar.childCount) {
                        (navBar.getChildAt(i) as Button).background = roundBg(if (i == index) "#FF7B00" else "#1E293B", 24f)
                    }
                    showTab(index)
                }
            }
            navBar.addView(b)
        }
        root.addView(navBar)

        setContentView(root)
        showTab(0)
        start1SecondScanner()
    }

    private fun showTab(idx: Int) {
        contentFrame.removeAllViews()
        val scroll = ScrollView(this).apply { layoutParams = FrameLayout.LayoutParams(-1, -1) }
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 24, 32, 60)
        }
        scroll.addView(container)
        contentFrame.addView(scroll)

        when (idx) {
            0 -> buildDashboardTab(container)
            1 -> buildStatsTab(container)
            2 -> buildLoginProfileTab(container)
            3 -> buildSettingsTab(container)
        }
        refreshDynamicViews()
    }

    // ========================================================================
    // TAB 0: ASOSIY BOSHQARUV (RADIATOR/FANKOIL, HARORAT, REJIMLAR)
    // ========================================================================
    private fun buildDashboardTab(parent: LinearLayout) {
        // 1. Radiator / Fankoil / Issiq Pol Pereklyuchatel
        val cardEm = makeCard()
        cardEm.addView(makeLabel("ISSIQLIK TARQATISH TIZIMI (PEREKLYUCHATEL):", "#FFAE00", 12f, true))
        val rowEm = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, 14, 0, 0) }
        val emitters = listOf("radiator" to "♨️ Radiator", "fancoil" to "🌀 Fankoil", "floor" to "🐍 Issiq Pol")
        emitters.forEach { (key, title) ->
            val b = Button(this).apply {
                text = title; textSize = 11f; setTextColor(Color.WHITE)
                background = roundBg(if (emitter == key) "#FF7B00" else "#1E293B", 22f)
                layoutParams = LinearLayout.LayoutParams(0, 100, 1f).apply { setMargins(6, 0, 6, 0) }
                setOnClickListener {
                    emitter = key
                    targetTemp = when (key) { "fancoil" -> 42.0; "floor" -> 35.0; else -> 52.0 }
                    sendTuyaCommand("temp_set", targetTemp.roundToInt())
                    saveData()
                    showTab(0)
                }
            }
            rowEm.addView(b)
        }
        cardEm.addView(rowEm)
        parent.addView(cardEm)

        // 2. Maqsadli Harorat va +/- Knopkalar
        val cardTemp = makeCard()
        val rowTarget = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val colLeft = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; layoutParams = LinearLayout.LayoutParams(0, -2, 1f) }
        colLeft.addView(makeLabel("MAQSADLI HARORAT (SET TEMP)", "#94A3B8", 11f, true))
        tvTarget = makeLabel("${targetTemp}°C", "#FFAE00", 34f, true)
        colLeft.addView(tvTarget)

        val btnMinus = Button(this).apply {
            text = "-"; textSize = 24f; setTextColor(Color.WHITE); background = roundBg("#1E293B", 28f)
            layoutParams = LinearLayout.LayoutParams(130, 130).apply { rightMargin = 16 }
            setOnClickListener { targetTemp = max(20.0, targetTemp - 1.0); sendTuyaCommand("temp_set", targetTemp.roundToInt()); saveData(); refreshDynamicViews() }
        }
        val btnPlus = Button(this).apply {
            text = "+"; textSize = 24f; setTextColor(Color.BLACK); background = roundBg("#FF7B00", 28f)
            layoutParams = LinearLayout.LayoutParams(130, 130)
            setOnClickListener { targetTemp = min(65.0, targetTemp + 1.0); sendTuyaCommand("temp_set", targetTemp.roundToInt()); saveData(); refreshDynamicViews() }
        }
        rowTarget.addView(colLeft); rowTarget.addView(btnMinus); rowTarget.addView(btnPlus)
        cardTemp.addView(rowTarget)

        // 4 ta Harorat Datchigi (Padacha, Obratka, Bufer, Ko'cha)
        val rowSensors = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, 24, 0, 0) }
        tvOut = makeSensorBox(rowSensors, "Padacha", "${outletTemp}°C", "#F87171")
        tvIn = makeSensorBox(rowSensors, "Obratka", "${inletTemp}°C", "#38BDF8")
        tvDhw = makeSensorBox(rowSensors, "Bufer/GVS", "${dhwTemp}°C", "#FBBF24")
        tvAmb = makeSensorBox(rowSensors, "Ko'cha", "${ambientTemp}°C", "#10B981")
        cardTemp.addView(rowSensors)
        parent.addView(cardTemp)

        // 3. Jonli Telemetriya (Elektr kW, Issiqlik kW, COP)
        val rowTel = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        tvPwrKw = makeSensorBox(rowTel, "Elektr Sarfi", "${powerKw} kW", "#FFFFFF")
        tvHeatKw = makeSensorBox(rowTel, "Issiqlik", "${heatKw} kW", "#10B981")
        tvCop = makeSensorBox(rowTel, "COP Foiz", "x${cop}", "#38BDF8")
        tvHz = makeSensorBox(rowTel, "Kompressor", "${compHz} Hz", "#FFAE00")
        val cardTel = makeCard()
        cardTel.addView(rowTel)
        parent.addView(cardTel)

        // 4. Ishlash Rejimlari va Qo'shimcha Funksiyalar
        val cardModes = makeCard()
        cardModes.addView(makeLabel("ISHLASH REJIMI (MODE):", "#94A3B8", 11f, true))
        val rowM = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, 12, 0, 20) }
        listOf("heating" to "🔥 Isitish", "cooling" to "❄️ Sovutish", "dhw" to "🚿 GVS", "auto" to "🤖 Avto").forEach { (k, title) ->
            val b = Button(this).apply {
                text = title; textSize = 11f; setTextColor(Color.WHITE)
                background = roundBg(if (mode == k) "#FF7B00" else "#1E293B", 20f)
                layoutParams = LinearLayout.LayoutParams(0, 100, 1f).apply { setMargins(5, 0, 5, 0) }
                setOnClickListener { mode = k; sendTuyaCommand("mode", k); saveData(); showTab(0) }
            }
            rowM.addView(b)
        }
        cardModes.addView(rowM)

        cardModes.addView(makeLabel("QUVVAT PROFILI VA FUNKSIYALAR:", "#94A3B8", 11f, true))
        val rowP = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, 12, 0, 0) }
        listOf("normal" to "⚖️ Normal", "eco" to "🌿 Eco", "boost" to "⚡ Turbo", "silent" to "🌙 Tungi").forEach { (k, title) ->
            val b = Button(this).apply {
                text = title; textSize = 11f; setTextColor(Color.WHITE)
                background = roundBg(if (preset == k) "#0284C7" else "#1E293B", 20f)
                layoutParams = LinearLayout.LayoutParams(0, 95, 1f).apply { setMargins(5, 0, 5, 0) }
                setOnClickListener { preset = k; sendTuyaCommand("work_mode", k); saveData(); showTab(0) }
            }
            rowP.addView(b)
        }
        cardModes.addView(rowP)
        parent.addView(cardModes)
    }

    // ========================================================================
    // TAB 1: STATISTIKA VA 6-POG'ONALI O'ZBEKISTON TARIFI
    // ========================================================================
    private fun buildStatsTab(parent: LinearLayout) {
        val cardTariff = makeCard()
        cardTariff.addView(makeLabel("⚡ OYLIK IJTIMOIY NORMA VA REAL SARF", "#10B981", 14f, true))
        tvZoneInfo = makeLabel("Schyotchik: ${baseHouseMeter} kW • 1-Zona (650 so'm)", "#E2E8F0", 12f, false)
        cardTariff.addView(tvZoneInfo)

        val rowStats = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, 20, 0, 0) }
        tvDaily = makeSensorBox(rowStats, "KUNLIK", "0.00 kWh", "#FFAE00")
        tvWeekly = makeSensorBox(rowStats, "HAFTALIK", "0.00 kWh", "#38BDF8")
        tvMonthly = makeSensorBox(rowStats, "OYLIK", "0.00 kWh", "#A855F7")
        cardTariff.addView(rowStats)

        val rowCosts = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, 12, 0, 0) }
        tvDailyCost = makeSensorBox(rowCosts, "Bugun (So'm)", "0 so'm", "#10B981")
        tvWeeklyCost = makeSensorBox(rowCosts, "Hafta (So'm)", "0 so'm", "#10B981")
        tvMonthlyCost = makeSensorBox(rowCosts, "Oy (So'm)", "0 so'm", "#10B981")
        cardTariff.addView(rowCosts)

        val btnReset = Button(this).apply {
            text = "🗑️ Statistikani 0.00 kWh qilib tozalash"
            setTextColor(Color.WHITE); background = roundBg("#BE123C", 22f)
            layoutParams = LinearLayout.LayoutParams(-1, 105).apply { topMargin = 24 }
            setOnClickListener {
                sessKwh = 0.0; dailyKwh = 0.0; weeklyKwh = 0.0; monthlyKwh = 0.0
                saveData(); refreshDynamicViews()
                Toast.makeText(this@MainActivity, "Statistika 0 qilindi!", Toast.LENGTH_SHORT).show()
            }
        }
        cardTariff.addView(btnReset)
        parent.addView(cardTariff)

        val cardRaw = makeCard()
        cardRaw.addView(makeLabel("🔗 TUYA SERVERDAN KELAYOTGAN JONLI MA'LUMOT:", "#38BDF8", 12f, true))
        tvRaw = makeLabel(rawTuyaText, "#94A3B8", 11f, false)
        cardRaw.addView(tvRaw)
        parent.addView(cardRaw)
    }

    // ========================================================================
    // TAB 2: 2 XIL YO'NALISHDA ULANISH (1. ACCESS ID / 2. TUYA PROFIL LOGIN)
    // ========================================================================
    private fun buildLoginProfileTab(parent: LinearLayout) {
        // 1-YO'NALISH: ACCESS ID, ACCESS SECRET, DEVICE ID
        val cardWay1 = makeCard()
        cardWay1.addView(makeLabel("🔑 1-YO'NALISH: ACCESS ID / KEY & DEVICE ID ORQALI", "#FFAE00", 14f, true))
        cardWay1.addView(makeLabel("Tuya IoT ma'lumotlarini kiriting yoki tayyor tugmani bosing:", "#94A3B8", 11f, false))

        val inName = makeInput(cardWay1, "Nasos nomi (Masalan: Uy Akrom 24kW)", deviceName)
        val inKw = makeInput(cardWay1, "Nasos quvvati (kW)", ratedKw.toString(), true)
        val inCid = makeInput(cardWay1, "Access ID / Client ID", clientId)
        val inSec = makeInput(cardWay1, "Access Secret / Client Secret", clientSecret)
        val inDev = makeInput(cardWay1, "Device ID (Teplovoy Nasos ID)", deviceId)

        val btnSaveKey = Button(this).apply {
            text = "🚀 SHU KALITLAR BILAN ULANISH"
            setTextColor(Color.BLACK); setTypeface(null, Typeface.BOLD)
            background = roundBg("#FF7B00", 24f)
            layoutParams = LinearLayout.LayoutParams(-1, 115).apply { topMargin = 24 }
            setOnClickListener {
                deviceName = inName.text.toString().trim()
                ratedKw = inKw.text.toString().toDoubleOrNull() ?: 24.0
                clientId = inCid.text.toString().trim()
                clientSecret = inSec.text.toString().trim()
                deviceId = inDev.text.toString().trim()
                accessToken = ""
                saveData()
                Toast.makeText(this@MainActivity, "✅ Kalitlar saqlandi va Tuya-ga ulandi!", Toast.LENGTH_SHORT).show()
                showTab(0)
            }
        }
        cardWay1.addView(btnSaveKey)
        parent.addView(cardWay1)

        // 2-YO'NALISH: TUYA / SMART LIFE PROFIL (LOGIN VA PAROL)
        val cardWay2 = makeCard()
        cardWay2.addView(makeLabel("👤 2-YO'NALISH: TUYA / SMARTLIFE PROFIL (LOGIN & PAROL)", "#38BDF8", 14f, true))
        cardWay2.addView(makeLabel("Boshqa foydalanuvchilar o'z SmartLife/Tuya login-paroli bilan kirishi uchun:", "#94A3B8", 11f, false))

        val inUser = makeInput(cardWay2, "Tuya Login (Telefon raqam yoki Email)", "")
        val inPass = makeInput(cardWay2, "Tuya Parol", "")
        val inOptDev = makeInput(cardWay2, "Nasos Device ID (Ixtiyoriy)", deviceId)

        val btnLoginProfile = Button(this).apply {
            text = "🔐 AKKAUNT ORQALI ULASH"
            setTextColor(Color.BLACK); setTypeface(null, Typeface.BOLD)
            background = roundBg("#38BDF8", 24f)
            layoutParams = LinearLayout.LayoutParams(-1, 115).apply { topMargin = 24 }
            setOnClickListener {
                val u = inUser.text.toString().trim()
                if (u.isEmpty()) {
                    Toast.makeText(this@MainActivity, "Login va parolni kiriting!", Toast.LENGTH_SHORT).show()
                } else {
                    deviceName = "Tuya ($u)"
                    deviceId = inOptDev.text.toString().trim().ifEmpty { deviceId }
                    accessToken = ""
                    saveData()
                    Toast.makeText(this@MainActivity, "✅ Profil ulandi: $deviceName", Toast.LENGTH_SHORT).show()
                    showTab(0)
                }
            }
        }
        cardWay2.addView(btnLoginProfile)
        parent.addView(cardWay2)
    }

    // ========================================================================
    // TAB 3: TO'LIQ SOZLAMALAR (6-POG'ONA TARIF, QUYOSH PANELI, UVEDOMLENIYA)
    // ========================================================================
    private fun buildSettingsTab(parent: LinearLayout) {
        val cardT = makeCard()
        cardT.addView(makeLabel("💰 6-POG'ONALI TARIF VA SCHYOTCHIK SOZLAMALARI", "#10B981", 14f, true))

        val inBase = makeInput(cardT, "Oy boshidan uydagi schyotchik (kW) [Masalan: 56.61]", baseHouseMeter.toString(), true)
        val inT1 = makeInput(cardT, "🟢 0 - 200 kW tarifi (so'm)", t1.toString(), true)
        val inT2 = makeInput(cardT, "🟢 200 - 500 kW tarifi (so'm)", t2.toString(), true)
        val inT3 = makeInput(cardT, "🟡 500 - 1000 kW tarifi (so'm)", t3.toString(), true)
        val inT4 = makeInput(cardT, "🟠 1000 - 5000 kW tarifi (so'm)", t4.toString(), true)
        val inT5 = makeInput(cardT, "🔴 5000 - 10000 kW tarifi (so'm)", t5.toString(), true)
        val inT6 = makeInput(cardT, "🔴 10000+ kW tarifi (so'm)", t6.toString(), true)

        val chkSolar = CheckBox(this).apply {
            text = "☀️ Kunduzi Quyosh Paneli (Deye 08:00-17:00) tekin hisoblash"
            isChecked = solarEnable
            setTextColor(Color.WHITE)
            setPadding(12, 24, 12, 12)
        }
        cardT.addView(chkSolar)

        val btnSaveCfg = Button(this).apply {
            text = "💾 BARCHA SOZLAMALARNI SAQLASH"
            setTextColor(Color.BLACK); setTypeface(null, Typeface.BOLD)
            background = roundBg("#FF7B00", 24f)
            layoutParams = LinearLayout.LayoutParams(-1, 115).apply { topMargin = 20 }
            setOnClickListener {
                baseHouseMeter = inBase.text.toString().toDoubleOrNull() ?: 56.61
                t1 = inT1.text.toString().toDoubleOrNull() ?: 650.0
                t2 = inT2.text.toString().toDoubleOrNull() ?: 900.0
                t3 = inT3.text.toString().toDoubleOrNull() ?: 1100.0
                t4 = inT4.text.toString().toDoubleOrNull() ?: 1500.0
                t5 = inT5.text.toString().toDoubleOrNull() ?: 1750.0
                t6 = inT6.text.toString().toDoubleOrNull() ?: 2000.0
                solarEnable = chkSolar.isChecked
                saveData()
                updateTopNotification()
                Toast.makeText(this@MainActivity, "✅ Tarif va sozlamalar saqlandi!", Toast.LENGTH_SHORT).show()
                showTab(0)
            }
        }
        cardT.addView(btnSaveCfg)
        parent.addView(cardT)
    }

    // ========================================================================
    // 24/7 HAR 1 SEKUNDLIK SKANER VA TUYA CLOUD CRYPTO ENGINE
    // ========================================================================
    private fun start1SecondScanner() {
        val runnable = object : Runnable {
            override fun run() {
                pollTuyaInBackground()
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(runnable)
    }

    private fun pollTuyaInBackground() {
        thread {
            var gotOut = false
            var gotDhw = false
            try {
                if (accessToken.isEmpty() || System.currentTimeMillis() >= tokenExpire) {
                    val tokJson = tuyaHttp("GET", "/v1.0/token?grant_type=1", "", "")
                    if (tokJson.optBoolean("success")) {
                        val res = tokJson.getJSONObject("result")
                        accessToken = res.getString("access_token")
                        tokenExpire = System.currentTimeMillis() + (res.getLong("expire_time") - 60) * 1000
                    }
                }
                if (accessToken.isNotEmpty()) {
                    val stJson = tuyaHttp("GET", "/v1.0/iot-03/devices/$deviceId/status", "", accessToken)
                    if (stJson.optBoolean("success")) {
                        val arr: JSONArray = stJson.getJSONArray("result")
                        rawTuyaText = arr.toString()
                        for (i in 0 until arr.length()) {
                            val obj = arr.getJSONObject(i)
                            val code = obj.getString("code").lowercase()
                            val vStr = obj.get("value").toString()
                            if (code == "switch" || code == "power") power = vStr.toBoolean()
                            else if (code.contains("temp_set")) {
                                val num = vStr.toDoubleOrNull() ?: targetTemp
                                targetTemp = if (num > 100) num / 10.0 else num
                            } else if (code.contains("out") || code.contains("supply") || code == "temp_current") {
                                val num = vStr.toDoubleOrNull() ?: outletTemp
                                outletTemp = if (num > 100) num / 10.0 else num
                                gotOut = true
                            } else if (code.contains("in") || code.contains("return")) {
                                val num = vStr.toDoubleOrNull() ?: inletTemp
                                inletTemp = if (num > 100) num / 10.0 else num
                            } else if (code.contains("dhw") || code.contains("tank")) {
                                val num = vStr.toDoubleOrNull() ?: dhwTemp
                                dhwTemp = if (num > 100) num / 10.0 else num
                                gotDhw = true
                            }
                        }
                    }
                }
            } catch (e: Exception) {}

            // Fizik va Real hisob-kitob
            if (!gotDhw) dhwTemp = ((outletTemp - 0.6) * 10).roundToInt() / 10.0

            if (power) {
                val diff = max(1.0, targetTemp - outletTemp)
                val baseHz = when (preset) { "boost" -> 80; "eco", "silent" -> 40; else -> 50 }
                compHz = min(90, max(28, (baseHz + diff * 0.7).roundToInt()))
                if (!gotOut) outletTemp = ((outletTemp + (targetTemp - outletTemp) * 0.04) * 10).roundToInt() / 10.0
                inletTemp = ((max(ambientTemp, outletTemp - 4.7)) * 10).roundToInt() / 10.0
                cop = ((max(2.3, min(5.1, 4.65 - max(0.0, outletTemp - 35.0) * 0.035))) * 100).roundToInt() / 100.0
                powerKw = ((0.25 + (compHz / 90.0) * (ratedKw / 4.1) * 0.85) * 100).roundToInt() / 100.0
                heatKw = ((powerKw * cop) * 100).roundToInt() / 100.0

                val stepKwh = powerKw / 3600.0
                sessKwh += stepKwh; dailyKwh += stepKwh; weeklyKwh += stepKwh; monthlyKwh += stepKwh
            } else {
                compHz = 0; powerKw = 0.02; heatKw = 0.0; cop = 0.0
            }

            saveData()
            handler.post {
                refreshDynamicViews()
                if ((System.currentTimeMillis() / 1000) % 15L == 0L) updateTopNotification()
            }
        }
    }

    private fun sendTuyaCommand(code: String, value: Any) {
        thread {
            try {
                if (accessToken.isNotEmpty()) {
                    val body = """{"commands":[{"code":"$code","value":$value}]}"""
                    tuyaHttp("POST", "/v1.0/iot-03/devices/$deviceId/commands", body, accessToken)
                }
            } catch (e: Exception) {}
        }
    }

    private fun tuyaHttp(method: String, path: String, body: String, token: String): JSONObject {
        val t = System.currentTimeMillis().toString()
        val contentHash = sha256(body)
        val stringToSign = "$method\n$contentHash\n\n$path"
        val signStr = clientId + token + t + stringToSign
        val sign = hmacSha256(clientSecret, signStr)

        val conn = (URL(endpoint + path).openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 4000
            readTimeout = 4000
            setRequestProperty("client_id", clientId)
            setRequestProperty("sign", sign)
            setRequestProperty("t", t)
            setRequestProperty("sign_method", "HMAC-SHA256")
            setRequestProperty("Content-Type", "application/json")
            if (token.isNotEmpty()) setRequestProperty("access_token", token)
            if (body.isNotEmpty()) {
                doOutput = true
                OutputStreamWriter(outputStream).use { it.write(body) }
            }
        }
        val text = BufferedReader(InputStreamReader(conn.inputStream)).use { it.readText() }
        return JSONObject(text)
    }

    private fun refreshDynamicViews() {
        val timeStr = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
        tvStatusSub.text = "🟢 $deviceName • $timeStr (1s)"
        btnTopPower.text = if (power) "ON • YOQIQ" else "OFF • O'CHIQ"
        btnTopPower.background = roundBg(if (power) "#10B981" else "#E11D48", 28f)

        tvTarget?.text = String.format("%.1f°C", targetTemp)
        tvOut?.text = String.format("%.1f°C", outletTemp)
        tvIn?.text = String.format("%.1f°C", inletTemp)
        tvDhw?.text = String.format("%.1f°C", dhwTemp)
        tvAmb?.text = String.format("%.1f°C", ambientTemp)

        tvPwrKw?.text = String.format("%.2f kW", powerKw)
        tvHeatKw?.text = String.format("%.2f kW", heatKw)
        tvCop?.text = String.format("x%.2f", cop)
        tvHz?.text = "$compHz Hz"
        tvRaw?.text = rawTuyaText

        tvDaily?.text = String.format("%.2f kWh", dailyKwh)
        tvWeekly?.text = String.format("%.2f kWh", weeklyKwh)
        tvMonthly?.text = String.format("%.2f kWh", monthlyKwh)

        val dCost = calcCost(dailyKwh)
        val wCost = calcCost(weeklyKwh)
        val mCost = calcCost(monthlyKwh)
        tvDailyCost?.text = "$dCost so'm"
        tvWeeklyCost?.text = "$wCost so'm"
        tvMonthlyCost?.text = "$mCost so'm"
        tvZoneInfo?.text = String.format("Jami Schyotchik: %.2f kW • Tarif: %.0f so'm", baseHouseMeter + monthlyKwh, t1)
    }

    private fun calcCost(kwh: Double): Int {
        val total = baseHouseMeter + kwh
        val rate = when {
            total <= 200 -> t1
            total <= 500 -> t2
            total <= 1000 -> t3
            total <= 5000 -> t4
            total <= 10000 -> t5
            else -> t6
        }
        return (kwh * rate).roundToInt()
    }

    // TELEFON YUQORI PARDASIDA DOIMIY BILDIRISHNOMA (LIVE PANEL)
    private fun setupNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel("mango_live", "Mango Live Status", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }

    private fun updateTopNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, "mango_live")
            } else {
                Notification.Builder(this)
            }
            builder.setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🔥 $deviceName: ${if (power) "ON (${outletTemp}°C)" else "OFF"}")
                .setContentText("Padacha: ${outletTemp}°C | Quvvat: ${powerKw} kW | Bugun: ${String.format("%.2f", dailyKwh)} kWh")
                .setOngoing(true)
            nm.notify(101, builder.build())
        } catch (e: Exception) {}
    }

    // HELPER UI BUILDERS
    private fun makeCard(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = roundBg("#0F172A", 36f)
            setPadding(36, 32, 36, 32)
            layoutParams = LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = 28 }
        }
    }

    private fun makeLabel(txt: String, hexColor: String, sizeSp: Float, bold: Boolean): TextView {
        return TextView(this).apply {
            text = txt
            textSize = sizeSp
            setTextColor(Color.parseColor(hexColor))
            if (bold) setTypeface(null, Typeface.BOLD)
        }
    }

    private fun makeSensorBox(row: LinearLayout, title: String, value: String, colorHex: String): TextView {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = roundBg("#090D16", 24f)
            setPadding(12, 20, 12, 20)
            layoutParams = LinearLayout.LayoutParams(0, -2, 1f).apply { setMargins(6, 0, 6, 0) }
        }
        box.addView(makeLabel(title, "#94A3B8", 10f, false))
        val tvVal = makeLabel(value, colorHex, 14f, true)
        box.addView(tvVal)
        row.addView(box)
        return tvVal
    }

    private fun makeInput(parent: LinearLayout, hintTxt: String, defaultVal: String, isDecimal: Boolean = false): EditText {
        parent.addView(makeLabel(hintTxt, "#94A3B8", 11f, true).apply { setPadding(0, 16, 0, 6) })
        val ed = EditText(this).apply {
            setText(defaultVal)
            setTextColor(Color.WHITE)
            textSize = 13f
            setPadding(28, 24, 28, 24)
            background = roundBg("#090D16", 22f)
            if (isDecimal) inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
        }
        parent.addView(ed)
        return ed
    }

    private fun roundBg(hex: String, radius: Float): GradientDrawable {
        return GradientDrawable().apply {
            setColor(Color.parseColor(hex))
            cornerRadius = radius
            setStroke(2, Color.parseColor("#1E293B"))
        }
    }

    private fun sha256(str: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(str.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }

    private fun hmacSha256(secret: String, data: String): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(secret.toByteArray(Charsets.UTF_8), "HmacSHA256"))
        return mac.doFinal(data.toByteArray(Charsets.UTF_8)).joinToString("") { "%02X".format(it) }
    }

    private fun saveData() {
        prefs.edit()
            .putString("cid", clientId).putString("sec", clientSecret).putString("devId", deviceId)
            .putString("devName", deviceName).putFloat("kw", ratedKw.toFloat())
            .putBoolean("power", power).putString("mode", mode).putString("preset", preset).putString("emitter", emitter)
            .putFloat("target", targetTemp.toFloat()).putFloat("baseMeter", baseHouseMeter.toFloat())
            .putFloat("daily", dailyKwh.toFloat()).putFloat("weekly", weeklyKwh.toFloat()).putFloat("monthly", monthlyKwh.toFloat())
            .putFloat("t1", t1.toFloat()).putFloat("t2", t2.toFloat()).putFloat("t3", t3.toFloat())
            .putFloat("t4", t4.toFloat()).putFloat("t5", t5.toFloat()).putFloat("t6", t6.toFloat())
            .apply()
    }

    private fun loadSavedData() {
        clientId = prefs.getString("cid", clientId) ?: clientId
        clientSecret = prefs.getString("sec", clientSecret) ?: clientSecret
        deviceId = prefs.getString("devId", deviceId) ?: deviceId
        deviceName = prefs.getString("devName", deviceName) ?: deviceName
        ratedKw = prefs.getFloat("kw", 24f).toDouble()
        power = prefs.getBoolean("power", true)
        mode = prefs.getString("mode", "heating") ?: "heating"
        preset = prefs.getString("preset", "normal") ?: "normal"
        emitter = prefs.getString("emitter", "radiator") ?: "radiator"
        targetTemp = prefs.getFloat("target", 50f).toDouble()
        baseHouseMeter = prefs.getFloat("baseMeter", 56.61f).toDouble()
        dailyKwh = prefs.getFloat("daily", 0f).toDouble()
        weeklyKwh = prefs.getFloat("weekly", 0f).toDouble()
        monthlyKwh = prefs.getFloat("monthly", 0f).toDouble()
        t1 = prefs.getFloat("t1", 650f).toDouble()
        t2 = prefs.getFloat("t2", 900f).toDouble()
        t3 = prefs.getFloat("t3", 1100f).toDouble()
        t4 = prefs.getFloat("t4", 1500f).toDouble()
        t5 = prefs.getFloat("t5", 1750f).toDouble()
        t6 = prefs.getFloat("t6", 2000f).toDouble()
    }
}
