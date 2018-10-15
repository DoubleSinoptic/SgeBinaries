#version 130
#extension GL_ARB_explicit_attrib_location : enable
layout(location = 0) in vec3 attr_vertex;

uniform mat4 depthVP;
#ifdef USE_INSTANCING
layout(location = 4) in vec4 tr0;
layout(location = 5) in vec4 tr1;
layout(location = 6) in vec4 tr2;
layout(location = 7) in vec4 tr3;
#else
uniform mat4 ObjectTransform;
#endif



void main()
{
#ifdef USE_INSTANCING
	mat4 Model = mat4(tr0, tr1, tr2, tr3);
#else
	mat4 Model = ObjectTransform;
#endif
	gl_Position = depthVP *  Model  * vec4(attr_vertex,1);
}

&

#version 130
void main()
{
}