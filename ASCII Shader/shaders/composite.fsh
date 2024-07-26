#version 330 compatibility

//main
in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;
uniform vec2 screenSize;

float colorRed;
float colorGreen;
float colorBlue;

void main() {
    vec4 color = texture(colortex0, texCoord);

    float luminance = (color.r + color.g + color.b) / 3.0;
    float luminanceWierd = 0.3 * color.r + 0.59 * color.g + 0.11 * color.b;

    fragColor = vec4(color.r, color.g, color.b, color.a);

}