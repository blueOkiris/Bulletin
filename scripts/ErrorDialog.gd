extends PopupDialog
class_name ErrorDialog

var text : String = ''

onready var _message = $MarginContainer/VBoxContainer/Message

func _process(_delta) -> void:
	_message.text = text

func _onOkayButtonPressed():
	hide()
