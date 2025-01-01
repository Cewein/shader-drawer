///// STRUCT /////

struct hitPayload
{
    vec3 orig;
    vec3 hitPos;
    vec3 dir;
    vec3 normal;
    int matIndex;
    int nbStep;
    float dist;
};

struct material
{
    vec3 albedo;
    float metalness;
    float roughness;
    float IOR;
};

vec3 BRDFOrenNayar(material mat, hitPayload p, vec3 refDir)
{
    // Oren Nayar BRDF
    // based on mat.roughness
    // found on https://dl.acm.org/doi/pdf/10.1145/192161.192213
    // chapter 4.4 Qualitative Model
    vec3 lambert = mat.albedo/PI;
    
    float sigmaSqrt = mat.roughness*mat.roughness;
    
    float a =  1.0 - 0.5*(sigmaSqrt/(sigmaSqrt+0.33));
    float b =  0.45*(sigmaSqrt/(sigmaSqrt+0.09));
    
    float cosThetaI = dot(p.normal,p.dir); //in coming ray
    float cosThetaR = dot(p.normal,refDir); //out going ray, can be also a ligth direction.
    
    //value of the angle
    float thetaI = acos(cosThetaI); 
    float thetaR = acos(cosThetaR);
    
    //diff tangent
    vec3 tangentI = normalize(cross(p.normal, cross(p.normal, p.dir)));
    vec3 tangentR = normalize(cross(p.normal, cross(p.normal, refDir)));

    float ndiff = max(0.0,dot(tangentI, tangentR));
    
    //Normally in the 
    float alpha = max(thetaI,thetaR);
    float beta = min(thetaI,thetaR);
    
    return lambert * (a + b*ndiff*sin(alpha)*tan(beta));
}