// PS1-style surface: wobbly snapped vertices, warped (affine) textures,
// per-vertex lighting and simple distance fog.
// `pattern` draws simple procedural surface detail so blocks read as materials:
// 0 plain, 1 wood siding, 2 brick, 3 floor planks, 4 tiles, 5 roof shingles,
// 6 wallpaper stripes, 7 asphalt, 8 concrete slabs.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting, fog_disabled, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D grain : source_color, filter_nearest, repeat_enable;
uniform float grain_amount = 0.14;
uniform float tex_scale = 1.5;
uniform int pattern = 0;
uniform float snap_res = 260.0;
global uniform vec4 world_fog;
global uniform float fog_scale;
uniform float fog_start = 6.0;
uniform float fog_end = 70.0;
uniform float emission = 0.0;

varying vec3 affine_uv;
varying float fog;

float line(float v, float width) {
	float f = fract(v);
	return step(f, width);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = abs(mat3(MODEL_MATRIX) * NORMAL);
	vec2 uv = n.y > n.x && n.y > n.z ? world.xz : (n.x > n.z ? world.zy : world.xy);

	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view;
	if (clip.w > 0.0) {
		vec2 grid = vec2(snap_res * VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, snap_res);
		clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	}
	POSITION = clip;
	// Multiply by w here and divide in fragment() to undo perspective correction.
	affine_uv = vec3(uv * clip.w, clip.w);
	fog = clamp((length(view.xyz) - fog_start * fog_scale) / ((fog_end - fog_start) * fog_scale), 0.0, 1.0);
}

void fragment() {
	vec2 m = affine_uv.xy / affine_uv.z; // metres
	vec3 g = texture(grain, m * tex_scale).rgb;
	vec3 c = albedo.rgb * mix(vec3(1.0), g * 1.6, grain_amount);

	float shade = 1.0;
	if (pattern == 1) {        // horizontal wood siding
		shade = 1.0 - 0.35 * line(m.y * 4.0, 0.12);
	} else if (pattern == 2) { // brick
		float row = floor(m.y * 6.0);
		float x = m.x * 3.0 + mod(row, 2.0) * 0.5;
		shade = 1.0 - 0.45 * max(line(m.y * 6.0, 0.12), line(x, 0.05));
		shade *= 0.88 + 0.24 * hash(vec2(floor(x), row));
	} else if (pattern == 3) { // floor planks
		float row = floor(m.y * 5.0);
		shade = 1.0 - 0.4 * max(line(m.y * 5.0, 0.07), line(m.x * 0.6 + hash(vec2(row, 1.0)), 0.015));
		shade *= 0.85 + 0.3 * hash(vec2(row, 3.0));
	} else if (pattern == 4) { // tiles
		shade = 1.0 - 0.3 * max(line(m.x * 3.0, 0.06), line(m.y * 3.0, 0.06));
	} else if (pattern == 5) { // shingles
		float row = floor(m.y * 4.0);
		float x = m.x * 3.0 + mod(row, 2.0) * 0.5;
		shade = 1.0 - 0.4 * max(line(m.y * 4.0, 0.15), line(x, 0.04));
		shade *= 0.85 + 0.3 * hash(vec2(floor(x), row));
	} else if (pattern == 6) { // wallpaper stripes
		shade = 1.0 - 0.12 * step(0.5, fract(m.x * 4.0));
	} else if (pattern == 7) { // asphalt
		shade = 0.85 + 0.3 * hash(floor(m * 8.0));
	} else if (pattern == 8) { // concrete slabs
		shade = 1.0 - 0.35 * max(line(m.x * 0.5, 0.02), line(m.y * 0.5, 0.02));
	}
	c *= shade;

	ALBEDO = c * (1.0 - fog);
	EMISSION = world_fog.rgb * fog + c * emission * (1.0 - fog);
}
