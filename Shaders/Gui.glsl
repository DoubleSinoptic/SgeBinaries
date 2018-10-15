#version 130
#extension GL_ARB_explicit_attrib_location : enable

layout (location = 0) in vec2 positon;
layout (location = 1) in vec2 texcoord;
layout (location = 2) in vec4 color;

uniform mat4 ortho;

out vec2 fragPosition;
out vec2 fragTexcoord;
out vec4 fragColor;

void main()
{
	fragPosition = positon;
	fragTexcoord = texcoord;
	fragColor = color;

	gl_Position = ortho * vec4(vec3(positon, 0.0), 1.0);    
}

&

#version 130
out vec4 FragColor;
uniform bool useEffectA;
uniform bool useEffectB;
uniform float time;
uniform sampler2D map;
uniform bool mapEnabled;

uniform vec2 clipLU;
uniform vec2 clipRB;


in vec2 fragPosition;
in vec2 fragTexcoord;
in vec4 fragColor;

void main()
{
	
	
	if(
	fragPosition.x < clipLU.x || 
	fragPosition.y < clipLU.y || 
	fragPosition.x > clipRB.x ||
	fragPosition.y > clipRB.y
	)
		discard;
		
	vec4 color = fragColor;
	if(mapEnabled)
		color *= texture(map, fragTexcoord);
	//if(mod(int(fragPosition.y), 2) == 0)
	//	FragColor *= 2;

	if(useEffectA)
	{
		float sin1 = sin(time);
		if(sin1 < 0)
			sin1 = -sin1;
		color.xyz = color.xyz * sin1;
	}

    FragColor = color;
}