import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('error_rate');
const apiLatency = new Trend('api_latency');

const BASE_URL = __ENV.BASE_URL || 'http://localhost';
const TOKEN = __ENV.TOKEN;

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 30 },
    { duration: '2m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<800'],
    error_rate: ['rate<0.01'],
  },
};

export default function () {
  const params = {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
    },
  };

  const res = http.get(
    `${BASE_URL}/api/estadisticas/globales`,
    params
  );

  const ok = check(res, {
    'status es 200': (r) => r.status === 200,
  });

  errorRate.add(!ok);
  apiLatency.add(res.timings.duration);

  sleep(1);
}