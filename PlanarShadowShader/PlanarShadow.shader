
Shader "Custom/PlanarShadow"
{
	Properties
	{ 
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_ShadowInvLen("ShadowInvLen", float) = 6.36 //0.4449261
		_ShadowFalloff("ShadowFalloff", float) = 0.49
		_ShadowPlane("ShadowPlane",vector) = (0, 1.0, 0, 0.1)
		_ShadowFadeParams("ShadowFadeParams",vector) = (1.13, 1.5, 0.7, 0)

	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry+10" }
		LOD 100
		Pass
			{
				Lighting Off
				SetTexture[_MainTex]
				{
					constantColor[_Color]
					Combine texture * constant , texture * constant
				}
		}
		//Pass
		//{
		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag
		//	// make fog work
		//	#pragma multi_compile_fog
		//	#include "UnityCG.cginc"

		//	struct appdata
		//	{
		//		float4 vertex : POSITION;
		//		float2 uv : TEXCOORD0;
		//	};

		//	struct v2f
		//	{
		//		float2 uv : TEXCOORD0;
		//		UNITY_FOG_COORDS(1)
		//		float4 vertex : SV_POSITION;
		//	};

		//	sampler2D _MainTex;
		//	float4 _MainTex_ST;

		//	v2f vert(appdata v)
		//	{
		//		v2f o;
		//		o.vertex = UnityObjectToClipPos(v.vertex);
		//		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		//		UNITY_TRANSFER_FOG(o,o.vertex);
		//		return o;
		//	}

		//	fixed4 frag(v2f i) : SV_Target
		//	{
		//		fixed4 col = tex2D(_MainTex, i.uv);
		//		UNITY_APPLY_FOG(i.fogCoord, col);
		//		return col;
		//	}
		//	ENDCG
		//}

		Pass
		{
				Blend SrcAlpha  OneMinusSrcAlpha
				ZWrite Off
				Cull Back
				ColorMask RGB

				Stencil
				{
					Ref 0
					Comp Equal
					WriteMask 255
					ReadMask 255
					Pass Invert
					Fail Keep
					ZFail Keep
				}

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"

				float4 _ShadowPlane;
				float _ShadowInvLen;
				float4 _ShadowFadeParams;
				float _ShadowFalloff;

				struct appdata
				{
					float4 vertex : POSITION;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float3 xlv_TEXCOORD0 : TEXCOORD0;
					float3 xlv_TEXCOORD1 : TEXCOORD1;
				};

				v2f vert(appdata v)
				{
					v2f o;
					float3 lightdir = normalize(_WorldSpaceLightPos0.xyz);
					float3 worldpos = mul(unity_ObjectToWorld, v.vertex).xyz;
					float distance = (_ShadowPlane.w - dot(_ShadowPlane.xyz, worldpos)) / dot(_ShadowPlane.xyz, lightdir.xyz);
					worldpos = worldpos + distance * lightdir.xyz;
					o.vertex = mul(unity_MatrixVP, float4(worldpos, 1.0));
					float3 center = mul(unity_ObjectToWorld,float4(0,0,0,1)).xyz;
					o.xlv_TEXCOORD0 = center;
					o.xlv_TEXCOORD1 = worldpos;
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					float3 posToPlane_2 = (i.xlv_TEXCOORD0 - i.xlv_TEXCOORD1);
					//float a = (pow((1.0 - clamp(((sqrt(dot(posToPlane_2, posToPlane_2)) * _ShadowInvLen) - _ShadowFadeParams.x), 0.0, 1.0)), _ShadowFadeParams.y) * _ShadowFadeParams.z);
					float a = 1.0 - saturate(distance(i.xlv_TEXCOORD0, i.xlv_TEXCOORD1) * _ShadowFalloff);
					return float4(0,0,0,a);
				}
				ENDCG
			}
	}
}