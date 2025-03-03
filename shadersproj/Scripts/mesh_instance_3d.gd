extends MeshInstance3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mesh.material.set_shader_parameter("height_scale", 0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
