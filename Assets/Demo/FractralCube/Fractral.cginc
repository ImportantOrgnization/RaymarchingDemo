#ifndef INCLUDE_FRACTRAL_CGINC
#define INCLUDE_FRACTRAL_CGINC

float _RayMarchingCnt;
float _A;
float _InitWeight;
float _F;
float _Scale;
int _FbmdIteration;
float _MapFix1;
float _MapFix2;
float4 _KParams1;
float4 _KParams2;
float _RayThreshold;
//---------------------------------------------------------------
// value noise, and its analytical derivatives
//---------------------------------------------------------------

float2 cuiblicPolynomial(float w){
    float fw = w*w*(3.0-2.0*w);
    float dfw = 6.0*w*(1.0-w);
    return float2(fw,dfw);
}

float2 quinticPolynomial(float w){
    float fw = w*w*w * (6*w*w - 15 * w + 10);
    float dfw = w*w* ( 30 * w * w + 60 * w + 30);
    return float2(fw,dfw);
}

fixed hash( fixed n ) { return frac(sin(n)*753.5453123); }
fixed4 noised( in fixed3 x )
{
    fixed3 p = floor(x);
    fixed3 w = frac(x);
    //cuiblicPolynomial
    fixed3 u = w*w*(3.0-2.0*w);
    fixed3 du = 6.0*w*(1.0-w);
    
    fixed n = p.x + p.y*157.0 + 113.0*p.z;
    fixed a = hash(n+  0.0);
    fixed b = hash(n+  1.0);
    fixed c = hash(n+157.0);
    fixed d = hash(n+158.0);
    fixed e = hash(n+113.0);
    fixed f = hash(n+114.0);
    fixed g = hash(n+270.0);
    fixed h = hash(n+271.0);
 
    
    fixed k0 =   a;
    fixed k1 =   b - a;
    fixed k2 =   c - a;
    fixed k3 =   e - a;
    fixed k4 =   a - b - c + d;
    fixed k5 =   a - c - e + g;
    fixed k6 =   a - b - e + f;
    fixed k7 = - a + b + c - d + e - f - g + h;

    return fixed4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                 du * (fixed3(k1,k2,k3) + u.yzx*fixed3(k4,k5,k6) + u.zxy*fixed3(k6,k4,k5) + k7*u.yzx*u.zxy ));
}

struct VertexInput{
    float2 uv:TEXCOORD0;
    float4 vertex:POSITION;
};

struct VertexOutput
{
    float4 screen_vertex : SV_POSITION;
    float3 world_vertex : TEXCOORD1;
};

fixed4 fbmd( in fixed3 x )
{
    fixed scale  = _Scale;

    fixed xResult = _A;
    fixed layeredWeight = _InitWeight;
    fixed layeredScale = _Scale;
    fixed3 yzwResult = fixed3(0.0,0.0,0.0);
    for( int i=0; i<_FbmdIteration; i++ )
    {
        fixed4 n = noised(layeredScale*x*scale);
        xResult += layeredWeight*n.x;           // accumulate values		
        yzwResult += layeredWeight*n.yzw*layeredScale; // accumulate derivatives
        layeredWeight *= 0.5;             // amplitude decrease
        layeredScale *= 1.8;             // frequency increase
    }   
    
    return fixed4( xResult, yzwResult );
}

// Function of distance.
fixed4 mapWithNormal( in fixed3 p )
{
    fixed4 d1 = fbmd( p );
    d1.x -= _MapFix1;
    d1.x *= _MapFix2;
    d1.yzw = normalize(d1.yzw);
    return d1;
}

float3 lighting (float3 p,float3 normal)
{
    float3 l = _WorldSpaceLightPos0.xyz;
    float3 n = normal;
    //return n; //查看法线
    return (max(dot(n,l),0.0) );
}

float4 raymarch (float3 ro, float3 rd)
{
    for (int i=0; i<_RayMarchingCnt; i++)
    {
        float4 ray = mapWithNormal(ro);
        if (ray.x < _RayThreshold) return float4 (lighting(ro,ray.yzw),1.0); else ro+=ray.x*rd; 
    }
    return float4 (0.0,0.0,0.0,0.0);
}

float4 noRaymarch(float3 ro , float3 rd){
    return mapWithNormal(ro).yzwy;
    /*
    for (int i=0; i<_RayMarchingCnt; i++)
    {
        float4 ray = mapWithNormal(ro);
        if (distance(ro,ray.x*rd)>_DistanceMax) break;  //如果累加值超过当前值
        if (ray.x < 0.001) return float4 (lighting(ro,ray.yzw),1.0); else ro+=ray.x*rd; 
    }
    return float4 (0.0,0.0,0.0,0.0);
    */
}


#endif