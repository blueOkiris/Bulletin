extends Panel
class_name Card

const isTask : bool = false

onready var titleBox = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit
onready var addTextBoxBtn = \
	$MarginContainer/VBoxContainer/ScrollContainer/List/AddTextBox
onready var list = $MarginContainer/VBoxContainer/ScrollContainer/List
var gridLocation = null

var _textBoxScene = load('objs/TextBox.tscn')
var _spacerScene = load('objs/Spacer.tscn')
onready var _title = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit
var _mouseOn : bool = false
var _mouseOffset : Vector2 = Vector2.ZERO

func _process(_delta) -> void:
	if _mouseOn:
		if Input.is_action_pressed('click'):
			raise()
			rect_global_position = get_global_mouse_position() + _mouseOffset
		elif Input.is_action_just_released('click'):
			_updateGridLocation()
			rect_global_position = gridLocation.rect_global_position
			for child in get_parent().get_children():
				if child.isTask:
					child.raise()
			var body = get_parent().get_parent().get_parent()
			var window = body.get_parent().get_parent()
			window.changed = true
		else:
			_mouseOffset = rect_global_position - get_global_mouse_position()
	else:
		rect_global_position = gridLocation.rect_global_position
	
	if Input.is_action_just_pressed('lose_focus'):
		_title.focus_mode = Control.FOCUS_NONE
	else:
		_title.focus_mode = Control.FOCUS_ALL

func _updateGridLocation() -> void:
	var cardGrid = gridLocation.get_parent()
	var bestDist : float = INF
	for loc in cardGrid.gridLocations:
		var dist = rect_global_position.distance_to(loc.rect_global_position)
		if dist < bestDist && !loc.isCovered(self):
			gridLocation = loc
			bestDist = dist

func _onMoverMouseEntered():
	_mouseOn = true

func _onMoverMouseExited():
	_mouseOn = false

func _onAddTextBoxPressed():
	var newTextBox = _textBoxScene.instance()
	var spacer = _spacerScene.instance()
	get_parent().add_child(newTextBox)
	newTextBox.card = self
	newTextBox.spacer = spacer
	list.add_child(spacer)
	addTextBoxBtn.raise()
	
	var body = get_parent().get_parent().get_parent()
	var window = body.get_parent().get_parent()
	window.changed = true

func _onCloseButtonPressed():
	for child in get_parent().get_children():
		if child.isTask:
			if child.card == self:
				child.queue_free()
	queue_free()
