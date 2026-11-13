class_name Unlocks
extends RefCounted
## Condiciones de desbloqueo de las especies (GDD §4.2). Funciones puras sobre el
## estado: el dato (`unlock_kind`, `unlock_amount`) vive en la [SpeciesDef].


## Verdadero si [param def] cumple su condición con el estado actual.
static func is_met(def: SpeciesDef, state: GameState) -> bool:
	return progress_value(def, state) >= required_value(def)


## Valor que se pide (0 si no hay condición).
static func required_value(def: SpeciesDef) -> float:
	if def.unlock_kind == SpeciesDef.UnlockKind.NONE:
		return 0.0
	return def.unlock_amount


## Valor actual de lo que se mide, sin recortar al requisito.
static func progress_value(def: SpeciesDef, state: GameState) -> float:
	match def.unlock_kind:
		SpeciesDef.UnlockKind.TOTAL_EARNED:
			return state.wallet.total_earned
		SpeciesDef.UnlockKind.FISH_COUNT:
			return float(state.fish_total())
		SpeciesDef.UnlockKind.SPECIES_COUNT:
			return float(state.count_of(def.unlock_species_id))
		_:
			return 0.0


## Avance de 0 a 1 hacia el desbloqueo.
static func progress_ratio(def: SpeciesDef, state: GameState) -> float:
	var needed: float = required_value(def)
	if needed <= 0.0:
		return 1.0
	return clampf(progress_value(def, state) / needed, 0.0, 1.0)
