extends ViewportContainer
class_name GridLocation

onready var panelContainer = $PanelContainer
var col : int = 0
var row : int = 0

onready var _cardScene = load('objs/Card.tscn')

func isCovered(skip : Card = null) -> bool:
	var cards : Array = []
	var cardControl = get_parent().get_parent()
	for child in cardControl.get_children():
		if child is Card && child != skip:
			cards.append(child)
	for card in cards:
		if rect_global_position.distance_to(card.rect_global_position) == 0:
			return true
	return false

func _onNewCardButtonPressed():
	if !isCovered():
		var newCard : Card = _cardScene.instance()
		var cardControl = get_parent().get_parent()
		cardControl.add_child(newCard)
		newCard.raise()
		newCard.gridLocation = self
		get_parent().updateCardsAndLocations()
		
		var body = get_parent().get_parent().get_parent().get_parent()
		var window = body.get_parent().get_parent()
		window.changed = true

func _onAddColumnButtonpressed():
	if col + 1 == len(get_parent().gridCols):
		for gridRow in range(len(get_parent().gridRows)):
			get_parent().addGridLocation(col + 1, gridRow)
		
		var body = get_parent().get_parent().get_parent().get_parent()
		var window = body.get_parent().get_parent()
		window.changed = true

func _onRemoveColumnButtonPressed():
	if len(get_parent().gridCols) > 1:
		get_parent().removeGridColumn(col)
		
		var body = get_parent().get_parent().get_parent().get_parent()
		var window = body.get_parent().get_parent()
		window.changed = true

func _onAddRowButtonPressed():
	if row + 1 == len(get_parent().gridRows):
		for gridCol in range(len(get_parent().gridCols)):
			get_parent().addGridLocation(gridCol, row + 1)
		
		var body = get_parent().get_parent().get_parent().get_parent()
		var window = body.get_parent().get_parent()
		window.changed = true

func _onRemoveRowButtonPressed():
	if len(get_parent().gridRows) > 1:
		get_parent().removeGridRow(row)
		
		var body = get_parent().get_parent().get_parent().get_parent()
		var window = body.get_parent().get_parent()
		window.changed = true

