#version 330 compatibility

in vec2 texCoord;
in vec2 lightCoord;
in vec4 vertexColor;
in float vertexDistance;
in float vertexPosition;
// Add some new uniforms and your in statement
in vec3 normal;

// Our new textures!
uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;

layout(location = 0) out vec4 pixelColor;


void main() {
    vec4 texColor = texture(gtexture, texCoord);
    if (texColor.a < 0.1) discard;
    vec4 lightColor = texture(lightmap, lightCoord);

    // Calculate our new fog color!
    float fogValue = vertexPosition < fogEnd ? smoothstep(fogStart, fogEnd, vertexPosition) : 1.0;

    vec4 finalColor = texColor * lightColor * vertexColor;

    pixelColor = vec4(mix(finalColor.xyz, fogColor, fogValue), finalColor.a);
}