// a small tribute to FF7 : Cloud's buster sword
// fell free to look around, there is mouse controle
//
// shader made by cewein
//
// link : https://www.shadertoy.com/view/wdByRw


// signed distance functions

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

mat2 rot(in float a)
{
    a *= 0.0174533;
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 sdSword(vec3 pos)
{
    //sword
    float sword;
    vec3 sp = pos;
    sp.y += 1.1; sp.xy *= rot(26.0);
    
    //blade
    float blade = sdBox(sp, vec3(0.5,2.5,0.03));
    float unBlade = sdBox(sp, vec3(0.5,2.5,0.025));
    float sharpen = dot(sp + vec3(0.,1.3,0.), normalize(vec3(0.75,-0.7,8.0)));
    unBlade = max(unBlade,sharpen);
    sharpen = dot(sp + vec3(-.45,0.,0.), normalize(vec3(1,0.0,11.)));
    unBlade = max(unBlade,sharpen);
    
    sharpen = dot(sp + vec3(0.,1.1,0.), normalize(vec3(0.75,-0.7,0.0)));
    blade = max(blade,sharpen);
    sharpen = dot(sp + vec3(-.25,0.,0.), normalize(vec3(1,0.0,0.)));
    blade = max(blade,sharpen);
    
    
    //blade hole
    float hole1 = length(sp - vec3(0.,2.2,0.)) - 0.1;
    float hole2 = length(sp - vec3(0.,1.9,0.)) - 0.1;
    unBlade = max(unBlade,-hole1);
    unBlade = max(unBlade,-hole2);
    blade = max(blade,-hole1);
    blade = max(blade,-hole2);
    
    sword = blade;
    vec3 res = vec3(sword, 1.0,1.);
    if(unBlade < blade)
    {
        sword = min(sword, unBlade);
    	res = vec3(sword, 4.0,1.);
    }
        
    //guard
    float guard = sdBox(sp - vec3(0.,2.5,0.), vec3(0.6,0.08,0.08));
    float rm = sdBox(sp - vec3(0.,2.5,0.15), vec3(0.62,0.06,0.08));
    guard = max(-rm,guard);
    rm = sdBox(sp - vec3(0.,2.5,-.15), vec3(0.62,0.06,0.08));
    guard = max(-rm,guard);
    rm = sdBox(sp - vec3(.78,2.5,0.), vec3(0.2,0.06,0.08));
    guard = max(-rm,guard);
    rm = sdBox(sp - vec3(-.78,2.5,0.), vec3(0.2,0.06,0.08));
    guard = max(-rm,guard);
	if( guard<sword)
    {
     	sword = min(sword,guard);
        res = vec3(sword, 2.0,-1.);
    }
    
    //guard bolt
    vec3 bp = sp;
    bp.yz *= rot(90.0);
    float bolts = sdVerticalCapsule(bp - vec3(-0.5,-.07,2.5), .14, 0.03);
    float b = sdVerticalCapsule(bp - vec3(-0.3,-.07,2.5), .14, 0.03);
    bolts = min(bolts, b);
    b = sdVerticalCapsule(bp - vec3(-0.1,-.07,2.5), .14, 0.03);
    bolts = min(bolts, b);
    b = sdVerticalCapsule(bp - vec3(0.1,-.07,2.5), .14, 0.03);
    bolts = min(bolts, b);
    b = sdVerticalCapsule(bp - vec3(0.3,-.07,2.5), .14, 0.03);
    bolts = min(bolts, b);
    b = sdVerticalCapsule(bp - vec3(0.5,-.07,2.5), .14, 0.03);
    bolts = min(bolts, b);
    
    if(bolts < sword)
    {
    	sword = min(sword,bolts);
    	res = vec3(sword, 4.0,0.3);
    }
    
    //handle
   	float handle = sdCappedCylinder(sp - vec3(0.,3.0,0.), 0.08, 0.4);
    float handleDown = sdCappedCylinder(sp - vec3(0.,2.635,0.), 0.1, 0.05);
    float handleUp = sdCappedCylinder(sp - vec3(0.,3.44,0.), 0.1, 0.05);
    handleDown = min(handleDown,handleUp);   
	if(handle<sword)
    {
     	sword = min(sword,handle);
        res = vec3(sword, 3.0,-1.);
    }
    
    if(handleDown<sword)
    {
        sword= min(sword,handleDown);
        res = vec3(sword, 4.0,.3);
    }
    
    //health ball
    float sph = length(sp - vec3(0.,2.2,0.)) - .09;
    if(sph  == sword)
    {
    	sword = min(sword, sph);
    	res = vec3(sword, 5.0, -1.);
    }
    
    return res;
}


//Mapping function
vec3 map(in vec3 pos) 
{
    //tm is the vec3(distance, id mat, boolean for reflection)
    vec3 tm = sdSword(pos);
    float flr = pos.y + 2.1;
 	if(flr<tm.x)
    {
        tm.x = flr;
        tm.y = 6.;
        tm.z = -1.;
    }
    
    return tm;

}

vec3 calcNormal(in vec3 pos)
{
    vec2 e = vec2(0.0001,0.);
    return normalize(vec3(map(pos + e.xyy).x-map(pos-e.xyy).x,
                          map(pos + e.yxy).x-map(pos-e.yxy).x,
                          map(pos + e.yyx).x-map(pos-e.yyx).x)
                    );
}

//ray marching algorithms
vec3 castRay(in vec3 ro, in vec3 rd)
{
    vec3 tm = vec3(0., -1., -1.);
    vec3 vc = vec3(0.);
    for(int i = 0; i<120; i++)
    {
        vec3 pos = ro + tm.x*rd;
        vec3 h = map(pos);
        if(h.x < 0.0001) break;
        tm.y = h.y;
        tm.x += h.x;
        tm.z = h.z;
        if(tm.x > 200.)
        {
            tm.y = -1.; 
            break;
        }
        
    }
        
    return tm;
}

vec3 hash33(vec3 p){
    p  = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p += dot(p.yzx, p.xyz  + vec3(21.5351, 14.3137, 15.3219));
    return fract(vec3(p.x * p.z * 95.4337, p.x * p.y * 97.597, p.y * p.z * 93.8365));
}

float tri(in float x)
{
    return abs(fract(x)-.5);
}

//thanks for the stars, check this shader out, it contain midgar
//https://www.shadertoy.com/view/XllXWN
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

vec3 render(in vec3 ro, in vec3 rd, vec2 uv)
{
    float mult = 1.0;
    vec3 col = stars(rd) * smoothstep(0.,.5, dot(rd,vec3(0.,1.,0.)));
    vec3 density;
    
   	vec3 tm = castRay(ro,rd);

    vec3 pos = ro + tm.x*rd;
    vec3 mat = vec3(0.01)* texture(iChannel2, (10. + pos.xz)/100.).x * smoothstep(10.,0.,length(pos));
    vec3 sunDir = normalize(vec3( 1.0,0.5,.6));
    
    if(tm.y < 1.5)
    {
        vec3 pos = ro + tm.x*rd;
        mat = vec3(0.025) * texture(iChannel0,pos.xy).x;
    }
    else if(tm.y < 2.5)
    {
        mat = vec3(.01);
    }
    else if(tm.y < 3.5)
    {
        mat = vec3(0.35, 0.20, 0.05)* texture(iChannel1,pos.xy).xyy;
    }
    else if(tm.y < 4.5)
    {
        mat = vec3(0.1);
    }
    else if(tm.y < 5.5)
    {
        mat = vec3(0.0,0.04,0.);   
    }
    
    if(tm.y > 0.)
    {
        vec3 density;
        vec3 norm = calcNormal(pos);
        
        vec3 volPos = vec3(0.95,.9,0.);
        
        vec3 tmp;
        
       	float sunDif = clamp( dot(norm, sunDir),0.,1.);
        float skyDif = clamp( 0.5 + 0.5*dot(norm, vec3(0.,1.,0.)),0.,1.);
        float sunSha = step(castRay(pos + norm * 0.001, sunDir).y,0.);
        float bouceDif = clamp( 0.5 + 0.5*dot(norm, vec3(0.,-1.,0.)),0.,1.);
        
        col =  mat * vec3(2.0)* sunDif * sunSha;
        col += mat * vec3(0.5) * skyDif;        
        col += mat * vec3(0.1) * bouceDif;
        
        if(tm.z > 0.)
        {
            vec3 ref = reflect(rd, norm);
            vec3 spe = vec3(smoothstep(0.0,0.35,clamp( dot(ref, sunDir),0.,1.)));
            float fre = clamp(1.0+dot(rd,norm), 0.,1.0);
            spe *= mat + (1.0-mat)*pow(fre,5.0);
            spe *= 100. * tm.z;
            
            col += mat*spe*sunSha;
        }
        
    }

    col += density;
    
    
    col = pow(col, vec3(0.4545));
    
    return col;
}
 
vec3 getDir(in vec3 ro, in vec2 uv)
{
    vec3 ta = vec3(0.,0.5,0.);
    
    vec3 ww = normalize(ta-ro); //front
    vec3 uu = normalize(cross(ww,vec3(0.,1.0,0.))); //right
    vec3 vv = normalize(cross(uu,ww)); //up
    
    return normalize(uv.x*uu + uv.y*vv + 1.5*ww);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord-iResolution.xy)/iResolution.y;
    float angle = 10.0*iMouse.x/iResolution.x;
    vec3 ro = vec3(5.0 * sin(angle),1.,5.0 * cos(angle));  
    vec3 rd = getDir(ro, uv);
    vec3 col = render(ro,rd, uv);
    fragColor = vec4(col,1.0);
}