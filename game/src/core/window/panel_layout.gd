class_name PanelLayout
extends RefCounted
## Reparto de la ventana en celdas: zona de pecera, barra lateral y panel.
##
## Es la base del prototipo de la decisión P02. Con [constant SettingsData.PanelMode.REPLACE]
## el panel tapa la zona de pecera y la ventana no cambia de altura. Con
## [constant SettingsData.PanelMode.GROW_UP] la ventana crece hacia arriba y el
## panel ocupa la parte nueva, dejando la pecera visible debajo.

## Ancho de la barra lateral en columnas.
const SIDEBAR_WIDTH: int = 20
## Filas que añade el modo GROW_UP cuando hay sitio.
const GROW_ROWS: int = 14
## Con menos filas nuevas que estas, el panel no cabe encima y se usa REPLACE.
const MIN_GROW_ROWS: int = 8

## Zona donde vive la pecera.
var tank_rect: Rect2i = Rect2i()
var sidebar_rect: Rect2i = Rect2i()
## Zona del panel abierto; sin área si no hay panel.
var panel_rect: Rect2i = Rect2i()


## Filas totales que debe tener la ventana. [param available_rows] son las que
## caben en la pantalla.
static func total_rows(
	strip_rows: int, mode: SettingsData.PanelMode, is_open: bool, available_rows: int
) -> int:
	if not is_open or mode != SettingsData.PanelMode.GROW_UP:
		return strip_rows
	var wanted: int = strip_rows + GROW_ROWS
	var room: int = maxi(available_rows, strip_rows)
	if room - strip_rows < MIN_GROW_ROWS:
		return strip_rows
	return mini(wanted, room)


## Modo que se aplica de verdad: GROW_UP sin sitio para crecer (pantalla
## pequeña) se comporta como REPLACE. [param wanted_rows] sale de [method total_rows].
static func effective_mode(
	mode: SettingsData.PanelMode, strip_rows: int, wanted_rows: int, is_open: bool
) -> SettingsData.PanelMode:
	if mode == SettingsData.PanelMode.GROW_UP and is_open and wanted_rows <= strip_rows:
		return SettingsData.PanelMode.REPLACE
	return mode


## Calcula el reparto para una ventana de [param columns] × [param rows] celdas
## cuya franja base mide [param strip_rows] filas.
static func compute(
	columns: int, rows: int, strip_rows: int, mode: SettingsData.PanelMode, is_open: bool
) -> PanelLayout:
	var layout: PanelLayout = PanelLayout.new()
	var side: int = mini(SIDEBAR_WIDTH, columns)
	var extra: int = maxi(rows - strip_rows, 0)
	var grows: bool = mode == SettingsData.PanelMode.GROW_UP and extra >= MIN_GROW_ROWS
	if grows:
		layout.tank_rect = Rect2i(0, extra, columns - side, rows - extra)
		layout.sidebar_rect = Rect2i(columns - side, extra, side, rows - extra)
		if is_open:
			layout.panel_rect = Rect2i(0, 0, columns, extra)
	else:
		layout.tank_rect = Rect2i(0, 0, columns - side, rows)
		layout.sidebar_rect = Rect2i(columns - side, 0, side, rows)
		if is_open and mode == SettingsData.PanelMode.REPLACE:
			layout.panel_rect = layout.tank_rect
	return layout
