shader_type canvas_item;
render_mode unshaded;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float lumi = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
	COLOR.rgb = vec3(lumi);
	COLOR.a *= opacity;
}
