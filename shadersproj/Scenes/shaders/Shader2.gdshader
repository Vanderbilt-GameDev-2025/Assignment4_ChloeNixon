shader_type spatial;
render_mode specular_toon;

uniform sampler2D noise;
uniform sampler2D normalmap;
uniform float water_calmness = 20.0;

uniform float height_scale = 0.2;
varying vec2 tex_position;

float wave(vec2 position){
  position += texture(noise, position / water_calmness).x * 2.0 - 1.0;
  vec2 wv = 1.0 - abs(sin(position));
  return pow(1.0 - pow(wv.x * wv.y, 0.65), 4.0);
}

float height(vec2 position, float time) {
	//number all d is multiplied by, amp, must =1 like so
	float d = wave((position + time) * 0.4) * 0.3;
  	d += wave((position - time) * 0.3) * 0.3;
  	d += wave((position + time) * 0.5) * 0.2;
  	d += wave((position - time) * 0.6) * 0.2;
  	return d;
}

void vertex() {
	// Called for every vertex the material is visible on.
	vec2 pos = VERTEX.xz;
	float k = height(pos, TIME);
	VERTEX.y = k;

	NORMAL = normalize(vec3(k - height(pos + vec2(0.1, 0.0), TIME), 0.1, k - height(pos + vec2(0.0, 0.1), TIME)));
}

void fragment() {
	// Called for every pixel the material is visible on.
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	RIM = 0.2;
	METALLIC = 0.00;
  	ROUGHNESS = 0.02;
	ALBEDO = vec3(0.05, 0.2, 0.15) + (0.1 * fresnel);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
