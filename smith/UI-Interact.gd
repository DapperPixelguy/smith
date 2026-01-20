extends Node
var ForgeOpen = false

func _ready():
	TimeManager.day_ended.connect(TickUpdated)
	$CanvasLayer/Button.pressed.connect(TweenForge)

func TickUpdated():
	return 0

func TweenForge():
	print("TweenForge called!")
	print("ForgeOpen is: ", ForgeOpen)
	print("Current offset: ", $CanvasLayer.offset)
	
	var tween = create_tween()
	if ForgeOpen:
		print("Closing - tweening to: ", get_viewport().get_visible_rect().size.y)
		tween.tween_property($CanvasLayer, "offset:y", get_viewport().get_visible_rect().size.y, 0.5)
		ForgeOpen = false
	else:
		print("Opening - tweening to: 0")
		tween.tween_property($CanvasLayer, "offset:y", 0, 0.5)
		ForgeOpen = true
	
	print("New ForgeOpen state: ", ForgeOpen)
