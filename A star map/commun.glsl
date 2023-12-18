//A define to create a 2D rotation matrix based on an angle.
//The angle must be in radian
#define rot(t) mat2(cos(t), -sin(t), sin(t), cos(t))

///// SDF FUNCTION - MOSTLY 2D /////

// for visualization purposes only
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 ba = b-a;
    vec2 pa = p-a;
    float h =clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length(pa-h*ba);
}

// Function to compute the signed distance from a 2D point 'p' to an ellipse defined by two radii 'a' and 'b'
// The function utilizes Newton's method for root finding to determine the distance
// See https://www.shadertoy.com/view/4sS3zz for more details on this method
float sdEllipse(vec2 p, vec2 a, vec2 b) 
{
    // Perform transformations and calculate the minor/major radii
    float la = length(a);
    float lb = length(b);
    p *= mat2(a / la, b / lb);
    vec2 ab = vec2(la, lb);
    
    // Code beyond this point by Inigo Quilez (iq)
    
    // Ensure symmetry
    p = abs(p);

    // Find root with Newton's solver
    vec2 q = ab * (p - ab);
    float w = (q.x < q.y) ? 1.570796327 : 0.0;
    for (int i = 0; i < 4; i++) {
        vec2 cs = vec2(cos(w), sin(w));
        vec2 u = ab * vec2(cs.x, cs.y);
        vec2 v = ab * vec2(-cs.y, cs.x);
        w = w + dot(p - u, v) / (dot(p - u, u) + dot(v, v));
    }
    
    // Compute final point and distance
    float d = length(p - ab * vec2(cos(w), sin(w)));
    
    // Return signed distance
    return (dot(p / ab, p / ab) > 1.0) ? d : -d;
}

///// RANDOMNESS - PART ONE: HASH /////

//  1 out, 2 in...
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

///  2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

/// 2 out, 2 in... made for perlin noise and use a sinusoid
/// work well with small value or hit floating point precision error
vec2 hashNoise22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

///  3 out, 2 in...
vec3 hash32(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

///// RANDOMNESS - PART TWO: PERLIN NOISE AND FRACTAL BROWNIAN MOTION /////

// From https://www.shadertoy.com/view/4tdSWr
// Function to generate Perlin noise at a 2D coordinate 'p' using Perlin's algorithm
// The noise function produces smooth, continuous noise values based on the input coordinate
float noise(in vec2 p) 
{
    // Constants used in the Perlin noise calculation
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hashNoise22(i + 0.0)), dot(b, hashNoise22(i + o)), dot(c, hashNoise22(i + 1.0)));
    return dot(n, vec3(70.0));
}

// Function to generate fractal Brownian motion (FBM) using Perlin noise from a point "n"
// with the two parametre (I.E : lacunarity and Persistance )
float fbm(vec2 n, float amplitude, float resiliation) 
{
    // Initialize the total value to accumulate noise
    float total = 0.0; 
    
    // Define a transformation matrix 'm', it provide rotation and scaling to avoid repetion
    // without this matrix the fbm will stack every octave on top of on and each other and become uniform
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);

    // Iterate through multiple octaves to compute the final noise value
    for (int i = 0; i < 7; i++) {
        // Accumulate noise values with varying amplitudes
        total += (0.1 + noise(n)) * amplitude;
        
        // Apply the transformation matrix 'm' to 'n' for the next octave
        n = m * n;
        
        // Decrease the amplitude for the next octave
        amplitude *= resiliation;
    }
    
    // Return the absolute accumulated noise value
    return abs(total);
}


/* Function to calculate the distance to an elliptical shape and perform color blending at a given UV coordinate
Parameter explanantion :
vec2 uv,           // 2D coordinates of the point on the surface
vec2 a,            // First axis of the ellipse
vec2 b,            // Second axis of the ellipse
vec2 factorA,      // Factors to modify the first axis: [scale, rotation]
vec2 factorB,      // Factors to modify the second axis: [scale, rotation]
vec3 fbmParam,     // Parameters for the fractal Brownian motion (scale, octaves, persistence)
vec4 color,        // Original color to be mixed
float intensity,   // Mixing factor
vec4 gazColor      // Color for blending
*/
vec4 applyEllipse(vec2 uv, vec2 a, vec2 b, vec2 factorA, vec2 factorB, vec3 fbmParam, vec4 color, float intensity, vec4 gazColor) 
{
    // Compute the distance from the current UV to the ellipse
    float d = -sdEllipse(uv, a * rot(factorA.y) * factorA.x, b * rot(factorB.y) * factorB.x);
    
    // smooth out the distance from the ellipse and clamp it between 0. and 1.
    d = smoothstep(-0.1, 0.4, d);
    
    // use d as a mask for the fractal Brownian motion and blend the two color with the value given from the mask * fbm
    color = mix(color, gazColor, intensity * d * fbm(uv * fbmParam.x, fbmParam.y, fbmParam.z));
    
    // Return the modified color
    return color;
}
