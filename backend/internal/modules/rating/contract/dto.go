package contract

// Summary is a rating aggregate.
type Summary struct {
	Average      float64
	Count        int
	Distribution [5]int
}
