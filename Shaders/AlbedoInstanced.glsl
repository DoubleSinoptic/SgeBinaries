#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout(location = 0) in vec3 vertex;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texCoord;
layout(location = 3) in vec3 tanget;
#ifdef USE_INSTANCING
layout(location = 4) in vec4 tr0;
layout(location = 5) in vec4 tr1;
layout(location = 6) in vec4 tr2;
layout(location = 7) in vec4 tr3;
#else
uniform mat4 ObjectTransform;
#endif

uniform mat4 view;
uniform mat4 projection;
out mat4 model;

uniform mat4 mvpShadow;
uniform vec3 lookDirection;
uniform vec3 lookPosition;
uniform sampler2D albedo;
uniform bool albedoEnable;
uniform float specularCofficent;
uniform mat4 vpShadow;

out vec3 o_vertex;
out vec3 o_normal;
out vec2 o_texCoord;
out vec4 o_vertexShadow;
out mat3 TBN;

void main(void)
{
	#ifdef USE_INSTANCING
	mat4 model = mat4(tr0, tr1, tr2, tr3);
	#else
	mat4 model = ObjectTransform;
	#endif
	vec3 T = normalize(mat3(model) * tanget);
    vec3 B = normalize(mat3(model) *  normalize(cross(normal, tanget))); 
    vec3 N = normalize(mat3(model) * normal); 

	TBN = mat3(T,B, N); 


	o_vertexShadow = vpShadow * model * vec4(vertex, 1.0);

	o_vertex = ( model * vec4(vertex, 1.0)).xyz;
	o_normal = mat3(model) * normal;

	o_texCoord = texCoord;
	gl_Position = projection * view *  model * vec4(vertex, 1.0);
}

&
#version 130
#extension GL_ARB_explicit_attrib_location : enable	
layout(location = 0) out vec4 FragPositon;	
layout(location = 1) out vec4 FragNormal;	
layout(location = 2) out vec4 FragColor;	
layout(location = 3) out vec4 FragSettings;	 
layout(location = 4) out vec4 FragDepth;	
layout(location = 5) out vec4 FragPBR;


uniform mat4 view;
uniform mat4 perspective;
in mat4 model;
uniform mat4 mvpShadow;
uniform sampler2D shadowMap;
uniform vec3 lookDirection;
uniform vec3 lookPosition;
uniform sampler2D albedo;
uniform sampler2D normalMap;
uniform bool albedoEnable;
uniform bool normalMapEnable;

uniform vec4 albedoStatic;
uniform	vec3 mraoStatic;

uniform sampler2D _m;
uniform bool _mEnable;
uniform sampler2D _r;
uniform bool _rEnable;
uniform sampler2D _ao;
uniform bool _aoEnable;

uniform float specularCofficent;


in vec3 o_vertex;
in vec3 o_normal;
in vec2 o_texCoord;
in vec4 o_vertexShadow;

in mat3 TBN;

void main(void)
{
	vec3 albedoColor = albedoStatic.xyz;
	float albedoAlpha = albedoStatic.w;
	if(albedoEnable)
	{
		vec2 e = o_texCoord;
		e.y = e.y;
		vec4 tmp = texture(albedo, e);
		albedoColor = tmp.rgb;
		albedoAlpha = tmp.a;
	}
	if(albedoAlpha < 0.5)
		discard;
		
	vec3 goodNormal = o_normal;
	if(normalMapEnable)
	{
		goodNormal = texture(normalMap, o_texCoord).rgb;
		goodNormal = normalize(goodNormal * 2.0 - 1.0);   
		goodNormal = normalize(TBN * goodNormal); 

	}
	
	//FragPBR = vec4(0.5, 100.0 / 255.0, 1.0, 1.0);
	
	FragPBR = vec4(mraoStatic, 1.0);
	if(_mEnable)
		FragPBR.x = texture(_m, o_texCoord).r;
	if(_rEnable)
		FragPBR.y = texture(_r, o_texCoord).r;
	if(_aoEnable)
		FragPBR.z = texture(_ao, o_texCoord).r;

	FragPositon = vec4(o_vertex, 1.0);
	FragNormal = vec4(goodNormal, 1.0);
	FragColor = vec4(albedoColor, /*albedoAlpha*/1.0);
	FragSettings = vec4(0.0, 0.0, 0.0, 1.0);
	FragDepth = o_vertexShadow;
}