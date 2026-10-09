// Nearby search smoke test (P07, 03-testing.md): p95 under 300 ms with 2,000 online
// providers. ./pao perf seeds the providers and passes the fixture path in FIXTURE.
import http from 'k6/http';
import { check } from 'k6';

const fixture = JSON.parse(open(__ENV.FIXTURE));
const base = __ENV.BASE_URL || 'http://localhost:8080';

// 40 searches a second spread over 50 customers stays under each customer's rate limit
// (120 per minute), so the run measures search, not throttling.
export const options = {
  scenarios: {
    search: { executor: 'constant-arrival-rate', rate: 40, timeUnit: '1s', duration: '30s', preAllocatedVUs: 20 },
  },
  thresholds: {
    http_req_duration: ['p(95)<300'],
    checks: ['rate>0.99'],
  },
};

export default function () {
  const token = fixture.tokens[(__VU * 997 + __ITER * 31) % fixture.tokens.length];
  const url = `${base}/v1/customer/providers/nearby?serviceId=${fixture.serviceId}` +
    `&subServiceId=${fixture.subServiceId}&quantity=1&lat=${fixture.lat}&lng=${fixture.lng}&limit=20`;
  const res = http.get(url, { headers: { Authorization: `Bearer ${token}` } });
  check(res, { 'status 200': (r) => r.status === 200, 'has providers': (r) => r.json('items').length > 0 });
}
