extends GutTest
## Las plantas del fondo: varias formas por bioma.


func _view(id: String) -> SeaweedView:
	var look: BiomeDef = load("res://content/biomes/%s.tres" % id) as BiomeDef
	var view: SeaweedView = SeaweedView.new()
	view.configure(240, 20, 8, look)
	return view


func test_every_biome_grows_plants_of_several_shapes() -> void:
	for id: String in ["pond", "reef", "mangrove", "abyss"]:
		var counts: Dictionary[WeedForm.Kind, int] = _view(id).kind_counts()
		assert_gte(counts.size(), 3, "%s: formas distintas" % id)


func test_without_forms_the_plants_are_the_classic_stalks() -> void:
	var look: BiomeDef = BiomeDef.new()
	var view: SeaweedView = SeaweedView.new()
	view.configure(120, 20, 8, look)
	var counts: Dictionary[WeedForm.Kind, int] = view.kind_counts()
	assert_eq(counts.size(), 1)
	assert_true(counts.has(WeedForm.Kind.STALK))


func test_same_seed_gives_the_same_garden() -> void:
	assert_eq(_view("pond").kind_counts(), _view("pond").kind_counts())


func test_short_water_only_gets_the_low_shapes() -> void:
	var look: BiomeDef = load("res://content/biomes/pond.tres") as BiomeDef
	var view: SeaweedView = SeaweedView.new()
	view.configure(240, 20, 1, look)
	var counts: Dictionary[WeedForm.Kind, int] = view.kind_counts()
	for kind: WeedForm.Kind in counts:
		assert_true(kind == WeedForm.Kind.TUFT, "solo matas cuando solo cabe una fila")
