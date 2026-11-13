extends GutTest

var _stepper: FixedStepper


func before_each() -> void:
	_stepper = FixedStepper.new()


func test_accumulates_small_deltas() -> void:
	assert_eq(_stepper.advance(0.04), 0)
	assert_eq(_stepper.advance(0.04), 0)
	assert_eq(_stepper.advance(0.04), 1, "0,12 s: ya cabe un paso de 0,1 s")


func test_whole_steps_per_frame() -> void:
	assert_eq(_stepper.advance(0.25), 2)
	assert_eq(_stepper.advance(0.05), 1, "0,05 sobrantes + 0,05 = un paso")


func test_long_pause_is_capped_and_not_recovered() -> void:
	assert_eq(_stepper.advance(60.0), FixedStepper.MAX_STEPS_PER_FRAME)
	assert_eq(_stepper.advance(0.01), 0, "el tiempo perdido se descarta")


func test_invalid_deltas_give_no_steps() -> void:
	assert_eq(_stepper.advance(0.0), 0)
	assert_eq(_stepper.advance(-1.0), 0)
	assert_eq(_stepper.advance(NAN), 0)


func test_ten_steps_per_second_over_a_long_run() -> void:
	var total: int = 0
	for _frame: int in range(600):
		total += _stepper.advance(1.0 / 60.0)
	assert_between(total, 99, 100, "10 s de juego a 60 FPS = 100 pasos")
