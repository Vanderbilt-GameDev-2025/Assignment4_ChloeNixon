shader_type spatial;
render_mode specular_toon;

uniform sampler2D noise;
uniform sampler2D normalmap;

// parameters effecting the waves overlayed on the ripples
uniform float water_calmness = 15.0;
uniform float height_scale = 0.3;
varying vec2 tex_position;

//parameters on the general rippled effecting the waves
uniform float ripple_speed : hint_range(0.0, 10.0) = 1.0;
uniform float ripple_frequency : hint_range(0.0, 10.0) = 2.0;
uniform float ripple_amplitude : hint_range(0.0, 1.0) = 0.05;

//Parameters for surface view reflection & specular reflection
uniform float reflection_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.75;
uniform float specular_shininess : hint_range(1.0, 128.0) = 40.0;
uniform vec3 light_direction = vec3(0.0, 6.0, 6.0); // Default direction (downwards)

//generates one wave based on noise texture, uses sin for circular wave pattern
float wave(vec2 position) {
    position += texture(noise, position / water_calmness).x * 2.0 - 1.0;
    vec2 wv = 1.0 - abs(sin(position));
    return pow(1.0 - pow(wv.x * wv.y, 0.65), 4.0);
}

//
float height(vec2 position, float time) {
	//number all d is multiplied by, amp, must = 1
	float d = wave((position + time) * 0.2) * 0.3;
  	d += wave((position - time) * 0.2) * 0.3;
  	d += wave((position + time) * 0.1) * 0.2;
  	d += wave((position - time) * 0.1) * 0.2;
  	return d;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	//generates one uniform, symmetrical ripple
	float ripple = sin(VERTEX.x * ripple_frequency + TIME * ripple_speed) *
                   cos(VERTEX.z * ripple_frequency + TIME * ripple_speed);
    // Displace the vertex along the Y-axis based on the ripple
    VERTEX.y += ripple * ripple_amplitude;
    // normal values of ripples
    float dx = ripple_frequency * cos(VERTEX.x * ripple_frequency + TIME * ripple_speed) *
               cos(VERTEX.z * ripple_frequency + TIME * ripple_speed);
    float dz = -ripple_frequency * sin(VERTEX.x * ripple_frequency + TIME * ripple_speed) *
               sin(VERTEX.z * ripple_frequency + TIME * ripple_speed);
    //normal vector of ripples
    vec3 normal = normalize(vec3(-dx, 1.0, -dz));
	//adds general waves to ripples, making it more dynamic
    vec2 pos = VERTEX.xz;
    float k = height(pos, TIME);
    VERTEX.y += k;
	//normals of waves
    NORMAL = normalize(vec3(k - height(pos + vec2(0.1, 0.0), TIME), 0.1, k - height(pos + vec2(0.0, 0.1), TIME)));
	NORMAL = normalize(normal);
}

void fragment() {
	vec3 water_color = vec3(0.05, 0.5, 0.4);
	float fresnel = fresnel(5.0, NORMAL, VIEW);
    // Reflection
	vec3 reflection = water_color * reflection_intensity;
	vec3 final_color = mix(water_color, reflection, fresnel);
    // Specular highlights
	//finds direction of light
    vec3 light_dir = normalize(light_direction);
	// finds direction of view camera
    vec3 view_dir = normalize(VIEW);
    vec3 half_dir = normalize(light_dir + view_dir);
    float specular = pow(max(dot(NORMAL, half_dir), 0.0), specular_shininess);
    specular *= specular_intensity;
    // Add specular highlights to the final color
    final_color += specular;

    ALBEDO = final_color;
	NORMAL_MAP = texture(normalmap, tex_position).xyz;

    RIM = 0.2;
    METALLIC = 0.0;
    ROUGHNESS = 0.02;
}

//attempted cell shader that looks really ugly
//void light() {
	 ////Called for every pixel for every light affecting the material.
	////float nDotL = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	////float sample = clamp((nDotL + 1.0) * ATTENUATION / 2.1, 0.05, 0.95); // Add smoothstep
	////vec4 shaded = texture(cellshade_color_grad, vec2(sample, 0.0));
	////DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
//}
