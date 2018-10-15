#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout(location = 0) in vec3 positon;
layout(location = 1) in vec3 color;
layout(location = 2) in vec2 texcoord;

uniform mat4 mvp;
out vec4 posf;
out vec3 colorgrad;
void main()
{
	posf = mvp * vec4(positon, 1.0);    
	gl_Position = posf;
	colorgrad = color;
}

&

#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout(location = 0) out vec4 FragPositon;
layout(location = 1) out vec4 FragNormal;
layout(location = 2) out vec4 FragColor;
layout(location = 3) out vec4 FragSettings;
layout(location = 4) out vec4 FragDepth;
in vec4 posf;
in vec3 colorgrad;

void main()
{
    FragColor = vec4(colorgrad, 1.0);
	FragPositon = posf;
	FragNormal = vec4(0.0, 1.0, 0.0, 1.0);
	FragSettings = vec4(0.0, 0.0, 0.0, 1.0);
	FragDepth = vec4(0.0, 0.0, -1000.0, 1.0);
}