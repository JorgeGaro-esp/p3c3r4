extends GutTest

var _wallet: Wallet


func before_each() -> void:
	_wallet = Wallet.new()


func test_add_increases_shells_and_total() -> void:
	assert_true(_wallet.add(15.5))
	assert_eq(_wallet.shells, 15.5)
	assert_eq(_wallet.total_earned, 15.5)


func test_spend_lowers_shells_but_not_the_total() -> void:
	_wallet.add(100.0)
	assert_true(_wallet.spend(30.0))
	assert_eq(_wallet.shells, 70.0)
	assert_eq(_wallet.total_earned, 100.0)


func test_spend_fails_without_changes_when_short() -> void:
	_wallet.add(10.0)
	assert_false(_wallet.spend(10.5))
	assert_eq(_wallet.shells, 10.0)
	assert_true(_wallet.spend(10.0), "gastar exactamente todo es posible")
	assert_eq(_wallet.shells, 0.0)


func test_invalid_amounts_are_rejected() -> void:
	assert_false(_wallet.add(-1.0))
	assert_false(_wallet.add(NAN))
	assert_false(_wallet.add(INF))
	assert_false(_wallet.spend(-5.0))
	assert_false(_wallet.spend(NAN))
	assert_eq(_wallet.shells, 0.0)


func test_shells_are_capped() -> void:
	_wallet.add(Wallet.MAX_SHELLS)
	_wallet.add(Wallet.MAX_SHELLS)
	assert_eq(_wallet.shells, Wallet.MAX_SHELLS)
	assert_false(is_inf(_wallet.total_earned))
