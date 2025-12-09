Shader "Custom/TP_Magic"
{
    Properties
    {
        _LineColor  ("Line Color", Color) = (0, 1, 1, 1)
        _LineWidth  ("Line Width", Range(0.001, 0.2)) = 0.02

        //Nivel 1
        _SquareSize1 ("Square Half Size", Range(0.1, 1.0)) = 0.146
        _Radius1    ("Circle Radius 1", Range(0.05, 1.0)) = 0.214

        //Nivel 2
        _SquareSize2  ("Square Half Size", Range(0.1, 1.0)) = 0.26
        _Radius2    ("Circle Radius 2", Range(0.05, 1.0)) = 0.377

        //Nivel 3
        _SquareSize3 ("Square Half Size", Range(0.1, 1.0)) = 0.43
        _Radius3    ("Circle Radius 1", Range(0.05, 1.0)) = 0.618

        //Nivel 4
        _SquareSize4  ("Square Half Size", Range(0.1, 1.0)) = 0.666
        _Radius4    ("Circle Radius 2", Range(0.05, 1.0)) = 0.95

        //Animacion
        _RotationSpeedRight ("Rotation Speed RIght (rad/s)", Float) = 2.5
        _RotationSpeedLeft ("Rotation Speed Left (rad/s)", Float) = -2.5
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

                float  _SquareSize1;
                float  _Radius1;
                float  _SquareSize2;
                float  _Radius2;
                float  _SquareSize3;
                float  _Radius3;
                float  _SquareSize4;
                float  _Radius4;

                float  _RotationSpeedRight;
                float _RotationSpeedLeft;
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

                // --- ROTACION SHADER ---
                float angleRight = _RotationSpeedRight * _Time.y; //angulo = velocidad * tiempo en segundos

                float sR = sin(angleRight);
                float cR = cos(angleRight);

                //Rotamos el punto alrededor del centro
                float2 prRight;
                prRight.x = cR * p.x - sR * p.y;
                prRight.y = sR * p.x + cR * p.y;

                float angleLeft  = _RotationSpeedLeft  * _Time.y;

                float sL = sin(angleLeft);
                float cL = cos(angleLeft);


                float2 prLeft;
                prLeft.x = cL * p.x - sL * p.y;
                prLeft.y = sL * p.x + cL * p.y;


                float lineMask = 0.0;

                // Orden por niveles
                lineMask = max(lineMask, SquareLine(prRight, _SquareSize1, _LineWidth));
                lineMask = max(lineMask, CircleLine(prRight, _Radius1,    _LineWidth));

                lineMask = max(lineMask, SquareLine(prLeft, _SquareSize2, _LineWidth));
                lineMask = max(lineMask, CircleLine(prLeft, _Radius2,     _LineWidth));

                lineMask = max(lineMask, SquareLine(prRight, _SquareSize3, _LineWidth));
                lineMask = max(lineMask, CircleLine(prRight, _Radius3,     _LineWidth));

                lineMask = max(lineMask, SquareLine(prLeft, _SquareSize4, _LineWidth));
                lineMask = max(lineMask, CircleLine(prLeft, _Radius4,     _LineWidth));

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
