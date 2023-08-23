shader_type canvas_item;
uniform sampler2D texture;

void fragment() {
	COLOR = texture(texture, UV);
	vec4 texture_color = texture(texture, UV);
	
	float gray = (texture_color.r + texture_color.g + texture_color.b) / 3.0;
	vec3 gray_color = vec3(gray);
	
	COLOR = vec4(mix(texture_color.rgb, gray_color, 0.65), texture_color.a);
}
