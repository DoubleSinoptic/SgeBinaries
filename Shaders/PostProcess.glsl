#version 130
#extension GL_ARB_explicit_attrib_location : enable

layout (location = 0) in vec2 positon;


out vec2 frag_texcoord;

void main()
{
	gl_Position = vec4(vec3(positon, 0.0), 1.0);    
	frag_texcoord = positon * 0.5 + 0.5;
}
&
#version 130
out vec4 FragColor;

in vec2 frag_texcoord;

uniform sampler2D rez_map;
uniform sampler2D god_map;
uniform sampler2D blur_map;

float gamma = 2.2;

vec3 linearToneMapping(vec3 color)
{
	float exposure = 5.0;
	color = clamp(exposure * color, 0.0, 1.0);
	color = pow(color, vec3(1.0 / gamma));
	return color;
}

vec3 simpleReinhardToneMapping(vec3 color)
{
	float exposure = 1.5;
	color *= exposure/(1.0 + color / exposure);
	color = pow(color, vec3(1.0 / gamma));
	return color;
}

vec3 lumaBasedReinhardToneMapping(vec3 color)
{
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma / (1.0 + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1.0 / gamma));
	return color;
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
{
	float white = 2.0;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1.0 + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1.0 / gamma));
	return color;
}

vec3 RomBinDaHouseToneMapping(vec3 color)
{
    color = exp( -1.0 / ( 2.72*color + 0.15 ) );
	color = pow(color, vec3(1.0 / gamma));
	return color;
}

vec3 _Uncharted2Tonemap(vec3 x) 
{
	float A = 0.28;		
	float B = 0.29;		
	float C = 0.10;
	float D = 0.2;
	float E = 0.025;
	float F = 0.35;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 Uncharted2ToneMappingConfigure(vec3 color)
{	

	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	//old 6.4
	float exposure = 8.0;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	color = pow(color, vec3(1.0 / 1.3));
	return color;
}

vec3 Uncharted2ToneMapping(vec3 color)
{		
	vec3 curr = _Uncharted2Tonemap(color*4.7);
	return pow(curr/_Uncharted2Tonemap(vec3(15.2)), vec3(0.454));
}
vec3 filmicToneMapping(vec3 color)
{
	color = max(vec3(0.0), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}


vec3 bluur_attach(vec3 rgbT)
{
	const float luminance = 0.5;
	const float middleGrey = 0.5;
	const float threshold = 0.4;
	rgbT *= (middleGrey/luminance);
	rgbT *= ( 1.0 + (rgbT/(threshold * threshold) ) );
	rgbT -= 0.5;
	rgbT /= (1.0 + rgbT);
	return rgbT;
}

void main()
{
#define USE_BORDER_MASK
	vec2 coordX = frag_texcoord;
#ifdef USE_BORDER_MASK
	const float offset = 0.016;
	coordX = coordX * vec2(1.0 - offset) + vec2(offset / 2.0);
#endif

	vec3 blur = texture(blur_map, coordX).rgb ;//* 0.1;
	vec3 god = texture(god_map, coordX).rgb ;//* 0.1;
    //vec3 color = pow(texture(rez_map, coordX).rgb, vec3(2.0)) + (god / 10) + blur * 0.1;
	vec3 color = texture(rez_map, coordX).rgb + (god / 10) + blur * 0.1;

	color = Uncharted2ToneMappingConfigure(color/* * 3.4*/);


    FragColor = vec4(color, 1.0);
}