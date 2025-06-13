Shader "Unlit/GakumasActor_Sample"
{
	Properties
	{
		_BaseMap ("Base (RGB)", 2D) = "white" { }
		[HDR] _BaseColor ("Base Color", Color) = (1,1,1,1)
		[Toggle(_ALPHAPREMULTIPLY_ON)] _AlphaPremultiply ("Alpha Premultiply", Float) = 0
		_ShadeMap ("Shade (RGB)", 2D) = "white" { }
		_RampMap ("Ramp (RGB) Ramp (A)", 2D) = "white" { }
		_HighlightMap ("Highlight (RGB)", 2D) = "black" { }
		[Toggle(_DEFMAP_OFF)]_DisableDefMap ("Disable DefMap", Float) = 0
		_DefMap ("Def", 2D) = "white" { }
		_DefValue ("DefValue", Vector) = (0.5,0,1,0)
		[Toggle(_LAYERMAP_ON)]_EnableLayerMap ("Use LayerMap", Float) = 0
		_LayerMap ("Layer (RGB)", 2D) = "white" { }
		_RenderMode ("Optional Rendering Mode", Float) = 0
		_BumpScale ("Scale", Float) = 1
		_BumpMap ("Normal", 2D) = "bump" { }
		_AnisotropicMap ("Anisotropic Tangent(RG) AnisoMask(B)", 2D) = "black" { }
		_AnisotropicScale ("Anisotropic Scale", Range(-0.95, 0.95)) = 1
		[Toggle(_RAMPADD_ON)]_EnableRampAddMap ("Use RampAddMap", Float) = 0
		_RampAddMap ("RampAdd (RGB)", 2D) = "white" { }
		[HDR] _RampAddColor ("RampAdd Color", Color) = (1,1,1,1)
		[HDR] _RimColor ("Rim Color", Color) = (0,0,0,0)
		[Toggle] _VertexColor ("Use VertexColor", Float) = 0
		_OutlineColor ("Outline Color", Color) = (0,0,0,0)
		[Toggle(_EMISSION)] _EnableEmission ("Enable Emission", Float) = 0
		_EmissionMap ("EmissionMap", 2D) = "black" { }
		[HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,0)
		_RefractThickness ("Refract Thickness", Float) = 0
		_DefDebugMask ("Def Debug", Float) = 15
		_SpecularThreshold ("Specular Threshold", Vector) = (0.6,0.05,0,0)
		[KeywordEnum(REFLECTION_TEXTURE, EYE_REFLECTION_TEXTURE)]_USE("ReflectionSwitch", Float) = 0
		[Toggle(_USE_REFLECTION_SPHERE)]_EnableReflectionSphereMap ("Use ReflectionSphereMap", Float) = 0
		_ReflectionSphereMap ("Reflection Sphere", 2D) = "black" { }
		_FadeParam ("Fade x=XOffset y=XScale z=YOffset w=YScale", Vector) = (0.75,2,0.4,4)
		_ShaderType ("Shader Type", Float) = 0
		[Toggle(_ALPHATEST_ON)] _AlphaTest("AlphaTest", Float) = 0.0
		_ClipValue ("Clip Value", Range(0.0, 1.0)) = 0.33
		[Enum(UnityEngine.Rendering.CullMode)]_Cull ("__cull", Float) = 2
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("__src", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("__dst", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcAlphaBlend ("__srcAlpha", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstAlphaBlend ("__dstAlpha", Float) = 0
		_ColorMask ("__colormask", Float) = 15
		_ColorMask1 ("__colormask1", Float) = 15
		_ZWrite ("__zw", Float) = 1
		[Toggle(_ENALBEHAIRCOVER_ON)] _EnalbeHairCover("EnalbeHairCover", Float) = 0.0
		_StencilRef ("__stencilRef", Float) = 64
		_StencilReadMask ("__stencilRead", Float) = 108
		_StencilWriteMask ("__stencilWrite", Float) = 108
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("__stencilComp", Float) = 8
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("__stencilPass", Float) = 2
		[PerRendererData] _ActorIndex ("Actor Index", Float) = 15
		// [PerRendererData] _LayerWeight ("Layer Weight", Float) = 0
		_LayerWeight ("Layer Weight", Float) = 0
		[PerRendererData]_HeadDirection ("Direction", Vector) = (0,0,1,1)
		[PerRendererData]_HeadUpDirection ("Up Direction", Vector) = (0,1,0,1)
		[PerRendererData] _MultiplyColor ("Multiply Color", Color) = (1,1,1,1)
		[PerRendererData] _MultiplyOutlineColor ("Outline Multiply Color", Color) = (1,1,1,1)
		[PerRendererData] _UseLastFramePositions ("Use Last Frame Positions", Float) = 0
	}
	SubShader
	{
		
		
		Pass
		{
			Tags
			{
				"RenderType"="Opaque"
			}
			LOD 100

			Cull [_Cull]
			ZWrite [_ZWrite]
			Blend [_SrcBlend] [_DstBlend], [_SrcAlphaBlend] [_DstAlphaBlend]
			Stencil
			{
				Ref [_StencilRef]
				ReadMask [_StencilReadMask]
				WriteMask [_StencilWriteMask]
				Comp [_StencilComp]
				Pass [_StencilPass]
			}
			
			HLSLPROGRAM
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _ADDITIONAL_LIGHTS
			
			#pragma shader_feature _ _ALPHATEST_ON

			#pragma shader_feature _ _LAYERMAP_ON
			#pragma shader_feature _ _RAMPADD_ON
			#pragma shader_feature _ _DEFMAP_OFF
			#pragma shader_feature _ _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _ _USE_REFLECTION_TEXTURE _USE_EYE_REFLECTION_TEXTURE
			#pragma shader_feature _ _USE_REFLECTION_SPHERE

			#include "GakumasCommon.hlsl"

			#pragma vertex vert
			#pragma fragment frag
			
			ENDHLSL
		}
		Pass
		{
			Name "HairCover"
			Tags
			{
				"LightMode"="UniversalForward"
			}
			LOD 100

			Cull [_Cull]
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha, [_SrcAlphaBlend] [_DstAlphaBlend]
//			Stencil
//			{
//				Ref [_StencilRef]
//				ReadMask [_StencilReadMask]
//				WriteMask [_StencilWriteMask]
//				Comp Always
//				Pass Keep
//			}
			HLSLPROGRAM
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _ADDITIONAL_LIGHTS
			
			#pragma shader_feature _ _ALPHATEST_ON

			#pragma shader_feature _ _LAYERMAP_ON
			#pragma shader_feature _ _RAMPADD_ON
			#pragma shader_feature _ _DEFMAP_OFF
			#pragma shader_feature _ _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _ _USE_REFLECTION_TEXTURE _USE_EYE_REFLECTION_TEXTURE
			#pragma shader_feature _ _USE_REFLECTION_SPHERE
			
			#define IS_HAIRCOVER_PASS
			#pragma shader_feature _ _ENALBEHAIRCOVER_ON
			
			#include "GakumasCommon.hlsl"

			#pragma vertex vert
			#pragma fragment frag
			
			ENDHLSL
		}
		Pass
		{
			Name "OutLine"
			Tags
			{
				"LightMode"="UniversalForwardOutline"
			}
			LOD 100

			Cull Front
			ZWrite [_ZWrite]
			Blend One Zero, One Zero
//			Stencil
//			{
//				Ref [_StencilRef]
//				ReadMask [_StencilReadMask]
//				WriteMask [_StencilWriteMask]
//				Comp [_StencilComp]
//				Pass [_StencilPass]
//			}
			HLSLPROGRAM
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _SHADOWS_SOFT
			
			#pragma shader_feature _ _ALPHATEST_ON

			#pragma shader_feature _ _LAYERMAP_ON
			#pragma shader_feature _ _RAMPADD_ON
			#pragma shader_feature _ _DEFMAP_OFF
			#pragma shader_feature _ _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _ _USE_REFLECTION_TEXTURE _USE_EYE_REFLECTION_TEXTURE
			#pragma shader_feature _ _USE_REFLECTION_SPHERE
			#include "GakumasCommon.hlsl"

			#pragma vertex vertOutline
			#pragma fragment fragOutline

			v2f vertOutline( appdata v )
			{
				v2f o;
				
				float3 PositionWS = TransformObjectToWorld(v.Position);
				float3 SmoothNormalWS = TransformObjectToWorldNormal(v.Tangent);

				G_VertexColor VertexColor = DecodeVertexColor(v.Color);
				o.Color1 = VertexColor.OutLineColor;
				o.Color2 = float4(
					VertexColor.OutLineWidth,
					VertexColor.OutLineOffset,
					VertexColor.RampAddID,
					VertexColor.RimMask);

	
				float CameraDistance = length(_WorldSpaceCameraPos - PositionWS);
				float OutLineWidth = min(CameraDistance * _OutlineParam.z * _OutlineParam.w, 1.0f);
				OutLineWidth = lerp(_OutlineParam.x, _OutlineParam.y, OutLineWidth);
				OutLineWidth *= 0.01f * VertexColor.OutLineWidth;
				
				float3 OffsetVector = OutLineWidth * SmoothNormalWS;
				
				float3 OffsetedPositionWS = PositionWS + OffsetVector;
				
				float4 OffsetedPositionCS = TransformWorldToHClip(OffsetedPositionWS);
				OffsetedPositionCS.z -= VertexColor.OutLineOffset * 6.66666747e-05;

				o.PositionCS = OffsetedPositionCS;
				
				return o;
			}

			float4 fragOutline( v2f i , bool IsFront : SV_IsFrontFace) : SV_Target
			{
				float3 OutLineColor = i.Color1.xyz * _MultiplyOutlineColor.xyz;
				float OutLineAlpha = _MultiplyColor.a;
				return float4(OutLineColor,OutLineAlpha);
			}
			
			ENDHLSL
		}

		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
	}
}