#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout (location = 0) in vec2 position;


uniform sampler2D image;
uniform bool horizontal;


out vec2 btc[11];

#define UPCONST_CONST 5

void main()
{
    gl_Position = vec4(vec3(position, 0.0), 1.0f);


	vec2 centerTexCoords = position * 0.5 + 0.5;

	if(horizontal)
	{
		float pixelSize = 1.0 /  textureSize(image, 0).x;
		for(int i = - UPCONST_CONST ; i <= UPCONST_CONST; i++)
				btc[i+ UPCONST_CONST ] = centerTexCoords + vec2(pixelSize * i, 0.0);	
		
	}
	else
	{
		float pixelSize = 1.0 /  textureSize(image, 0).y;
		for(int i = - UPCONST_CONST ; i <= UPCONST_CONST ; i++)
				btc[i+ UPCONST_CONST ] = centerTexCoords + vec2(0.0, pixelSize * i);	
		
	}

		
}

&


#version 130

out vec4 FragColor;

uniform sampler2D image;
in vec2 btc[11];

//http://dev.theomader.com/gaussian-kernel-calculator/

//float kernel[17] = float[] (0.055935,	0.056994,	0.057927,	0.058729,	0.059394,	0.059915,	0.060291,	0.060517	,0.060593	,0.060517,	0.060291	,0.059915	,0.059394,	0.058729	,0.057927,	0.056994,	0.055935);

//float kernel[17] = float[] (0.058706,	0.05875,	0.058788,	0.058821,	0.058847	,0.058868	,0.058882,	0.058891,	0.058894,	0.058891,	0.058882,	0.058868,	0.058847,	0.058821,	0.058788,	0.05875,	0.058706
//);

float kernel_11[11] = float[] (
0.000003,	0.000229,	0.005977,	0.060598,	0.24173,	0.382925,	0.24173,	0.060598,	0.005977,	0.000229,	0.000003
);


float kernel[17] = float[] (

0.038265,	0.044582	,0.050895	,0.05693	,0.062396	,0.067007	,0.070509	,0.072697	,0.073441	,0.072697	,0.070509	,0.067007	,0.062396	,0.05693	,0.050895	,0.044582	,0.038265


 );

void main()
{     

	FragColor = vec4(0.0);
	
	for(int i = 0; i < 11; i++)
	{	
		FragColor += texture(image, btc[i]) * kernel_11[i];
	}

   
}
