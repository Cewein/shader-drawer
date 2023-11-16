///// STRUCTURE /////

struct hitPayload
{
    vec3 pos;
    vec3 dir;
    vec3 normal;
    float mat;
    int nbStep;
    float totalDist;
};


///// CONSTANTE /////

const float PI = atan(1.0)*4.0;

///// SDF FUNCION /////
//https://iquilezles.org/articles/distfunctions/

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

///// SDF OPERATION /////
// https://iquilezles.org/articles/distfunctions/

float opUnionRound( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * ( b - a ) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * ( 1.0 - h );
}

float opSubstractRound( float a, float b, float r ) 
{
	vec2 u = max( vec2( r + a, r - b ), vec2( 0.0, 0.0 ) );
	return min( -r, max( a, -b ) ) + length( u );
}

mat2 rot(in float a)
{
    a *= 0.0174533;
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

///// DOMAIN REPETITION /////

// found on the demogroup website : https://mercury.sexy/hg_sdf/

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
	float angle = 2.0*PI/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = vec2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2.0)) c = abs(c);
	return c;
}

vec3 opRep( in vec3 p, in vec3 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

///// TENTACLE /////
//based on this shader : https://www.shadertoy.com/view/MdsBz2
//modify to not use smooth and saturate and small tweek to rotate the whole sdf

float Tentacle( vec3 p , float nbTentacle, float iTime, sampler2D iChannel0)
{    

    //polar mod and rotation + displacement in world
    float c = pModPolar(p.xz,nbTentacle);
    p.xy *= rot(-60.0 + cos(sin(iTime + c))*3.0);
    p.y += 0.6;
    
    float scale = 1.0 - 2.5 * clamp( abs( p.y ) * 0.25,0.,1. );    
    
    p -= vec3( 1.0, -0.5, 0.0 );
    
    //controle the length
    p.xy *= rot(60.0);
    p.x -= sin( p.y * 5.0 + iTime * 1.6 ) * 0.05;
    p.z -= cos( p.x * 5.0 + iTime * 1.6 ) * 0.02;

    vec3 t = p;    

    float ret = sdCapsule( p, vec3( 0.0, -1000.0, 0.0 ), vec3( 0.0, 1000.0, 0.0 ), 0.25 * scale );
    
    p.z = abs( p.z );
    p.y = mod( p.y + 0.08, 0.16 ) - 0.08;
    p.z -= 0.12 * scale;
    float tent = sdCapsule( p, vec3( 0.0, 0.0, 0.0 ), vec3( -0.4 * scale, 0.0, 0.0 ), 0.1 * scale );
    
    float pores = sdSphere( p - vec3( -0.4 * scale, 0.0, 0.0 ), mix( 0.04, 0.1, scale ) );
    tent = opSubstractRound( tent, pores, 0.01 );
  
    ret = opUnionRound( ret, tent, 0.05 * scale );
    ret += textureLod( iChannel0, vec2( t.xy * 0.5 ), 0. ).x * 0.02;

    return ret;
}


///// PSEUDO-RANDOM FUNCTION /////

//quick and poor function
float frand(vec2 st)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(st.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

vec3 hash33(vec3 p){
    p  = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p += dot(p.yzx, p.xyz  + vec3(21.5351, 14.3137, 15.3219));
    return fract(vec3(p.x * p.z * 95.4337, p.x * p.y * 97.597, p.y * p.z * 93.8365));
}

///// MATRIX OPERATION /////

// matrix operations
mat4 translate(vec3 t)
{
 	return mat4(
        vec4(1.,0.,0.,0.),
        vec4(0.,1.,0.,0.),
        vec4(0.,0.,1.,0.),
        vec4(t,1.)
        );
}
mat4 translateInv(vec3 t)
{
 	return translate(-t);   
}

mat4 scale(vec3 s)
{
 	return mat4(
        vec4(s.x,0.,0.,0.),
        vec4(0.,s.y,0.,0.),
        vec4(0.,0.,s.z,0.),
        vec4(0.,0.,0.,1.)
        );
}
mat4 scaleInv(vec3 s)
{
 	return scale(1./s);   
}

mat4 rightToLeft()
{
    // 1 0 0  0
    // 0 1 0  0
    // 0 0 -1 0
    // 0 0 0  1
 	return scale(vec3(1.,1.,-1.));
}

mat4 rightToLeftInv()
{
    // same matrix
    return rightToLeft();
}
	

mat4 ortho(float l, float r, float b, float t, float n, float f)
{

    
       // translation and scale
    return scale(vec3(2./(r-l),2./(t-b),2./(f-n))) * 
                 translate(vec3(-(l+r)/2.,-(t+b)/2.,-(f+n)/2.));
    
}

mat4 orthoInv(float l, float r, float b, float t, float n, float f)
{
    return translateInv(vec3(-(l+r)/2.,-(t+b)/2.,-(f+n)/2.)) *
        scaleInv(vec3(2./(r-l),2./(t-b),2./(f-n)));
}

mat4 projection(float n, float f)
{
 	// n 0 0 0	0
    // 0 n 0 0	0
    // 0 0 n+f	-fn
    // 0 0 1	0
    return mat4(
        vec4(n,0.,0.,0.),
        vec4(0.,n,0.,0.),
        vec4(0.,0.,n+f,1.),
        vec4(0.,0.,-f*n,0.)
        );
}

mat4 projectionInv(float n, float f)
{
 	// 1/n 	0 	0 		0
    // 0 	1/n	0 		0
    // 0	0	0 		1
    // 0	0	-1/fn	(f+n)/fn
    
    return mat4(
        vec4(1./n,0.,0.,0.),
        vec4(0.,1./n,0.,0.),
        vec4(0.,0.,0.,-1./(f*n)),
        vec4(0.,0.,1.,(f+n)/(f*n))
        );
}


mat4 perspective(float fov, float aspect, float n, float f)
{
 	   float l = 1.0 / tan(fov*n);
       float b = l/aspect;
    
    	return ortho(-l,l,-b,b,n,f)*
            projection(n,f)*rightToLeft();
}


mat4 perspectiveInv(float fov, float aspect,float n, float f)
{
     float l = 1.0 / tan(fov*n);
       float b = l/aspect;
    
    return rightToLeftInv()*
        projectionInv(n,f)*
        orthoInv(-l,l,-b,b,n,f);
}

