//知识点1： SDF 
//知识点2： Distance Function

Shader "Custom/Cloud3dNoise"
{
    Properties
	{
		_Color1("_Color1",color) = (0.6,0.71,0.75)
		_BackgroundSupplement("_BackgroundSupplement",Range(0,0.1)) = 0.075
		
		_Color2("_Color2",color) = (1.0,0.5,1.0)
        _YMultiplier("_YMultiplier",Range(0,1)) = 0.2

		_SunLightColor("_SunLightColor",color) = (1.0,0.6,0.1)
		_SunMultiplier("_SunMultiplier",Range(0,1)) = 0.2
		_SunPow("_SunPow",Range(0,20)) = 8
		
        _AmbientColor("_AmbientColor",color) = (0.0,0.0,0,1)
		_HighDensityCloudC("_HighDensityCloudC",color) = (1.0,0.95,0.8,1)
		_LowDensityCloudC("_LowDensityCloudC",color) = (0.25,0.3,0.35,1)
		
		
		_WindDir("_WindDir",Vector) = (1,0,1)
		_Speed("_Speed",float) = 1
		_CloudSize("_CloudSize",float) = 1
		
		_FBMSamplerScale("_FBMSamplerScale",float ) = 2.02
        
        //步进控制
		_MinStepDist5("_MinStepDist5",float ) = 0.03
		_StepForwardPercentage5("_StepForwardPercentage5",float ) = 0.03
        _MinStepDist3("_MinStepDist3",float ) = 0.06
		_StepForwardPercentage3("_StepForwardPercentage3",float ) = 0.05
		
		_CloudBottom("_CloudBottom",float) = 0
		_CloudTop("_CloudTop",float) = 1
		_RangePurity("_RangePurity",Range(0,2)) = 1             //高度范围的纯度，越高，越界的云越少
		_CloudScatter("_CloudScatter",Range(0,2) ) = 1.75       //云在纵向上的分散能力
		
		
		_FBM1("_FBM1",float) = 0.5
		_FBM2("_FBM2",float) = 0.25
		_FBM3("_FBM3",float) = 0.125
		_FBM4("_FBM4",float) = 0.0625
		_FBM5("_FBM5",float) = 0.0317
		
		_AccumulateAttenuation("_AccumulateAttenuation",Range(0,1)) = 0.5
	    
	    [Toggle(_USE3DNoiseTex)] _USE3DNoiseTex ("_USE3DNoiseTex", Float) = 0
	    _3DNoiseTex("_3DNoiseTex",3D) = "black"{}

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
            #pragma multi_compile _ _USE3DNoiseTex 

            #include "UnityCG.cginc"
            #define STEPS 128  
            
            float3 _Color1;
            float _BackgroundSupplement;

            float3 _Color2;
            float _YMultiplier;
            
            float3 _SunLightColor;
            float _SunMultiplier;
            float _SunPow;
            
            float3 _AmbientColor;
            float3 _HighDensityCloudC;
            float3 _LowDensityCloudC;
            
            float _FBMSamplerScale;
            float _MinStepDist5;
            float _StepForwardPercentage5;
            float _MinStepDist3;
            float _StepForwardPercentage3;
            float _CloudScatter;
            
            float _AccumulateAttenuation;
            
            int _StepCnt;
            
            float _FBM1;
            float _FBM2;
            float _FBM3;
            float _FBM4;
            float _FBM5;
            
            sampler3D _3DNoiseTex;
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
            
            float hash(float3 p)  // replace this by something better
            {
                p  = 50.0*frac( p*0.3183099 + float3(0.71,0.113,0.419));
                return -1.0+2.0*frac( p.x*p.y*p.z*(p.x+p.y+p.z) );
            }
            
            // return value noise (in x) and its derivatives (in yzw)
            float4 noised( in float3 positionWS )
            {
                return tex3D(_3DNoiseTex,positionWS);
            }   
              
            float3 _WindDir;
            float _Speed;
            float _CloudSize;
            float3 GetWind(){
                return _WindDir * _Speed;
            }
            
            float _CloudBottom;
            float _CloudTop;
            float _RangePurity;
            float GetCloudHeightDensity(float3 positionWS){
                float y = positionWS.y;
                float y1 = max(-_RangePurity,y - _CloudBottom);
                float y2 = max(-_RangePurity,_CloudTop - y);
                return min(y1,y2);   
            }

            struct MarchResult {
                float4 sum;
                float t;  
            };
            
            float map5(in float3 p )
            {    
                float3 q = p - GetWind()*_Time.y;
                q *= _CloudSize;    
                float f;
                f  = _FBM1*noised( q ); q = q*_FBMSamplerScale;    
                f += _FBM2*noised( q ); q = q*_FBMSamplerScale;    
                f += _FBM3*noised( q ); q = q*_FBMSamplerScale;    
                f += _FBM4*noised( q ); q = q*_FBMSamplerScale;    
                f += _FBM5*noised( q );    
                return clamp(  GetCloudHeightDensity(p) + _CloudScatter *f, 0.0, 1.0 );
            }
            
            MarchResult MARCH5(int steps,float3 ro,float3 rd,float3 bgcol,float4 sum,float t){ 
                MarchResult result;
                for(int i=0; i<30; i++) {
                    float3 pos = ro + t*rd; 
                    if( sum.a>0.99 ) 
                        break; 
                    float den = map5( pos );
                    
                    if( den>0.01 ) {
                         
                        float4  col = float4( lerp( _HighDensityCloudC.rgb, _LowDensityCloudC.rgb, den ), den );
                        
                        //计算光照
                        float ndotL = clamp((den - map5(pos+0.2*_WorldSpaceLightPos0))/0.6, 0.05, 1.0 );
                        ndotL = pow(ndotL,2);
                        float3  lit = _SunLightColor*ndotL; 
                        col.xyz *= lit; 
                        //和背景混合
                        //col.xyz = lerp( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );  // y = 1.0 - e^(-0.003 * t*t) 是一个顶点为 0，1 类似于倒挂的抛物线，且经过 1，0 点
                        
                        //对颜色值进行衰减
                        col.a *= _AccumulateAttenuation; 
                        //col.rgb *= col.a;
                        
                        sum += col*(1.0-sum.a); //越到后面比例越小，但还是不断累积
                        
                        //sum += float4(ndotL,ndotL,ndotL,1- sum.a);
                        //sum += col;
                        
                    } 
                    t += max(_MinStepDist5,_StepForwardPercentage5*t); 
                }
                result.sum = sum;
                result.t = t;
                return result;
            }
           
            
            float map3( in float3 p )
            {
                float3 q = p - GetWind()*_Time.y;    
                q *= _CloudSize;    
                float f;
                f  = _FBM1*noised( q ); q = q*_FBMSamplerScale;    
                f += _FBM2*noised( q ); q = q*_FBMSamplerScale;    
                f += _FBM3*noised( q ); 
                return clamp(  GetCloudHeightDensity(p) + _CloudScatter *f, 0.0, 1.0 );
            }
            
            MarchResult MARCH3(int steps,float3 ro,float3 rd,float3 bgcol,float4 sum,float t){ 
                MarchResult result;
                for(int i=0; i<20; i++) {
                    float3 pos = ro + t*rd; 
                    if( sum.a>0.99 ) 
                        break; 
                    float den = map3( pos );
                    
                    if( den>0.01 ) {
                         
                        float4  col = float4( lerp( _HighDensityCloudC.rgb, _LowDensityCloudC.rgb, den ), den );
                        
                        //计算光照
                        float ndotL = clamp((den - map3(pos+0.2*_WorldSpaceLightPos0))/0.6, 0.05, 1.0 );
                        ndotL = pow(ndotL,2);
                        float3  lit = _SunLightColor*ndotL; 
                        col.xyz *= lit; 
                        //和背景混合
                        //col.xyz = lerp( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );  // y = 1.0 - e^(-0.003 * t*t) 是一个顶点为 0，1 类似于倒挂的抛物线，且经过 1，0 点
                        
                        //对颜色值进行衰减
                        col.a *= _AccumulateAttenuation; 
                        //col.rgb *= col.a;
                        
                        sum += col*(1.0-sum.a); //越到后面比例越小，但还是不断累积
                        
                        //sum += float4(ndotL,ndotL,ndotL,1- sum.a);
                        //sum += col;
                        
                    } 
                    t += max(_MinStepDist3 ,_StepForwardPercentage3*t); 
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
                bgcol += _SunMultiplier*_SunLightColor*pow( sun, _SunPow );  
                
                //bgcol = 0;
                
                
                i.uv /= i.uv.w;
                
                //raymarch
                //return float4(t.xxx,1);
                MarchResult result;
                result.sum = 0;
                result.t = 0;
                result = MARCH5(_StepCnt,ro,rd,bgcol,result.sum,result.t);    
                result = MARCH3(_StepCnt,ro,rd,bgcol,result.sum,result.t);    
              
                float4 res = clamp( result.sum, 0.0, 1.0 );
                return res + float4(_AmbientColor.rgb,0);
                
                //bgcol = bgcol*(1.0-res.w) + res.xyz;       
                //return float4(lerp(bgcol.xyz,res.xyz,res.w),1);
                
            }
            
            ENDCG
        }
    }
}
