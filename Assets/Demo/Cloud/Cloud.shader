//知识点1： SDF 
//知识点2： Distance Function

Shader "Custom/Cloud"
{
    Properties
	{
        _StepCnt("_StepCnt",int ) = 100

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
		
		_FBMSamplerScale("_FBMSamplerScale",float ) = 2.02
        
        //步进控制
		_MinStepDist5("_MinStepDist5",float ) = 0.03
		_StepForwardPercentage5("_StepForwardPercentage5",float ) = 0.03
        _MinStepDist3("_MinStepDist3",float ) = 0.06
		_StepForwardPercentage3("_StepForwardPercentage3",float ) = 0.05
		
		_CloudHeight("_CloudHeight",float ) = -0.5
		_CloudScatter("_CloudScatter",float ) = 1.75
		
		
		_AccumulateAttenuation("_AccumulateAttenuation",Range(0,1)) = 0.5
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
            float _CloudHeight;
            float _CloudScatter;
            
            float _AccumulateAttenuation;
            
            int _StepCnt;

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
              
            float3 _WindDir;
            float _Speed;
            float3 GetWind(){
                return _WindDir * _Speed;
            }
            

            struct MarchResult {
                float4 sum;
                float t;  
            };
            
            float map5(in float3 p )
            {    
                float3 q = p - GetWind()*_Time.y;    
                float f;
                f  = 0.50000*noised( q ); q = q*_FBMSamplerScale;    
                f += 0.25000*noised( q ); q = q*_FBMSamplerScale;    
                f += 0.12500*noised( q ); q = q*_FBMSamplerScale;    
                f += 0.06250*noised( q ); q = q*_FBMSamplerScale;    
                f += 0.03125*noised( q );    
                return clamp(  - p.y + _CloudHeight + _CloudScatter *f, 0.0, 1.0 );
            }
            
            MarchResult MARCH5(int steps,float3 ro,float3 rd,float3 bgcol,float4 sum,float t){ 
                MarchResult result;
                for(int i=0; i<steps; i++) {
                    float3 pos = ro + t*rd; 
                    if( sum.a>0.99 ) 
                        break; 
                    float den = map5( pos );
                    
                    if( den>0.01 ) {
                         
                        float4  col = float4( lerp( _HighDensityCloudC.rgb, _LowDensityCloudC.rgb, den ), den );
                        
                        //计算光照
                        float ndotL = clamp((den - map5(pos+0.2*_WorldSpaceLightPos0))/0.6, 0.05, 1.0 );
                        ndotL = pow(ndotL,2);
                        float3  lit = _SunLightColor*ndotL+ _AmbientColor.rgb; 
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
                float f;
                f  = 0.50000*noised( q ); q = q*_FBMSamplerScale;    
                f += 0.25000*noised( q ); q = q*_FBMSamplerScale;    
                f += 0.12500*noised( q ); 
                return clamp(  - p.y + _CloudHeight + _CloudScatter *f, 0.0, 1.0 );
            }
            
            MarchResult MARCH3(int steps,float3 ro,float3 rd,float3 bgcol,float4 sum,float t){ 
                MarchResult result;
                for(int i=0; i<steps; i++) {
                    float3 pos = ro + t*rd; 
                    if( sum.a>0.99 ) 
                        break; 
                    float den = map3( pos );
                    
                    if( den>0.01 ) {
                         
                        float4  col = float4( lerp( _HighDensityCloudC.rgb, _LowDensityCloudC.rgb, den ), den );
                        
                        //计算光照
                        float ndotL = clamp((den - map3(pos+0.2*_WorldSpaceLightPos0))/0.6, 0.05, 1.0 );
                        ndotL = pow(ndotL,2);
                        float3  lit = _SunLightColor*ndotL+ _AmbientColor.rgb; 
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
                return res;
                
                //bgcol = bgcol*(1.0-res.w) + res.xyz;       
                //return float4(lerp(bgcol.xyz,res.xyz,res.w),1);
                
            }
            
            ENDCG
        }
    }
}
