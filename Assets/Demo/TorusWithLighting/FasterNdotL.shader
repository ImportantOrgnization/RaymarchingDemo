//微积分环境下更快的 n dot l
//https://iquilezles.org/articles/derivative/
//该文章的关键句在这里
//Now, if x was the point in space we are shading/lighting, and f was out SDF or cloud density field, 
//then f(x) would be the density at that point we are shading, 
//and ∇f(x) the gradient (or 'normal'). At the same time, if v was the light direction,
//then the right side of the equation ∇f(x)⋅v/|v| would be nothing but our regular N⋅L lambertian lighting... 
//which according to the equation is equal to the directional derivative of the field taken in the direction of the light (left side of the equation)!

Shader "Custom/FasterNdotL"
{
    Properties
    {
        _MinDistance("Min Distance",Float) = 0.01
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vertex_shader
            #pragma fragment pixel_shader
            #include "UnityCG.cginc"
            
            float _Limit = 1;
            float _MinDistance = 0.001;
            
            struct custom_type
			{
				float4 pos : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
            
            float sdTorus( float3 p, float2 t )
            {
                float2 q = float2(length(p.xz)-t.x,p.y);
                return length(q)-t.y;
            }
            
            float DistanceFunction (float3 p)
			{
				return sdTorus(p,float2(1.0,0.5));
			}
			
			float3 lighting (float3 p,float var_p )
			{
                float3 eps = 0.001;
				float3 l = _WorldSpaceLightPos0.xyz;
				float3 diffuse = clamp( (DistanceFunction(p+ eps * l) - var_p)/eps ,0,1).xxx;
				return diffuse;
			}
				
			//ro -> ray orig , rd -> ray direction
			 float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float ray = DistanceFunction(ro);
					if(_Limit != 0){
					    if (distance(ro,ray*rd)>250) break;
					}
					if (ray < _MinDistance){ 
					    return float4 (lighting(ro,ray),1.0); 
                    }
					else{ 
					    ro+=ray*rd;
					} 
				}
				return float4 (1.0,0.0,0.0,1.0);
			}
			
            custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.pos = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				return vs;
			}
			
			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			}
			
            ENDCG
        }
    }
}
