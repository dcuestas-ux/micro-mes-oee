import json, time, random
from datetime import datetime, timezone
import paho.mqtt.client as mqtt

BROKER_HOST = "localhost"
BROKER_PORT = 1883
SITE = "bog"; LINE = "l1"; MACH="cnc01"; V="v1"
TOP = f"site/{SITE}/line/{LINE}/machine/{MACH}/{V}"

cli = mqtt.Client()
cli.connect(BROKER_HOST, BROKER_PORT, 60)

seq = 1

def now():
    return datetime.now(timezone.utc).isoformat(timespec='milliseconds')

def pub(stream, payload, qos=1, retain=False):
    cli.publish(f"{TOP}/{stream}", json.dumps(payload), qos=qos, retain=retain)

# Enviar meta ONLILNE (retained)
pub("meta", {"msg_ver":"1.0.0","ts":now(),"machine_id":MACH,"event":"meta","seq":seq,"source":"sim","status":"ONLINE","ct_ideal_ms":1200}, qos=0, retain=True); seq+=1

# Estado inicial RUN (retained)
pub("state", {"msg_ver":"1.0.0","ts":now(),"machine_id":MACH,"event":"state","state":"RUN","reason_code":None,"order_id":"O-2411-001","lot_id":"L-001","seq":seq,"source":"sim"}, retain=True); seq+=1

while True:
    good = 1 if random.random() > 0.1 else 0
    scrap = 1 - good
    ct_ideal_ms = 1200
    ct_actual_ms = int(random.gaus(1300, 60))

    pub("cycle", {
        "msg_ver":"1.0.0","ts":now(),"machine_id":MACH,"event":"cycle",
        "order_id":"O-2411-001","lot_id":"L-001",
        "result":"GOOD" if good else "SCRAP",
        "good":good,"scrap":scrap,
        "scrap_reason_code": None if good else "S-BURR",
        "ct_ideal_ms": ct_ideal_ms, "ct_actual_ms": ct_actual_ms,
        "seq": seq, "source":"sim"
    }); seq+=1

    if random.random() < 0.05:
        pub("alarm", {
            "msg_ver":"1.0.0","ts":now(),"machine_id":MACH,"event":"alarm",
            "alarm_code":"E-099","severity":"warn","text":"Temp high","active":True,
            "seq": seq, "source":"sim"
        }); seq+=1

    time.sleep(ct_actual_ms / 1000.0)

