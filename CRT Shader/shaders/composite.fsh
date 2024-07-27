#version 330 compatibility

in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;
uniform vec2 screenSize;

// Adjust these values to fine-tune the effect
uniform float distortionStrength = 2;
uniform float zoomFactor = 1.3;

vec2 applyLensDistortion(vec2 uv) {
    vec2 center = vec2(0.5);
    vec2 distortedUV = uv - center;
    float distSq = dot(distortedUV, distortedUV);
    distortedUV *= 1.0 + distortionStrength * distSq;
    return distortedUV + center;
}

void main() {
    // Apply zoom
    vec2 zoomedCoord = (texCoord - 0.5) / zoomFactor + 0.5;

    // Apply lens distortion to the zoomed coordinates
    vec2 distortedTexCoord = applyLensDistortion(zoomedCoord);

    // Check if the distorted coordinates are within bounds
    if (true) { // Turn off and on black borders
        if (distortedTexCoord.x < 0.0 || distortedTexCoord.x > 1.0 ||
        distortedTexCoord.y < 0.0 || distortedTexCoord.y > 1.0) {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black for out of bounds
            return;
        }
    }

    float pixelArea = 3;
    vec2 pixelSize = vec2(pixelArea) / vec2(2560, 1440);

    vec2 pixelPos = mod(texCoord, pixelSize);
    vec2 roundedCoord = floor(distortedTexCoord / pixelSize) * pixelSize;

    vec4 color = texture(colortex0, roundedCoord);

    float borderThickness = 0.1;
    bool isBorder = (pixelPos.x < borderThickness * pixelSize.x || pixelPos.x > (1.0 - borderThickness) * pixelSize.x ||
    pixelPos.y < borderThickness * pixelSize.y || pixelPos.y > (1.0 - borderThickness) * pixelSize.y);

    if (isBorder) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black border
    } else {
        if (pixelPos.y < 3.0 * pixelSize.y / 9.0) {
            fragColor = color * vec4(1.0, 0.0, 0.0, 1.0); // Red tint
        } else if (pixelPos.y < 6.0 * pixelSize.y / 9.0) {
            fragColor = color * vec4(0.0, 1.0, 0.0, 1.0); // Green tint
        } else {
            fragColor = color * vec4(0.0, 0.0, 1.0, 1.0); // Blue tint
        }
    }
}