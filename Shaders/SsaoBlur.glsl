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

uniform sampler2D ssaoInput;
/*
void main() 
{

	vec2 screen_size = textureSize(ssaoInput, 0);
    vec4 sum = vec4(0.0);
    vec2 offset[9] = vec2[](vec2(-1.0, 1.0), vec2(0.0, 1.0), vec2(1.0, 1.0), 
                            vec2(-1.0, 0.0), vec2(0.0, 0.0), vec2(1.0, 0.0), 
                            vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0));
    float kernel[9] = float[](0.0, 0.0, 0.0, 
                             -1.0, 1.0, 0.0, 
                              0.0, 0.0, 0.0);

    for (int i = 0; i < 9; i++)
    {
        vec4 colour = texture(ssaoInput, (TexCoords + offset[i]) / screen_size);
        sum += colour * kernel[i];
    }

    float sharpen_amount = 0.25;
    FragColor = (sum * sharpen_amount) + texture(ssaoInput, TexCoords / screen_size);
}
 */ 

void main() 
{
    vec2 texelSize = 1.0 / vec2(textureSize(ssaoInput, 0));
    float result = 0.0;
    for (int x = -2; x < 2; ++x) 
    {
        for (int y = -2; y < 2; ++y) 
        {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(ssaoInput, TexCoords + offset).r;
        }
    }
    FragColor = vec4(vec3(result / (4.0 * 4.0)), 1.0);
}