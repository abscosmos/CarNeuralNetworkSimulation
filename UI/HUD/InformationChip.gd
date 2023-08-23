class_name InformationChip extends TextureRect;

@onready var title: Label = $Control/MarginContainer/VBoxContainer/Title;
@onready var information: Label = $Control/MarginContainer/VBoxContainer/Information;

var info_text:
	get: return information.text;
	set(text): information.text = str(text);
