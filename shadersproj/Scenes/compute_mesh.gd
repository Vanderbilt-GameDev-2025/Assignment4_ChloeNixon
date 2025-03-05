extends MeshInstance3D

func get_plane_vertices(mesh_instance: MeshInstance3D) -> Array:
	var mesh: PlaneMesh = mesh_instance.mesh
	if not mesh:
		push_error("MeshInstance3D does not have a valid mesh")
		return []
	
	var vertices = []
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh, 0)
	var array_mesh = surface_tool.commit()
	
	if array_mesh:
		var mesh_data = array_mesh.surface_get_arrays(0)
		var vertex_array = mesh_data[ArrayMesh.ARRAY_VERTEX]
		
		for vertex in vertex_array:
			vertices.append(vertex)
	
	return vertices

func process_glsl_vertex(vertex):
	# Create a local rendering device.
	var rd := RenderingServer.create_local_rendering_device()
	# Load GLSL shader
	var shader_file := load("res://glsl_scripts/vertex_shader.glsl")
	if (shader_file == null):
		print("Error: Shader file could not be loaded!")
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)

	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var input := PackedFloat32Array(vertex)
	var input_bytes := input.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)

	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()

	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	var output_bytes := rd.buffer_get_data(buffer)
	var output := output_bytes.to_float32_array()
	print("Output: ", output)
	return output

func _ready():
	var mesh_instance = $"."  # Replace with actual node path
	var vertices = get_plane_vertices(mesh_instance)
	
	var flat_vertices := PackedFloat32Array()
	for vertex in vertices:
		flat_vertices.append_array([vertex.x, vertex.y, vertex.z])
		#print(vertex)
	var new_flat_vertices = process_glsl_vertex(flat_vertices)
	var new_vertices := []
	for i in range(0, new_flat_vertices.size(), 3):
		new_vertices.append(Vector3(new_flat_vertices[i], new_flat_vertices[i + 1], new_flat_vertices[i + 2]))
	
	# Create a new surface array with updated vertices
	var new_mesh := ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_vertices)
	mesh_instance.mesh = new_mesh
	
	
