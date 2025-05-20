#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables

float density = 30.0;
float opacityScanline = .2;
float opacityNoise = .1;
float flickering = 0.00;


float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float blend(const float x, const float y) {
	return (x < 0.5) ? (2.0 * x * y) : (1.0 - 2.0 * (1.0 - x) * (1.0 - y));
}

vec3 blend(const vec3 x, const vec3 y, const float opacity) {
	vec3 z = vec3(blend(x.r, y.r), blend(x.g, y.g), blend(x.b, y.b));
	return z * opacity + x * (1.0 - opacity);
}


vec3 chromatic(vec3 offsets, sampler2D samp, vec2 uv) {

    vec2 dir =  vec2(0.5, 0.5) - uv;

    float r = texture(samp, uv + (dir * offsets.r)).r;
    float g = texture(samp, uv + (dir * offsets.g)).g;
    float b = texture(samp, uv + (dir * offsets.b)).b;

    return vec3(r,g,b);

}

void main()
{
    // Texel color fetching from texture sampler
    vec4 color = texture(texture0, fragTexCoord);

    
 


    vec3 rgb = chromatic(vec3(0.003, 0.003, -0.003), texture0, fragTexCoord);


    finalColor = vec4(rgb,1.0);
}