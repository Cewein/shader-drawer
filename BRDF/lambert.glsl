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

vec3 BRDFLambert(material mat, hitPayload p, vec3 refDir)
{
    //Lambert BRDF : albedo / pi;
    vec3 brdf = mat.albedo/PI;
    return brdf;
}