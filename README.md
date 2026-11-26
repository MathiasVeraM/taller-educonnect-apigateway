# EduConnect · PoC de API Gateway con Kong

Laboratorio de Arquitectura Aplicada — Integración de Sistemas.
Integrantes: Wilson Egas, Elizabeth Guerrón, Jean Luc Morales, Mayra Vargas y Mathias Vera.

Un único punto de entrada (Kong) expone cuatro APIs simuladas (Estudiantes, Matrículas, Pagos, Certificados), valida API Key y limita el tráfico.

> **Entregables 4–7** (matriz de evidencias, diagrama, decisiones AuthN/AuthZ y límites, uso de IA y fuentes): [`docs/ENTREGABLES.md`](docs/ENTREGABLES.md)

## Requisitos
- Docker Engine/Desktop y Docker Compose v2.
- Para las pruebas: Thunder Client (extensión de VS Code) o `curl` + Bash (`tests/pruebas.sh`; en Windows, Git Bash).
- Puertos libres en el host: **8080** y **8001**.

## Versión elegida
Kong Gateway OSS **3.9.1** (fijada en `docker-compose.yml`), modo DB-less. Justificación en `docs/ENTREGABLES.md`.

## Estructura
```
docker-compose.yml        Kong + 4 mocks en la red educonnect-net
kong/kong.yml             Configuración declarativa (Services, Routes, plugins, consumidor)
mocks/                    Mock HTTP en Node (una imagen, parametrizada con SERVICE)
tests/pruebas.sh          Pruebas positivas/negativas por consola
tests/generar_thunder.py  Genera la colección de Thunder Client
thunder-client/           Colección y entorno para importar en Thunder Client
docs/                     ENTREGABLES.md y evidencias
```

## Arranque
```bash
docker compose up -d --build
docker compose ps
docker compose exec kong kong version
```
Tras cambiar `kong/kong.yml`: `docker compose restart kong`.

## URLs
| Qué | URL |
|---|---|
| Gateway (público) | `http://localhost:8080` |
| Estudiantes / Matrículas / Pagos / Certificados | `GET /api/estudiantes`, `/api/matriculas`, `/api/pagos`, `/api/certificados` |
| Admin API (solo localhost) | `http://127.0.0.1:8001` |

Los backends (`estudiantes`, `matriculas`, `pagos`, `certificados`, puerto interno 3000) no se publican; solo se alcanzan dentro de la red Docker. Sus rutas internas son `/estudiantes`, `/matriculas`, `/pagos` y `/certificados`.

> Se usa el 8080 porque en la máquina de desarrollo el 8000 estaba ocupado. Si el 8080 está ocupado, cambie `"8080:8000"` en `docker-compose.yml`.

## Autenticación y límites
- Cabecera: `apikey`. Consumidor ficticio: `app-externa-demo`, clave de demostración `demo-key-educonnect-2026` (no es un secreto real).
- Límite: 5 solicitudes/minuto por consumidor (contador compartido entre Estudiantes, Matrículas y Pagos); `/api/certificados`: 3/minuto con contador propio.

```bash
curl -i -H "apikey: demo-key-educonnect-2026" http://localhost:8080/api/estudiantes
```

## Pruebas
**Thunder Client:** en VS Code → Thunder Client → *Collections* → ⋯ → *Import* → `thunder-client/thunder-collection_EduConnect.json`; en *Env* importar `thunder-client/thunder-environment_EduConnect.json` y activarlo. La solicitud 08 debe ejecutarse 6 o más veces seguidas (la 6.ª da 429); para la 09 detenga antes `pagos` (`docker compose stop pagos`) y vuelva a iniciarlo después (`docker compose start pagos`).

**Por consola** (≈ 3 min; espera ventanas de minuto limpias y detiene/inicia `pagos`):
```bash
bash tests/pruebas.sh
```
La salida de una ejecución completa está en `docs/evidencias/salida-pruebas.txt`.

## Detener
```bash
docker compose down
```
