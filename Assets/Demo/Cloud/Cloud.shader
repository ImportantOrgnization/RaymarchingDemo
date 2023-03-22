//知识点1： SDF 
//知识点2： Distance Function

Shader "Custom/Cloud"
{
    Properties
	{
		_Size("Size",Float) = 15
		
		_Color1("_Color1",color) = (0.6,0.71,0.75)
		_BackgroundSupplement("_BackgroundSupplement",Range(0,0.1)) = 0.075
		
		_Color2("_Color2",color) = (1.0,0.5,1.0)
        _YMultiplier("_YMultiplier",Range(0,1)) = 0.2

		_Color3("_Color3",color) = (1.0,0.6,0.1)
		_SunMultiplier("_SunMultiplier",Range(0,1)) = 0.2
		_SunPow("_SunPow",Range(0,20)) = 8
		
		iChannel0("iChannel0",2d) = "white"{}
		iChannel1("iChannel1",2d) = "white"{}
		
		
        _Color4("_Color4",color) = (0.91,0.98,1.05,1)
		_Color5("_Color5",color) = (1.0,0.95,0.8,1)
		_Color6("_Color6",color) = (0.25,0.3,0.35,1)
		_Color7("_Color7",color) = (1.0,0.6,0.1)
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
            #define STEPS 128  
            
            float3 _Color1;
            float _BackgroundSupplement;

            float3 _Color2;
            float _YMultiplier;
            
            float3 _Color3;
            float _SunMultiplier;
            float _SunPow;
            
            sampler2D iChannel0;
            sampler2D iChannel1;
            float3 _Color4;
            float3 _Color5;
            float3 _Color6;
            float3 _Color7;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;	// Clip space
                float3 wPos : TEXCOORD1;	// World position
                float4 uv : TEXCOORD2;
            };
            
            
            // 0: one 3d texture lookup
            // 1: two 2d texture lookups with hardware interpolation
            // 2: two 2d texture lookups with software interpolation
            #define NOISE_METHOD 1
            
            // 0: no LOD
            // 1: yes LOD
            #define USE_LOD 1
            
            // 0: sunset look
            // 1: bright look
            #define LOOK 1
            
            
            float noise( in float3 worldPos )
            {
                float3 p = floor(worldPos);
                float3 f = frac(worldPos);
                f = f*f*(3.0-2.0*f);
            
                float2 uv = (p.xy+float2(37.0,239.0)*p.z) + f.xy;
                float2 rg = tex2Dlod(iChannel0,float4( (uv+0.5)/256.0,0,0)).yx;
                return lerp( rg.x, rg.y, f.z )*2.0-1.0;
              
            }
            
            
            float map5( in float3 p )
            {    
                float3 q = p - float3(0.0,0.1,1.0)*_Time;    
                float f;
                f  = 0.50000*noise( q ); q = q*2.02;    
                f += 0.25000*noise( q ); q = q*2.03;    
                f += 0.12500*noise( q ); q = q*2.01;    
                f += 0.06250*noise( q ); q = q*2.02;    
                f += 0.03125*noise( q );    
                return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
            }
            float map4( in float3 p )
            {    
                float3 q = p - float3(0.0,0.1,1.0)*_Time;    
                float f;
                f  = 0.50000*noise( q ); q = q*2.02;    
                f += 0.25000*noise( q ); q = q*2.03;    
                f += 0.12500*noise( q ); q = q*2.01;   
                f += 0.06250*noise( q );    
                return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
            }
            float map3( in float3 p )
            {
                float3 q = p - float3(0.0,0.1,1.0)*_Time;    
                float f;
                f  = 0.50000*noise( q ); q = q*2.02;    
                f += 0.25000*noise( q ); q = q*2.03;    f += 0.12500*noise( q );    
                return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
            }
            float map2( in float3 p )
            {    
                float3 q = p - float3(0.0,0.1,1.0)*_Time;    
                float f;
                f  = 0.50000*noise( q ); 
                q = q*2.02;    f += 0.25000*noise( q );;    
                return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
            }
            
            const float3 sundir = float3(-0.7071,0.0,-0.7071);
            
            float mapWithLod(int lod,float3 pos){
                if(lod == 2)
                    return map2(pos);
                if(lod == 3)
                    return map3(pos);
                if(lod == 4)
                    return map4(pos);
                if(lod == 5)
                    return map5(pos);
                else 
                    return 0;
            }
            
            struct MarchResult {
                float4 sum;
                float t;  
            };
            
            //#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { float3 pos = ro + t*rd; if( pos.y<-3.0 || pos.y>2.0 || sum.a>0.99 ) break; float den = MAPLOD( pos ); if( den>0.01 ) { float dif = clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 ); float3  lin = float3(1.0,0.6,0.3)*dif+float3(0.91,0.98,1.05); float4  col = float4( mix( float3(1.0,0.95,0.8), float3(0.25,0.3,0.35), den ), den ); col.xyz *= lin; col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) ); col.w *= 0.4; col.rgb *= col.a; sum += col*(1.0-sum.a); } t += max(0.06,0.05*t); }
            MarchResult MARCH(int steps,int lod,float3 ro,float3 rd,float3 bgcol,float4 sum,float t){ 
                MarchResult result;
                for(int i=0; i<steps; i++) {
                    float3 pos = ro + t*rd; 
                    if( sum.a>0.99 ) 
                        break; 
                    float den = mapWithLod(lod, pos );
                    
                    if( den>0.01 ) {
                        float ndotL = clamp((den - mapWithLod(lod,pos+0.3*_WorldSpaceLightPos0))/0.6, 0.0, 1.0 ); 
                        float4  col = float4( lerp( _Color5.rgb, _Color6.rgb, den ), den );

                        //float3  lit = _Color3*ndotL+ _Color4.rgb; 
                        //col.xyz *= lit; 

                        col.xyz = lerp( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );  // y = 1.0 - e^(-0.003 * t*t) 是一个顶点为 0，1 类似于倒挂的抛物线，且经过 1，0 点
                        col.w *= 0.4; 
                        col.rgb *= col.a; 
                        sum += col*(1.0-sum.a);
                    } 
                    t += max(0.06,0.05*t); 
                }
                result.sum = sum;
                result.t = t;
                return result;
            }



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
                o.uv = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //ray origin
                float3 ro = i.wPos;
                //ray direction
                float3 rd = normalize(i.wPos - _WorldSpaceCameraPos);
                //大气
                float sun = clamp(dot(_WorldSpaceLightPos0,rd),0,1);
                float3 bgcol = _Color1 - rd.y*_YMultiplier*_Color2 + _BackgroundSupplement;
                bgcol += _SunMultiplier*_Color3*pow( sun, _SunPow );  
                
                bgcol = 0;
                
                
                
                i.uv /= i.uv.w;
                
                //raymarch
                float4 sum = 0;    
                float t = 0.05 * tex2Dlod( iChannel1,float4(i.uv.xy,0,0)).x;
                
                //return float4(t.xxx,1);
                MarchResult result;
                result.sum = sum;
                result.t = t;
                result = MARCH(40,5,ro,rd,bgcol,result.sum,result.t);    
                //result = MARCH(40,4,ro,rd,bgcol,result.sum,result.t);    
                //result = MARCH(30,3,ro,rd,bgcol,result.sum,result.t);    
                //result = MARCH(30,2,ro,rd,bgcol,result.sum,result.t);    
                float4 res = clamp( result.sum, 0.0, 1.0 );
                return res;

                
                bgcol = bgcol*(1.0-res.w) + res.xyz;       
                
                
            }
            
            ENDCG
        }
    }
}
