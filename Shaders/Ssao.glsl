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

in vec2 TexCoords;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D texNoise;

#define KERNEL_SAMPLES 32
uniform vec3 samples[KERNEL_SAMPLES];

int kernelSize = KERNEL_SAMPLES;
float radius = 0.5;
float bias = 0.025;

uniform mat4 projectionView;
uniform mat4 projection;
uniform vec3 displaySize;



void main()
{
	//FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	//return;
    vec2 noiseScale = vec2(displaySize.x/4.0, displaySize.y/4.0);
	vec4 tx = texture(gPosition, TexCoords);
	if((tx.w + 1) < 0.001)
	{
		FragColor = vec4(1.0);
		return;
	}
    vec3 fragPos = ( projectionView * tx).xyz;
	
	
	vec3 notClenedNormal =  texture(gNormal, TexCoords).rgb;
	
	if(length(notClenedNormal - vec3(0.0)) < 0.001)
	{
		FragColor = vec4(1.0);
		return;
	}
    vec3 normal = normalize(
		 mat3(projectionView) * notClenedNormal
	);


    vec3 randomVec = normalize(texture(texNoise, TexCoords * noiseScale).xyz);
  
    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);
   
    float occlusion = 0.0;
    for(int i = 0; i < kernelSize; ++i)
    {
     
        vec3 sample = TBN * samples[i]; 
        sample = fragPos + sample * radius; 
        
       
        vec4 offset = vec4(sample, 1.0);
        offset = projection  * offset; 
        offset.xyz /= offset.w; 
        offset.xyz = offset.xyz * 0.5 + 0.5;
        
		if(offset.x > 1.0 || offset.x < 0.0 || offset.y > 1.0 || offset.y < 0.0)
			continue ;
		float sampleDepth = ( projectionView * texture(gPosition, offset.xy)).z;
	

       
        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(fragPos.z - sampleDepth));
        occlusion += (sampleDepth >= sample.z + bias ? 1.0 : 0.0) * rangeCheck;           
    
	}
    occlusion = 1.0 - (occlusion / kernelSize);
	
    occlusion = pow(occlusion, 1);
    FragColor = vec4(occlusion, occlusion, occlusion, 1.0);
}