# ==============================================================================
# MANGO ENERGY PRO v3 - TO'LIQ SOZLAMALAR, AKKAUNT, QURILMALAR, BILDIRISHNOMA
# ==============================================================================

$ProjectDir = "C:\MangoEnergyPro"
Set-Location $ProjectDir
New-Item -ItemType Directory -Force -Path "$ProjectDir\www" | Out-Null

$HtmlContent = @'
<!DOCTYPE html>
<html lang="uz">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Mango Energy Pro</title>
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.2.0/crypto-js.min.js"></script>
<style>
  body { background-color: #070b14; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; user-select: none; -webkit-tap-highlight-color: transparent; }
  input, select, textarea { user-select: text; }
  .glass { background: rgba(15, 23, 42, 0.88); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.08); }
  .mango-grad { background: linear-gradient(135deg, #ff7b00 0%, #ffae00 100%); }
  .pulse-dot { animation: pulse 1s infinite; }
  @keyframes pulse { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.35; transform: scale(1.3); } }
  .modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.8); z-index: 100; backdrop-filter: blur(5px); }
  .modal.active { display: flex; }
  .inp { width: 100%; background: #1e293b; color: #fff; font-weight: 700; padding: 8px 10px; border-radius: 10px; margin-top: 4px; border: 1px solid #334155; font-size: 13px; }
  .lbl { font-size: 10px; color: #94a3b8; font-weight: 600; }
  .fld { background: #0f172a; padding: 10px; border-radius: 12px; border: 1px solid #1e293b; }
  .tabbtn { padding: 7px 11px; border-radius: 10px; font-size: 11px; font-weight: 700; white-space: nowrap; color: #94a3b8; }
  .tabbtn.on { background: linear-gradient(135deg, #ff7b00, #ffae00); color: #020617; }
  .sw { width: 42px; height: 24px; border-radius: 99px; background: #334155; position: relative; flex: none; transition: .2s; }
  .sw::after { content: ""; position: absolute; top: 3px; left: 3px; width: 18px; height: 18px; border-radius: 50%; background: #fff; transition: .2s; }
  input.chk:checked + .sw { background: #10b981; }
  input.chk:checked + .sw::after { left: 21px; }
  #toast { position: fixed; left: 50%; top: 14px; transform: translateX(-50%) translateY(-120px); z-index: 300; transition: .3s; max-width: 92%; }
  #toast.show { transform: translateX(-50%) translateY(0); }
</style>
</head>
<body class="pb-24">

<div id="toast" class="glass rounded-2xl px-4 py-3 text-xs font-bold border border-orange-500/40 shadow-xl"></div>

<!-- TOP BAR -->
<div class="sticky top-0 z-50 glass px-4 py-3 flex items-center justify-between border-b border-slate-800/80">
  <div class="flex items-center gap-3">
    <img src="mango_icon.png" onerror="this.style.display='none'" class="w-10 h-10 rounded-xl shadow-lg border border-orange-500/40">
    <div>
      <div class="font-extrabold text-base tracking-wide flex items-center gap-2">
        MANGO PRO <span class="text-[10px] px-2 py-0.5 rounded-md bg-orange-500/20 text-orange-400 border border-orange-500/30" id="badgeEmitter">PRO</span>
      </div>
      <div class="text-[11px] text-slate-400 flex items-center gap-1.5 mt-0.5">
        <span id="connDot" class="w-2 h-2 rounded-full bg-amber-400 pulse-dot"></span>
        <span id="connText">Tuya Direct • <b id="lastUpd" class="text-slate-200">--:--:--</b></span>
      </div>
    </div>
  </div>
  <div class="flex items-center gap-2">
    <button onclick="openAlerts()" class="relative w-10 h-10 rounded-xl bg-slate-800/80 border border-slate-700 flex items-center justify-center text-lg active:scale-95 shadow">🔔<span id="alertBadge" class="hidden absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-rose-600 text-[10px] font-black flex items-center justify-center">0</span></button>
    <button onclick="openSettings()" class="w-10 h-10 rounded-xl bg-slate-800/80 border border-slate-700 flex items-center justify-center text-lg active:scale-95 shadow">⚙️</button>
    <button onclick="togglePower()" id="pwrBtn" class="px-4 py-2.5 rounded-xl font-extrabold text-xs shadow-lg transition-all active:scale-95">
      YUKLANMOQDA...
    </button>
  </div>
</div>

<div class="max-w-xl mx-auto p-3.5 space-y-3.5">

  <!-- BIRINCHI SOZLASH BANNERI -->
  <div id="setupBanner" class="hidden glass rounded-2xl p-4 border border-orange-500/40">
    <div class="font-extrabold text-sm text-orange-400">👋 Xush kelibsiz!</div>
    <div class="text-xs text-slate-300 mt-1">Boshlash uchun Tuya akkauntingizni ulang va teplovoy nasosingizni qo'shing.</div>
    <button onclick="openSettings('account')" class="mt-3 px-4 py-2 rounded-xl mango-grad text-slate-950 font-extrabold text-xs">Akkaunt ulash →</button>
  </div>

  <!-- QURILMA TANLASH -->
  <div id="devBar" class="glass rounded-2xl p-3 flex items-center justify-between border border-slate-800">
    <div class="min-w-0">
      <div class="text-[10px] text-slate-400">Faol qurilma</div>
      <div class="text-sm font-extrabold truncate" id="devName">—</div>
    </div>
    <select id="devSelect" onchange="switchDevice(this.value)" class="bg-slate-800 border border-slate-700 rounded-lg text-xs font-bold px-2 py-1.5 max-w-[50%]"></select>
  </div>

  <!-- FANKOIL / RADIATOR -->
  <div class="glass rounded-2xl p-3 flex items-center justify-between border border-slate-800">
    <div>
      <div class="text-xs font-bold text-slate-300">Issiqlik Tizimi Turi</div>
      <div class="text-[10px] text-slate-400" id="sysModeDesc">Radiator rejimi</div>
    </div>
    <div class="flex bg-slate-900 p-1 rounded-xl border border-slate-800">
      <button onclick="setSysMode('radiator')" id="btnRad" class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all">♨️ Radiator</button>
      <button onclick="setSysMode('fancoil')" id="btnFan" class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all">🌀 Fankoil</button>
    </div>
  </div>

  <!-- ASOSIY HARORAT -->
  <div class="glass rounded-3xl p-5 relative overflow-hidden">
    <div class="flex justify-between items-center mb-4">
      <div>
        <span class="text-[11px] uppercase tracking-wider text-slate-400 font-semibold">Maqsadli Harorat (Set Temp)</span>
        <div class="text-4xl font-black text-orange-400 mt-0.5"><span id="targetTemp">45.0</span>°C</div>
      </div>
      <div class="flex items-center gap-2.5">
        <button onclick="changeTemp(-1)" class="w-12 h-12 rounded-2xl bg-slate-800 active:scale-90 text-2xl font-bold border border-slate-700 shadow">-</button>
        <button onclick="changeTemp(1)" class="w-12 h-12 rounded-2xl mango-grad text-slate-950 active:scale-90 text-2xl font-black shadow-lg shadow-orange-500/20">+</button>
      </div>
    </div>

    <div class="grid grid-cols-4 gap-2 text-center pt-3 border-t border-slate-800/80">
      <div class="bg-slate-900/90 p-2.5 rounded-2xl border border-slate-800/60">
        <div class="text-[10px] text-slate-400">Padacha</div>
        <div class="text-base font-extrabold text-red-400 mt-0.5"><span id="outTemp">--</span>°C</div>
      </div>
      <div class="bg-slate-900/90 p-2.5 rounded-2xl border border-slate-800/60">
        <div class="text-[10px] text-slate-400">Obratka</div>
        <div class="text-base font-extrabold text-sky-400 mt-0.5"><span id="inTemp">--</span>°C</div>
      </div>
      <div class="bg-slate-900/90 p-2.5 rounded-2xl border border-slate-800/60">
        <div class="text-[10px] text-slate-400">Bufer/GVS</div>
        <div class="text-base font-extrabold text-amber-400 mt-0.5"><span id="dhwTemp">--</span>°C</div>
      </div>
      <div class="bg-slate-900/90 p-2.5 rounded-2xl border border-slate-800/60">
        <div class="text-[10px] text-slate-400">Ko'cha</div>
        <div class="text-base font-extrabold text-emerald-400 mt-0.5"><span id="ambTemp">--</span>°C</div>
      </div>
    </div>
  </div>

  <!-- JONLI TELEMETRIYA -->
  <div class="grid grid-cols-3 gap-2.5">
    <div class="glass p-3.5 rounded-2xl">
      <div class="text-[11px] text-slate-400">Elektr Quvvati</div>
      <div class="text-xl font-black text-white mt-0.5"><span id="pwrKw">0.00</span> <span class="text-xs font-normal text-slate-400">kW</span></div>
      <div class="text-[11px] text-orange-400 mt-1">Kompr: <span id="compHz">0</span> Hz</div>
    </div>
    <div class="glass p-3.5 rounded-2xl">
      <div class="text-[11px] text-slate-400">Issiqlik Quvvati</div>
      <div class="text-xl font-black text-emerald-400 mt-0.5"><span id="heatKw">0.00</span> <span class="text-xs font-normal text-slate-400">kW</span></div>
      <div class="text-[11px] text-slate-400 mt-1">Oqim: <span id="wFlow">0</span> L/m</div>
    </div>
    <div class="glass p-3.5 rounded-2xl">
      <div class="text-[11px] text-slate-400">Samaradorlik (COP)</div>
      <div class="text-xl font-black text-sky-400 mt-0.5">x<span id="copVal">0.00</span></div>
      <div class="text-[11px] text-slate-400 mt-1">Holat: <span id="errCode" class="text-emerald-400 font-bold">OK</span></div>
    </div>
  </div>

  <!-- REJIMLAR -->
  <div class="glass rounded-3xl p-4 space-y-3">
    <div class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Ishlash Rejimi (Mode)</div>
    <div class="grid grid-cols-4 gap-2" id="modeBtns">
      <button onclick="setMode('heating')" data-m="heating" class="py-2.5 rounded-xl text-xs font-bold border border-slate-800">🔥 Isitish</button>
      <button onclick="setMode('cooling')" data-m="cooling" class="py-2.5 rounded-xl text-xs font-bold border border-slate-800">❄️ Sovutish</button>
      <button onclick="setMode('dhw')" data-m="dhw" class="py-2.5 rounded-xl text-xs font-bold border border-slate-800">🚿 Issiq Suv</button>
      <button onclick="setMode('auto')" data-m="auto" class="py-2.5 rounded-xl text-xs font-bold border border-slate-800">🤖 Avto</button>
    </div>

    <div class="text-[11px] font-bold uppercase tracking-wider text-slate-400 pt-1">Quvvat Profili</div>
    <div class="grid grid-cols-4 gap-2" id="presetBtns">
      <button onclick="setPreset('normal')" data-p="normal" class="py-2 rounded-xl text-xs font-bold border border-slate-800">⚖️ Normal</button>
      <button onclick="setPreset('eco')" data-p="eco" class="py-2 rounded-xl text-xs font-bold border border-slate-800">🌿 Eco</button>
      <button onclick="setPreset('boost')" data-p="boost" class="py-2 rounded-xl text-xs font-bold border border-slate-800">⚡ Turbo</button>
      <button onclick="setPreset('silent')" data-p="silent" class="py-2 rounded-xl text-xs font-bold border border-slate-800">🌙 Tungi</button>
    </div>

    <div class="grid grid-cols-3 gap-2 pt-1">
      <button onclick="toggleExtra('weather_comp')" id="btnWeather" class="py-2 px-2 rounded-xl text-[11px] font-bold border border-slate-800">📈 EKD Krivaya</button>
      <button onclick="toggleExtra('defrost')" id="btnDefrost" class="py-2 px-2 rounded-xl text-[11px] font-bold border border-slate-800">🧊 Defrost</button>
      <button onclick="toggleExtra('sterilize')" id="btnLegion" class="py-2 px-2 rounded-xl text-[11px] font-bold border border-slate-800">🛡️ Anti-Legion</button>
    </div>
  </div>

  <!-- QURILMA MA'LUMOTLARI -->
  <div class="glass rounded-3xl p-4 space-y-2.5">
    <div class="flex items-center justify-between">
      <div class="font-extrabold text-sm">📟 Qurilma Ma'lumotlari</div>
      <button onclick="document.getElementById('rawBox').classList.toggle('hidden')" class="text-[11px] px-2.5 py-1 rounded-lg bg-slate-800 border border-slate-700 font-bold">Barcha DP</button>
    </div>
    <div class="grid grid-cols-2 gap-2 text-[11px]">
      <div class="bg-slate-900/90 p-2.5 rounded-xl border border-slate-800"><div class="text-slate-400">Nomi</div><div class="font-bold truncate" id="iName">—</div></div>
      <div class="bg-slate-900/90 p-2.5 rounded-xl border border-slate-800"><div class="text-slate-400">Device ID</div><div class="font-bold truncate" id="iId">—</div></div>
      <div class="bg-slate-900/90 p-2.5 rounded-xl border border-slate-800"><div class="text-slate-400">Server</div><div class="font-bold truncate" id="iSrv">—</div></div>
      <div class="bg-slate-900/90 p-2.5 rounded-xl border border-slate-800"><div class="text-slate-400">Aloqa</div><div class="font-bold truncate" id="iConn">—</div></div>
      <div class="bg-slate-900/90 p-2.5 rounded-xl border border-slate-800"><div class="text-slate-400">Delta T (Padacha-Obratka)</div><div class="font-bold" id="iDelta">—</div></div>
      <div class="bg-slate-900/90 p-2.5 rounded-xl border border-slate-800"><div class="text-slate-400">Ishlash vaqti (seans)</div><div class="font-bold" id="iUp">—</div></div>
    </div>
    <div id="rawBox" class="hidden bg-slate-950 rounded-xl border border-slate-800 p-2.5 max-h-48 overflow-y-auto text-[11px] font-mono text-slate-300"></div>
  </div>

  <!-- STATISTIKA -->
  <div class="glass rounded-3xl p-4 space-y-3.5">
    <div class="flex items-center justify-between">
      <div class="font-extrabold text-sm">📊 Aniq Statistika (Progressiv Tarif)</div>
      <span class="text-[11px] text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-lg border border-emerald-500/20">
        Joriy seans: <b id="curSessMin">0</b> daq (<b id="curSessKwh">0.00</b> kWh)
      </span>
    </div>

    <div class="grid grid-cols-3 gap-2 text-center">
      <div class="bg-slate-900/90 p-3 rounded-2xl border border-slate-800">
        <div class="text-[10px] text-slate-400 font-bold">KUNLIK (Bugun)</div>
        <div class="text-lg font-black text-orange-400 mt-0.5"><span id="dKwh">0.0</span> <span class="text-[10px]">kWh</span></div>
        <div class="text-[10px] text-slate-400 mt-0.5">COP: <b id="dCop">0</b></div>
        <div class="text-[10px] text-emerald-400 font-bold mt-1" id="dUzs">0 so'm</div>
      </div>
      <div class="bg-slate-900/90 p-3 rounded-2xl border border-slate-800">
        <div class="text-[10px] text-slate-400 font-bold">HAFTALIK (7 kun)</div>
        <div class="text-lg font-black text-sky-400 mt-0.5"><span id="wKwh">0.0</span> <span class="text-[10px]">kWh</span></div>
        <div class="text-[10px] text-slate-400 mt-0.5">COP: <b id="wCop">0</b></div>
        <div class="text-[10px] text-emerald-400 font-bold mt-1" id="wUzs">0 so'm</div>
      </div>
      <div class="bg-slate-900/90 p-3 rounded-2xl border border-slate-800">
        <div class="text-[10px] text-slate-400 font-bold">OYLIK (Norma)</div>
        <div class="text-lg font-black text-purple-400 mt-0.5"><span id="mKwh">0.0</span> <span class="text-[10px]">kWh</span></div>
        <div class="text-[10px] text-slate-400 mt-0.5" id="normZone">1-Zona</div>
        <div class="text-[10px] text-emerald-400 font-bold mt-1" id="mUzs">0 so'm</div>
      </div>
    </div>

    <div>
      <div class="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">⏱️ Oxirgi Seanslar Tarixi</div>
      <div class="space-y-1.5 max-h-56 overflow-y-auto" id="sessionsList"></div>
    </div>
  </div>

</div>

<!-- ========== SOZLAMALAR OYNASI ========== -->
<div id="settingsModal" class="modal items-end sm:items-center justify-center p-0 sm:p-4">
  <div class="glass w-full max-w-md rounded-t-3xl sm:rounded-3xl p-4 border border-slate-700 flex flex-col" style="max-height:92vh">
    <div class="flex justify-between items-center pb-3">
      <div class="font-extrabold text-base">⚙️ Sozlamalar</div>
      <button onclick="closeSettings()" class="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center font-bold text-slate-400">✕</button>
    </div>
    <div class="flex gap-1.5 overflow-x-auto pb-2 border-b border-slate-800" id="tabBar"></div>
    <div class="overflow-y-auto flex-1 py-3 space-y-2.5 text-xs" id="tabBody"></div>
    <button onclick="saveSettings()" class="w-full py-3 rounded-xl mango-grad text-slate-950 font-extrabold text-sm shadow-lg mt-2">💾 Saqlash</button>
  </div>
</div>

<!-- ========== XABARLAR OYNASI ========== -->
<div id="alertsModal" class="modal items-center justify-center p-4">
  <div class="glass w-full max-w-md rounded-3xl p-4 border border-slate-700 flex flex-col" style="max-height:85vh">
    <div class="flex justify-between items-center pb-3 border-b border-slate-800">
      <div class="font-extrabold text-base">🔔 Xabarlar tarixi</div>
      <div class="flex gap-2">
        <button onclick="clearAlerts()" class="px-3 h-8 rounded-lg bg-slate-800 text-[11px] font-bold text-slate-300">Tozalash</button>
        <button onclick="closeAlerts()" class="w-8 h-8 rounded-full bg-slate-800 font-bold text-slate-400">✕</button>
      </div>
    </div>
    <div class="overflow-y-auto flex-1 pt-3 space-y-2" id="alertsList"></div>
  </div>
</div>

<script>
// ====================== SOZLAMALAR (CONFIG) ======================
const DEFAULT_CFG = {
  account: { clientId: "", secret: "", region: "auto" },
  devices: [],           // [{id, name}]
  active: 0,
  limits: { min: 15, max: 65, step: 1, radTarget: 50, fanTarget: 40 },
  dp: { switch: "switch", temp_set: "temp_set", mode: "mode", scale: "auto",
        m_heating: "heating", m_cooling: "cooling", m_dhw: "dhw", m_auto: "auto" },
  poll: 5,
  tariffs: { t1: 650, t2: 900, t3: 1100, t4: 1500, l1: 200, l2: 500, l3: 1000, cur: "so'm" },
  notif: { enabled: true, offline: true, error: true, power: true, session: true,
           highOut: 60, lowDhw: 0, freeze: 2, dailyKwh: 0, monthlyKwh: 0,
           cooldown: 30, quiet: false, qFrom: "23:00", qTo: "07:00", vibrate: true }
};

function deepMerge(base, add) {
  const o = Array.isArray(base) ? [...base] : { ...base };
  for (const k in add) {
    if (add[k] && typeof add[k] === "object" && !Array.isArray(add[k]) && base[k] && typeof base[k] === "object") o[k] = deepMerge(base[k], add[k]);
    else o[k] = add[k];
  }
  return o;
}
function loadJSON(k, d) { try { const v = JSON.parse(localStorage.getItem(k)); return v == null ? d : v; } catch (e) { return d; } }

let cfg = deepMerge(DEFAULT_CFG, loadJSON("mango_cfg", {}));
// Eski versiyadan tariflarni ko'chirish
const oldT = loadJSON("mango_tariffs", null);
if (oldT && !localStorage.getItem("mango_cfg")) cfg.tariffs = deepMerge(cfg.tariffs, oldT);
function saveCfg() { localStorage.setItem("mango_cfg", JSON.stringify(cfg)); }

let sysMode = localStorage.getItem("mango_sysmode") || "radiator";
let accessToken = "", tokenExpireTime = 0, activeEndpoint = "", lastScale = 1;
let failCount = 0, wasOffline = false, lastOkTs = 0, lastTick = 0, rawDps = {};
let alertsLog = loadJSON("mango_alerts", []);
let alertCooldown = {};
let unread = 0;

function curDev() { return cfg.devices[cfg.active] || null; }
function devKey(p) { const d = curDev(); return p + (d ? d.id : "none"); }

function freshState() {
  return { power: false, mode: "heating", preset: "normal",
    target_temp: sysMode === "radiator" ? cfg.limits.radTarget : cfg.limits.fanTarget,
    inlet_temp: 15, outlet_temp: 15, ambient_temp: 6, dhw_temp: 18,
    compressor_hz: 0, water_flow: 0, power_kw: 0.02, heat_kw: 0, cop: 0,
    weather_comp: true, defrost: false, sterilize: false, err: "OK" };
}
function freshStats() { return { days: {}, sessions: [], cur: null }; }

let state = freshState();
let statsDB = freshStats();
function loadDeviceData() {
  state = deepMerge(freshState(), loadJSON(devKey("mango_state_"), {}));
  statsDB = deepMerge(freshStats(), loadJSON(devKey("mango_stats_"), {}));
  rawDps = {}; accessToken = ""; tokenExpireTime = 0;
}
function saveDeviceData() {
  localStorage.setItem(devKey("mango_state_"), JSON.stringify(state));
  localStorage.setItem(devKey("mango_stats_"), JSON.stringify(statsDB));
}

// ====================== YORDAMCHI ======================
function $(id) { return document.getElementById(id); }
function dkey(d = new Date()) { return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0"); }
function fmtTime(ts) { const d = new Date(ts); return d.toLocaleDateString("uz", { day: "2-digit", month: "2-digit" }) + " " + d.toTimeString().slice(0, 5); }
function esc(s) { return String(s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])); }
let toastT;
function toast(msg) { const t = $("toast"); t.innerText = msg; t.classList.add("show"); clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove("show"), 3200); }

// ====================== BILDIRISHNOMALAR ======================
function inQuiet() {
  if (!cfg.notif.quiet) return false;
  const n = new Date(), m = n.getHours() * 60 + n.getMinutes();
  const p = s => { const a = s.split(":"); return Number(a[0]) * 60 + Number(a[1]); };
  const f = p(cfg.notif.qFrom), t = p(cfg.notif.qTo);
  return f <= t ? (m >= f && m < t) : (m >= f || m < t);
}
async function sysNotify(title, body) {
  try {
    const LN = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.LocalNotifications;
    if (LN) {
      await LN.schedule({ notifications: [{ id: Math.floor(Date.now() % 2147483647), title, body }] });
      return;
    }
  } catch (e) {}
  try {
    if ("Notification" in window && Notification.permission === "granted") new Notification(title, { body });
  } catch (e) {}
}
function notify(title, body, key, icon) {
  if (!cfg.notif.enabled) return;
  const now = Date.now();
  if (key && alertCooldown[key] && now - alertCooldown[key] < cfg.notif.cooldown * 60000) return;
  if (key) alertCooldown[key] = now;
  alertsLog.unshift({ ts: now, title, body, icon: icon || "🔔" });
  alertsLog = alertsLog.slice(0, 60);
  localStorage.setItem("mango_alerts", JSON.stringify(alertsLog));
  unread++; renderBadge();
  toast((icon || "🔔") + " " + title + " — " + body);
  if (inQuiet()) return;
  sysNotify(title, body);
  if (cfg.notif.vibrate && navigator.vibrate) navigator.vibrate([200, 100, 200]);
}
async function askNotifPermission() {
  try {
    const LN = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.LocalNotifications;
    if (LN) { const r = await LN.requestPermissions(); toast("Ruxsat: " + r.display); return; }
    if ("Notification" in window) { const r = await Notification.requestPermission(); toast("Ruxsat: " + r); return; }
    toast("Bu qurilmada tizim bildirishnomasi yo'q, ilova ichida ko'rsatiladi");
  } catch (e) { toast("Ruxsat so'rashda xato"); }
}
function testNotify() { notify("Test xabar", "Bildirishnomalar ishlayapti ✅", null, "✅"); }
function renderBadge() { const b = $("alertBadge"); if (unread > 0) { b.classList.remove("hidden"); b.innerText = unread > 99 ? "99+" : unread; } else b.classList.add("hidden"); }
function openAlerts() {
  unread = 0; renderBadge();
  $("alertsList").innerHTML = alertsLog.length ? alertsLog.map(a =>
    `<div class="bg-slate-900 border border-slate-800 rounded-xl p-3"><div class="flex justify-between text-[10px] text-slate-400"><span>${esc(a.icon)} ${fmtTime(a.ts)}</span></div><div class="text-xs font-extrabold mt-1">${esc(a.title)}</div><div class="text-[11px] text-slate-300 mt-0.5">${esc(a.body)}</div></div>`
  ).join("") : `<div class="text-center text-xs text-slate-500 py-6">Hozircha xabarlar yo'q.</div>`;
  $("alertsModal").classList.add("active");
}
function closeAlerts() { $("alertsModal").classList.remove("active"); }
function clearAlerts() { alertsLog = []; localStorage.setItem("mango_alerts", "[]"); openAlerts(); }

// ====================== TARIF ======================
function calculateCost(totalKwh) {
  const T = cfg.tariffs;
  const lim = [T.l1, T.l2, T.l3], rate = [T.t1, T.t2, T.t3, T.t4];
  let cost = 0, prev = 0, zone = 4;
  for (let i = 0; i < 3; i++) {
    const part = Math.max(0, Math.min(totalKwh, lim[i]) - prev);
    cost += part * rate[i]; prev = lim[i];
    if (totalKwh <= lim[i]) { zone = i + 1; break; }
  }
  if (totalKwh > lim[2]) cost += (totalKwh - lim[2]) * rate[3];
  return { cost, zone: zone + "-Zona (" + rate[zone - 1] + ")" };
}

// ====================== STATISTIKA ======================
function addEnergy(e, h) {
  const k = dkey();
  if (!statsDB.days[k]) statsDB.days[k] = { e: 0, h: 0 };
  statsDB.days[k].e += e; statsDB.days[k].h += h;
  if (statsDB.cur) { statsDB.cur.e += e; statsDB.cur.h += h; }
  const keys = Object.keys(statsDB.days).sort();
  while (keys.length > 70) delete statsDB.days[keys.shift()];
}
function agg() {
  const t = dkey(), mk = t.slice(0, 7);
  const today0 = new Date(); today0.setHours(0, 0, 0, 0);
  const d = { e: 0, h: 0 }, w = { e: 0, h: 0 }, m = { e: 0, h: 0 };
  for (const k in statsDB.days) {
    const v = statsDB.days[k];
    const diff = Math.round((today0 - new Date(k + "T00:00:00")) / 864e5);
    if (k === t) { d.e += v.e; d.h += v.h; }
    if (diff >= 0 && diff < 7) { w.e += v.e; w.h += v.h; }
    if (k.startsWith(mk)) { m.e += v.e; m.h += v.h; }
  }
  return { d, w, m };
}
function applyPower(v) {
  v = Boolean(v);
  if (v === state.power) return;
  const was = state.power;
  state.power = v;
  if (v && !was) {
    statsDB.cur = { start: Date.now(), e: 0, h: 0 };
    if (cfg.notif.power) notify("Nasos yoqildi", (curDev() ? curDev().name : "Qurilma") + " ishga tushdi", "pwr_on", "🟢");
  }
  if (!v && was) {
    if (statsDB.cur) {
      const mins = Math.round((Date.now() - statsDB.cur.start) / 60000);
      if (mins >= 1 || statsDB.cur.e > 0.01) {
        statsDB.sessions.unshift({ start: statsDB.cur.start, end: Date.now(), min: mins, e: statsDB.cur.e, h: statsDB.cur.h });
        statsDB.sessions = statsDB.sessions.slice(0, 40);
        if (cfg.notif.session) notify("Seans tugadi", mins + " daq, " + statsDB.cur.e.toFixed(2) + " kWh sarflandi", null, "⏱️");
      }
    }
    statsDB.cur = null;
    if (cfg.notif.power) notify("Nasos o'chdi", (curDev() ? curDev().name : "Qurilma") + " to'xtadi", "pwr_off", "🔴");
  }
}

// ====================== TUYA API ======================
function endpointList() {
  const all = ["https://openapi.tuyaeu.com", "https://openapi.tuyacn.com", "https://openapi.tuyaus.com", "https://openapi.tuyain.com"];
  return cfg.account.region === "auto" ? all : [cfg.account.region];
}
function signTuyaRequest(method, path, bodyStr = "", token = "") {
  const t = Date.now().toString();
  const contentHash = CryptoJS.SHA256(bodyStr).toString(CryptoJS.enc.Hex);
  const stringToSign = [method, contentHash, "", path].join("\n");
  const signStr = cfg.account.clientId + token + t + stringToSign;
  const sign = CryptoJS.HmacSHA256(signStr, cfg.account.secret).toString(CryptoJS.enc.Hex).toUpperCase();
  const headers = { client_id: cfg.account.clientId, sign: sign, t: t, sign_method: "HMAC-SHA256", "Content-Type": "application/json" };
  if (token) headers["access_token"] = token;
  return headers;
}
async function ensureToken() {
  if (accessToken && Date.now() < tokenExpireTime && activeEndpoint) return true;
  const p = "/v1.0/token?grant_type=1";
  let lastMsg = "Token olinmadi";
  for (const ep of endpointList()) {
    try {
      const r = await fetch(ep + p, { method: "GET", headers: signTuyaRequest("GET", p, "", "") });
      const data = await r.json();
      if (data && data.success && data.result) {
        accessToken = data.result.access_token;
        tokenExpireTime = Date.now() + (data.result.expire_time - 60) * 1000;
        activeEndpoint = ep;
        return true;
      }
      if (data && data.msg) lastMsg = data.msg;
    } catch (e) { lastMsg = "Tarmoq xatosi"; }
  }
  ensureToken.lastMsg = lastMsg;
  return false;
}
async function tuyaFetch(method, path, bodyObj = null) {
  if (!cfg.account.clientId || !cfg.account.secret) throw new Error("Akkaunt ulanmagan");
  const ok = await ensureToken();
  if (!ok) throw new Error(ensureToken.lastMsg || "Token xatosi");
  const bodyStr = bodyObj ? JSON.stringify(bodyObj) : "";
  const headers = signTuyaRequest(method, path, bodyStr, accessToken);
  const res = await fetch(activeEndpoint + path, { method, headers, body: bodyObj ? bodyStr : undefined });
  return await res.json();
}
async function sendCommand(code, value) {
  const d = curDev();
  if (!d) { toast("Avval qurilma qo'shing"); return false; }
  try {
    const res = await tuyaFetch("POST", `/v1.0/iot-03/devices/${d.id}/commands`, { commands: [{ code, value }] });
    if (!res.success) { toast("Buyruq xatosi: " + (res.msg || "noma'lum")); return false; }
    return true;
  } catch (e) { toast("Buyruq yuborilmadi: " + e.message); return false; }
}
const toC = v => { v = Number(v); return v > 100 ? v / 10 : v; };
const scaled = v => { v = Number(v); const s = cfg.dp.scale === "auto" ? (v > 100 ? 10 : lastScale) : Number(cfg.dp.scale); if (cfg.dp.scale === "auto" && v > 100) lastScale = 10; return v / s; };

function parseStatus(list) {
  rawDps = {};
  let kw = null, heat = null, cop = null, flow = null, errv = null;
  list.forEach(item => {
    const k = String(item.code).toLowerCase(), v = item.value;
    rawDps[item.code] = v;
    if (k === cfg.dp.switch.toLowerCase() || k === "switch" || k === "power") { if (typeof v === "boolean") applyPower(v); }
    else if (k === cfg.dp.temp_set.toLowerCase() || k.includes("temp_set")) state.target_temp = scaled(v);
    else if (k === cfg.dp.mode.toLowerCase() || k === "mode") {
      for (const m of ["heating", "cooling", "dhw", "auto"]) if (String(v).toLowerCase() === String(cfg.dp["m_" + m]).toLowerCase()) state.mode = m;
    }
    else if (/fault|error|err_|alarm/.test(k)) { if (v && v !== 0 && v !== "0" && v !== false) errv = String(v); }
    else if (k.includes("out") || k.includes("supply")) state.outlet_temp = scaled(v);
    else if (/(^|_)in(let)?($|_|\d)|return|back/.test(k)) state.inlet_temp = scaled(v);
    else if (k.includes("amb")) state.ambient_temp = scaled(v);
    else if (k.includes("dhw") || k.includes("tank")) state.dhw_temp = scaled(v);
    else if (k.includes("freq")) state.compressor_hz = Number(v);
    else if (k.includes("cop")) cop = Number(v) > 20 ? Number(v) / 100 : Number(v);
    else if (k.includes("flow")) flow = Number(v);
    else if (/heat.*(kw|power)|capacity/.test(k)) heat = Number(v) > 100 ? Number(v) / 1000 : Number(v);
    else if (/(cur_)?power|electric|watt/.test(k) && typeof v === "number") kw = v > 100 ? v / 1000 : v;
  });
  state.err = errv || "OK";
  if (!state.power) {
    state.outlet_temp = state.ambient_temp; state.inlet_temp = state.ambient_temp;
    state.compressor_hz = 0; state.power_kw = 0.02; state.heat_kw = 0; state.cop = 0; state.water_flow = 0;
  } else {
    state.power_kw = kw != null ? kw : 2.85;
    const dT = Math.max(0, state.outlet_temp - state.inlet_temp);
    state.water_flow = flow != null ? flow : 28.1;
    state.heat_kw = heat != null ? heat : (dT > 0.5 ? state.water_flow / 60 * 4.186 * dT : 14.14);
    state.cop = cop != null ? cop : (state.power_kw > 0 ? state.heat_kw / state.power_kw : 0);
  }
}

function checkAlerts() {
  const N = cfg.notif, nm = curDev() ? curDev().name : "Qurilma";
  if (N.error && state.err !== "OK") notify("Nosozlik: " + state.err, nm + " xato kodi berdi", "err_" + state.err, "⚠️");
  if (N.highOut > 0 && state.power && state.outlet_temp >= N.highOut) notify("Padacha harorati yuqori", state.outlet_temp.toFixed(1) + "°C (chegara " + N.highOut + "°C)", "highout", "🌡️");
  if (N.lowDhw > 0 && state.dhw_temp <= N.lowDhw) notify("Issiq suv sovib ketdi", "Bufer/GVS: " + state.dhw_temp.toFixed(1) + "°C", "lowdhw", "🚿");
  if (N.freeze !== "" && !state.power && state.ambient_temp <= Number(N.freeze)) notify("Muzlash xavfi!", "Ko'cha " + state.ambient_temp.toFixed(1) + "°C, nasos o'chiq", "freeze", "🥶");
  const a = agg();
  if (N.dailyKwh > 0 && a.d.e >= N.dailyKwh) notify("Kunlik limit oshdi", a.d.e.toFixed(1) + " kWh (limit " + N.dailyKwh + ")", "dlimit", "⚡");
  if (N.monthlyKwh > 0 && a.m.e >= N.monthlyKwh) notify("Oylik limit oshdi", a.m.e.toFixed(1) + " kWh (limit " + N.monthlyKwh + ")", "mlimit", "⚡");
}

async function pollTuyaDevice() {
  const d = curDev();
  $("lastUpd").innerText = new Date().toTimeString().split(" ")[0];
  if (!d || !cfg.account.clientId) {
    $("connDot").className = "w-2 h-2 rounded-full bg-slate-500";
    renderUI(); return;
  }
  const now = Date.now();
  try {
    const res = await tuyaFetch("GET", `/v1.0/iot-03/devices/${d.id}/status`);
    if (res && res.success && Array.isArray(res.result)) {
      parseStatus(res.result);
      failCount = 0; lastOkTs = now;
      $("connDot").className = "w-2 h-2 rounded-full bg-emerald-400 pulse-dot";
      if (wasOffline) { wasOffline = false; if (cfg.notif.offline) notify("Aloqa tiklandi", d.name + " yana onlayn", "online", "✅"); }
    } else {
      throw new Error((res && res.msg) || "Javob xato");
    }
  } catch (e) {
    failCount++; state.err = failCount >= 3 ? "Aloqa yo'q" : state.err;
    $("connDot").className = "w-2 h-2 rounded-full bg-amber-400 pulse-dot";
    $("iConn").innerText = e.message;
    if (failCount >= 3 && !wasOffline) { wasOffline = true; if (cfg.notif.offline) notify("Aloqa uzildi", d.name + ": " + e.message, "offline", "📡"); }
  }

  // Energiya hisobi
  if (lastTick && state.power) {
    const dt = Math.min(now - lastTick, 120000) / 3.6e6;
    addEnergy(state.power_kw * dt, state.heat_kw * dt);
  }
  lastTick = now;
  if (failCount === 0) checkAlerts();
  saveDeviceData();
  renderUI();
}
async function pollLoop() {
  try { await pollTuyaDevice(); } catch (e) {}
  setTimeout(pollLoop, Math.max(2, Number(cfg.poll) || 5) * 1000);
}

// ====================== BOSHQARUV ======================
function setSysMode(m) {
  sysMode = m; localStorage.setItem("mango_sysmode", m);
  state.target_temp = m === "fancoil" ? cfg.limits.fanTarget : cfg.limits.radTarget;
  sendCommand(cfg.dp.temp_set, Math.round(state.target_temp * (cfg.dp.scale === "auto" ? lastScale : Number(cfg.dp.scale))));
  renderUI();
}
async function togglePower() {
  if (!curDev()) { toast("Avval qurilma qo'shing"); openSettings("account"); return; }
  const nv = !state.power;
  applyPower(nv); renderUI();
  const ok = await sendCommand(cfg.dp.switch, nv);
  if (!ok) { applyPower(!nv); renderUI(); }
  saveDeviceData();
}
let tempT;
function changeTemp(dir) {
  const L = cfg.limits;
  state.target_temp = Math.max(L.min, Math.min(L.max, +(state.target_temp + dir * L.step).toFixed(1)));
  renderUI();
  clearTimeout(tempT);
  tempT = setTimeout(() => sendCommand(cfg.dp.temp_set, Math.round(state.target_temp * (cfg.dp.scale === "auto" ? lastScale : Number(cfg.dp.scale)))), 700);
}
function setMode(m) { state.mode = m; sendCommand(cfg.dp.mode, cfg.dp["m_" + m]); renderUI(); }
function setPreset(p) { state.preset = p; renderUI(); }
function toggleExtra(k) { state[k] = !state[k]; renderUI(); }
function switchDevice(i) {
  saveDeviceData(); cfg.active = Number(i); saveCfg();
  loadDeviceData(); lastTick = 0; failCount = 0; wasOffline = false;
  renderUI(); pollTuyaDevice();
}

// ====================== INTERFEYS ======================
function renderUI() {
  const d = curDev();
  $("setupBanner").classList.toggle("hidden", !!(d && cfg.account.clientId));
  $("devBar").classList.toggle("hidden", cfg.devices.length === 0);
  $("devName").innerText = d ? d.name : "—";
  $("devSelect").innerHTML = cfg.devices.map((x, i) => `<option value="${i}" ${i === cfg.active ? "selected" : ""}>${esc(x.name)}</option>`).join("");

  const pBtn = $("pwrBtn");
  pBtn.innerText = state.power ? "ON • ISHLAMOQDA" : "OFF • O'CHIQ";
  pBtn.className = state.power
    ? "px-4 py-2.5 rounded-xl font-extrabold text-xs bg-emerald-500 text-slate-950 shadow-lg shadow-emerald-500/30"
    : "px-4 py-2.5 rounded-xl font-extrabold text-xs bg-rose-600 text-white shadow-lg";

  $("targetTemp").innerText = state.target_temp.toFixed(1);
  $("outTemp").innerText = state.outlet_temp.toFixed(1);
  $("inTemp").innerText = state.inlet_temp.toFixed(1);
  $("dhwTemp").innerText = state.dhw_temp.toFixed(1);
  $("ambTemp").innerText = state.ambient_temp.toFixed(1);
  $("pwrKw").innerText = state.power_kw.toFixed(2);
  $("heatKw").innerText = state.heat_kw.toFixed(2);
  $("copVal").innerText = state.cop.toFixed(2);
  $("compHz").innerText = state.compressor_hz;
  $("wFlow").innerText = state.water_flow.toFixed(1);
  const ec = $("errCode"); ec.innerText = state.err;
  ec.className = (state.err === "OK" ? "text-emerald-400" : "text-rose-400") + " font-bold";

  const on = "mango-grad text-slate-950 shadow", off = "text-slate-400";
  $("btnRad").className = "px-3 py-1.5 rounded-lg text-xs font-bold " + (sysMode === "radiator" ? on : off);
  $("btnFan").className = "px-3 py-1.5 rounded-lg text-xs font-bold " + (sysMode === "fancoil" ? on : off);
  $("sysModeDesc").innerText = sysMode === "radiator" ? "Radiator rejimi (Maqsad: " + cfg.limits.radTarget + "°C)" : "Fankoil rejimi (Maqsad: " + cfg.limits.fanTarget + "°C)";

  document.querySelectorAll("#modeBtns button").forEach(b => b.className = "py-2.5 rounded-xl text-xs font-bold border " + (b.dataset.m === state.mode ? "mango-grad text-slate-950 border-transparent" : "border-slate-800"));
  document.querySelectorAll("#presetBtns button").forEach(b => b.className = "py-2 rounded-xl text-xs font-bold border " + (b.dataset.p === state.preset ? "mango-grad text-slate-950 border-transparent" : "border-slate-800"));
  [["btnWeather", "weather_comp"], ["btnDefrost", "defrost"], ["btnLegion", "sterilize"]].forEach(([id, k]) => {
    $(id).className = "py-2 px-2 rounded-xl text-[11px] font-bold border " + (state[k] ? "bg-emerald-500/20 text-emerald-300 border-emerald-500/40" : "border-slate-800");
  });

  // Qurilma ma'lumotlari
  $("iName").innerText = d ? d.name : "—";
  $("iId").innerText = d ? d.id : "—";
  $("iSrv").innerText = activeEndpoint ? activeEndpoint.replace("https://openapi.", "").replace(".com", "").toUpperCase() : "—";
  if (failCount === 0 && lastOkTs) $("iConn").innerText = "Onlayn";
  $("iDelta").innerText = state.power ? (state.outlet_temp - state.inlet_temp).toFixed(1) + " °C" : "—";
  $("iUp").innerText = statsDB.cur ? Math.round((Date.now() - statsDB.cur.start) / 60000) + " daq" : "—";
  const keys = Object.keys(rawDps);
  $("rawBox").innerHTML = keys.length ? keys.map(k => `<div class="flex justify-between gap-2"><span class="text-orange-300">${esc(k)}</span><span class="truncate">${esc(JSON.stringify(rawDps[k]))}</span></div>`).join("") : "Ma'lumot kelmagan";

  // Statistika
  const a = agg(), cu = cfg.tariffs.cur;
  const mCost = calculateCost(a.m.e);
  const share = p => Math.round(mCost.cost - calculateCost(Math.max(0, a.m.e - p)).cost).toLocaleString() + " " + cu;
  $("dKwh").innerText = a.d.e.toFixed(1); $("dCop").innerText = a.d.e > 0.01 ? (a.d.h / a.d.e).toFixed(2) : "0";
  $("dUzs").innerText = share(a.d.e);
  $("wKwh").innerText = a.w.e.toFixed(1); $("wCop").innerText = a.w.e > 0.01 ? (a.w.h / a.w.e).toFixed(2) : "0";
  $("wUzs").innerText = share(a.w.e);
  $("mKwh").innerText = a.m.e.toFixed(1);
  $("mUzs").innerText = Math.round(mCost.cost).toLocaleString() + " " + cu;
  $("normZone").innerText = mCost.zone;
  $("curSessMin").innerText = statsDB.cur ? Math.round((Date.now() - statsDB.cur.start) / 60000) : 0;
  $("curSessKwh").innerText = statsDB.cur ? statsDB.cur.e.toFixed(2) : "0.00";
  $("sessionsList").innerHTML = statsDB.sessions.length ? statsDB.sessions.slice(0, 20).map(s =>
    `<div class="flex items-center justify-between bg-slate-900/90 border border-slate-800 rounded-xl px-3 py-2 text-[11px]"><span class="text-slate-300">${fmtTime(s.start)}</span><span class="text-slate-400">${s.min} daq</span><span class="font-bold text-orange-400">${s.e.toFixed(2)} kWh</span><span class="text-sky-400">COP ${s.e > 0.01 ? (s.h / s.e).toFixed(1) : "0"}</span></div>`
  ).join("") : `<div class="text-center text-xs text-slate-500 py-3">Hozircha seanslar yo'q. Nasos ishlaganda yozib boriladi.</div>`;
}

// ====================== SOZLAMALAR OYNASI ======================
const TABS = [["account", "👤 Akkaunt"], ["devices", "📟 Qurilmalar"], ["system", "🌡️ Tizim"], ["tariff", "💰 Tarif"], ["notif", "🔔 Xabarlar"], ["adv", "🔧 Qo'shimcha"], ["data", "💾 Ma'lumot"]];
const SCHEMA = {
  account: [
    { k: "account.clientId", l: "Tuya Client ID (Access ID)", t: "text" },
    { k: "account.secret", l: "Tuya Client Secret (Access Secret)", t: "password" },
    { k: "account.region", l: "Server mintaqasi (Data Center)", t: "select", o: [["auto", "Avtomatik topish"], ["https://openapi.tuyaeu.com", "Yevropa (EU)"], ["https://openapi.tuyacn.com", "Xitoy (CN)"], ["https://openapi.tuyaus.com", "AQSh (US)"], ["https://openapi.tuyain.com", "Hindiston (IN)"]] }
  ],
  system: [
    { k: "limits.radTarget", l: "Radiator: standart harorat (°C)", t: "number" },
    { k: "limits.fanTarget", l: "Fankoil: standart harorat (°C)", t: "number" },
    { k: "limits.min", l: "Minimal harorat (°C)", t: "number" },
    { k: "limits.max", l: "Maksimal harorat (°C)", t: "number" },
    { k: "limits.step", l: "+/- tugma qadami (°C)", t: "number", step: "0.5" },
    { k: "poll", l: "Ma'lumot yangilash (soniya, min 2)", t: "number" }
  ],
  tariff: [
    { k: "tariffs.t1", l: "1-zona narxi", t: "number" }, { k: "tariffs.l1", l: "1-zona chegarasi (kWh gacha)", t: "number" },
    { k: "tariffs.t2", l: "2-zona narxi", t: "number" }, { k: "tariffs.l2", l: "2-zona chegarasi (kWh gacha)", t: "number" },
    { k: "tariffs.t3", l: "3-zona narxi", t: "number" }, { k: "tariffs.l3", l: "3-zona chegarasi (kWh gacha)", t: "number" },
    { k: "tariffs.t4", l: "4-zona narxi (chegaradan yuqori)", t: "number" },
    { k: "tariffs.cur", l: "Valyuta belgisi", t: "text" }
  ],
  notif: [
    { k: "notif.enabled", l: "Bildirishnomalar yoqilgan", t: "check" },
    { k: "notif.offline", l: "Aloqa uzilsa / tiklansa", t: "check" },
    { k: "notif.error", l: "Nosozlik (xato kodi) bo'lsa", t: "check" },
    { k: "notif.power", l: "Nasos yoqilsa / o'chsa", t: "check" },
    { k: "notif.session", l: "Seans tugaganda hisobot", t: "check" },
    { k: "notif.vibrate", l: "Tebranish", t: "check" },
    { k: "notif.highOut", l: "Padacha harorati shundan oshsa (°C, 0 = o'chiq)", t: "number" },
    { k: "notif.lowDhw", l: "Issiq suv shundan pasaysa (°C, 0 = o'chiq)", t: "number" },
    { k: "notif.freeze", l: "Nasos o'chiq va ko'cha shundan sovuq (°C)", t: "number" },
    { k: "notif.dailyKwh", l: "Kunlik kWh limit (0 = o'chiq)", t: "number" },
    { k: "notif.monthlyKwh", l: "Oylik kWh limit (0 = o'chiq)", t: "number" },
    { k: "notif.cooldown", l: "Bir xil xabar oralig'i (daqiqa)", t: "number" },
    { k: "notif.quiet", l: "Tinch soatlar (tizim xabari yo'q)", t: "check" },
    { k: "notif.qFrom", l: "Tinch soat boshlanishi", t: "time" },
    { k: "notif.qTo", l: "Tinch soat tugashi", t: "time" }
  ],
  adv: [
    { k: "dp.switch", l: "Yoqish/o'chirish DP kodi", t: "text" },
    { k: "dp.temp_set", l: "Maqsadli harorat DP kodi", t: "text" },
    { k: "dp.mode", l: "Rejim DP kodi", t: "text" },
    { k: "dp.scale", l: "Harorat masshtabi", t: "select", o: [["auto", "Avto"], ["1", "x1 (25 = 25°C)"], ["10", "x10 (250 = 25.0°C)"]] },
    { k: "dp.m_heating", l: "Rejim qiymati: Isitish", t: "text" },
    { k: "dp.m_cooling", l: "Rejim qiymati: Sovutish", t: "text" },
    { k: "dp.m_dhw", l: "Rejim qiymati: Issiq suv", t: "text" },
    { k: "dp.m_auto", l: "Rejim qiymati: Avto", t: "text" }
  ]
};
const HINTS = {
  account: "Tuya IoT Platform (iot.tuya.com) → Cloud → Project → Overview dan Access ID va Access Secret ni oling. Qurilmangiz ulangan Smart Life ilovasi shu loyihaga bog'langan bo'lishi kerak.",
  adv: "Bu yerni faqat qurilmangiz DP kodlari boshqacha bo'lsa o'zgartiring. Asosiy ekrandagi «Barcha DP» tugmasi qurilma yuborayotgan kodlarni ko'rsatadi."
};
let curTab = "account";
function getPath(o, p) { return p.split(".").reduce((a, k) => a && a[k], o); }
function setPath(o, p, v) { const a = p.split("."); const l = a.pop(); a.reduce((x, k) => x[k], o)[l] = v; }

function fieldHTML(f) {
  const id = "f_" + f.k.replace(/\./g, "_"), v = getPath(cfg, f.k);
  if (f.t === "check") return `<label class="fld flex items-center justify-between gap-3"><span class="text-[12px] font-bold">${f.l}</span><input type="checkbox" class="chk hidden" id="${id}" ${v ? "checked" : ""}><span class="sw" onclick="this.previousElementSibling.click()"></span></label>`;
  if (f.t === "select") return `<div class="fld"><div class="lbl">${f.l}</div><select class="inp" id="${id}">${f.o.map(o => `<option value="${o[0]}" ${String(v) === o[0] ? "selected" : ""}>${o[1]}</option>`).join("")}</select></div>`;
  return `<div class="fld"><div class="lbl">${f.l}</div><input class="inp" id="${id}" type="${f.t}" ${f.step ? `step="${f.step}"` : ""} value="${esc(v)}"></div>`;
}
function collectTab() {
  (SCHEMA[curTab] || []).forEach(f => {
    const el = $("f_" + f.k.replace(/\./g, "_")); if (!el) return;
    let v = f.t === "check" ? el.checked : el.value;
    if (f.t === "number") v = Number(v);
    setPath(cfg, f.k, v);
  });
}
function renderTabs() {
  $("tabBar").innerHTML = TABS.map(t => `<button class="tabbtn ${t[0] === curTab ? "on" : ""}" onclick="gotoTab('${t[0]}')">${t[1]}</button>`).join("");
  let h = "";
  if (HINTS[curTab]) h += `<div class="text-[11px] text-slate-400 leading-relaxed bg-slate-900/70 p-2.5 rounded-xl border border-slate-800">${HINTS[curTab]}</div>`;
  if (curTab === "devices") h += devicesHTML();
  else if (curTab === "data") h += dataHTML();
  else h += (SCHEMA[curTab] || []).map(fieldHTML).join("");
  if (curTab === "account") h += `<button onclick="testConn()" class="w-full py-2.5 rounded-xl bg-sky-600 text-white font-bold text-xs">🔌 Ulanishni tekshirish</button><div id="testRes" class="text-[11px] text-center text-slate-300"></div>`;
  if (curTab === "notif") h += `<div class="grid grid-cols-2 gap-2"><button onclick="askNotifPermission()" class="py-2.5 rounded-xl bg-slate-800 border border-slate-700 font-bold text-xs">🔐 Ruxsat so'rash</button><button onclick="testNotify()" class="py-2.5 rounded-xl bg-slate-800 border border-slate-700 font-bold text-xs">🧪 Test xabar</button></div>`;
  $("tabBody").innerHTML = h;
}
function gotoTab(t) { collectTab(); curTab = t; renderTabs(); }
function openSettings(tab) { curTab = tab || curTab; renderTabs(); $("settingsModal").classList.add("active"); }
function closeSettings() { $("settingsModal").classList.remove("active"); }
function saveSettings() {
  collectTab();
  cfg.poll = Math.max(2, Number(cfg.poll) || 5);
  if (cfg.limits.min >= cfg.limits.max) { cfg.limits.min = 15; cfg.limits.max = 65; toast("Min/Max noto'g'ri, tiklandi"); }
  saveCfg();
  accessToken = ""; tokenExpireTime = 0; activeEndpoint = "";
  closeSettings(); toast("✅ Sozlamalar saqlandi");
  renderUI(); pollTuyaDevice();
}
async function testConn() {
  collectTab();
  const r = $("testRes"); r.innerText = "Tekshirilmoqda...";
  accessToken = ""; tokenExpireTime = 0; activeEndpoint = "";
  if (!cfg.account.clientId || !cfg.account.secret) { r.innerHTML = "<span class='text-rose-400'>Client ID va Secret kiriting</span>"; return; }
  const ok = await ensureToken();
  r.innerHTML = ok ? `<span class="text-emerald-400 font-bold">✅ Muvaffaqiyatli! Server: ${esc(activeEndpoint)}</span>` : `<span class="text-rose-400 font-bold">❌ ${esc(ensureToken.lastMsg || "Xato")}</span>`;
}

// --- Qurilmalar ---
function devicesHTML() {
  let h = cfg.devices.map((d, i) => `<div class="fld flex items-center justify-between gap-2 ${i === cfg.active ? "border-orange-500/60" : ""}"><div class="min-w-0"><div class="font-extrabold text-[12px] truncate">${esc(d.name)} ${i === cfg.active ? "<span class='text-orange-400'>• faol</span>" : ""}</div><div class="text-[10px] text-slate-400 truncate">${esc(d.id)}</div></div><div class="flex gap-1.5 flex-none"><button onclick="devUse(${i})" class="px-2.5 py-1.5 rounded-lg bg-slate-800 text-[11px] font-bold">Tanlash</button><button onclick="devEdit(${i})" class="px-2.5 py-1.5 rounded-lg bg-slate-800 text-[11px] font-bold">✏️</button><button onclick="devDel(${i})" class="px-2.5 py-1.5 rounded-lg bg-rose-700/70 text-[11px] font-bold">🗑</button></div></div>`).join("");
  if (!cfg.devices.length) h += `<div class="text-center text-slate-500 py-2">Hali qurilma qo'shilmagan.</div>`;
  h += `<div class="fld space-y-2"><div class="font-extrabold text-[12px]">➕ Yangi teplovoy nasos qo'shish</div><div><div class="lbl">Nomi (masalan: Uy, Dacha)</div><input class="inp" id="nd_name" type="text"></div><div><div class="lbl">Device ID (Tuya)</div><input class="inp" id="nd_id" type="text"></div><button onclick="devAdd()" class="w-full py-2.5 rounded-xl mango-grad text-slate-950 font-extrabold text-xs">Qo'shish</button></div>`;
  return h;
}
function devAdd() {
  const n = $("nd_name").value.trim(), id = $("nd_id").value.trim();
  if (!n || !id) { toast("Nom va Device ID kerak"); return; }
  if (cfg.devices.some(d => d.id === id)) { toast("Bu qurilma allaqachon bor"); return; }
  saveDeviceData();
  cfg.devices.push({ id, name: n }); cfg.active = cfg.devices.length - 1; saveCfg();
  loadDeviceData(); lastTick = 0; renderTabs(); renderUI(); toast("✅ Qurilma qo'shildi");
}
function devUse(i) { switchDevice(i); renderTabs(); }
function devEdit(i) {
  const n = prompt("Yangi nom:", cfg.devices[i].name); if (n && n.trim()) cfg.devices[i].name = n.trim();
  const id = prompt("Device ID:", cfg.devices[i].id);
  if (id && id.trim() && id.trim() !== cfg.devices[i].id) { cfg.devices[i].id = id.trim(); if (i === cfg.active) { loadDeviceData(); } }
  saveCfg(); renderTabs(); renderUI();
}
function devDel(i) {
  if (!confirm("«" + cfg.devices[i].name + "» o'chirilsinmi? Uning statistikasi ham o'chadi.")) return;
  const id = cfg.devices[i].id;
  localStorage.removeItem("mango_state_" + id); localStorage.removeItem("mango_stats_" + id);
  cfg.devices.splice(i, 1);
  if (cfg.active >= cfg.devices.length) cfg.active = Math.max(0, cfg.devices.length - 1);
  saveCfg(); loadDeviceData(); renderTabs(); renderUI();
}

// --- Ma'lumot / zaxira ---
function dataHTML() {
  return `
  <div class="fld space-y-2"><div class="font-extrabold text-[12px]">📤 Zaxira nusxa (sozlamalar, qurilmalar)</div><div class="text-[11px] text-slate-400">Akkaunt kalitlari ham kiradi — begonaga bermang.</div>
  <button onclick="exportCfg()" class="w-full py-2.5 rounded-xl bg-slate-800 border border-slate-700 font-bold text-xs">Matn sifatida ko'rsatish</button>
  <textarea id="bk" rows="5" class="inp font-mono" placeholder="Zaxira JSON shu yerda; tiklash uchun bu yerga joylang"></textarea>
  <button onclick="importCfg()" class="w-full py-2.5 rounded-xl bg-slate-800 border border-slate-700 font-bold text-xs">📥 Tiklash</button></div>
  <button onclick="resetStats()" class="w-full py-2.5 rounded-xl bg-amber-600/80 text-white font-bold text-xs">🧹 Faol qurilma statistikasini 0 qilish</button>
  <button onclick="resetAll()" class="w-full py-2.5 rounded-xl bg-rose-700 text-white font-bold text-xs">⚠️ Hamma narsani tozalash (zavod holati)</button>
  <div class="text-center text-[10px] text-slate-500 pt-2">Mango Energy Pro v3.0</div>`;
}
function exportCfg() { $("bk").value = JSON.stringify(cfg); $("bk").select(); try { document.execCommand("copy"); toast("Nusxalandi"); } catch (e) {} }
function importCfg() {
  try { const o = JSON.parse($("bk").value); cfg = deepMerge(DEFAULT_CFG, o); saveCfg(); loadDeviceData(); renderTabs(); renderUI(); toast("✅ Tiklandi"); }
  catch (e) { toast("JSON noto'g'ri"); }
}
function resetStats() { if (!confirm("Statistika 0 qilinsinmi?")) return; statsDB = freshStats(); saveDeviceData(); renderUI(); toast("Statistika tozalandi"); }
function resetAll() {
  if (!confirm("BARCHA sozlama, akkaunt va statistika o'chadi. Davom etasizmi?")) return;
  localStorage.clear(); location.reload();
}

// ====================== BOSHLASH ======================
loadDeviceData();
renderUI();
renderBadge();
if (!cfg.account.clientId || !cfg.devices.length) setTimeout(() => openSettings("account"), 600);
setInterval(renderUI, 15000);
pollLoop();
</script>
</body>
</html>
'@

Set-Content -Path "$ProjectDir\index.html" -Value $HtmlContent -Encoding UTF8
Set-Content -Path "$ProjectDir\www\index.html" -Value $HtmlContent -Encoding UTF8

# GITHUB-GA YUBORISH
Write-Host "🚀 v3: To'liq sozlamalar, akkaunt, qurilmalar, bildirishnoma GitHub-ga yuklanmoqda..." -ForegroundColor Cyan
git add .
git commit -m "v3: full settings, account, multi-device, notifications, real stats, device info panel"
git push origin main --force

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host "✅ TAYYOR! GITHUB ACTIONS YANGI APK YIG'ISHNI BOSHLADI." -ForegroundColor Green
Write-Host "👉 1.5 daqiqadan so'ng Actions bo'limidan tayyor APK-ni yuklab oling." -ForegroundColor Yellow
Write-Host "=======================================================`n" -ForegroundColor Green

Start-Process "https://github.com/akrom3388-ui/mango-energy-pro/actions"
