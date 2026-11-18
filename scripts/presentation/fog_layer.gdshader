shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D fog_current : filter_linear, repeat_disable;
uniform sampler2D fog_previous : filter_linear, repeat_disable;
uniform float reveal_progress : hint_range(0.0, 1.0) = 1.0;
uniform vec2 reveal_origin_uv = vec2(0.5, 0.5);
uniform vec3 fog_color = vec3(0.44, 0.49, 0.55);
uniform vec3 veil_color = vec3(0.07, 0.10, 0.15);
uniform vec3 grid_color = vec3(0.03, 0.04, 0.06);

varying vec2 fog_uv;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.55;
	for (int i = 0; i < 4; i++) {
		value += amplitude * vnoise(p);
		p = p * 2.03 + vec2(17.0, 31.0);
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	fog_uv = (VERTEX.xz + vec2(8.0)) / 16.0;
}

void fragment() {
	float current = texture(fog_current, fog_uv).r;
	float previous = texture(fog_previous, fog_uv).r;
	float dist = distance(fog_uv, reveal_origin_uv);
	float edge = reveal_progress * 1.55 + 0.02;
	float mask = 1.0 - smoothstep(edge - 0.10, edge + 0.06, dist);
	mask = max(mask, step(0.999, reveal_progress));
	float veil = mix(previous, current, clamp(mask, 0.0, 1.0));

	float drift = TIME * 0.012;
	float n = fbm(fog_uv * vec2(15.0, 13.0) + vec2(drift, drift * 0.7));
	float billow = smoothstep(0.22, 0.78, n + veil * 0.30);
	float fog_amount = smoothstep(0.45, 0.92, veil);
	float alpha = veil * (0.82 + 0.28 * billow);

	vec2 cell = fract(fog_uv * 16.0);
	float grid_edge = min(min(cell.x, 1.0 - cell.x), min(cell.y, 1.0 - cell.y));
	float grid = 1.0 - smoothstep(0.0, 0.028, grid_edge);

	vec3 color = mix(veil_color, fog_color, fog_amount);
	color *= 0.78 + 0.34 * billow;
	color = mix(color, grid_color, grid * 0.35 * fog_amount);
	ALBEDO = color;
	ALPHA = clamp(alpha, 0.0, 1.0);
	if (ALPHA < 0.012) {
		discard;
	}
}
