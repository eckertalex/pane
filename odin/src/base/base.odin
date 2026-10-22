package base

KB :: 1 << 10
MB :: 1 << 20
GB :: 1 << 30

align_pow2 :: proc "contextless" (x, b: u64) -> u64 {
	return (x + b - 1) & ~(b - 1)
}
