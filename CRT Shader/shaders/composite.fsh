#version 330 compatibility

in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;
uniform vec2 screenSize;

void main() {
    float pixelArea = 6;
    // Calculate the size of each "pixel" in texture coordinates
    vec2 pixelSize = vec2(pixelArea) / vec2(2560, 1440);

    // Calculate the position within the current "pixel"
    vec2 pixelPos = mod(texCoord, pixelSize);

    // Round the texture coordinates to the nearest "pixel"
    vec2 roundedCoord = floor(texCoord / pixelSize) * pixelSize;

    vec4 color = texture(colortex0, roundedCoord);

    // First third (rows 0-2, indices 0-2)
    if (pixelPos.y < 3.0 * pixelSize.y / 9.0) {
        fragColor = color * vec4(1.0, 0.0, 0.0, 1.0); // Red tint
    }
    // Second third (rows 3-5, indices 3-5)
    else if (pixelPos.y < 6.0 * pixelSize.y / 9.0) {
        fragColor = color * vec4(0.0, 1.0, 0.0, 1.0); // Green tint
    }
    // Last third (rows 6-8, indices 6-8)
    else {
        fragColor = color * vec4(0.0, 0.0, 1.0, 1.0); // Blue tint
    }
}