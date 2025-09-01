shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(0.8706, 0.9333, 0.8392, 1.0);
uniform vec4 target_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tolerance = 0.05;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a == 0.0) {
		COLOR = c;
	}
	else {
		float d = distance(c.rgb, key_color.rgb);
		COLOR = d < tolerance ? vec4(target_color.rgb, c.a) : c;
	}
}