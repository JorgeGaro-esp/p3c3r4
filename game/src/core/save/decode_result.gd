class_name DecodeResult
extends RefCounted
## Resultado de leer una partida: el estado o el motivo por el que no se pudo.

enum Status { OK, MALFORMED, CHECKSUM, TOO_NEW, INVALID }

var status: Status = Status.MALFORMED
var state: GameState = null
## Avisos no fatales (valores recortados, peces descartados…).
var warnings: PackedStringArray = PackedStringArray()
## Motivo del fallo, para el registro.
var reason: String = ""


func is_ok() -> bool:
	return status == Status.OK and state != null


static func failure(new_status: Status, why: String) -> DecodeResult:
	var result: DecodeResult = DecodeResult.new()
	result.status = new_status
	result.reason = why
	return result
