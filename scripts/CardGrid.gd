extends GridContainer
class_name CardGrid

const isTask : bool = false

var cards : Array = []
var gridLocations : Array = []
var gridRows : Array = []
var gridCols : Array = []

onready var _gridLocScene = load('objs/GridLocation.tscn')

func _ready() -> void:
	addGridLocation(0, 0)

func newFile() -> void:
	for child in get_parent().get_children():
		if child.isTask:
			get_parent().remove_child(child)
			child.queue_free()
	
	cards = []
	for child in get_parent().get_children():
		if child is Card:
			get_parent().remove_child(child)
			child.queue_free()
	
	gridLocations = []
	gridRows = []
	gridCols = []
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	addGridLocation(0, 0)

func removeGridColumn(col : int) -> void:
	# Check for filled columns
	for child in get_parent().get_children():
		if child is Card:
			if child.gridLocation.col == col:
				return
	
	# Everything's good let's delete!
	var rng = range(len(gridRows))
	rng.invert()
	for row in rng:
		print(gridLocations)
		var child = gridLocations[row * columns + col]
		remove_child(child)
		child.queue_free()
	updateCardsAndLocations()

func removeGridRow(row : int) -> void:
	# Check for filled rows
	for child in get_parent().get_children():
		if child is Card:
			if child.gridLocation.row == row:
				return
	
	# Everything's good let's delete!
	var rng = range(len(gridCols))
	rng.invert()
	for col in rng:
		var child = gridLocations[row * columns + col]
		remove_child(child)
		child.queue_free()
	updateCardsAndLocations()

func addGridLocation(col : int, row : int) -> void:
	var loc : GridLocation = _gridLocScene.instance()
	add_child(loc)
	loc.col = col
	loc.row = row
	updateCardsAndLocations()

func updateCardsAndLocations() -> void:
	cards = []
	gridLocations = []
	gridRows = []
	gridCols = []
	var children : Array = get_children()
	for child in children:
		if child is GridLocation:
			gridLocations.append(child)
			while !(child.row < len(gridRows)):
				gridRows.append(null)
			gridRows[child.row] = child
			while !(child.col < len(gridCols)):
				gridCols.append(null)
			gridCols[child.col] = child
	columns = len(gridCols)
	for child in children:
		move_child(child, child.row * columns + child.col)
