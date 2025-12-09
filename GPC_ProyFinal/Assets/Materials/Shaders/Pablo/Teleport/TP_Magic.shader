Shader "Custom/TP_Magic"
{
    Properties
    {
        _LineColor  ("Line Color", Color) = (0, 1, 1, 1)
        _LineWidth  ("Line Width", Range(0.001, 0.2)) = 0.02
        _SquareSize ("Square Half Size", Range(0.1, 1.0)) = 0.5
        _Radius1    ("Circle Radius 1", Range(0.05, 1.0)) = 0.25
        _Radius2    ("Circle Radius 2", Range(0.05, 1.0)) = 0.45
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        LOD 100

        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha   // Transparente

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _LineColor;
                float  _LineWidth;
                float  _SquareSize;
                float  _Radius1;
                float  _Radius2;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = posInputs.positionCS;
                OUT.uv = IN.uv;
                return OUT;
            }

            // Línea de un círculo (1 = hay línea, 0 = no)
            float CircleLine(float2 p, float radius, float width)
            {
                float d = abs(length(p) - radius);
                return step(d, width);
            }

            // Línea de un cuadrado eje-alineado (centrado)
            float SquareLine(float2 p, float halfSize, float width)
            {
                float2 a = float2(halfSize, halfSize); // semilado
                float2 d = abs(p) - a;
                float dist = max(d.x, d.y);   // distancia firmada al borde
                dist = abs(dist);
                return step(dist, width);
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // UV (0..1) -> coords centradas (-1..1)
                float2 p = (IN.uv - 0.5) * 2.0;

                // Cuadrado
                float sq = SquareLine(p, _SquareSize, _LineWidth);

                // Dos círculos
                float c1 = CircleLine(p, _Radius1, _LineWidth);
                float c2 = CircleLine(p, _Radius2, _LineWidth);

                // Combinar líneas
                float lineMask = max(sq, max(c1, c2));

                // Color solo en las líneas, fondo alpha 0
                float4 col;
                col.rgb = _LineColor.rgb;
                col.a   = lineMask * _LineColor.a;

                return col;
            }

            ENDHLSL
        }
    }

    FallBack Off
}
