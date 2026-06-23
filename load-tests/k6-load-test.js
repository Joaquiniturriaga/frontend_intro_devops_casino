import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('error_rate');
const apiLatency = new Trend('api_latency');

const BASE_URL = __ENV.BASE_URL || 'http://localhost';

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // calentamiento
    { duration: '1m', target: 30 },    // sube la carga -> el HPA debería empezar a reaccionar
    { duration: '2m', target: 50 },    // mantiene la carga alta -> HPA escala
    { duration: '30s', target: 0 },    // baja la carga -> HPA debería bajar replicas después de cooldown
  ],
  thresholds: {
    http_req_duration: ['p(95)<800'],   // p95 < 800ms
    error_rate: ['rate<0.01'],          // tasa de error < 1%
  },
};

export default function () {

  const res = http.get(`${BASE_URL}/api/estadisticas`);

  const ok = check(res, {
    'status es 200': (r) => r.status === 200,
  });

  errorRate.add(!ok);
  apiLatency.add(res.timings.duration);

  sleep(1);
}

