#[compute]
#version 450

// Define work group size (adjust based on your mesh resolution)
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Storage buffer for vertex positions (SSBO)
layout(set = 0, binding = 0, std430) buffer VertexBuffer {
    vec4 positions[];  // Array of vertex positions (XYZW)
};

// Noise texture sampler (allowed outside a block)
layout(set = 0, binding = 1) uniform sampler2D noise_texture;

// Uniform block (required in Vulkan for non-opaque types)
layout(set = 0, binding = 2) uniform WaveParams {
    float time;
    float wave_height;
    float wave_speed;
    float wave_scale;
};

void main() {
    // Get the unique index of this thread
    uint index = gl_GlobalInvocationID.x;

    // Read the original vertex position
    vec4 vertex = positions[index];

    // Compute texture coordinates for noise lookup
    vec2 tex_position = vertex.xz / 10.0 + 0.5; // Normalize to [0,1] range

    // Sample noise texture with animated offset
    float noise_value = texture(noise_texture, tex_position * wave_scale + vec2(time * wave_speed, 0.0)).r;

    // Compute vertical displacement
    float displacement = (noise_value - 0.5) * wave_height;

    // Apply displacement to Y coordinate
    vertex.y += displacement;

    // Write the modified vertex back to the buffer
    positions[index] = vertex;
}
