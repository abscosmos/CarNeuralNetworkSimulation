class_name NetworkLayerNode extends HBoxContainer;

@onready var line_edit: LineEdit = $Number;

@export var min_value: int = 1;
@export var max_value: int = 100;

var regex := RegEx.new();
var old_text: String = "";

signal layer_update;
signal delete_layer_node(_self);

var layer_value: int:
	set(n):
		line_edit.text = str(clamp(int(n), min_value, max_value));
	get:
		return int(line_edit.text);

func _ready() -> void:
	regex.compile("^[0-9]*$");

func _on_line_edit_text_changed(new_text: String) -> void:
	var caret_pos: int = line_edit.caret_column;
	if regex.search(new_text):
		line_edit.text = new_text;
		old_text = line_edit.text;
		line_edit.caret_column = caret_pos;
	else:
		line_edit.text = old_text;
		line_edit.caret_column = caret_pos - 1;

func _on_line_edit_text_submitted(new_text: String) -> void:
	var caret_pos: int = line_edit.caret_column;
	if line_edit.text.length() != 0:
		line_edit.text = str(clamp(int(new_text), min_value, max_value));
		old_text = str(clamp(int(new_text), min_value, max_value));
	line_edit.caret_column = caret_pos;
	emit_signal("layer_update");
	
func _on_delete_pressed() -> void:
	emit_signal("delete_layer_node", self);

func _on_line_edit_focus_exited() -> void:
	var caret_pos: int = line_edit.caret_column;
	if line_edit.text.length() != 0:
		line_edit.text = str(clamp(int(line_edit.text), min_value, max_value));
		old_text = str(clamp(int(line_edit.text), min_value, max_value));
	line_edit.caret_column = caret_pos;
	emit_signal("layer_update");
