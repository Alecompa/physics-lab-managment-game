extends SceneTree
# Offline sprite bake. Source GLBs are Kenney Furniture Kit; no 3D scene ships at runtime.
const SOURCE = "res://tools/art_sources/furniture/"
const OUTPUT = "res://assets/kenney/furniture/"
func _initialize() -> void: call_deferred("run")
func bounds(node: Node3D) -> AABB:
	var result = AABB()
	var first = true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var box = mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
func model(name: String, parent: Node3D) -> Node3D:
	var document = GLTFDocument.new()
	var state = GLTFState.new()
	var error = document.append_from_file(SOURCE + name + ".glb", state)
	assert(error == OK, "Cannot load furniture model")
	var instance = document.generate_scene(state)
	parent.add_child(instance)
	return instance
func run() -> void:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(384, 384)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world = Node3D.new(); viewport.add_child(world)
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0,0,0,0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e0f2ff")
	environment.environment.ambient_light_energy = 0.3
	world.add_child(environment)
	var sun = DirectionalLight3D.new(); world.add_child(sun)
	sun.rotation_degrees = Vector3(-50, -25, 0); sun.light_energy = 0.75
	var camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; world.add_child(camera); camera.current = true
	var names = {"desk":"desk", "bed":"bedSingle", "chair":"chairDesk", "plant":"pottedPlant", "shelf":"bookcaseOpen", "sink":"kitchenSink", "counter":"kitchenCabinet", "coffee":"kitchenCoffeeMachine", "armchair":"loungeChair", "table":"tableCoffee"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for key in names:
		var pivot = Node3D.new(); world.add_child(pivot)
		model(names[key], pivot)
		if key == "desk":
			var desk_bounds = bounds(pivot)
			var monitor = model("computerScreen", pivot)
			monitor.position = Vector3(-0.15, desk_bounds.end.y, -0.12)
			var keyboard = model("computerKeyboard", pivot)
			keyboard.position = Vector3(-0.15, desk_bounds.end.y + 0.01, 0.16)
			var mouse = model("computerMouse", pivot)
			mouse.position = Vector3(0.30, desk_bounds.end.y + 0.01, 0.18)
		var box = bounds(pivot)
		var center = box.get_center()
		camera.position = center + Vector3(0, 6, 4)
		camera.look_at(center)
		camera.size = maxf(box.size.x, box.size.y * 0.56 + box.size.z * 0.84) * 1.22
		for i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		var picture = viewport.get_texture().get_image()
		var used = picture.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, picture.get_size()))
		picture.get_region(used).save_png(OUTPUT + key + ".png")
		pivot.queue_free(); await process_frame
	print("Furniture sprites baked: ", names.size())
	quit()
