
Shader "Custom/PlanarShadow2"
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
		Pass {
				Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				fixed4 _Color;

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float3 worldNormal : TEXCOORD0;
				};

				v2f vert(a2v v) {
					v2f o;
					// Transform the vertex from object space to projection space
					o.pos = UnityObjectToClipPos(v.vertex);

					// Transform the normal from object space to world space
					o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target {
					// Get ambient term
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				// Get the normal in world space
				fixed3 worldNormal = normalize(i.worldNormal);
				// Get the light direction in world space
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				// 和逐片元的最大的不同就是漫反射公式
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * halfLambert;

				fixed3 color = ambient + diffuse;

				return fixed4(color, 1.0);
			}

			ENDCG
		}

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