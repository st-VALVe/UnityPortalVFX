Shader "Custom/Portal"
{
    Properties
    {
        [Header(Texture Masks)]
        [Space (10)]
        _DistortionTexture("Distortion Texture", 2D) = "white" {}
        _DistortionAmount("Distortion Amount", Float) = 0.25
        _DistortionSpeed("Distortion Speed", Float) = 5
        [Space(10)]
        _AdditionalNoiseTexture("Additional Noise Texture", 2D) = "white" {}
        _NoiseSpeed("Noise Speed", Float) = 5
        [Space(10)]
        [Header(Additional Parameters)]
        [Space(10)]
        _Brightness("Brightness", Float) = 1        
        _Contrast("Contrast", Float) = 1
        _CenterGlow("Center Glow", Float) = 0.25
        [Space]
        _RadialBrightness("Radial brightness", Float) = 1
        _RadialContrast("Radial contrast", Float) = 1
    }
    Category{
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "AlphaBlended" "PreviewType" = "Plane" }

        Cull Off Lighting Off

        // you can choose what kind of blending mode you want for the outline
        Blend SrcAlpha OneMinusSrcAlpha // Normal
        //Blend One OneMinusSrcAlpha // Alpha Blended PreMultiply
        //Blend One One // Additive
        //Blend One OneMinusDstColor // Soft Additive
        //Blend DstColor Zero // Multiplicative
        //Blend DstColor SrcColor // 2x Multiplicative

        SubShader
        {
            // Grab the screen behind the object into _BackgroundTexture
            GrabPass
            {
                "_BackgroundTexture"
            }

            Pass
            {
                Name "BASE"

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 2.0
                #pragma multi_compile_particles
                #pragma multi_compile_fog
                #pragma multi_compile_instancing

                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    fixed4 color : COLOR;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0; 
                    float4 grabPos : TEXCOORD1;
                    float4 vertex : SV_POSITION;
                    fixed4 color : COLOR;
                    
                    UNITY_FOG_COORDS(7)
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    o.color = v.color;
                    UNITY_TRANSFER_FOG(o,o.vertex);

                    o.grabPos = ComputeGrabScreenPos(o.vertex);

                    return o;
                }

                uniform float _Brightness;
                uniform float _Contrast;
                uniform float _RadialBrightness;
                uniform float _RadialContrast;
                uniform float _DistortionAmount;
                uniform float _DistortionSpeed;
                uniform float _NoiseSpeed;

                uniform float _CenterGlow;

                sampler2D _DistortionTexture;
                float4 _DistortionTexture_ST;
                sampler2D _AdditionalNoiseTexture;
                float4 _AdditionalNoiseTexture_ST;
                sampler2D _BackgroundTexture;

                fixed4 frag(v2f i) : SV_Target
                {                    
                    fixed distortion = tex2D(_DistortionTexture, TRANSFORM_TEX(i.uv, _DistortionTexture) - _Time.x * _DistortionSpeed);
                    distortion = pow(distortion * max(_Brightness, 0), _Contrast);
                    
                    fixed uMaskOriginal = i.uv.x;                    
                    fixed uMask = i.uv.x * max(_RadialBrightness, 0);
                    fixed uMaskInv = 1 - uMask;

                    fixed additionalNoise = tex2D(_AdditionalNoiseTexture, TRANSFORM_TEX(i.uv, _AdditionalNoiseTexture) - _Time.x * _NoiseSpeed * 0.25);                    
                    additionalNoise *= uMaskInv * uMaskInv;
                    additionalNoise *= 3;
                                        
                    half4 bgcolor = tex2Dproj(_BackgroundTexture, i.grabPos + distortion * _DistortionAmount);
                    fixed4 color = bgcolor;

                    distortion *= distortion * uMask;
                    distortion += additionalNoise * 10;
                    distortion += uMask;
                    distortion *= uMask;
                    distortion += uMask;
                    
                    color *= i.color;
                    color += uMaskOriginal * (uMaskOriginal * uMaskOriginal * uMaskOriginal + uMaskOriginal) * _CenterGlow;
                    color += additionalNoise * (additionalNoise * additionalNoise + additionalNoise) * 0.01;
                    UNITY_APPLY_FOG(i.fogCoord, color);

                    return color * distortion;
                }
                ENDCG
            }
        }
    }
    FallBack "Diffuse"
}
