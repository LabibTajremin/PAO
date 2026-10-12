import { addDays, DASHBOARD_DAYS, fillDays } from './dashboard';

describe('fillDays', () => {
  const today = '2026-10-09';

  it('fills an empty window with zeros', () => {
    const { days, completionRate } = fillDays(today, []);
    expect(days).toHaveLength(DASHBOARD_DAYS);
    expect(completionRate).toBe(0);
    expect(days[29]?.date).toBe(today);
    expect(days[0]?.date).toBe(addDays(today, -29));
    expect(days[0]?.date).toBe('2026-09-10');
  });

  it('places stored days and rounds the completion rate', () => {
    const { days, completionRate } = fillDays(today, [
      { date: today, total: 2, completed: 1 },
      { date: addDays(today, -3), total: 1, completed: 1 },
    ]);
    expect(days[29]?.total).toBe(2);
    expect(days[26]?.completed).toBe(1);
    expect(completionRate).toBe(0.67);
  });
});
