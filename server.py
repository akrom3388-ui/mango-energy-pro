import asyncio
import sqlite3
import time
import math
import random
from datetime import datetime, timedelta
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse, JSONResponse
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Mango Energy Pro Server")
DB_FILE = "mango_stats.db"

# Global State (Real-time holat)
state = {
    "power": True,
    "mode": "HEATING",       # HEATING, COOLING, DHW, AUTO
    "preset": "NORMAL",      # NORMAL, ECO, TURBO, SILENT
    "target_temp": 45.0,
    "inlet_temp": 41.2,      # Obratka
    "outlet_temp": 46.5,     # Padacha
    "ambient_temp": 4.5,     # Ko'cha harorati
    "dhw_temp": 52.0,        # Issiq suv / Bufer
    "compressor_hz": 58,
    "fan_rpm": 620,
    "water_flow": 28.5,      # L/min
    "power_kw": 3.45,        # Elektr sarfi (kW)
    "heat_kw": 14.80,        # Issiqlik berishi (kW)
    "cop": 4.29,
    "defrost": False,
    "weather_comp": True,
    "anti_legionella": False,
    "error_code": "OK",
    "online": True,
    "last_update": "",
    "current_session_start": time.time() - 5400,
    "current_session_kwh": 4.82
}

def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    # Har sekundlik va daqiqalik loglar uchun
    c.execute('''CREATE TABLE IF NOT EXISTS telemetry (
        ts INTEGER PRIMARY KEY,
        power INTEGER,
        mode TEXT,
        inlet REAL,
        outlet REAL,
        ambient REAL,
        power_kw REAL,
        heat_kw REAL,
        cop REAL,
        hz INTEGER
    )''')
    # Seanslar tarixi
    c.execute('''CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_ts INTEGER,
        end_ts INTEGER,
        duration_min REAL,
        total_kwh REAL,
        avg_cop REAL,
        max_outlet REAL,
        mode TEXT
    )''')
    
    # Agar baza bo'sh bo'lsa, oxirgi 30 kunlik realistik demo-statistika yaratamiz
    c.execute("SELECT COUNT(*) FROM sessions")
    if c.fetchone()[0] == 0:
        now = int(time.time())
        for d in range(30, 0, -1):
            day_ts = now - (d * 86400)
            for s in range(4): # Kuniga 4 ta katta seans
                st = day_ts + (s * 20000)
                dur = random.randint(45, 180)
                en = st + (dur * 60)
                kwh = round(dur * random.uniform(0.04, 0.08), 2)
                cop = round(random.uniform(3.4, 4.6), 2)
                c.execute("INSERT INTO sessions (start_ts, end_ts, duration_min, total_kwh, avg_cop, max_outlet, mode) VALUES (?,?,?,?,?,?,?)",
                          (st, en, dur, kwh, cop, round(random.uniform(44, 52), 1), "HEATING"))
    conn.commit()
    conn.close()

init_db()

# 24/7 BACKGROUND SKANER (1 SEKUNDDA 1 MARTA ISHLAYDI - APK YOPIQ BO'LSA HAM)
async def background_scanner():
    session_active = state["power"]
    session_start = int(time.time())
    session_kwh = 0.0
    cop_sum = 0.0
    ticks = 0

    while True:
        now = int(time.time())
        state["last_update"] = datetime.now().strftime("%H:%M:%S")
        
        # AGAR MODBUS/RS485 YOKI WI-FI ULANSA SHU YERDA O'QILADI
        # Hozir tizim fizik qonuniyatga asoslangan aniq telemetriyani simulyatsiya va hisob-kitob qiladi:
        if state["power"]:
            diff = state["target_temp"] - state["outlet_temp"]
            if state["preset"] == "TURBO":
                target_hz = min(90, max(35, int(55 + diff * 8)))
            elif state["preset"] == "ECO" or state["preset"] == "SILENT":
                target_hz = min(50, max(25, int(40 + diff * 5)))
            else:
                target_hz = min(75, max(30, int(48 + diff * 6)))

            state["compressor_hz"] = int(state["compressor_hz"] * 0.7 + target_hz * 0.3)
            state["outlet_temp"] = round(state["outlet_temp"] + (state["target_temp"] - state["outlet_temp"]) * 0.08 + random.uniform(-0.05, 0.05), 1)
            state["inlet_temp"] = round(state["outlet_temp"] - random.uniform(4.5, 5.5), 1)
            state["power_kw"] = round(0.4 + (state["compressor_hz"] / 90.0) * 5.2, 2)
            
            # COP ko'cha haroratiga va padachaga bog'liq
            base_cop = 4.5 + (state["ambient_temp"] * 0.06) - ((state["outlet_temp"] - 35) * 0.04)
            state["cop"] = round(max(2.1, min(5.4, base_cop + random.uniform(-0.05, 0.05))), 2)
            state["heat_kw"] = round(state["power_kw"] * state["cop"], 2)
            state["fan_rpm"] = int(300 + state["compressor_hz"] * 6.5)
            state["water_flow"] = round(26.0 + (state["compressor_hz"] * 0.08), 1)

            # Seans hisoblagichi (1 sekundlik ulush)
            kwh_step = state["power_kw"] / 3600.0
            state["current_session_kwh"] = round(state["current_session_kwh"] + kwh_step, 3)
            session_kwh += kwh_step
            cop_sum += state["cop"]
            ticks += 1
        else:
            state["compressor_hz"] = 0
            state["power_kw"] = 0.02 # Kutish rejimi
            state["heat_kw"] = 0.0
            state["cop"] = 0.0
            state["fan_rpm"] = 0
            state["outlet_temp"] = round(max(state["ambient_temp"], state["outlet_temp"] - 0.03), 1)
            state["inlet_temp"] = round(max(state["ambient_temp"], state["inlet_temp"] - 0.03), 1)

        # Seans o'chib-yoqilganini bazaga yozish
        if state["power"] and not session_active:
            session_active = True
            session_start = now
            state["current_session_start"] = now
            state["current_session_kwh"] = 0.0
            session_kwh = 0.0
            cop_sum = 0.0
            ticks = 0
        elif not state["power"] and session_active:
            session_active = False
            dur_min = round((now - session_start) / 60.0, 1)
            if dur_min >= 0.1:
                avg_c = round(cop_sum / max(1, ticks), 2)
                conn = sqlite3.connect(DB_FILE)
                conn.execute("INSERT INTO sessions (start_ts, end_ts, duration_min, total_kwh, avg_cop, max_outlet, mode) VALUES (?,?,?,?,?,?,?)",
                             (session_start, now, dur_min, round(session_kwh, 3), avg_c, state["outlet_temp"], state["mode"]))
                conn.commit()
                conn.close()

        # Har 10 sekundda telemetriyani bazaga muhrlash
        if now % 10 == 0:
            conn = sqlite3.connect(DB_FILE)
            conn.execute("INSERT OR REPLACE INTO telemetry VALUES (?,?,?,?,?,?,?,?,?,?)",
                         (now, int(state["power"]), state["mode"], state["inlet_temp"], state["outlet_temp"],
                          state["ambient_temp"], state["power_kw"], state["heat_kw"], state["cop"], state["compressor_hz"]))
            conn.commit()
            conn.close()

        await asyncio.sleep(1.0) # ANIQ 1 SEKUNDDA YANGILANISH

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(background_scanner())

class ControlCmd(BaseModel):
    action: str
    value: str | float | bool

@app.get("/api/status")
async def get_status():
    now = int(time.time())
    sess_dur = int((now - state["current_session_start"]) / 60) if state["power"] else 0
    return {**state, "current_session_min": sess_dur}

@app.post("/api/control")
async def set_control(cmd: ControlCmd):
    a = cmd.action
    v = cmd.value
    if a == "power": state["power"] = bool(v)
    elif a == "mode": state["mode"] = str(v)
    elif a == "preset": state["preset"] = str(v)
    elif a == "target_temp": state["target_temp"] = max(15.0, min(65.0, float(v)))
    elif a == "defrost": state["defrost"] = bool(v)
    elif a == "weather_comp": state["weather_comp"] = bool(v)
    elif a == "anti_legionella": state["anti_legionella"] = bool(v)
    return {"ok": True, "state": state}

@app.get("/api/stats")
async def get_stats():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    now = int(time.time())
    
    def calc_period(seconds):
        c.execute("SELECT SUM(total_kwh), AVG(avg_cop), SUM(duration_min), COUNT(*) FROM sessions WHERE start_ts >= ?", (now - seconds,))
        row = c.fetchone()
        kwh = round((row[0] or 0.0) + (state["current_session_kwh"] if seconds <= 86400 else 0), 2)
        cop = round(row[1] or state["cop"] or 4.1, 2)
        hrs = round((row[2] or 0.0) / 60.0, 1)
        cnt = row[3] or 0
        return {"kwh": kwh, "cop": cop, "hours": hrs, "sessions": cnt, "cost_uzs": int(kwh * 450)}

    # Oxirgi 10 ta seans
    c.execute("SELECT start_ts, end_ts, duration_min, total_kwh, avg_cop, max_outlet, mode FROM sessions ORDER BY id DESC LIMIT 10")
    sessions = []
    for r in c.fetchall():
        sessions.append({
            "start": datetime.fromtimestamp(r[0]).strftime("%d.%m %H:%M"),
            "end": datetime.fromtimestamp(r[1]).strftime("%H:%M"),
            "duration_min": r[2],
            "kwh": r[3],
            "cop": r[4],
            "max_temp": r[5],
            "mode": r[6]
        })

    # Grafik uchun kunlik/haftalik massiv
    c.execute("SELECT start_ts, total_kwh, avg_cop FROM sessions WHERE start_ts >= ? ORDER BY start_ts ASC", (now - 7*86400,))
    chart_data = [{"t": datetime.fromtimestamp(r[0]).strftime("%d/%m"), "kwh": r[1], "cop": r[2]} for r in c.fetchall()[-14:]]

    conn.close()
    return {
        "daily": calc_period(86400),
        "weekly": calc_period(7 * 86400),
        "monthly": calc_period(30 * 86400),
        "sessions": sessions,
        "chart": chart_data
    }

@app.get("/mango_icon.png")
async def get_icon():
    return FileResponse("mango_icon.png")

@app.get("/manifest.json")
async def get_manifest():
    return JSONResponse({
        "name": "Mango Energy Pro",
        "short_name": "MangoPro",
        "start_url": "/",
        "display": "standalone",
        "background_color": "#0b0f19",
        "theme_color": "#ff7b00",
        "icons": [{"src": "/mango_icon.png", "sizes": "512x512", "type": "image/png"}]
    })

@app.get("/", response_class=HTMLResponse)
async def index():
    with open("index.html", "r", encoding="utf-8") as f:
        return f.read()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8050)
