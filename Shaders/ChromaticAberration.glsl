#version 130
#extension GL_ARB_explicit_attrib_location : enable

layout (location = 0) in vec2 positon;

out vec2 v_texCoord;

void main()
{
	gl_Position = vec4(vec3(positon, 0.0), 1.0);    
	v_texCoord = positon * 0.5 + 0.5;
}
&
#version 130
uniform sampler2D tInput;
uniform vec2 resolution;
in vec2 v_texCoord;
out vec4 FragColor;
vec2 barrelDistortion(vec2 coord, float amt) {
	vec2 cc = coord - 0.5;
	float dist = dot(cc, cc);
	return coord + cc * dist * amt;
}

float sat( float t )
{
	return clamp( t, 0.0, 1.0 );
}

float linterp( float t ) {
	return sat( 1.0 - abs( 2.0*t - 1.0 ) );
}

float remap( float t, float a, float b ) {
	return sat( (t - a) / (b - a) );
}

vec4 spectrum_offset( float t ) {
	vec4 ret;
	float lo = step(t,0.5);
	float hi = 1.0-lo;
	float w = linterp( remap( t, 1.0/6.0, 5.0/6.0 ) );
	ret = vec4(lo,1.0,hi, 1.) * vec4(1.0-w, w, 1.0-w, 1.);

	return pow( ret, vec4(1.0/2.2) );
}

const float max_distort = 0.05;
const int num_iter = 12;
const float reci_num_iter_f = 1.0 / float(num_iter);


vec4 texture2D_WrapLength(sampler2D s, vec2 coords)
{
//	if(coords.x > 1.0 || coords.x < 0.0 || coords.y > 1.0 || coords.y  < 0.0)
	//	return vec4(0.0);
	return texture( s, coords );
}

void main()
{	
	vec2 uv = v_texCoord;
	vec2 cc = uv - 0.5;
	float dist = dot(cc, cc);

	vec4 sumcol = vec4(0.0);
	vec4 sumw = vec4(0.0);	
	for ( int i=0; i<num_iter;++i )
	{
		float t = float(i) * reci_num_iter_f;
		vec4 c = texture2D_WrapLength( tInput, barrelDistortion(uv, .6 * max_distort*t ) );
	
		
		vec4 w = spectrum_offset( t );
		sumw += w;
		sumcol += w * c;
	}

	FragColor = vec4((sumcol / sumw * (1.0 - pow(abs(dist * 1.0), 1.0))).rgb, 1.0);;
	//gl_FragColor = sumcol / sumw;
}