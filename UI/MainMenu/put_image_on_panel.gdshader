shader_type canvas_item;
uniform sampler2D texture;

void fragment() {
	COLOR = texture(texture, UV);
}
