import { type Point } from './customer';

type Ring = readonly (readonly number[])[];
type Polygon = readonly Ring[];

/**
 * Reports whether the launch area (a GeoJSON Polygon or MultiPolygon from the
 * `service_area.geojson` setting, D5) contains `p`. An empty area covers everywhere; an
 * unreadable one covers nothing, so a bad edit cannot open bookings nationwide.
 */
export function covers(areaGeoJson: string, p: Point): boolean {
  if (areaGeoJson === '') {
    return true;
  }
  return polygons(areaGeoJson).some((poly) => inPolygon(poly, p));
}

function polygons(geoJson: string): readonly Polygon[] {
  let g: { type?: unknown; coordinates?: unknown };
  try {
    g = JSON.parse(geoJson) as typeof g;
  } catch {
    return [];
  }
  if (!Array.isArray(g.coordinates)) {
    return [];
  }
  if (g.type === 'Polygon') {
    return [g.coordinates as Polygon];
  }
  return g.type === 'MultiPolygon' ? (g.coordinates as Polygon[]) : [];
}

/** The even-odd rule: inside the outer ring and outside every hole. */
function inPolygon(rings: Polygon, p: Point): boolean {
  const [outer, ...holes] = rings;
  return outer !== undefined && inRing(outer, p) && !holes.some((h) => inRing(h, p));
}

/** Casts a ray east from p and counts edge crossings; GeoJSON stores [lng, lat]. */
function inRing(ring: Ring, p: Point): boolean {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi = 0, yi = 0] = ring[i] ?? [];
    const [xj = 0, yj = 0] = ring[j] ?? [];
    if (yi > p.lat !== yj > p.lat && p.lng < ((xj - xi) * (p.lat - yi)) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}
