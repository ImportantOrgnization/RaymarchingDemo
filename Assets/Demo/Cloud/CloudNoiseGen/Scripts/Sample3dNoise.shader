Shader "Custom/Sample3dNoise"
{
    Properties
    {
        _MainTex ("Texture", 3D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                
                float4 vertex : SV_POSITION;
            };

            sampler3D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = mul(unity_ObjectToWorld,v.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                return tex3D(_MainTex,i.uv);
            }
            ENDCG
        }
    }
}
