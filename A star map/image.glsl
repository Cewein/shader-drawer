// Shader made by Maximilien "Cewein", december 2023
//
// This is a 2D star field, this use a probabilistic quad tree [1]
// to make the star, the version it was based on was nice but still very
// bloated, therefore was cleaned here. Use fractal brownian motion [2] from
// perlin noise [3] to generate the "space dust". star brigthness is a poor's man
// black body radiation approximation [4][5]
//
//
// Possible improvement :
// 		- Anti-Aliasing (but heave on perf)
//		- in the quadtree perform neighbour check
//      - better control of the star size, color, brigthness and blinking periode
//      - better control for the gaz clouds
//
// sources : 
// [1]: https://ciphrd.com/2020/04/02/building-a-quadtree-filter-in-glsl-using-a-probabilistic-approach/
// [2]: https://www.esaim-proc.org/articles/proc/pdf/1998/03/proc-Vol5.7.pdf
// [3]: https://mrl.cs.nyu.edu/~perlin/paper445.pdf
// [4]: https://www.atnf.csiro.au/outreach//education/senior/cosmicengine/stars_colour.html
// [5]: https://en.wikipedia.org/wiki/Planck%27s_law

// Constants for quadtree division and iteration counts
#define MIN_DIVISIONS 10.0
#define MAX_ITERATIONS 4
#define SAMPLES_PER_ITERATION 5

// Function to calculate color variation for a quad division in space
// Computes the average and variance of color components from random samples
float colorVariation(in vec2 center, in float size, vec2 a, vec2 b) 
{
    vec3 avg = vec3(0);
    vec3 var = vec3(0);

    // Sampling for color calculation
    for (int i = 0; i < SAMPLES_PER_ITERATION; i++) {
        vec2 r = hash22(center.xy + vec2(float(i))) - 0.5;
        float d = -sdEllipse(center + r * size, a, b);
        d = smoothstep(-.3, 2.0, d);
        vec3 sp = vec3(d);
        avg += sp;
        var += sp * sp;
    }
    
    // Calculate average and variance
    avg /= float(SAMPLES_PER_ITERATION);
    var = var / float(SAMPLES_PER_ITERATION) - avg * avg;
    
    return dot(var, vec3(1.0, 1.0, 1.0)) / 3.0;
}

// Main function for rendering
void mainImage(out vec4 fragColor, in vec2 fragCoord) 
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;;
    
    // Threshold for quad variance
    float threshold = 1.5e-5;  

    // Number of space divisions
    float divs = MIN_DIVISIONS;

    // Initialize ellipses parameters
    vec2 a = vec2(sin(2.5) * 0.1 + 0.5, 0);
    vec2 b = vec2(0, sin(1.5) * 0.1 + 0.5);

    for (int i = 0; i < MAX_ITERATIONS; i++) 
    {
    
        //probabilistic quadtree information
        // Center of the active quad and length of a side of the active quad
        vec2 quadCenter = (floor(uv * divs) + 0.5) / divs;
        float quadSize = 1.0 / divs;
        
        // Calculate color variation 
        float quadAvgVar = colorVariation(quadCenter, quadSize, a * rot(0.5) * 2.2, b * rot(0.75) * 0.05);
        
        // Check if variance is below threshold
        if (quadAvgVar < threshold) break;
        
        // Divide the space again
        divs *= 2.0;
    }
    
    // Coordinates inside the quad
    vec2 nUv = fract(uv * divs);
    vec2 id = floor(uv * divs);
    
    // Random position and color
    vec2 randPos = hash22(id);
    vec3 col = hash32(id);
    float randNum = hash12(id);
    
    //distance to the "star"
    float d = 1.0 - smoothstep(distance(randPos, nUv), 0.0001 * divs, 0.002 * divs);
    vec4 color = vec4(d);

    // Perform blinking effect between two colors
    // and fake black body radiation
    // the blinking is slow and just for a pure "artistic" vision
    // and the brigthness as a poorman's version of the Planck's law
    float blinkFactor = clamp(sin(100.0 * cos(randNum) + .50 * iTime * randNum),0.,1.0);
    float brigthness = smoothstep(0.1, 1.0, randNum * 0.7 + 0.3);
    
    //brigth star are "white blue" and dim stars are "fire orange"
    vec4 brightColor = vec4(0.859, 0.914, 0.957,1.0); // White-blue color
    vec4 dimColor = vec4(0.70, 0.27, 0.0,1.0); // Fire orange color
    vec4 blendedColor = mix(dimColor, brightColor,randNum);
    color *= brigthness * blinkFactor * blendedColor; 
    
    // Apply ellipses with different parameters and update color each time
    color = applyEllipse(uv, a, b, vec2(2.2, 0.5), vec2(0.25, 0.75), vec3(2.0, 0.9, 0.7), color, 0.75, vec4(1.0, 0.4, 0.6, 1.0));
    color = applyEllipse(uv, a, b, vec2(0.75, 0.5), vec2(0.5, 0.65), vec3(2.5, 0.8, 0.7), color, 0.5, vec4(1.0, 0.8, 0.4, 1.0));
    color = applyEllipse(uv, a, b, vec2(2.25, 0.5), vec2(0.75, 0.75), vec3(1.0, 0.7, 0.6), color, 0.1, vec4(.0, 0.2, 0.9, 1.0));
    
    // Create lines from the UV coordinates
    vec2 lWidth = vec2(1.0 / iResolution.x, 1.0 / iResolution.y);
    vec2 uvAbs = abs(nUv - 0.5);
    float s = step(0.5 - uvAbs.x, lWidth.x * divs) + step(0.5 - uvAbs.y, lWidth.y * divs);
    
    // Output to screen
    fragColor = color;
}
