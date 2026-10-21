// See-through glass with the same PS1 vertex wobble and fog as ps1.gdshader.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, fog_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.55, 0.62, 0.66, 0.28);
uniform float dirt = 0.35;
uniform sampler2D grain : source_color, filter_nearest, repeat_enable;
uniform float snap_res = 260.0;
global uniform vec4 world_fog;
global uniform float fog_scale;
uniform float fog_start = 6.0;
uniform float fog_end = 70.0;

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
	affine_uv = vec3(uv * clip.w, clip.w);
	fog = clamp((length(view.xyz) - fog_start * fog_scale) / ((fog_end - fog_start) * fog_scale), 0.0, 1.0);
}

void fragment() {
	vec2 m = affine_uv.xy / affine_uv.z;
	// Ash and grime gather in blotches and toward the bottom edge.
	float g = texture(grain, m * 4.0).r;
	float grime = smoothstep(0.45, 0.8, g) * dirt;
	vec3 c = mix(tint.rgb, vec3(0.7, 0.68, 0.62), grime);
	ALBEDO = mix(c, world_fog.rgb, fog);
	ALPHA = mix(tint.a + grime * 0.5, 1.0, fog);
}
