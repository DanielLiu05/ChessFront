shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(0.01, 0.015, 0.02, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	float distance_from_center = distance(UV, vec2(0.5)) / 0.7071;
	float alpha = smoothstep(0.55, 1.05, distance_from_center) * strength;
	COLOR = vec4(tint.rgb, alpha);
}
