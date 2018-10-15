#version 130
#extension GL_ARB_explicit_attrib_location : enable
#extension GL_ARB_explicit_uniform_location : enable
layout (location = 0) in vec2 positon;


out vec2 fragTexcoord;

void main()
{
	gl_Position = vec4(vec3(positon, 0.0), 1.0);    
	fragTexcoord = positon * 0.5 + 0.5;
}


&

#version 130
#extension GL_ARB_explicit_attrib_location : enable
#extension GL_ARB_explicit_uniform_location : enable
layout ( location = 0 ) out vec4 RezFragColor;
layout ( location = 1 ) out vec4 RezBrightColor;
layout ( location = 2 ) out vec4 RezGodRay;

in vec2 fragTexcoord;

layout ( location = 23 ) uniform sampler2D FragPosition;
uniform sampler2D FragNormal;
uniform sampler2D FragColor;
uniform sampler2D FragSettings;
uniform sampler2D FragDepth;
uniform sampler2D FragSSAO;
uniform sampler2D FragPBR;
uniform bool debugDrawShadowProjection;
uniform sampler2D shadowMap;
uniform samplerCube skybox;
uniform vec3	  lookPosition;

uniform samplerCube irradianceMap;
uniform samplerCube prefilterMap;
uniform sampler2D brdfLUT;

uniform bool ssaoEnabled;

vec3 fragPos;
vec3 fragNorm;
vec4 fragColor;
vec4 fragSett;
vec4 fragDepth;
vec4 fragPBR;
float ssaoAtt;
float shadowLume = 0.0;
float assymp = 0.0;

struct LightSource
{
        vec3 position;
        vec3 color;
		bool inFragSpace;
};

uniform LightSource lights[64];
uniform int lightsCount;

float calculateShadows(vec4 fragPosLightSpace)
{
	 vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5; 


	#ifdef DEBUG_DRAW_PROJ
	if(debugDrawShadowProjection)
	{	
		if(
		((projCoords.x > 1.0) && (projCoords.x < 1.0015) && ((projCoords.y <= 1.0) && (projCoords.z >= 0.00) && (projCoords.z <= 1.0) && (projCoords.y >= 0.00))) ||
		((projCoords.x < 0.0) && (projCoords.x > -0.0015) && ((projCoords.y <= 1.0)  && (projCoords.z >= 0.00) && (projCoords.z <= 1.0) && (projCoords.y >= 0.00))) ||
		((projCoords.y > 1.0) && (projCoords.y < 1.0015) && ((projCoords.x <= 1.0)  && (projCoords.z >= 0.00) && (projCoords.z <= 1.0) && (projCoords.x >= 0.00))) ||
		((projCoords.y < 0.0) && (projCoords.y > -0.0015) && ((projCoords.x <= 1.0)  && (projCoords.z >= 0.00) && (projCoords.z <= 1.0) && (projCoords.x >= 0.00))) 
		)
		{
			shadowLume = 1.0;
			return 0.0;
		}
	}
	#endif
	if(projCoords.x > 1.0 || projCoords.x < 0.0 || projCoords.y > 1.0 || projCoords.y < 0.0)
		return 0.0;

	float currentDepth = projCoords.z;
	if(currentDepth > 1.0)
		return 0.0;
	float bias = 0.000;
	float shadow = 0.0;
	vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
	for(int x = -1; x <= 1; ++x)
	{
		for(int y = -1; y <= 1; ++y)
		{
			float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r; 
			shadow += currentDepth - bias > pcfDepth ? 1.0 : 0.0;        
		}    
	}
	shadow /= 9.3;
	return shadow;
}

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.15,0.02),
								vec3(0.58597,0.35,0.09),
								vec3(0.58597,0.5,0.26),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));


const float PI = 3.14159265359;

// Нотация NVIDIA
// Дистрибутивность отражательной способности
//TODO 
float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / max(denom, 0.001); 
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
//Функция затенения геометрии
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}   
//Конец натации

void main()
{
	fragPos = texture(FragPosition, fragTexcoord).xyz;
    fragNorm = texture(FragNormal, fragTexcoord).xyz;
	fragColor = texture(FragColor, fragTexcoord);
	fragSett = texture(FragSettings, fragTexcoord);
	fragDepth = texture(FragDepth, fragTexcoord);
	fragPBR = texture(FragPBR, fragTexcoord);
	if(ssaoEnabled)
	{
		float ssaoAttantion = texture(FragSSAO, fragTexcoord).r;
		ssaoAttantion = pow(ssaoAttantion, 2.0);
		fragColor =  vec4(vec3(ssaoAttantion) * fragColor.xyz, fragColor.w);
	}

	//fragColor *= ssaoAttantion;

	if(fragSett.z > 0)
	{
		RezBrightColor = vec4(1.0, 1.0, 1.0, 1.0);
		RezFragColor = vec4(fragColor.xyz , 1.0);
		//RezBrightColor = vec4(vec3(0.0), 1.0);
		//RezFragColor = vec4(vec3(0.0), 1.0);
		RezGodRay = vec4(1.0);	
		return;
	}
	RezGodRay = vec4(vec3(0.0), 1.0);
	vec3 color;


	vec3 albedo = pow(fragColor.xyz, vec3(2.2));



	float roughness = fragPBR.y;
	float ao = fragPBR.z;
	float metallic = fragPBR.x;

	vec3 N = normalize(fragNorm);
    vec3 V = normalize(lookPosition - fragPos);
	vec3 R = reflect(-V, N); 
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, albedo, metallic);

	vec3 Lo = vec3(0.0);

	float mullCoff = 1.0f;
	float dt = dot(normalize(-vec3(1, -1, 1)), N);
	if(dt >= 0)
	{
		float val = calculateShadows(fragDepth);
		mullCoff = clamp(1.0 - val, 0.0, 1.0);
	}

	for(int i = 0; i <lightsCount; i++)
	{
		
		vec3 lightPosition;
		if(lights[i].inFragSpace)
			lightPosition=  fragPos + lights[i].position;
		else
			lightPosition= lights[i].position;
		 
		vec3 L = normalize(lightPosition - fragPos);
		vec3 H = normalize(V + L);
		float distance = length(lightPosition - fragPos);
		float attenuation = 1.0 / (distance * distance);
		vec3 radiance = lights[i].color * attenuation /** 0.85*/;
		
		float NDF = DistributionGGX(N, H, roughness);   
		float G   = GeometrySmith(N, V, L, roughness);      
		vec3 F    = fresnelSchlick(clamp(dot(H, V), 0.0, 1.0), F0);
           
		vec3 nominator    = NDF * G * F; 
		float denominator = 4 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
		vec3 specular = nominator / max(denominator, 0.001); 
             
		vec3 kS = F; 
		vec3 kD = vec3(1.0) - kS;
   
		kD *= 1.0 - metallic;	  
   
		float NdotL = max(dot(N, L), 0.0);        
		Lo += (kD * albedo / PI + specular) * radiance * NdotL; 	 
	}
	
	
	

	#define COSEL_PANNING
#ifdef COSEL_PANNING
    vec3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
    
    vec3 kS = F;
    vec3 kD = 1.0 - kS;
    kD *= 1.0 - metallic;	  
    
    vec3 irradiance = texture(irradianceMap, N).rgb;
    vec3 diffuse      = irradiance * albedo;

    const float MAX_REFLECTION_LOD = 4.0;
    vec3 prefilteredColor = textureLod(prefilterMap, R,  roughness * MAX_REFLECTION_LOD).rgb;    
    vec2 brdf  = texture(brdfLUT, vec2(max(dot(N, V), 0.0), roughness)).rg;
    vec3 specular = prefilteredColor * (F * brdf.x + brdf.y);


    vec3 ambient = (kD * diffuse + specular) * ao;
#else
    vec3 ambient = vec3(0.33) * albedo * ao;
	
#endif

    color = ambient + Lo * mullCoff;
	

	float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
//#define BLUR_MODEL_A
#ifdef BLUR_MODEL_A
    if(brightness > 0.7)
	{
		 RezBrightColor = vec4((color / 3), 1.0);
		 RezFragColor = vec4((color - (color / 12)), fragColor.a);
	}     
    else
	{
		 RezBrightColor = vec4(0.0, 0.0, 0.0, 1.0);
		 RezFragColor = vec4(color, fragColor.a);
	}
#else
	 RezBrightColor = vec4(clamp(color * brightness, vec3(0.0), vec3(1893.0)), 1.0);
	 RezFragColor = vec4(color, fragColor.a);
#endif
}