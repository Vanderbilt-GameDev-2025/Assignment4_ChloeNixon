extends Node3D

@onready var mesh_instance = $MeshInstance3D
var rd: RenderingDevice
var shader: RID
var pipeline: RID
var storage_buffer: RID
var uniform_set: RID
var buffer_size: int

# Define the size of the plane (10x10 meters) and resolution (e.g., 50x50 vertices)
const MESH_SIZE = 10.0
const RESOLUTION = 50  # Number of vertices along each axis

func _ready():
	rd = RenderingServer.get_rendering_device()
	setup_mesh()
	setup_compute_shader()
	dispatch_compute_shader()

func setup_mesh():
	# Create a PlaneMesh and get its vertex positions
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(MESH_SIZE, MESH_SIZE)
	plane_mesh.subdivide_width = RESOLUTION
	plane_mesh.subdivide_depth = RESOLUTION
	mesh_instance.mesh = plane_mesh

	# Extract the vertex positions
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var mesh_data = surface_tool.commit_to_arrays()

	# Store vertex positions as a flat float32 array
	var vertex_array = mesh_data[ArrayMesh.ARRAY_VERTEX]
	buffer_size = vertex_array.size() * 4  # Each vec3 is 3 floats, each float is 4 bytes

	var vertex_bytes = PackedByteArray()
	for v in vertex_array:
		vertex_bytes.append_array(v.to_float32_array())  # Convert each Vector3 to float32

	# Create a Storage Buffer (SSBO) and store vertex data
	storage_buffer = rd.storage_buffer_create(buffer_size, vertex_bytes)

func setup_compute_shader():
	# Load the compiled compute shader
	var shader_source = preload("res://glsl_scripts/waves.glsl")  # Path to GLSL file
	shader = rd.shader_create_from_spirv(shader_source.get_spirv())
	
	# Create a pipeline for execution
	pipeline = rd.compute_pipeline_create(shader)

	# Create a Uniform Set for the shader
	uniform_set = rd.uniform_set_create([
		{ "binding": 0, "resource": storage_buffer },  # Vertex buffer
		{ "binding": 1, "resource": preload("res://noise_texture.tres") },  # Noise texture
		{ "binding": 2, "resource": rd.uniform_buffer_create(16, PackedFloat32Array([0.0, 1.0, 1.0, 0.5])) }  # time, wave_height, speed, scale
	], shader, 0)

func dispatch_compute_shader():
	# Start compute pass
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	# Dispatch compute shader (1 thread per vertex)
	var num_vertices = buffer_size / 12  # Each vertex = 3 floats (XYZ), 12 bytes total
	rd.compute_list_dispatch(compute_list, num_vertices, 1, 1)

	# End compute pass
	rd.compute_list_end()

	# Retrieve modified vertex data
	var updated_bytes = rd.buffer_get_data(storage_buffer)
	
	# Convert back to Vector3 array
	var updated_vertices = []
	for i in range(0, updated_bytes.size(), 12):
		var x = updated_bytes.decode_float(0, i)
		var y = updated_bytes.decode_float(0, i + 4)
		var z = updated_bytes.decode_float(0, i + 8)
		updated_vertices.append(Vector3(x, y, z))

	# Update the mesh with new vertex positions
	update_mesh(updated_vertices)

func update_mesh(vertices: Array):
	# Create a new SurfaceTool to modify the mesh
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Reconstruct the mesh with modified vertex positions
	for v in vertices:
		surface_tool.add_vertex(v)
	
	mesh_instance.mesh = surface_tool.commit()



#extends Node3D
#
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	## Create a local rendering device.
	#var rd := RenderingServer.create_local_rendering_device()
	## Load GLSL shader
	#var shader_file := load("res://glsl_scripts/compute_example.glsl")
	#if (shader_file == null):
		#print("Error: Shader file could not be loaded!")
		#return
	#var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	#var shader := rd.shader_create_from_spirv(shader_spirv)
#
	## Prepare our data. We use floats in the shader, so we need 32 bit.
	#var input := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	#var input_bytes := input.to_byte_array()
#
	## Create a storage buffer that can hold our float values.
	## Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	#var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)
#
	## Create a uniform to assign the buffer to the rendering device
	#var uniform := RDUniform.new()
#
	#uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#uniform.binding = 0 # this needs to match the "binding" in our shader file
	#uniform.add_id(buffer)
	#var uniform_set := rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
#
	## Create a compute pipeline
	#var pipeline := rd.compute_pipeline_create(shader)
	#var compute_list := rd.compute_list_begin()
	#rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	#rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	#rd.compute_list_dispatch(compute_list, 5, 1, 1)
	#rd.compute_list_end()
	#
	## Submit to GPU and wait for sync
	#rd.submit()
	#rd.sync()
	#
	#var output_bytes := rd.buffer_get_data(buffer)
	#var output := output_bytes.to_float32_array()
	#print("Input: ", input)
	#print("Output: ", output)
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
