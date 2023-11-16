// Shader made by Maximilien "Cewein", september 2023
//
// This is a raymarch scene of eigth tentacle in a water pit
// around a black hole, the black hole deform the direction of the rays
//
//
// Possible improvement :
// 		- Anti-Aliasing (but heave on perf)
//		- try to add some global illumination
//
// main help came from here : 
// https://iquilezles.org/articles/distfunctions/
// https://mercury.sexy/hg_sdf/
//
//


///// CONSTANT /////

#define MAX_STEP 256
#define MAX_DIST 100.0

vec3 blackHolePos = vec3(0.0,3.0,0.0);

///// RAY MARCHING FUNCTION /////

vec2 map(vec3 pos)
{
    vec2 dm = vec2(0.0,0.5);
    
    float total = 0.0;
    
    //black hole
    float sphere = distance(pos, blackHolePos)-0.35;
    total = sphere;
    
    
    //floor + hole in the ground
    float ground = pos.y;
    float cylinder = sdCylinder(pos, vec3(0.0,0.0,4.5));
    ground = max(ground,-cylinder);
    
    if( total > ground) dm.y = 2.5;
    total = min(total,ground);
    
    ground = abs(pos.y+1.0);
    if( total > ground) dm.y = 4.5;
    total = min(total,ground);
    
    //tentacle
    float tentacle = Tentacle((pos - vec3(0.,-3.,0.))*0.4,8.0, iTime, iChannel0);
    if( total > tentacle) dm.y = 3.5;
    
    dm.x = min(total,tentacle);
    
    return dm;
}

//raymarching loop
hitPayload trace(hitPayload p)
{
    float dist = 0.0;
    for(int i = 0; i < MAX_STEP; i++)
    {
        p.pos = p.pos + dist * p.dir;
        vec2 tmp = map(p.pos);
        
        if(tmp.x < 0.00001) return p;
        
        p.nbStep = i;
        
        dist = tmp.x;
        p.totalDist += tmp.x;
        p.mat = tmp.y;

        if(p.totalDist > MAX_DIST) 
        {
            p.mat = -1.0;
            break;
        }
        
        //add lensing, very basic but do the trick
        //we interpolate the original direction and the direction troward
        //the blackhole at each step based on the distance
        //of the point to the blackhole
        float inter = distance(p.pos, blackHolePos);
        inter = smoothstep(-9.5,2.5,inter);
        p.dir = mix(normalize(blackHolePos-p.pos),p.dir,inter);
    }
    
    return p;
}

///// SHADING FUNCTION /////

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(0.001,0.);
    return normalize(vec3(map(pos + e.xyy).x-map(pos-e.xyy).x,
                          map(pos + e.yxy).x-map(pos-e.yxy).x,
                          map(pos + e.yyx).x-map(pos-e.yyx).x)
                    );
}


//since the tentacle came out of the water
//add a "watery" effect 
vec3 Water( vec3 rayDir )
{

    vec3 WaterKeyColor  = vec3( 0.19, 0.92, 0.98 );
    vec3 WaterFillColor = vec3( 0.1, 0.06, 0.28 );
    
    rayDir.xy *= rot(-80.0); 
    vec3 color = mix( WaterKeyColor, WaterFillColor, clamp( -1.2 * rayDir.y + 0.6 ,0.0,1.0) );
    return color;
}

//thanks for the stars, check this shader out, it contain midgar
//https://www.shadertoy.com/view/XllXWN

float tri(in float x)
{
    return abs(fract(x)-.5);
}

vec3 stars(in vec3 p)
{
    vec3 c = vec3(0.);
    
    //Triangular deformation (used to break sphere intersection pattterns)
    p.x += (tri(p.z*50.)+tri(p.y*50.))*0.006;
    p.y += (tri(p.z*50.)+tri(p.x*50.))*0.006;
    p.z += (tri(p.x*50.)+tri(p.y*50.))*0.006;
    
	for (float i=0.;i<2.;i++)
    {
        vec3 q = fract(p*250.)-0.5;
        vec3 id = floor(p*250.);
        float rn = hash33(id).z;
        float c2 = 1.-smoothstep(-0.2,.4,length(q));
        c2 *= step(rn,0.005+i*0.014);
        c += c2*(mix(vec3(1.0,0.75,0.5),vec3(0.85,0.9,1.),rn*30.)*0.5 + 0.5);
        p *= 1.15;
    }
    return c*c*smoothstep(-0.1, 0., p.y);
}


//this is the function that translate a material to the correct color
vec3 getColor(hitPayload p)
{
    vec3 color = stars(p.dir);
    vec3 dm = vec3(p.mat);
  
    vec3 newWorldPos;
    hitPayload pNew;
    
    
    if(p.mat > 4.0 && p.mat < 5.0)
    {
        color = vec3(0.60);
        int nbStep;
        vec3 rdref = refract(p.dir,p.normal,0.9);
        p.pos -= p.normal*0.1;
        pNew = trace(p);
        p.pos += p.normal*0.1;
        newWorldPos = pNew.pos;
        dm.xy = vec2(pNew.mat);
    }
    
    p.mat = dm.y;
    
    //prevent tilling in the water pit
    if(dm.z < 4.0 || dm.z > 5.0)
    {
        if(p.mat > 2.0 ) //floor
        {
            //floor tilling 
            if(mod(floor(p.pos.xz*0.25), 2.0) == vec2(0.) || mod(floor(p.pos.xz*0.25), 2.0) == vec2(1.))
                color = vec3(0.6);
            else
                color = vec3(0.3);

        }
    }
    
    //tentacle shading
    //explanation is a bit more ditail here since
    //the code look a bit messy
    if(p.mat > 3.0)
    {
        
        // Calculate the background color
        vec3 background = Water(p.dir) * 0.3;

        // Calculate the specular occlusion based on the distance from the black hole
        float specOcc = clamp(0.5 * length(p.pos - vec3(blackHolePos)), 0.0, 1.0);

        // Define color constants
        vec3 c1 = vec3(0.67, 0.1, 0.05);    // Reddish color
        vec3 c2 = vec3(0.1, 0.06, 0.28);    // Dark blue color

        // Calculate the base color based on the normal
        vec3 baseColor = mix(c1, p.normal.y > 0.0 ? c1 : c2, smoothstep(vec3(0.0), vec3(0.8), p.normal));

        // Calculate the reflection vector
        vec3 reflVec = reflect(p.dir, p.normal);

        // Calculate the Fresnel term
        float fresnel = clamp(pow(1.2 + dot(p.dir, p.normal), 5.0), 0.0, 1.0);

        // Combine components to determine the final color based on the specular occlusion
        color = mix(
            0.8 * baseColor + 0.6 * Water(reflVec) * mix(0.04, 1.0, fresnel * specOcc),
            background,
            0.9 + dot(p.dir, p.normal) * specOcc
        );
    }
    if(dm.z > 4.0 && dm.z < 5.0) //water pit
    {
        color *= 4.5/((distance(newWorldPos,p.pos)-0.1)*20.);

    }

    return color;
}


///// RENDERING FUNCTION /////

//this is the quick way to obtain a invervse view matrix
//go to common to see alternative way with a long process
mat4 getInvViewMatrix(vec3 ro, vec3 at)
{
    vec3 ww = normalize(at-ro); //front
    vec3 uu = normalize(cross(ww, vec3(0.0,1.0,0.0))); // rigth;
    vec3 vv = normalize(cross(uu,ww)); // up;
    
    return mat4(uu,0.,
                vv,0.,
                -ww,0.,
                0.,0.,0.,1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord-iResolution.xy - 1.0)/iResolution.y;
    
    //init camera para
    float angle = 5.0*iMouse.x/iResolution.x;
    float height = 5.0*iMouse.y/iResolution.y;
    
    //if screen has not been clicked yet
    if(iMouse.x == 0.0 )
    {
        angle = 89.95;
        height = 0.5;

    }
    
    //ray origin and look at point
    vec3 ro = vec3(10.0 * cos(angle), 4.0*height, 10.0 * sin(angle));
    vec3 at = vec3(0.0,4.0,0.0);
    
    //ray direction
    vec3 rd = normalize(getInvViewMatrix(ro,at) * vec4(uv,-1.5,1.0)).xyz;
    
    //init scope variable
    vec3 color = vec3(0.0);
    
    //Using a struct make the code cleaner and
    //will also shorten many function 
    hitPayload p = hitPayload(
        ro, //postion aka origin at first
        rd, //ray direction
        vec3(0.0), //normal
        -1.0, //material
        0, //number of step
        0.0 //total distance
    );
        
    
    //preform ray-marching
    p = trace(p);
    
    //compute normal and get color
    p.normal = calcNormal(p.pos);
    color = getColor(p);
    
    //perform color grading before shadow (prefere this way)
    color = pow(color,vec3(0.4545));
    
    /***** SHADOW *****/
    //change the direction throward the bh
    p.dir =  normalize(blackHolePos - p.pos);
    
    //apply shadow on everything exect the sky
    if(p.mat > 0.0)
    {
        color *= clamp(dot(p.normal, p.dir), 0.0, 1.0 );
        color *= smoothstep(50.0,20.0,length(p.pos.xz));
    }
    
    //trace the shadow troward the blackhole
    //if anyhing else that the sky or bh is hit then it in shadow
    p.pos += p.normal*0.001;
    p = trace(p);
    if(p.mat > 1.0) color *= 0.3;

    fragColor = vec4(color,1.0);
}