// Package geo holds the location types shared by modules and contracts.
package geo

// Point is a WGS84 position in decimal degrees.
type Point struct {
	Lat float64
	Lng float64
}
