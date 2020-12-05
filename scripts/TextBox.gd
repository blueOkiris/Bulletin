extends HBoxContainer
class_name TextBox

const isTask : bool = true

var card = null
var spacer = null

onready var line = $LineEdit
var _mouseOn : bool = false
var _mouseOffset : Vector2 = Vector2.ZERO
var _sorting : bool = false
var _doneSorting : bool = false

func _process(_delta) -> void:
	if _sorting:
		_sortSpacers()
	else:
		if Input.is_action_just_pressed('lose_focus'):
			line.focus_mode = Control.FOCUS_NONE
		else:
			line.focus_mode = Control.FOCUS_ALL
		
		if _mouseOn:
			if Input.is_action_pressed('click'):
				raise()
				rect_global_position = \
					get_global_mouse_position() + _mouseOffset
			elif Input.is_action_just_released('click'):
				var oldCard = card
				_upgradeCard()
				if card != oldCard:
					_sorting = true
					_doneSorting = false
				else:
					_sortSpacers()
			elif _doneSorting:
				rect_global_position = spacer.rect_global_position
				_doneSorting = false
			else:
				_mouseOffset = \
					rect_global_position - get_global_mouse_position()
		else:
			rect_global_position = spacer.rect_global_position
			var titleBoxBottom : int = \
				card.titleBox.rect_global_position.y + card.titleBox.rect_size.y
			var cardBottom : int = \
				card.rect_global_position.y + card.rect_size.y
			visible = \
				rect_global_position.y >= titleBoxBottom - 5 \
				&& rect_global_position.y <= cardBottom - 32
		
		rect_size = spacer.rect_size
		_raiseListButton()

func _upgradeCard() -> void:
	var cardControl = card.get_parent()
	var bestDist : float = INF
	for child in cardControl.get_children():
		if child is Card:
			var dist = rect_global_position.distance_to(
				child.rect_global_position
			)
			if dist < bestDist:
				bestDist = dist
				card.list.remove_child(spacer)
				card = child
				card.list.add_child(spacer)

func _raiseListButton() -> void:
	for child in spacer.get_parent().get_children():
		if child is Button:
			child.raise()

# Change to move spacers up
func _sortSpacers() -> void:
	var spacers = card.list.get_children()
	var closeInd = _closestSpacer()
	var spacerInd = spacerInd()
	if spacers[closeInd] != spacer:
		var otherY = spacers[closeInd].rect_global_position.y
		var y = spacer.rect_global_position.y
		if otherY < y:
			var oldObj = spacers[spacerInd - 1]
			card.list.remove_child(oldObj)
			card.list.add_child_below_node(spacer, oldObj)
		else:
			print(spacers)
			var oldObj = spacers[spacerInd + 1]
			card.list.remove_child(spacer)
			card.list.add_child_below_node(oldObj, spacer)
		
		_sorting = true
		_doneSorting = false
	else:
		_sorting = false
		_doneSorting = true

func _forceButtonLastInSpacerList() -> void:
	var listChildren = card.list.get_children()
	for ind in range(len(listChildren)):
		if listChildren[ind] is Button && ind + 1 != len(listChildren):
			var btn = listChildren[ind]
			var lastChild = listChildren[len(listChildren) - 1]
			card.list.remove_child(btn)
			card.list.add_child_below_node(lastChild, btn)
			

func spacerInd() -> int:
	_forceButtonLastInSpacerList()
	var spacers = card.list.get_children()
	for ind in range(len(spacers)):
		if spacers[ind] == spacer:
			return ind
	return -1

func _closestSpacer() -> int:
	_forceButtonLastInSpacerList()
	var spacers = card.list.get_children()
	print(spacers)
	var bestDist = INF
	var closest : int = -1
	for ind in range(len(spacers)):
		if spacers[ind] is Button:
			continue
		var dist = spacers[ind].rect_global_position.distance_to(
			rect_global_position
		)
		if dist < bestDist:
			bestDist = dist
			closest = ind
	return closest

func _onCloseButtonPressed():
	spacer.get_parent().remove_child(spacer)
	spacer.queue_free()
	get_parent().remove_child(self)
	queue_free()

func _onMoverMouseEntered():
	_mouseOn = true
	
func _onMoverMouseExited():
	_mouseOn = false
