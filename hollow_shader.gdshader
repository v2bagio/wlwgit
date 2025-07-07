shader_type canvas_item;

uniform sampler2D gradient;
// O offset agora é controlado inteiramente pelo nosso script
uniform float offset;

void fragment() {
    // A coordenada Y da textura do gradiente é movida pelo nosso offset animado
    vec4 color = texture(gradient, vec2(0.0, fract(UV.y - offset)));
    COLOR = color;
}