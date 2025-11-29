shader_type canvas_item;
uniform vec4 border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // rojo
uniform float thickness = 0.01;   // grosor del marco (0..0.5)
uniform float softness  = 0.02;   // difuminado interior del borde
uniform float intensity = 0.0;    // 0..1 (lo animaremos con Tween)
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	 // UV va de 0..1 dentro del rect del ColorRect
    vec2 uv = UV;
    float dist_edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

    // edge = 1 en el borde, 0 hacia adentro (con suavizado)
    float edge = smoothstep(0.0005 + 0.1, 0.0005, dist_edge);

    vec4 col = vec4(border_color.rgb, border_color.a * edge * intensity);
    COLOR = col; // centro transparente, solo bordes con alpha
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
