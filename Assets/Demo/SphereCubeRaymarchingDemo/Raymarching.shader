//知识点1： SDF 
//知识点2： Distance Function

Shader "Custom/Raymarching"
{
    Properties
	{
		_Size("Size",Float) = 15
	}
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        // No culling
		Cull Off  ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "UnityCG.cginc"
            float _Size;
            #define STEPS 34  
             
            //SDF : signed distance field -------------------------------------
            //Sphere - signed - exact //center = float3(0,0,0) ; radius = s;
            float sdSphere( float3 p, float s )
            {
                return length(p)-s;
            }
            
            //Box - signed - exact
            float sdBox( float3 p, float3 b )
            {
                float3 d = abs(p) - b;  //将p坍缩到正象限，记为p+，正角点c到达坍缩后的点p+的向量 c-> p+
                float part1 = min( max(d.x, max(d.y,d.z)) , 0.0);   //在立方体外侧，绝对返回0 ; 在内侧会返回一个负值，代表点最小点到面的距离
                float part2 = length(max(d,0.0));   // 如果p+在立方体外侧，将其坍缩到立方体表面，然后计算 length c->p+，是一个正值 ; 在内侧会返回 0    
                return  part1 + part2;  
            }
            
            //Distance Functions ----------------------------------------------
            float2x2 rotate(float a) { 
                return float2x2( cos(a), sin(a), -sin(a), cos(a) );
            }

            // sphere
            float DistanceFunction_Sphere( fixed3 p ) {
                p.xz = mul(rotate(_Time.y),p.xz);
                float Sphere = sdSphere(p,_Size*1.2);   //表示点到球面的距离，外侧点为正值，内侧点为负值
                return Sphere ;
            }
            
            // box
            float DistanceFunction_Box( fixed3 p ) {
                p.xz = mul(rotate(_Time.y),p.xz);
                float Box = sdBox(p,float3(_Size,_Size,_Size)); //2倍size边长立方体
                return Box;
            }
            
            // box subtraction sphere
            float DistanceFunction_BoxSubSphere( fixed3 p ) {
                p.xz = mul(rotate(_Time.y),p.xz);
                float Sphere = sdSphere(p,_Size*1.2);   //表示点到1.2倍size球体表面的距离
                float Box = sdBox(p,float3(_Size,_Size,_Size)); //2倍size边长立方体
                return max(-Sphere,Box);;
            }
            
            // box cross sphere
            float DistanceFunction_BoxCrossSphere( fixed3 p ) {
                p.xz = mul(rotate(_Time.y),p.xz);
                float Sphere = sdSphere(p,_Size*1.2);   //表示点到1.2倍size球体表面的距离
                float Box = sdBox(p,float3(_Size,_Size,_Size)); //2倍size边长立方体
                return max(Sphere,Box);;
            }
            
            float DistanceFunction_BoxUnionSphere( fixed3 p ) {
                p.xz = mul(rotate(_Time.y),p.xz);
                float Sphere = sdSphere(p,_Size*1.2);   //表示点到1.2倍size球体表面的距离
                float Box = sdBox(p,float3(_Size,_Size,_Size)); //2倍size边长立方体
                return min(Sphere,Box);;
            }
            
            //Raymarching Function --------------------------------------------
            //#define _DistanceFunction DistanceFunction_Sphere
            //#define _DistanceFunction DistanceFunction_Box
            #define _DistanceFunction DistanceFunction_BoxSubSphere
            #define _DistanceFunction DistanceFunction_BoxCrossSphere
            #define _DistanceFunction DistanceFunction_BoxUnionSphere
            
            fixed4 raymarch (float3 position, float3 direction)
            {
                // Loop do raymarcher.
                for (int i = 0; i < STEPS; i++)
                {
                    float distance = _DistanceFunction(position);
                    if (distance < 0.01)
                        return i / (float) STEPS;
            
                    position += distance * direction;
                }
                return 0;
            }
            
            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;	// Clip space
                float3 wPos : TEXCOORD1;	// World position
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
                float rayMarchResult = raymarch (worldPosition, viewDirection)  ;

                float3 rayMarchColor = float3(1,0,0);
                float3 planeColor = float3(0,0,0);
                float3 finalColor = lerp(planeColor,rayMarchColor,rayMarchResult);
                return float4(finalColor,1);
            }
            
            ENDCG
        }
    }
}
