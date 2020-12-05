extends PopupDialog
class_name SaveWarning

signal done

var doSave : bool = false

func _onYesButtonPressed():
	doSave = true
	emit_signal('done')
	hide()

func _onNoButtonPressed():
	doSave = false
	emit_signal('done')
	hide()
