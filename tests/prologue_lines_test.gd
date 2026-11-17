extends "res://tests/support/story_test.gd"
## The in-game line table must match the approved dialogue sheet, ID for ID.

const Lines = preload("res://scripts/prologue_lines.gd")
const SHEET := "res://docs/prologue/Kath_Prologue_Dialogue_Lines_v1_3.csv"


func _run() -> void:
	var file := FileAccess.open(SHEET, FileAccess.READ)
	if file == null:
		_fail("Could not open the dialogue sheet.")
		return
	var header := file.get_csv_line()
	var id_column := header.find("dialogue_id")
	var text_column := header.find("english_text")
	if id_column < 0 or text_column < 0:
		_fail("The dialogue sheet has no dialogue_id / english_text columns.")
		return
	var seen := {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() <= text_column or row[id_column].strip_edges().is_empty():
			continue
		var id := row[id_column].strip_edges()
		seen[id] = true
		if not Lines.LINES.has(id):
			_fail("Line %s is in the sheet but not in the game table." % id)
			return
		if Lines.LINES[id] != row[text_column]:
			_fail("Line %s differs from the sheet: '%s'" % [id, Lines.LINES[id]])
			return
	for id in Lines.LINES:
		if not seen.has(id):
			_fail("Line %s is in the game table but not in the sheet." % id)
			return
	_pass("%d lines match the v1.3 sheet" % seen.size())
