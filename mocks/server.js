// Mock HTTP genérico para EduConnect. Sin dependencias.
// El servicio se elige con la variable de entorno SERVICE.
const http = require('http');

const CATALOGO = {
  estudiantes:  { ruta: '/estudiantes',  datos: { id: 101, nombre: 'Ana Perez' } },
  matriculas:   { ruta: '/matriculas',   datos: { id: 501, estudianteId: 101, estado: 'ACTIVA' } },
  pagos:        { ruta: '/pagos',        datos: { id: 701, matriculaId: 501, valor: 150.0, estado: 'PENDIENTE' } },
  certificados: { ruta: '/certificados', datos: { id: 901, estudianteId: 101, tipo: 'CERTIFICADO_MATRICULA', estado: 'EMITIDO' } },
};

const nombre = process.env.SERVICE;
const servicio = CATALOGO[nombre];
if (!servicio) {
  console.error(`SERVICE inválido: "${nombre}". Opciones: ${Object.keys(CATALOGO).join(', ')}`);
  process.exit(1);
}
const puerto = Number(process.env.PORT || 3000);

http.createServer((req, res) => {
  console.log(`[${nombre}] ${new Date().toISOString()} ${req.method} ${req.url}`);
  const path = req.url.split('?')[0];
  if (req.method === 'GET' && path === servicio.ruta) {
    res.writeHead(200, { 'Content-Type': 'application/json', 'X-Served-By': nombre });
    return res.end(JSON.stringify({ servicio: nombre, ...servicio.datos }));
  }
  res.writeHead(404, { 'Content-Type': 'application/json', 'X-Served-By': nombre });
  res.end(JSON.stringify({ servicio: nombre, error: 'No encontrado' }));
}).listen(puerto, () => console.log(`[${nombre}] escuchando en :${puerto}`));
