Shader "Custom/WatercolorOutlineIrregularURP"
{
    Properties
    {
        _OutlineWidth("Outline Width", Range(0.001,0.05)) = 0.01
        _OutlineColor("Outline Color", Color) = (0.2,0.2,0.2,1)
        _NoiseStrength("Vertex Noise Strength", Range(0,0.05)) = 0.005
        _ObjectSeed("Object Seed", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Front
        ZWrite On
        ZTest LEqual

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 posHCS : SV_POSITION;
            };

            float _OutlineWidth;
            float4 _OutlineColor;
            float _NoiseStrength;
            float _ObjectSeed;

            float Random(float x)
            {
                return frac(sin(x)*43758.5453);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Genera ruido dependiente del objeto
                float seed = _ObjectSeed + IN.positionOS.x*12.989 + IN.positionOS.y*78.233 + IN.positionOS.z*45.164;
                float randOffset = (Random(seed) - 0.5) * _NoiseStrength;

                float3 pos = IN.positionOS.xyz + IN.normalOS * (_OutlineWidth + randOffset);

                // CORRECCIÓN URP
                OUT.posHCS = TransformObjectToHClip(pos);

                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }
    }
}
