// PS1-style surface: wobbly snapped vertices, warped (affine) textures,
// per-vertex lighting and simple distance fog.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting, fog_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D grain : source_color, filter_nearest, repeat_enable;
uniform float grain_amount = 0.25;
uniform float tex_scale = 0.5;
uniform float snap_res = 120.0;
uniform vec3 fog_color : source_color = vec3(0.55, 0.52, 0.47);
uniform float fog_start = 6.0;
uniform float fog_end = 70.0;
uniform float emission = 0.0;

varying vec3 affine_uv;
varying float fog;

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
	affine_uv = vec3(uv * tex_scale * clip.w, clip.w);
	fog = clamp((length(view.xyz) - fog_start) / (fog_end - fog_start), 0.0, 1.0);
}

void fragment() {
	vec2 uv = affine_uv.xy / affine_uv.z;
	vec3 g = texture(grain, uv).rgb;
	vec3 c = albedo.rgb * mix(vec3(1.0), g * 1.6, grain_amount);
	ALBEDO = c * (1.0 - fog);
	EMISSION = fog_color * fog + c * emission * (1.0 - fog);
}
