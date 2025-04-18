shader_type canvas_item;

void fragment() {
	vec4 inputColor = texture(TEXTURE, UV);
	COLOR = vec4(inputColor.r, inputColor.g, 1.0, inputColor.a);
}
