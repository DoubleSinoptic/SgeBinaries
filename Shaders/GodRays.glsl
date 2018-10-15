#version 130
#extension GL_ARB_explicit_attrib_location : enable

layout (location = 0) in vec2 positon;


out vec2 TexCoords;

void main()
{
	gl_Position = vec4(vec3(positon, 0.0), 1.0);    
	TexCoords = positon * 0.5 + 0.5;
}
&

#version 130
out vec4 FragColor;

uniform sampler2D UserMapSampler;
uniform vec3 lightPosition;

uniform mat4 view;
uniform mat4 projection;
in vec2 TexCoords;
void main()
{

	vec4 lightPositionOnScreen = projection * mat4(mat3(view)) * vec4(normalize(vec3(-1, 1, -1))*1000, 1.0);
	lightPositionOnScreen /= lightPositionOnScreen.w;
	vec3 forward = vec3(view[0][2], view[1][2], view[2][2]);
	if(dot(-forward, normalize(vec3(-1, 1, -1))) < 0.0)
	{	
		FragColor = vec4(vec3(0.0), 1.0);
		return;
	}
	lightPositionOnScreen = lightPositionOnScreen * 0.5 + 0.5;

	float decay=0.96815;
	float exposure=2.2;
	float density=0.926;
	float weight=0.58767;

	int NUM_SAMPLES = 500;
	vec2 tc = TexCoords;
	vec2 deltaTexCoord = (tc-lightPositionOnScreen.xy);
	deltaTexCoord *= 1.0 / float(NUM_SAMPLES) * density;
	float illuminationDecay = 1.0;
	vec4 color =texture(UserMapSampler, tc.xy)*0.4;
	for(int i=0; i < NUM_SAMPLES ; i++)
	{
		tc -= deltaTexCoord;
		vec4 sample = texture(UserMapSampler, tc)*0.4;
		sample *= illuminationDecay * weight;
		color += sample;
		illuminationDecay *= decay;
	}
	FragColor = color * 0.2;
}