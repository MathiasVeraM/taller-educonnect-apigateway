#!/usr/bin/env bash
# Pruebas reproducibles del gateway (alternativa por consola a Thunder Client).
# Uso:  bash tests/pruebas.sh        (gateway ya levantado con docker compose up -d)
BASE="${BASE:-http://localhost:8080}"
KEY="${KEY:-demo-key-educonnect-2026}"
H="apikey: $KEY"
n=0; fallos=0

# probar "<descripcion>" <esperado> <curl args...>
probar() {
  local desc="$1" esperado="$2"; shift 2
  local codigo; codigo=$(curl -s -o /tmp/cuerpo.$$ -w "%{http_code}" "$@")
  local ok="OK "; [ "$codigo" = "$esperado" ] || { ok="FALLA"; fallos=$((fallos+1)); }
  n=$((n+1)); printf "[%s] %-52s esperado=%s obtenido=%s\n      %s\n" "$ok" "$desc" "$esperado" "$codigo" "$(head -c 160 /tmp/cuerpo.$$ | tr '\n' ' ')"
}
sec() { echo; echo "== $1"; }

sec "Reto 1/2 - rutas con API Key valida (3 de las 5 solicitudes del minuto)"
probar "GET /api/estudiantes con key valida" 200 -H "$H" "$BASE/api/estudiantes"
probar "GET /api/matriculas  con key valida" 200 -H "$H" "$BASE/api/matriculas"
probar "GET /api/pagos       con key valida" 200 -H "$H" "$BASE/api/pagos"

sec "Reto 2 - autenticacion (no consumen cuota: fallan antes del rate limiting)"
probar "Sin API Key"                          401 "$BASE/api/estudiantes"
probar "API Key incorrecta"                   401 -H "apikey: incorrecta" "$BASE/api/estudiantes"

sec "Reto 4 - ruta no registrada"
probar "GET /api/inexistente con key valida"  404 -H "$H" "$BASE/api/inexistente"

sec "Reto 3 - rate limiting (se espera al inicio del siguiente minuto para una ventana limpia)"
sleep $((61 - 10#$(date +%S)))
echo "Ventana iniciada ~ $(date +%H:%M:%S)"
for i in 1 2 3 4 5; do probar "Solicitud $i/5 (dentro del limite)" 200 -H "$H" "$BASE/api/estudiantes"; done
probar "Solicitud 6 (supera el limite)"       429 -H "$H" "$BASE/api/estudiantes"
probar "Solicitud 7 (otra ruta, mismo consumidor)" 429 -H "$H" "$BASE/api/pagos"
curl -si -H "$H" "$BASE/api/pagos" | grep -iE "^(retry-after|x-ratelimit-(limit|remaining)-minute)"

sec "Desafio de transferencia - /api/certificados (limite propio 3/min, contador independiente)"
probar "Certificados sin API Key"              401 "$BASE/api/certificados"
for i in 1 2 3; do probar "Certificados solicitud $i/3" 200 -H "$H" "$BASE/api/certificados"; done
probar "Certificados solicitud 4 (supera 3/min)" 429 -H "$H" "$BASE/api/certificados"

sec "Reto 4 - backend no disponible (se detiene SOLO pagos)"
docker compose stop pagos >/dev/null 2>&1
echo "(se espera la siguiente ventana para tener cuota)"; sleep $((61 - 10#$(date +%S)))
probar "GET /api/pagos con backend detenido"  502 -H "$H" "$BASE/api/pagos"
docker compose logs kong 2>&1 | grep "\[error\]" | tail -1 | cut -c1-230
docker compose start pagos >/dev/null 2>&1

rm -f /tmp/cuerpo.$$
echo; echo "Resumen: $n pruebas, $fallos fallas"; [ "$fallos" -eq 0 ]
