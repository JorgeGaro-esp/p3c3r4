class_name AutostartCommand
extends RefCounted
## Argumentos de `reg.exe` para activar o quitar el arranque con Windows (P09).
##
## Solo construye listas de argumentos; no ejecuta nada. Quien las ejecuta es
## `Platform`, la única pieza del juego autorizada a llamar a `OS.execute`
## (excepción anotada en 07-DECISIONES, T26). Se usa la clave de usuario
## HKCU\...\Run, que no necesita permisos de administrador.

const RUN_KEY: String = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
const VALUE_NAME: String = "P3C3R4"
const _DRIVE_SEPARATOR: String = ":\\"


## Una ruta es segura si es absoluta de Windows, termina en `.exe` y no contiene
## comillas ni caracteres de control, que romperían el comando.
static func is_safe_path(path: String) -> bool:
	var native: String = to_native(path)
	if native.length() < 7 or not native.to_lower().ends_with(".exe"):
		return false
	if native.substr(1, 2) != _DRIVE_SEPARATOR:
		return false
	for index: int in range(native.length()):
		var code: int = native.unicode_at(index)
		if code < 32 or native[index] == '"':
			return false
	return true


## Ruta con barras de Windows (`C:/a/b.exe` → `C:\a\b.exe`).
static func to_native(path: String) -> String:
	return path.replace("/", "\\")


## Argumentos para registrar [param executable_path] al iniciar sesión. Lista
## vacía si la ruta no es segura.
static func add_arguments(executable_path: String) -> PackedStringArray:
	if not is_safe_path(executable_path):
		return PackedStringArray()
	return PackedStringArray(
		[
			"add",
			RUN_KEY,
			"/v",
			VALUE_NAME,
			"/t",
			"REG_SZ",
			"/d",
			'"%s"' % to_native(executable_path),
			"/f",
		]
	)


## Argumentos para quitar el registro.
static func delete_arguments() -> PackedStringArray:
	return PackedStringArray(["delete", RUN_KEY, "/v", VALUE_NAME, "/f"])
