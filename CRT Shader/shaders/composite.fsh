#version 330 compatibility

#define DISTORTION_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0 2.5 3.0]
#define ZOOM_FACTOR 1.2 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.25 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]
#define MAX_CHROMATIC_ABERRATION 5 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
#define MAX_COLOR_BLEED 0.5 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define PIXEL_AREA 3 // [3 4 5 6 7 8 9 10 11 12]
#define BORDER_THICKNESS 0 // [0.0 0.1 0.2]
#define BLACK_OUT_OF_BOUNDS false // [true false]
#define POSTERIZATION false // [true false]
#define POSTERIZATION_STEPS 8 // [4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]
#define RED_STRENGTH 1 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GREEN_STRENGTH 1 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLUE_STRENGTH 1 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]


//SCAN LINES
#define SCAN_LINES false // [true false]
#define SCAN_LINE_HEIGHT 0.2 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SCAN_LINE_SPEED 0.4 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SCAN_LINE_INTENSITY 0.2 // [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;
uniform vec2 ScreenSize;
uniform float frameTimeCounter;

// Adjust these values to fine-tune the effect
uniform float distortionStrength = DISTORTION_STRENGTH;
uniform float zoomFactor = ZOOM_FACTOR;
uniform float maxChromaticAberrationStrength = MAX_CHROMATIC_ABERRATION;
uniform float maxColorBleedStrength = MAX_COLOR_BLEED;
uniform int colorLevels = POSTERIZATION_STEPS; // Posterization levels per channel

float scanlineEffect(vec2 uv, float time) {
    float scanlineHeight = SCAN_LINE_HEIGHT;
    float scanlineSpeed = SCAN_LINE_SPEED;

    // Calculate the scanline position
    float scanlinePosition = fract(time * scanlineSpeed);

    // Calculate distance from the scanline, wrapping around at screen edges
    float distFromScanline = abs(uv.y - scanlinePosition);
    distFromScanline = min(distFromScanline, 1.0 - distFromScanline);

    // Create a smooth falloff for the scanline intensity
    float intensity = 1.0 - smoothstep(0.0, scanlineHeight, distFromScanline);

    return 1.0 - (intensity * SCAN_LINE_INTENSITY);
}


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

vec4 applyPosterization(vec4 color, int levels) {
    vec3 scaledColor = floor(color.rgb * float(levels)) / float(levels);
    return vec4(scaledColor, color.a);
}

void main() {
    // Get the resolution of the screen (or texture)
    vec2 resolution = textureSize(colortex0, 0);

    // Apply zoom
    vec2 zoomedCoord = (texCoord - 0.5) / zoomFactor + 0.5;

    // Apply lens distortion to the zoomed coordinates
    vec2 distortedTexCoord = applyLensDistortion(zoomedCoord);

    // Handle out of bounds scenario
    if (BLACK_OUT_OF_BOUNDS) {
        if (distortedTexCoord.x < 0.0 || distortedTexCoord.x > 1.0 || distortedTexCoord.y < 0.0 || distortedTexCoord.y > 1.0) {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black for out of bounds
            return;
        }
    }

    float pixelArea = PIXEL_AREA;
    vec2 pixelSize = vec2(pixelArea) / resolution;

    vec2 pixelPos = mod(texCoord, pixelSize);
    vec2 roundedCoord = floor(distortedTexCoord / pixelSize) * pixelSize;

    // Calculate edge factor
    float edgeFactor = getEdgeFactor(distortedTexCoord);

    // Apply chromatic aberration and color bleed with increasing strength towards edges
    float chromaticAberrationStrength = (maxChromaticAberrationStrength / 1000) * edgeFactor;
    float colorBleedStrength = (maxColorBleedStrength / 150) * edgeFactor;

    vec2 redOffset = vec2(chromaticAberrationStrength, 0);
    vec2 blueOffset = vec2(-chromaticAberrationStrength, 0);
    float r = sampleWithColorBleed(colortex0, roundedCoord + redOffset, vec2(1, 0), colorBleedStrength).r;
    float g = sampleWithColorBleed(colortex0, roundedCoord, vec2(0, 1), colorBleedStrength).g;
    float b = sampleWithColorBleed(colortex0, roundedCoord + blueOffset, vec2(-1, 0), colorBleedStrength).b;

    vec4 color = vec4(r, g, b, 1.0);

    // Apply posterization effect
    if (POSTERIZATION) {
        color = applyPosterization(color, colorLevels);
    }

    float borderThickness = 0.1;
    bool isBorder = (pixelPos.x < borderThickness * pixelSize.x || pixelPos.x > (1.0 - borderThickness) * pixelSize.x ||
    pixelPos.y < borderThickness * pixelSize.y || pixelPos.y > (1.0 - borderThickness) * pixelSize.y);

    if (isBorder) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black border
    } else {
        if (pixelPos.y < 3.0 * pixelSize.y / 9.0) {
            fragColor = color * (vec4(1.0, 0.0, 0.0, 1.0) * vec4(RED_STRENGTH, 1.0, 1.0, 1.0)); // Red tint
        } else if (pixelPos.y < 6.0 * pixelSize.y / 9.0) {
            fragColor = color * (vec4(0.0, 1.0, 0.0, 1.0) * vec4(1.0, GREEN_STRENGTH, 1.0, 1.0)); // Green tint
        } else {
            fragColor = color * (vec4(0.0, 0.0, 1.0, 1.0) * vec4(1.0, 1.0, BLUE_STRENGTH, 1.0)); // Blue tint
        }
    }
    if (SCAN_LINES) {
        float scanline = scanlineEffect(texCoord, frameTimeCounter);
        fragColor.rgb *= scanline;
    }
}
