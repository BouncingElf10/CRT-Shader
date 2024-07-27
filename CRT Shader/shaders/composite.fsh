#version 330 compatibility

in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;
uniform vec2 screenSize;

// Adjust these values to fine-tune the effect
uniform float distortionStrength = 1.5;
uniform float zoomFactor = 1.25;
uniform float maxChromaticAberrationStrength = 0.005;
uniform float maxColorBleedStrength = 0.001;
uniform float scanLineIntensity = 0.1;
uniform float scanLineCount = 1080.0;

vec2 applyLensDistortion(vec2 uv) {
    vec2 center = vec2(0.5);
    vec2 distortedUV = uv - center;
    float distSq = dot(distortedUV, distortedUV);
    distortedUV *= 1.0 + distortionStrength * distSq;
    return distortedUV + center;
}

vec4 sampleWithColorBleed(sampler2D tex, vec2 uv, vec2 direction, float strength) {
    vec4 color = texture(tex, uv);
    vec4 bleed = texture(tex, uv + direction * strength);
    return mix(color, bleed, 0.5);
}

float getEdgeFactor(vec2 uv) {
    vec2 center = vec2(0.5);
    return length(uv - center) * 1.3;
}

float getScanLineIntensity(vec2 uv) {
    return sin(uv.y * scanLineCount * 3.14159 * 2.0) * 0.5 + 0.5;
}

void main() {
    // Apply zoom
    vec2 zoomedCoord = (texCoord - 0.5) / zoomFactor + 0.5;

    // Apply lens distortion to the zoomed coordinates
    vec2 distortedTexCoord = applyLensDistortion(zoomedCoord);

    // Check if the distorted coordinates are within bounds
    if (false) { // Turn on and off
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

    // Calculate edge factor
    float edgeFactor = getEdgeFactor(distortedTexCoord);

    // Apply chromatic aberration and color bleed with increasing strength towards edges
    float chromaticAberrationStrength = maxChromaticAberrationStrength * edgeFactor;
    float colorBleedStrength = maxColorBleedStrength * edgeFactor;

    vec2 redOffset = vec2(chromaticAberrationStrength, 0);
    vec2 blueOffset = vec2(-chromaticAberrationStrength, 0);
    float r = sampleWithColorBleed(colortex0, roundedCoord + redOffset, vec2(1, 0), colorBleedStrength).r;
    float g = sampleWithColorBleed(colortex0, roundedCoord, vec2(0, 1), colorBleedStrength).g;
    float b = sampleWithColorBleed(colortex0, roundedCoord + blueOffset, vec2(-1, 0), colorBleedStrength).b;

    vec4 color = vec4(r, g, b, 1.0);

    // Apply scan lines
    if (false) {
        float scanLine = getScanLineIntensity(distortedTexCoord);
        color.rgb *= 1.0 - (scanLineIntensity * (1.0 - scanLine));
    }

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