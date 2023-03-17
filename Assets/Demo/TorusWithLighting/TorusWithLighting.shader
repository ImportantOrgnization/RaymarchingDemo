//https://iquilezles.org/articles/distfunctions/
//上述网址提供了众多 SDF 方法
Shader "Custom/TorusWithLighting"
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
            
            float ambient_occlusion( float3 pos, float3 nor )
			{
				float occ = 0.0;
				float sca = 1.0;
				for( int i=0; i<25; i++ )
				{
					float hr = 0.01 + 0.03*float(i);
					float3 aopos =  nor * hr + pos;
					float dd = DistanceFunction( aopos );
					occ += -(dd-hr)*sca;
					sca *= 0.95;
				}
				return clamp( 1.0 - occ, 0.0, 1.0 );    
			}	
            
            float3 set_normal (float3 p)
			{
				float3 x = float3 (0.001,0.00,0.00);
				float3 y = float3 (0.00,0.001,0.00);
				float3 z = float3 (0.00,0.00,0.001);
				//如果斜率表示的是球面点在xyz三轴上的变化率
				//那么法线就是一个点离开球面时在xyz三轴上的变化率,具体的物理涵义可以用下面的微分表示！
				return normalize(float3(DistanceFunction(p+x)-DistanceFunction(p-x), DistanceFunction(p+y)-DistanceFunction(p-y), DistanceFunction(p+z)-DistanceFunction(p-z))); 
			}
			
			float3 lighting (float3 p)
			{
				float3 l = _WorldSpaceLightPos0.xyz;
				float3 n = set_normal(p);
				//return n; 查看法线
				float ao = ambient_occlusion(p,n);
				//return ao;
				return (max(dot(n,l),0.0) )*ao;
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
					    return float4 (lighting(ro),1.0); 
                    }
					else{ 
					    ro+=ray*rd;
					} 
				}
				return float4 (0.0,0.0,0.0,0.0);
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
