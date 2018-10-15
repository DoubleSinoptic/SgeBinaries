#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout (location = 0) in vec3 aPos;

out vec3 TexCoords;
out vec3 VertexPosition;
uniform mat4 projection;
uniform mat4 view;

void main()
{
    TexCoords = aPos;
	VertexPosition = aPos * 1000;
    gl_Position = projection * mat4(mat3(view)) * vec4(aPos * 1000, 1.0);
}  

&

#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout ( location = 0 ) out vec4 FragPositon;
layout ( location = 1 ) out vec4 FragNormal;
layout ( location = 2 ) out vec4 FragColor;
layout ( location = 3 ) out vec4 FragSettings;
layout ( location = 4 ) out vec4 FragDepth;

in vec3 TexCoords;
in vec3 VertexPosition;

uniform samplerCube skybox;

void main()
{    
	FragPositon = vec4(VertexPosition, -1.0);
	FragNormal = vec4(normalize(vec3(0.0) - VertexPosition / 1000), 1.0);
    FragColor = vec4(texture(skybox, TexCoords).rgb, 1.0);
	FragSettings = vec4(0.0, 0.0, 1.0, 1.0);
	FragDepth = vec4(0.0, 0.0, 0.0, 1.0);
}