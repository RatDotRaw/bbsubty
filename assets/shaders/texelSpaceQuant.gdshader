// source: https://godotshaders.com/shader/texel-space-quantization/

shader_type spatial;

uniform sampler2D albedo_map : source_color, filter_nearest_mipmap;

// Calculate screen-space displacement to the center of the current texel
vec2 screen_delta(vec2 uv, sampler2D tex) {
	vec2 tex_size = vec2(textureSize(tex, 0));
	vec2 texel_center = (floor(uv * tex_size) + 0.5) / tex_size;
	vec2 delta = texel_center - uv;
	mat2 screen_to_uv = mat2(dFdx(uv), dFdy(uv));
	mat2 uv_to_screen = inverse(screen_to_uv);
	return uv_to_screen * delta;
}

// Snap vector to the value at the center of the current texel
// Note this works for any vec type (float, vec2, vec3, vec4)
vec3 texel_snap(vec3 v, vec2 delta) {
	return v + dFdx(v) * delta.x + dFdy(v) * delta.y;
}

void fragment() {
	vec2 delta = screen_delta(UV, albedo_map);
	LIGHT_VERTEX = texel_snap(VERTEX, delta);
	NORMAL = texel_snap(NORMAL, delta);

	ALBEDO = texture(albedo_map, UV).rgb;
}

// Simple posterized lighting
void light() {
	#define levels 12.0
	float n_dot_l = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float i = n_dot_l * ATTENUATION;
	i = floor(i * levels) / levels;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * i;
}