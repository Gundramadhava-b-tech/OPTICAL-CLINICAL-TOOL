import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 20,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<800'],  // 95% of requests under 800ms
    checks: ['rate>0.95'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';

export default function () {
  // Health check
  const health = http.get(`${BASE_URL}/health`);
  check(health, { 'health status is 200': (r) => r.status === 200 });

  // Example: hit a lightweight GET endpoint (swap for your real routes)
  const res = http.get(`${BASE_URL}/api/patients`);
  check(res, {
    'patients status is 200 or 401': (r) => r.status === 200 || r.status === 401,
  });

  sleep(1);
}
