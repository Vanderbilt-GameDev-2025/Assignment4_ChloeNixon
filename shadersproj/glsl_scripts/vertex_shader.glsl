#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
    float data[];
}
my_data_buffer;

// Simple hash function for pseudo-random noise
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Noise function using the vertex position as a seed
float noise(float x, float z) {
    float seed = x * 12.9898 + z * 78.233;
    return hash(seed) * 2.0 - 1.0; // Scale noise to range [-1, 1]
}

// The code we want to execute in each invocation
void main() {
    uint index = gl_GlobalInvocationID.x * 3; // Each vertex has 3 components (x, y, z)

    // Multiply each component by 2
    my_data_buffer.data[index] *= 2.0;
    my_data_buffer.data[index + 1] += noise(my_data_buffer.data[index], my_data_buffer.data[index + 2]); // Apply noise to Y
    my_data_buffer.data[index + 2] *= 2.0;
}





// #[compute]
// #version 450

// // Invocations in the (x, y, z) dimension
// layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

// // A binding to the buffer we create in our script
// layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
//     float data[];
// }
// my_data_buffer;

// // Noise texture sampler
// layout(set = 0, binding = 1) uniform sampler2D noise_texture;

// // A uniform controlling the noise strength
// layout(set = 0, binding = 2) uniform NoiseScale {
//     float noise_scale;
// };

// // The length of the data buffer, passed as a uniform
// layout(set = 0, binding = 3) uniform uint data_length;

// // The code we want to execute in each invocation
// void main() {
//     // tex_position = VERTEX.xz / 2.0 + 0.5;
//  	// float height = texture(noise, tex_position).x;
// 	// VERTEX.y += height * height_scale;

//     // Get the unique index for this invocation
//     uint index = gl_GlobalInvocationID.x;
    
//     // Generate a texture coordinate based on index (example mapping)
//     float tex_x = float(index) / float(data_length);  // Normalize index to [0,1]
//     float tex_y = 0.5;  // Use a constant Y (or modify if needed)

//     // Sample noise texture
//     float noise_value = texture(noise_texture, vec2(tex_x, tex_y)).r;  // Using red channel

//     // Multiply by 2 and add noise
//     my_data_buffer.data[index] = my_data_buffer.data[index] * 2.0 + (noise_value * noise_scale);
// }