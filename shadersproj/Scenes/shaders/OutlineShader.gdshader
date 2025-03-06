//shader_type spatial;
//
//uniform vec4 outline_color = vec4(1.0, 0.0, 0.0, 1.0); // Outline color (red by default)
//uniform float outline_thickness : hint_range(0.0, 0.1) = 0.08; // Thickness of the outline
//
//
//void vertex() {
	//VERTEX += NORMAL * outline_thickness;
	//// Called for every vertex the material is visible on.
//}
//
//void fragment() {
	//ALBEDO = outline_color.rgb; // Set the outline color
	//ALPHA = outline_color.a; // Set the outline alpha
	//// Called for every pixel the material is visible on.
//}
//
////void light() {
	//// Called for every pixel for every light affecting the material.
	//// Uncomment to replace the default light processing function with this one.
////}
