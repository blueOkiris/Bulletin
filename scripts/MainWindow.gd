extends Control
class_name MainWindow

var _textBoxScene = load('objs/TextBox.tscn')
var _spacerScene = load('objs/Spacer.tscn')
onready var _cardScene = load('objs/Card.tscn')
const minWindowSize : Vector2 = Vector2(800, 600)
const appName : String = 'Bulletin'

onready var _fileBtn = $VBoxContainer/ToolBar/Buttons/HBoxContainer/FileButton
onready var _layoutBtn = \
	$VBoxContainer/ToolBar/Buttons/HBoxContainer/LayoutButton
onready var _openFileDialog = $OpenFileDialog
onready var _saveFileDialog = $SaveFileDialog
onready var _cardGrid = $VBoxContainer/Body/ScrollContainer/CardControl/CardGrid
onready var _saveWarning = $SaveWarning
onready var _errorDialog = $ErrorDialog
var _currFileName : String = 'New File'
var _openNotNew : bool = false
var _fileOpened : bool = false
var changed : bool = false

func _ready() -> void:
	_openFileDialog.current_dir = ProjectSettings.globalize_path("res://")
	_saveFileDialog.current_dir = ProjectSettings.globalize_path("res://")
	OS.min_window_size = minWindowSize
	
	var err = _fileBtn.get_popup().connect(
		'id_pressed', self, '_onFileMenuItemPressed'
	)
	if err != OK:
		throw('Unknown error with initializing file menu')
	err = _layoutBtn.get_popup().connect(
		'id_pressed', self, '_onLayoutMenuItemPressed'
	)
	if err != OK:
		throw('Unknown error with initializing layout menu')

func throw(msg : String) -> void:
	_newFile()
	print('Error: ' + msg)
	_errorDialog.text = msg
	_errorDialog.popup()

func _onLayoutMenuItemPressed(id):
	if id == 0: # Add Column
		var col = len(_cardGrid.gridCols)
		for row in range(len(_cardGrid.gridRows)):
			_cardGrid.addGridLocation(col, row)
	elif id == 1: # Remove Column
		if len(_cardGrid.gridCols) > 1:
			_cardGrid.removeGridColumn(len(_cardGrid.gridCols) - 1)
	elif id == 3: # Add Row
		var row = len(_cardGrid.gridRows)
		for col in range(len(_cardGrid.gridCols)):
			_cardGrid.addGridLocation(col, row)
	elif id == 4: # Remove Row
		if len(_cardGrid.gridRows) > 1:
			_cardGrid.removeGridRow(len(_cardGrid.gridRows) - 1)

func _onFileMenuItemPressed(id):
	if id == 0: # New
		_openNotNew = false
		if _fileOpened && changed:
			_saveWarning.popup()
		else:
			_newFile()
	elif id == 1: # Save
		if !_fileOpened:
			_saveFileDialog.popup()
		elif changed:
			_saveFile()
	elif id == 2: # Save As
		_saveFileDialog.popup()
	elif id == 3: # Open
		_openNotNew = true
		if _fileOpened && changed:
			_saveWarning.popup()
		else:
			_openFileDialog.popup()

func _process(_delta) -> void:
	if changed:
		OS.set_window_title(appName + ' ( ' + _currFileName + '* ) ')
	else:
		OS.set_window_title(appName + ' ( ' + _currFileName + ' ) ')
	
	if Input.is_action_pressed('ctrl'):
		if Input.is_action_just_pressed('ctrl_save'):
			if !_fileOpened || Input.is_action_pressed('shift'):
				_saveFileDialog.popup()
			elif changed:
				_saveFile()
		elif Input.is_action_just_pressed('ctrl_open'):
			_openNotNew = true
			if _fileOpened && changed:
				_saveWarning.popup()
			else:
				_openFileDialog.popup()
		elif Input.is_action_just_pressed('ctrl_new'):
			_openNotNew = false
			if _fileOpened && changed:
				_saveWarning.popup()
			else:
				_newFile()

func _onOpenDialogFileSelected(path):
	_newFile()
	_currFileName = path
	_fileOpened = true
	_openFile()

func _onSaveFileDialogFileSelected(path):
	_currFileName = path
	_fileOpened = true
	_saveFile()

func _onSaveWarningDone():
	if _saveWarning.doSave:
		_saveFile()
	
	if _openNotNew:
		_openFileDialog.popup()
	else:
		_newFile()

"""
XML File:
	<grid num-cols='10' num-rows='5'>
		<card col='4' row='1' title='card example 1'>
			<task text='task 1' index='0'/>
			<task text='task 2' index='1'/>
			...
		</card>
		<card col='6' row='1' title='card example 2'>
			<task text='task 1' index='0'/>
			<task text='task 2' index='1'/>
			...
		</card>
		...
	</grid>
"""
func _openFile() -> void:
	var parser : XMLParser = XMLParser.new()
	if parser.open(_currFileName) != OK:
		throw('Failed to open file!')
	
	if parser.read() != OK || parser.get_node_name() != 'grid':
		throw('Failed to get grid node!')
	
	if !parser.has_attribute('num-cols') || !parser.has_attribute('num-rows'):
		throw('Invalid grid tag in .blt file!')
		return
	
	# No error checking as it will be ZERO if it fails
	var numCols : int = int(parser.get_named_attribute_value_safe('num-cols'))
	var numRows : int = int(parser.get_named_attribute_value_safe('num-rows'))
	for row in range(0, numRows):
		for col in range(0, numCols):
			if !(col == 0 && row == 0):
				_cardGrid.addGridLocation(col, row)
	
	while !(
		parser.get_node_type() == XMLParser.NODE_ELEMENT_END \
		&& parser.get_node_name() == 'grid'
	):
		if parser.read() != OK:
			throw('Failed to continue parsing file')
			return
		while parser.get_node_type() == XMLParser.NODE_TEXT:
			if parser.read() != OK:
				throw('Failed to continue parsing file')
				return
		if parser.get_node_name() != 'card' \
		&& parser.get_node_type() != XMLParser.NODE_ELEMENT_END:
			throw('Unexpectd node in blt file: ' + parser.get_node_name())
			return
		elif parser.get_node_name() == 'card':
			if !parser.has_attribute('row') || !parser.has_attribute('col') \
			|| !parser.has_attribute('title'):
				throw('Invalid card tag in .blt file')
				return
			
			var col = int(parser.get_named_attribute_value_safe('col'))
			var row = int(parser.get_named_attribute_value_safe('row'))
			var cardGridLocation = _cardGrid.gridLocations[row * numCols + col]
			
			var title : String = parser.get_named_attribute_value_safe('title')
			title = title.replace('\\n', ' ')
			title = title.replace('\\\\', '\\')
			title = title.replace('\\s', ' ')
			title = title.replace('\\t', '    ')
			
			var newCard : Card = _cardScene.instance()
			_cardGrid.get_parent().add_child(newCard)
			newCard.raise()
			newCard.titleBox.text = title
			newCard.gridLocation = cardGridLocation
			_cardGrid.updateCardsAndLocations()
			
			if parser.read() != OK:
				throw('Failed to continue parsing file')
				return
			while parser.get_node_type() == XMLParser.NODE_TEXT:
				if parser.read() != OK:
					throw('Failed to continue parsing file')
					return
			
			var tasks : Array = []
			while parser.get_node_name() == 'task':
				if !parser.has_attribute('index'):
					throw('No index on task')
					return
				var index = int(parser.get_named_attribute_value_safe('index'))
				
				if parser.read() != OK:
					throw('Failed to continue parsing file')
					return
				var text : String = parser.get_node_data()
				text = text.replace('\\n', ' ')
				text = text.replace('\\\\', '\\')
				text = text.replace('\\s', ' ')
				text = text.replace('\\t', '    ')
				
				if parser.read() != OK:
					throw('Failed to continue parsing file')
					return
				if parser.get_node_type() != XMLParser.NODE_ELEMENT_END \
				|| parser.get_node_name() != 'task':
					throw('Missing closing tag for task!')
					return
				if parser.read() != OK:
					throw('Failed to continue parsing file')
					return
				while parser.get_node_type() == XMLParser.NODE_TEXT:
					if parser.read() != OK:
						throw('Failed to continue parsing file')
						return
				
				var spacer = _spacerScene.instance()
				newCard.list.add_child(spacer)
				newCard.addTextBoxBtn.raise()
				tasks.append([ index, text ])
			
			for task in tasks:
				var newTextBox = _textBoxScene.instance()
				newCard.get_parent().add_child(newTextBox)
				newTextBox.card = newCard
				newTextBox.spacer = newCard.list.get_children()[task[0]]
				if task[1] != '':
					newTextBox.line.text = task[1]
			
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END \
		&& parser.get_node_name() != 'grid':
			if parser.read() != OK:
				throw('Failed to continue parsing file')
				return

func _saveFile() -> void:
	var xml : String = \
		'<grid num-cols=\'' + str(len(_cardGrid.gridCols)) \
		+ '\' num-rows=\'' + str(len(_cardGrid.gridRows)) \
		+ '\' >\n'
	
	var tasks : Array = []
	var cards : Array = []
	for child in _cardGrid.get_parent().get_children():
		if child.isTask:
			tasks.append([
				child.spacerInd(),
				child.line.text.replace('\\', '\\\\').replace(' ', '\\s'),
				child.card.gridLocation.row, child.card.gridLocation.col 
			])
		if child is Card:
			cards.append([
				child.gridLocation.col, child.gridLocation.row,
				child.titleBox.text.replace('\\', '\\\\').replace(' ', '\\s')
			])
	for card in cards:
		xml += \
			'    <card col=\'' + str(card[0]) + '\' row=\'' + str(card[1]) \
			+ '\' title=\'' + card[2] + '\' >\n'
		
		for task in tasks:
			if task[2] == card[0] && task[3] == card[1]:
				xml += \
					'        <task index=\'' + str(task[0]) + '\'>' \
					+ task[1] \
					+ '</task>\n'
		
		xml += '    </card>\n'
	
	xml += '</grid>\n'
	
	var file = File.new()
	file.open(_currFileName, File.WRITE)
	file.store_string(xml)
	file.close()
	
	changed = false

func _newFile() -> void:
	_cardGrid.newFile()
	_currFileName = 'New File'
	_fileOpened = false
