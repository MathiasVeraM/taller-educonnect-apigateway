"""Genera la colección y el entorno de Thunder Client (import en la extensión de VS Code)."""
import json, uuid, pathlib
out = pathlib.Path(__file__).resolve().parent.parent / "thunder-client"
col = "educonnect-poc-0001"
H = lambda k: [{"name": "apikey", "value": k}] if k else []
def t(code, extra=None):
    r = [{"type": "res-code", "custom": "", "action": "equal", "value": str(code)}]
    return r + (extra or [])
srv = lambda s: {"type": "res-header", "custom": "x-served-by", "action": "equal", "value": s}
casos = [
 ("01 Estudiantes - key válida (200)", "/api/estudiantes", "{{apikey}}", t(200, [srv("estudiantes")])),
 ("02 Matrículas - key válida (200)", "/api/matriculas", "{{apikey}}", t(200, [srv("matriculas")])),
 ("03 Pagos - key válida (200)", "/api/pagos", "{{apikey}}", t(200, [srv("pagos")])),
 ("04 Sin API Key (401)", "/api/estudiantes", "", t(401)),
 ("05 API Key incorrecta (401)", "/api/estudiantes", "incorrecta", t(401)),
 ("06 Ruta no registrada (404)", "/api/inexistente", "{{apikey}}", t(404)),
 ("07 Certificados - key válida (200)", "/api/certificados", "{{apikey}}", t(200, [srv("certificados")])),
 ("08 Rate limit - ejecutar 6+ veces seguidas (la 6ª da 429)", "/api/estudiantes", "{{apikey}}", t(200)),
 ("09 Backend caído - detener pagos antes (502)", "/api/pagos", "{{apikey}}", t(502)),
]
reqs = []
for i, (n, path, key, tests) in enumerate(casos, 1):
    reqs.append({"_id": str(uuid.uuid5(uuid.NAMESPACE_URL, n)), "colId": col, "containerId": "",
      "name": n, "url": "{{baseUrl}}" + path, "method": "GET", "sortNum": i*10000,
      "created": "2026-11-25T00:00:00.000Z", "modified": "2026-11-25T00:00:00.000Z",
      "headers": H(key), "params": [], "tests": tests})
(out/"thunder-collection_EduConnect.json").write_text(json.dumps({
  "clientName": "Thunder Client", "collectionName": "EduConnect PoC", "collectionId": col,
  "dateExported": "2026-11-25T00:00:00.000Z", "version": "1.2", "folders": [], "requests": reqs}, indent=2, ensure_ascii=False), encoding="utf-8")
(out/"thunder-environment_EduConnect.json").write_text(json.dumps({
  "_id": "educonnect-env-0001", "name": "EduConnect local", "default": True, "global": False,
  "local": True, "sortNum": 1, "created": "2026-11-25T00:00:00.000Z",
  "data": [{"name": "baseUrl", "value": "http://localhost:8080"},
           {"name": "apikey", "value": "demo-key-educonnect-2026"}]}, indent=2), encoding="utf-8")
