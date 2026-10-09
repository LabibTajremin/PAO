package domain

import "encoding/json"

// Covers reports whether the launch area (a GeoJSON Polygon or MultiPolygon from the
// service_area.geojson setting, D5) contains p. An empty area covers everywhere; an
// unreadable one covers nothing, so a bad edit cannot open bookings nationwide.
func Covers(areaGeoJSON string, p Point) bool {
	if areaGeoJSON == "" {
		return true
	}
	var g struct {
		Type        string          `json:"type"`
		Coordinates json.RawMessage `json:"coordinates"`
	}
	if json.Unmarshal([]byte(areaGeoJSON), &g) != nil {
		return false
	}
	var polygons [][][][2]float64
	switch g.Type {
	case "Polygon":
		var poly [][][2]float64
		if json.Unmarshal(g.Coordinates, &poly) == nil {
			polygons = append(polygons, poly)
		}
	case "MultiPolygon":
		_ = json.Unmarshal(g.Coordinates, &polygons)
	}
	for _, poly := range polygons {
		if inPolygon(poly, p) {
			return true
		}
	}
	return false
}

// inPolygon applies the even-odd rule: inside the outer ring and outside every hole.
func inPolygon(rings [][][2]float64, p Point) bool {
	if len(rings) == 0 || !inRing(rings[0], p) {
		return false
	}
	for _, hole := range rings[1:] {
		if inRing(hole, p) {
			return false
		}
	}
	return true
}

// inRing casts a ray east from p and counts edge crossings; GeoJSON stores [lng, lat].
func inRing(ring [][2]float64, p Point) bool {
	inside := false
	for i, j := 0, len(ring)-1; i < len(ring); j, i = i, i+1 {
		xi, yi, xj, yj := ring[i][0], ring[i][1], ring[j][0], ring[j][1]
		if (yi > p.Lat) != (yj > p.Lat) && p.Lng < (xj-xi)*(p.Lat-yi)/(yj-yi)+xi {
			inside = !inside
		}
	}
	return inside
}
