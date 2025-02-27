extends Camera2D
var game:Node

# self = game.camera

var is_panning:bool = false
var pan_position:Vector2 = Vector2.ZERO
var zoom_default:Vector2 = Vector2.ONE
var zoom_limit:Vector2 = Vector2.ONE
var margin:int = limit_right;
var position_limit:int = 756
var arrow_keys_speed:int = 4
var arrow_keys_move:Vector2 = Vector2.ZERO


func _ready():
	game = get_tree().get_current_scene()
	zoom = zoom_default
	yield(get_tree(), "idle_frame")


func _unhandled_input(event):
	# KEYBOARD
	if event is InputEventKey:
		
		# ARROW KEYS
		match event.scancode:
			
			# cam zoom test
#			KEY_Q: game.camera.zoom_out()
#			KEY_W: game.camera.zoom_reset()
#			KEY_E: game.camera.zoom_in()
			
			#
			KEY_1: focus_leader(1)
			KEY_2: focus_leader(2)
			KEY_3: focus_leader(3)
			KEY_4: focus_leader(4)
			KEY_5: focus_leader(5)
			
			
			KEY_LEFT:  arrow_keys_move.x = -arrow_keys_speed if event.is_pressed() else 0
			KEY_RIGHT: arrow_keys_move.x =  arrow_keys_speed if event.is_pressed() else 0
			KEY_UP:    arrow_keys_move.y = -arrow_keys_speed if event.is_pressed() else 0
			KEY_DOWN:  arrow_keys_move.y =  arrow_keys_speed if event.is_pressed() else 0
		
		# NUMBER KEYPAD
		if not event.is_pressed():
			var cam_move = null;
			var x = position_limit*0.93
			match event.scancode:
				KEY_KP_1: cam_move = [-x, x]
				KEY_KP_2: cam_move = [0, x]
				KEY_KP_3: cam_move = [x, x]
				KEY_KP_4: cam_move = [-x, 0]
				KEY_KP_5: cam_move = [0, 0]
				KEY_KP_6: cam_move = [x, 0]
				KEY_KP_7: cam_move = [-x, -x]
				KEY_KP_8: cam_move = [0, -x]
				KEY_KP_9: cam_move = [x, -x]
			
			if cam_move: 
				zoom_reset()
				global_position = Vector2(cam_move[0], cam_move[1])
	
	if game:
		var over_minimap = game.ui.minimap.over_minimap(event)
		# MOUSE PAN
		if event.is_action("pan") and not over_minimap:
			is_panning = event.is_action_pressed("pan")
		elif event is InputEventMouseMotion:
			if is_panning: pan_position = Vector2(-1 * event.relative)
		
		
		# TOUCH PAN
		if event is InputEventScreenTouch and not over_minimap:
			is_panning = event.is_pressed()
		elif event is InputEventScreenDrag:
			if is_panning: pan_position = Vector2(-1 * event.relative)
		
	
	# ZOOM
	if event.is_action_pressed("zoom_in"):
		if zoom.x >= 1:
			var point = game.camera.get_global_mouse_position()
			game.camera.global_position = point - game.map.mid
		if zoom.x == zoom_limit.y: zoom_reset()
		elif zoom == zoom_default: zoom_in()
	if event.is_action_pressed("zoom_out"):
		if zoom.x == zoom_limit.x: zoom_reset()
		elif zoom == zoom_default: zoom_out()


func start():
	offset = game.map.mid
	var h = offset.x
	limit_left = -h
	limit_top = -h
	limit_right = h
	limit_bottom = h
	margin = h


func focus_leader(index):
	if game.player_leaders.size() >= index:
		var leader = game.player_leaders[index-1]
		if leader:
			game.camera.global_position = leader.global_position - game.camera.offset
			game.selection.select_unit(leader)
			var buttons = game.ui.leaders_icons.buttons_name
			for all_leader_name in buttons: 
				buttons[all_leader_name].pressed = false
			buttons[leader.name].pressed = true


func zoom_reset(): 
	zoom = zoom_default
	game.ui.minimap.corner_view()
	game.unit.hud.hide_hpbars()
	
	
func zoom_in(): 
	zoom = Vector2(zoom_limit.x,zoom_limit.x)
	game.ui.minimap.corner_view()
	game.unit.hud.show_hpbars()
	
	
func zoom_out(): 
	zoom = Vector2(zoom_limit.y, zoom_limit.y)
	game.ui.minimap.hide_view()


func process():
	var ratio = get_viewport().size.x / get_viewport().size.y
	
	# APPLY MOUSE PAN
	if is_panning: translate(pan_position * zoom.x)
	# APPLY KEYBOARD PAN
	else: translate(arrow_keys_move)
	
	pan_position = Vector2.ZERO
	
	# KEEP CAMERA PAN LIMITS
	if global_position.x > margin: global_position.x = margin
	if global_position.x < -margin: global_position.x = -margin
	if global_position.y > margin: global_position.y = margin
	if global_position.y < -margin: global_position.y = -margin
	
	# ADJUST CAMERA PAN LIMITS TO SCREEN RATIO
	limit_top = -margin
	limit_bottom = margin
	limit_left = -margin
	limit_right = margin
	
	var s = 0.65
	if ratio >= 1 and zoom.x > 1:
		limit_left = -margin - (margin * (ratio-1) * (zoom.x-zoom_limit.x) * s)
		limit_right = margin + (margin * (ratio-1) * (zoom.x-zoom_limit.x) * s)

	if ratio < 1 and zoom.x > 1:
		limit_top = -margin - (margin * ((1/ratio)-1) * (zoom.x-zoom_limit.x) * s)
		limit_bottom = margin + (margin * ((1/ratio)-1) * (zoom.x-zoom_limit.x)* s)
	
