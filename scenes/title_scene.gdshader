shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform float brightness : hint_range(0.0, 1.0) = 0.7;

void fragment() {
    vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
    color.rgb *= brightness;
    COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
