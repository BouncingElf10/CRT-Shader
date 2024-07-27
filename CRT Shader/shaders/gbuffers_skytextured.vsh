#version 330 compatibility

out vec2 texCoord;
out vec2 lightCoord;
out vec4 vertexColor;
out float vertexDistance;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texCoord = gl_MultiTexCoord0.xy;
    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    vertexDistance = length((gl_ModelViewMatrix * gl_Vertex).xyz);

}