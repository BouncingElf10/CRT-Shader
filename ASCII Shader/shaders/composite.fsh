#version 330 compatibility

//main
in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;
uniform vec2 screenSize;

float colorRed;
float colorGreen;
float colorBlue;
//main
void main() {
    float Pixels = 3240.0;
    float dx = 9.0 * (1.0 / Pixels);
    float dy = 16.0 * (1.0 / Pixels);
    vec2 Coord = vec2(dx * floor(texCoord.x / dx), dy * floor(texCoord.y / dy));

    vec4 color = texture(colortex0, Coord);

    float luminance = (color.r + color.g + color.b) / 3.0;
    float luminanceWierd = 0.3 * color.r + 0.59 * color.g + 0.11 * color.b;

    fragColor = vec4(color.r, color.g, color.b, color.a);
    fragColor = vec4(luminance, luminance, luminance, color.a);
}