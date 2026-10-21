// Final screen pass: light ordered dithering, gentle colour banding and a soft vignette.
shader_type canvas_item;
uniform float levels = 30.0;
uniform float dither = 0.45;
uniform float vignette = 0.25;
const float BAYER[16] = float[](0.0,8.0,2.0,10.0,12.0,4.0,14.0,6.0,3.0,11.0,1.0,9.0,15.0,7.0,13.0,5.0);
void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	ivec2 px = ivec2(UV / TEXTURE_PIXEL_SIZE);
	float b = (BAYER[(px.y % 4) * 4 + (px.x % 4)] / 16.0 - 0.5) * dither;
	c = floor(c * levels + b + 0.5) / levels;
	float d = distance(UV, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.4, 0.85, d);
	COLOR = vec4(c, 1.0);
}
