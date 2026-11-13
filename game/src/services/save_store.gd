class_name SaveStore
extends RefCounted
## Archivos de guardado en disco: escritura atómica con copias rotativas.
##
## Solo mueve texto; no sabe qué hay dentro (eso es de [SaveCodec]). Todo ocurre
## dentro de [member directory], por defecto `user://saves` (06-SEGURIDAD §2 y §4).

const DEFAULT_DIRECTORY: String = "user://saves"
const MAIN_FILE: String = "save.json"
const TEMP_FILE: String = "save.tmp"
const BACKUP_COUNT: int = 3
const QUARANTINE_PREFIX: String = "corrupt_"
const MAX_QUARANTINED: int = 5

var directory: String = DEFAULT_DIRECTORY


func _init(new_directory: String = DEFAULT_DIRECTORY) -> void:
	directory = new_directory


## Nombre de la copia número [param number] (1 es la más reciente).
static func backup_name(number: int) -> String:
	return "save.bak%d.json" % number


## Archivos que existen y pueden contener una partida, de mejor a peor candidato:
## el principal, las copias y, por último, el temporal (la suma de comprobación
## descarta uno que se quedara a medio escribir).
func candidates() -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var names: PackedStringArray = PackedStringArray([MAIN_FILE])
	for number: int in range(1, BACKUP_COUNT + 1):
		names.append(backup_name(number))
	names.append(TEMP_FILE)
	for file_name: String in names:
		if FileAccess.file_exists(_path(file_name)):
			found.append(file_name)
	return found


## Lee un archivo como texto. Devuelve "" si no existe o pasa de [constant SaveCodec.MAX_BYTES].
func read(file_name: String) -> String:
	var file: FileAccess = FileAccess.open(_path(file_name), FileAccess.READ)
	if file == null:
		return ""
	if file.get_length() > SaveCodec.MAX_BYTES:
		return ""
	return file.get_as_text()


## Guarda [param text] como partida principal, rotando las copias. Si algo falla
## deja intacto el guardado anterior y devuelve falso.
func write(text: String) -> bool:
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return false
	if not _write_temp(text):
		return false
	_rotate()
	if DirAccess.rename_absolute(_path(TEMP_FILE), _path(MAIN_FILE)) != OK:
		# Sin partida principal: devolver la última copia a su sitio.
		DirAccess.rename_absolute(_path(backup_name(1)), _path(MAIN_FILE))
		return false
	return true


## Aparta un archivo dañado con otro nombre para no perderlo ni rotarlo a las
## copias. Conserva solo los [constant MAX_QUARANTINED] más recientes.
func quarantine(file_name: String, unix_time: int) -> bool:
	var target: String = "%s%d_%s" % [QUARANTINE_PREFIX, unix_time, file_name]
	var moved: bool = DirAccess.rename_absolute(_path(file_name), _path(target)) == OK
	_prune_quarantine()
	return moved


func exists(file_name: String) -> bool:
	return FileAccess.file_exists(_path(file_name))


## Nombres de los archivos apartados, ordenados.
func quarantined() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.begins_with(QUARANTINE_PREFIX):
			result.append(file_name)
	result.sort()
	return result


func _write_temp(text: String) -> bool:
	var file: FileAccess = FileAccess.open(_path(TEMP_FILE), FileAccess.WRITE)
	if file == null:
		return false
	var stored: bool = file.store_string(text)
	file.close()
	if not stored or file.get_error() != OK:
		return false
	# Comprobar lo escrito: leerlo de vuelta y compararlo.
	return FileAccess.get_file_as_string(_path(TEMP_FILE)) == text


func _rotate() -> void:
	_remove(backup_name(BACKUP_COUNT))
	for number: int in range(BACKUP_COUNT - 1, 0, -1):
		_move(backup_name(number), backup_name(number + 1))
	_move(MAIN_FILE, backup_name(1))


func _move(from_name: String, to_name: String) -> void:
	if FileAccess.file_exists(_path(from_name)):
		_remove(to_name)
		DirAccess.rename_absolute(_path(from_name), _path(to_name))


func _remove(file_name: String) -> void:
	if FileAccess.file_exists(_path(file_name)):
		DirAccess.remove_absolute(_path(file_name))


func _prune_quarantine() -> void:
	var names: PackedStringArray = quarantined()
	while names.size() > MAX_QUARANTINED:
		_remove(names[0])
		names.remove_at(0)


func _path(file_name: String) -> String:
	return directory.path_join(file_name)
