Shader "Custom/FractralCube"
{
    Properties
    {
        _RayMarchingCnt ("_RayMarchingCnt",float) = 64
        _Scale("_Scale",float) = 1.5
        _FbmdIteration("_FdbmIteration",float) = 8
        _A("_A",float) = 0
        _InitWeight("_InitWeight",float) = 0.5
        _F("_F",float) = 1.0
        _MapFix1("_MapFix1",float) = 0.37
        _MapFix2("_MapFix2",float) = 0.70
        
        _KParams1("_KParams1",Vector) = (1,1,1,1)
        _KParams2("_KParams2",Vector) = (1,1,1,1)
         
        
 
    }
    SubShader
    {
    		Blend SrcAlpha OneMinusSrcAlpha
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vertex_shader
            #pragma fragment pixel_shader

            #include "UnityCG.cginc"
            #include "Fractral.cginc"

            VertexOutput vertex_shader (VertexInput v)
            {
                VertexOutput o;
                o.screen_vertex = UnityObjectToClipPos (v.vertex);
                o.world_vertex = mul (unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 pixel_shader (VertexOutput i) : SV_TARGET
            {
                float3 worldPosition = i.world_vertex;
                float3 viewDirection = normalize(i.world_vertex - _WorldSpaceCameraPos.xyz);
                return raymarch (worldPosition,viewDirection);
            }
            ENDCG
        }
    }
}

