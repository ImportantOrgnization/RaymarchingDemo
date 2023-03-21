
//https://www.shadertoy.com/view/XsXfRH
//https://iquilezles.org/articles/morenoise/
Shader "Custom/NaturalNoise"
{
    Properties
    {
        _FbmdIteration("_FdbmIteration",float) = 8
        _PositionScale("_PositionScale",float) = 1.5
        _InitHeight("_InitHeight",float) = 0
        _IteratedWeightScale("_IteratedWeightScale",Range(0,1)) = 0.5
        _InitWeight("_InitWeight",float) = 0.5
        _IteratedNormalScale("_IteratedNormalScale",Range(1,2)) = 1.8
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vertex_shader
            #pragma fragment pixel_shader

            #include "UnityCG.cginc"
            
            
            float hash(float3 p)  // replace this by something better
            {
                p  = 50.0*frac( p*0.3183099 + float3(0.71,0.113,0.419));
                return -1.0+2.0*frac( p.x*p.y*p.z*(p.x+p.y+p.z) );
            }
            
            
            // return value noise (in x) and its derivatives (in yzw)
            float4 noised( in float3 positionWS )
            {
                float3 i = floor(positionWS);
                float3 w = frac(positionWS);
                
            #if 1
                // quintic interpolation
                float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
                float3 du = 30.0*w*w*(w*(w-2.0)+1.0);
            #else
                // cubic interpolation
                float3 u = w*w*(3.0-2.0*w);
                float3 du = 6.0*w*(1.0-w);
            #endif    
                
                
                float a = hash(i+float3(0.0,0.0,0.0));
                float b = hash(i+float3(1.0,0.0,0.0));
                float c = hash(i+float3(0.0,1.0,0.0));
                float d = hash(i+float3(1.0,1.0,0.0));
                float e = hash(i+float3(0.0,0.0,1.0));
                float f = hash(i+float3(1.0,0.0,1.0));
                float g = hash(i+float3(0.0,1.0,1.0));
                float h = hash(i+float3(1.0,1.0,1.0));
                
                float k0 =   a;
                float k1 =   b - a;
                float k2 =   c - a;
                float k3 =   e - a;
                float k4 =   a - b - c + d;
                float k5 =   a - c - e + g;
                float k6 =   a - b - e + f;
                float k7 = - a + b + c - d + e - f - g + h;
            
                return float4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                             du * float3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                        k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                        k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
            }   
                 
            struct VertexInput{
                float2 uv:TEXCOORD0;
                float4 vertex:POSITION;
            };
            
            struct VertexOutput
            {
                float4 screen_vertex : SV_POSITION;
                float3 world_vertex : TEXCOORD1;
                float4 ndc : TEXCOORD2;
            };
            
            
            float _RayMarchingCnt;
            float _InitHeight;
            float _InitWeight;
            float _PositionScale;
            int _FbmdIteration;
            float _NormalScale;
            float _IteratedWeightScale;
            float _IteratedNormalScale;
            
            fixed4 fbmd( in fixed3 x )
            {
            
                fixed heightResult = _InitHeight;
                fixed iteratedWeight = _InitWeight;
                fixed iteratedScale = _PositionScale;
                fixed3 normalResult = fixed3(0.0,0.0,0.0);
                for( int i=0; i<_FbmdIteration; i++ )
                {
                    fixed4 n = noised(iteratedScale*x);
                    heightResult += iteratedWeight*n.x;           // accumulate values		
                    normalResult += iteratedWeight*n.yzw*iteratedScale; // accumulate derivatives
                    iteratedWeight *= _IteratedWeightScale;             // amplitude decrease
                    iteratedScale *= _IteratedNormalScale;             // frequency increase
                }   
                
                return fixed4( heightResult, normalResult );
            }


            VertexOutput vertex_shader (VertexInput v)
            {
                VertexOutput o;
                o.screen_vertex = UnityObjectToClipPos (v.vertex);
                o.ndc = o.screen_vertex / o.screen_vertex.w;
                o.world_vertex = mul (unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 pixel_shader (VertexOutput i) : SV_TARGET
            {
            
                float4 noiseTex = fbmd( i.world_vertex );
                if(i.world_vertex.x < 0 ) 
                    return noiseTex.xxxx;
                else
                    return noiseTex.yzwx;
                
                
                float3 normal =  normalize( noiseTex.yzw * float3(1,1,1));
                float3 height = noiseTex.x;
                float3 l = _WorldSpaceLightPos0.xyz;
                float ndotl = dot(normal,l);
                return ndotl    ;
            }
            ENDCG
        }
    }
}
