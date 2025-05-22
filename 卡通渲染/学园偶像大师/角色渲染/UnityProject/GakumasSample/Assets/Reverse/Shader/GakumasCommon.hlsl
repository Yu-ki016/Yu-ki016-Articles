#ifndef _GAKUMAS_COMMON_INCLUDED
#define _GAKUMAS_COMMON_INCLUDED

#include "Library/PackageCache/com.unity.render-pipelines.core@14.0.11/ShaderLibrary/Common.hlsl"
#include "Library/PackageCache/com.unity.render-pipelines.core@14.0.11/ShaderLibrary/API/D3D11.hlsl"
#include "Library/PackageCache/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/BRDF.hlsl"
#include "Library/PackageCache/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/GlobalIllumination.hlsl"
#include "Library/PackageCache/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/Input.hlsl"
#include "Library/PackageCache/com.unity.render-pipelines.core@14.0.11/ShaderLibrary/SpaceTransforms.hlsl"
#include "Library/PackageCache/com.unity.render-pipelines.core@14.0.11/ShaderLibrary/Texture.hlsl"

// A、B、C的取值范围都是[0, 1]
void Encode4BitTo8Bit(float4 A, float4 B, out float4 C)
{
	float4 HighBit = floor(A * 15.9375f + 0.03125f);
	float4 LowBit = floor(B * 15.9375f + 0.03125f);
	C = (HighBit * 16.0f + LowBit) / 255.0f;
}

// A、B、C的取值范围都是[0, 1]
void Decode4BitFrom8Bit(float4 C, out float4 A, out float4 B)
{
	const float k = 1.0f / 16.0f;
	float4 HighBit = floor(C * 15.9375f + 0.03125f);
	float4 LowBit = C * 255.0f - HighBit * 16.0f;
	A = HighBit * k;
	B = LowBit * k;
}

struct G_VertexColor
{
	float4 OutLineColor;
	float OutLineWidth;
	float OutLineOffset;
	float RampAddID;
	float RimMask;
};

G_VertexColor DecodeVertexColor(float4 VertexColor)
{
	G_VertexColor OutColor;
	float4 LowBit, HighBit;
	Decode4BitFrom8Bit(VertexColor, HighBit, LowBit);
	OutColor.OutLineColor = float4(HighBit.x, LowBit.x, HighBit.y, LowBit.w);
	OutColor.OutLineWidth = LowBit.z;
	OutColor.OutLineOffset = HighBit.z;
	OutColor.RampAddID = LowBit.y;
	OutColor.RimMask = HighBit.w;
	
	return OutColor;
}

BRDFData G_InitialBRDFData(float3 BaseColor, float Smoothness, float Metallic, float Specular, bool IsEye)
{
	float OutAlpha = 1.0f;
	BRDFData G_BRDFData;
	InitializeBRDFData(BaseColor, Metallic, Specular, Smoothness, OutAlpha, G_BRDFData);
	G_BRDFData.grazingTerm = IsEye ? saturate(Smoothness + kDieletricSpec.x) : G_BRDFData.grazingTerm;
	G_BRDFData.diffuse = IsEye ? BaseColor * kDieletricSpec.a : G_BRDFData.diffuse;
	G_BRDFData.specular = IsEye ? BaseColor : G_BRDFData.specular;
	
	return G_BRDFData;
}

half G_DirectBRDFSpecular(BRDFData BrdfData, half3 NormalWS, half3 NormalMatS, float4 LightDir, float3 ViewDir)
{
	bool DisableMatCap = LightDir.w > 0.5f;
	ViewDir = DisableMatCap ? ViewDir : float3(0.0f, 0.0f, 1.0f);
    float3 HalfDir = SafeNormalize(LightDir.xyz + ViewDir);

	float3 Normal = DisableMatCap ? NormalWS : NormalMatS;
    float NoH = saturate(dot(float3(Normal), HalfDir));
    half LoH = half(saturate(dot(LightDir.xyz, HalfDir)));

    float D = NoH * NoH * BrdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half SpecularTerm = BrdfData.roughness2 / ((D * D) * max(0.1h, LoH2) * BrdfData.normalizationTerm);

    return SpecularTerm;
}

cbuffer ShaderParameters : register(b0)
{
	float4 _BaseColor;
	float4 _DefValue;
	float _EnableLayerMap;
	float _RenderMode;
	float _BumpScale;
	float _AnisotropicScale;
	float4 _RampAddColor;
	float4 _RimColor;
	float _VertexColor;
	float4 _OutlineColor;
	float _EnableEmission;
	float _RefractThickness;
	float _DefDebugMask;
	float4 _SpecularThreshold;
	float4 _FadeParam;
	float _ShaderType;
	float _ClipValue;
	float _Cull;
	float _SrcBlend;
	float _DstBlend;
	float _SrcAlphaBlend;
	float _DstAlphaBlend;
	float _ColorMask;
	float _ColorMask1;
	float _ZWrite;
	float _StencilRef;
	float _StencilReadMask;
	float _StencilWriteMask;
	float _StencilComp;
	float _StencilPass;
	float _ActorIndex;
	float _LayerWeight;
	float _SkinSaturation;
	float4 _HeadDirection;
	float4 _HeadUpDirection;
	float4 _MultiplyColor;
	float4 _MultiplyOutlineColor;
	float _UseLastFramePositions;
	float4x4 _HeadXAxisReflectionMatrix;
	float4 _BaseMap_ST;
	float4 _MatCapParam;
	float4 _MatCapMainLight;
	float4 _MatCapLightColor;
	float4 _ShadeMultiplyColor;
	float4 _ShadeAdditiveColor;
	float4 _EyeHighlightColor;
	float4 _VLSpecColor;
	float4 _VLEyeSpecColor;
	float4 _MatCapRimColor;
	float4 _MatCapRimLight;
	float4 _GlobalLightParameter;
	float4 _ReflectionSphereMap_HDR;
	float4 _OutlineParam;
};

Texture2D _BaseMap;
SAMPLER(sampler_BaseMap);
Texture2D _ShadeMap;
SAMPLER(sampler_ShadeMap);
Texture2D _RampMap;
SAMPLER(sampler_RampMap);
Texture2D _HighlightMap;
SAMPLER(sampler_HighlightMap);
Texture2D _DefMap;
SAMPLER(sampler_DefMap);
Texture2D _LayerMap;
SAMPLER(sampler_LayerMap);
Texture2D _BumpMap;
SAMPLER(sampler_BumpMap);
Texture2D _AnisotropicMap;
SAMPLER(sampler_AnisotropicMap);
Texture2D _RampAddMap;
SAMPLER(sampler_RampAddMap);
Texture2D _EmissionMap;
SAMPLER(sampler_EmissionMap);
Texture2D _ReflectionSphereMap;
SAMPLER(sampler_ReflectionSphereMap);
TextureCube _VLSpecCube;
SAMPLER(sampler_VLSpecCube);

struct appdata
{
    float4 Position             : POSITION; 
    float3 Normal               : NORMAL;     
    float4 Tangent              : TANGENT;   
    float2 UV0                  : TEXCOORD0;     
    float2 UV1                  : TEXCOORD1;     
    float4 Color                : COLOR;       
    float3 PrePosition          : TEXCOORD4;     
};

struct v2f
{
    float4 UV                   : TEXCOORD0;     
    float3 PositionWS           : TEXCOORD1;     
    float4 Color1               : COLOR;      
    float4 Color2               : TEXCOORD2;     
    float3 NormalWS             : TEXCOORD3;     
    float3 NormalHeadReflect    : TEXCOORD4;     
    float4 ShadowCoord          : TEXCOORD6;
    float4 PositionCSNoJitter   : TEXCOORD7;    
    float4 PrePosionCS          : TEXCOORD8;     
    float4 PositionCS           : SV_POSITION;
};


v2f vert( appdata v )
{
	v2f o;

	o.UV.xy = v.UV0 * _BaseMap_ST.xy + _BaseMap_ST.zw;
	o.UV.zw = v.UV1.xy;
	
	o.PositionWS = TransformObjectToWorld(v.Position);
	o.NormalWS = TransformObjectToWorldNormal(v.Normal);
	o.NormalHeadReflect = mul(_HeadXAxisReflectionMatrix, float4(v.Normal, 0.0f)).xyz;

	G_VertexColor VertexColor = DecodeVertexColor(v.Color);
	o.Color1 = VertexColor.OutLineColor;
	o.Color2 = float4(
		VertexColor.OutLineWidth,
		VertexColor.OutLineOffset,
		VertexColor.RampAddID,
		VertexColor.RimMask);
	
	o.ShadowCoord = TransformWorldToShadowCoord(o.PositionWS);
	
	float4 PositionWS = float4(o.PositionWS, 1.0f);
	o.PositionCSNoJitter = mul(_NonJitteredViewProjMatrix, PositionWS);

	bool UseLastFramePositions = _UseLastFramePositions + unity_MotionVectorsParams.x > 1.0f;
	float3 LastFramePositionOS = UseLastFramePositions ? v.PrePosition : v.Position;
	float4 LastFramePositionWS = mul(unity_MatrixPreviousM, LastFramePositionOS);
	o.PrePosionCS = mul(_PrevViewProjMatrix, LastFramePositionWS);

	o.PositionCS = TransformWorldToHClip(PositionWS);
	return o;
}

float4 frag( v2f i , bool IsFront : SV_IsFrontFace) : SV_Target
{
	#if defined(IS_HAIRCOVER_PASS) && !defined(_ENALBEHAIRCOVER_ON)
		clip(-1);
	#endif
	
	G_VertexColor VertexColor;
	VertexColor.OutLineColor = i.Color1;
	VertexColor.OutLineWidth = i.Color2.x;
	VertexColor.OutLineOffset = i.Color2.y;
	VertexColor.RampAddID = i.Color2.z;
	VertexColor.RimMask = i.Color2.w;

	bool IsFace = _ShaderType == 9;
	bool IsHair = _ShaderType == 8;
	bool IsEye = _ShaderType == 4;
	bool IsEyeHightLight = _ShaderType == 5;
	bool IsEyeBrow = _ShaderType == 6;

	float3 NormalWS = normalize(i.NormalWS);
	NormalWS = IsFront ? NormalWS : NormalWS * -1.0f;
	
	bool IsOrtho = unity_OrthoParams.w; // unity_OrthoParams.w == 1时表示正交投影
	
	float3 ViewVector = _WorldSpaceCameraPos - i.PositionWS;
	float3 ViewDirection = normalize(ViewVector);
	ViewDirection = IsOrtho ? unity_MatrixV[2].xyz : ViewDirection;

	float3 CameraUp = unity_MatrixV[1].xyz;
	float3 ViewSide = normalize(cross(ViewDirection, CameraUp));
	float3 ViewUp = normalize(cross(ViewSide, ViewDirection));
	float3x3 WorldToMatcap = float3x3(ViewSide, ViewUp, ViewDirection);

	float3 NormalMatS = mul(WorldToMatcap, float4(NormalWS, 0.0f));

	float NoL = dot(NormalWS, _MatCapMainLight);
	float MatCapNoL = dot(NormalMatS, _MatCapMainLight);
	bool DisableMatCap = _MatCapMainLight.w > 0.5f;
	NoL = DisableMatCap ? NoL : MatCapNoL;

	float Shadow = MainLightRealtimeShadow(i.ShadowCoord);
    float ShadowFadeOut = dot(-ViewVector, -ViewVector);
    ShadowFadeOut = saturate(ShadowFadeOut * _MainLightShadowParams.z + _MainLightShadowParams.w);
    ShadowFadeOut *= ShadowFadeOut;
    Shadow = lerp(Shadow, 1, ShadowFadeOut);
	Shadow = lerp(1.0f, Shadow, _MainLightShadowParams.x);
	Shadow = saturate(Shadow * ((4.0f * Shadow - 6) * Shadow + 3.0f));

	float3 LayerMapColor = 0;
	float LayerWeight = 0;
	float4 LayerMapDef = 0;
	#ifdef _LAYERMAP_ON
    if (_LayerWeight != 0)
    {
        float2 LayerMapUV = i.UV * float2(0.5f, 1.0f);
        float LayerMapTextureBias = _GlobalMipBias.x - 2;
        float4 LayerMap = SAMPLE_TEXTURE2D_BIAS(_LayerMap, sampler_LayerMap, LayerMapUV, LayerMapTextureBias);
        LayerMapColor = LayerMap.rgb;
        LayerWeight = LayerMap.a * _LayerWeight;
        
        float2 LayerMapDefUV = LayerMapUV + float2(0.5f, 0.0f);
        LayerMapDef = SAMPLE_TEXTURE2D_BIAS(_LayerMap, sampler_LayerMap, LayerMapDefUV, LayerMapTextureBias);
    }
	#endif
	
	float TextureBias = _GlobalMipBias.x - 1;
	float4 BaseMap = SAMPLE_TEXTURE2D_BIAS(_BaseMap, sampler_BaseMap, i.UV.xy, TextureBias);
	#ifdef _LAYERMAP_ON
        BaseMap.rgb = lerp(BaseMap, LayerMapColor.rgb, LayerWeight);
	#endif
	float4 ShadeMap = SAMPLE_TEXTURE2D_BIAS(_ShadeMap, sampler_ShadeMap, i.UV.xy, TextureBias);
	float4 DefMap = _DefValue;
	#ifndef _DEFMAP_OFF
		DefMap = SAMPLE_TEXTURE2D_BIAS(_DefMap, sampler_DefMap, i.UV.xy, TextureBias).xyzw;
	#endif
	#ifdef _LAYERMAP_ON
        DefMap = lerp(DefMap, LayerMapDef, LayerWeight);
	#endif
	float DefDiffuse = DefMap.x;
	float DefMetallic = DefMap.z;
	float DefSmoothness = DefMap.y;
	float DefSpecular = DefMap.w;

	float DiffuseOffset = DefDiffuse * 2.0f - 1.0f;
	float Smoothness = min(DefSmoothness, 1);
	float Metallic = IsFace ? 0 : DefMetallic;
	
	float SpecularIntensity = min(DefSpecular, Shadow);
	float3 NormalWorM = DisableMatCap ? NormalWS : NormalMatS;
	float3 ViewDirWorM = DisableMatCap ? ViewDirection : float3(0, 0, 1);

	if (IsHair)
	{
		float IsMicroHair = saturate(i.UV.x - 0.75f) * saturate(i.UV.y - 0.75f);
		IsMicroHair = IsMicroHair != 0;
	
		float HairSpecular = Pow4(saturate(dot(NormalWorM, ViewDirWorM)));
		HairSpecular = smoothstep(_SpecularThreshold.x - _SpecularThreshold.y, _SpecularThreshold.x + _SpecularThreshold.y, HairSpecular);
		HairSpecular *= SpecularIntensity;
		HairSpecular = IsMicroHair ? 0 : HairSpecular;
		
		float3 HighlightMap = SAMPLE_TEXTURE2D_BIAS(_HighlightMap, sampler_HighlightMap, i.UV.xy, TextureBias).xyz;
		BaseMap.xyz = lerp(BaseMap.xyz, HighlightMap.xyz, HairSpecular);
		
	
		float HairFadeX = dot(_HeadDirection, ViewDirection);
		HairFadeX = _FadeParam.x - HairFadeX;
		HairFadeX = saturate(HairFadeX * _FadeParam.y);
		float HairFadeZ = dot(_HeadUpDirection, ViewDirection);
		HairFadeZ = abs(HairFadeZ) - _FadeParam.z;
		HairFadeZ = saturate(HairFadeZ * _FadeParam.w);
	
		BaseMap.a = lerp(1, max(HairFadeX, HairFadeZ), BaseMap.a);
	
		SpecularIntensity *= IsMicroHair ? 1 : 0;
	}
	
	float4 RampAddMap = 0;
	float3 RampAddColor = 0;
	#ifdef _RAMPADD_ON
    float2 RampAddMapUV = float2(saturate(DiffuseOffset + NormalMatS.z), VertexColor.RampAddID);
    RampAddMap = SAMPLE_TEXTURE2D_BIAS(_RampAddMap, sampler_RampAddMap, RampAddMapUV, _GlobalMipBias.x);
	RampAddColor = RampAddMap.xyz * _RampAddColor.xyz;
	
    float3 DiffuseRampAddColor = lerp(RampAddColor, 0, RampAddMap.a);
    BaseMap.xyz += DiffuseRampAddColor;
    ShadeMap.xyz += DiffuseRampAddColor;
	#endif
	
	float BaseLighting = NoL * 0.5f + 0.5f;
	BaseLighting = saturate(BaseLighting + (DiffuseOffset - _MatCapParam.x) * 0.5f);

	float3 NormalHeadMatS = mul(WorldToMatcap, i.NormalHeadReflect.xyz);
	float FaceNoL = DisableMatCap ? dot(i.NormalHeadReflect, _MatCapMainLight) : dot(NormalHeadMatS, _MatCapMainLight);
	float FaceLighting = saturate((FaceNoL + DiffuseOffset) * 0.5f + 0.5f);
	FaceLighting = max(FaceLighting, BaseLighting);
	FaceLighting = lerp(BaseLighting, FaceLighting, DefMetallic);
	
	BaseLighting = IsFace ? FaceLighting : BaseLighting;
	BaseLighting = min(BaseLighting, Shadow);
	
	float2 RampMapUV = float2(BaseLighting, 0);
	float4 RampMap = SAMPLE_TEXTURE2D_BIAS(_RampMap, sampler_RampMap, RampMapUV, _GlobalMipBias.x);

	const float ShadowIntensity = _MatCapParam.z;
	float3 RampedLighting = lerp(BaseMap.xyz, ShadeMap.xyz * _ShadeMultiplyColor, RampMap.w * ShadowIntensity);
	float3 SkinRampedLighting =	lerp(RampMap, RampMap.xyz * _ShadeMultiplyColor, RampMap.w);
	SkinRampedLighting = lerp(1, SkinRampedLighting, ShadowIntensity);
	SkinRampedLighting = BaseMap * SkinRampedLighting;
	RampedLighting = lerp(RampedLighting, SkinRampedLighting, ShadeMap.w);

	float SkinSaturation = _SkinSaturation - 1;
	SkinSaturation = SkinSaturation * ShadeMap.w + 1.0f;
	RampedLighting = lerp(Luminance(RampedLighting), RampedLighting, SkinSaturation);
	RampedLighting *= _BaseColor;
	
	RampedLighting = IsEyeHightLight ? RampedLighting * _EyeHighlightColor : RampedLighting;
	BRDFData G_BRDFData = G_InitialBRDFData(RampedLighting, Smoothness, Metallic, SpecularIntensity, IsEye);

	float3 IndirectSpecular = 0;
	float3 ReflectVector = reflect(-ViewDirection, NormalWS);
	#ifdef _USE_REFLECTION_TEXTURE
		float ReflectionTextureMip = PerceptualRoughnessToMipmapLevel(G_BRDFData.perceptualRoughness);
        float3 VLSpecCube = SAMPLE_TEXTURECUBE_LOD(_VLSpecCube, sampler_VLSpecCube, ReflectVector, ReflectionTextureMip);
        VLSpecCube *= _VLSpecColor;
        IndirectSpecular = VLSpecCube;
	#endif
	#ifdef _USE_EYE_REFLECTION_TEXTURE
		float ReflectionTextureMip = PerceptualRoughnessToMipmapLevel(G_BRDFData.perceptualRoughness);
        float3 VLSpecCube = SAMPLE_TEXTURECUBE_LOD(_VLSpecCube, sampler_VLSpecCube, ReflectVector, ReflectionTextureMip);
        VLSpecCube *= _VLEyeSpecColor;
        IndirectSpecular = VLSpecCube;
	#endif

	float3 MatCapReflection = 0.0f;
	#ifdef _USE_REFLECTION_SPHERE
        float2 ReflectionSphereMapUV = NormalMatS.xy * 0.5 + 0.5;
        float4 ReflectionSphereMap = SAMPLE_TEXTURE2D_BIAS(_ReflectionSphereMap, sampler_ReflectionSphereMap, ReflectionSphereMapUV, _GlobalMipBias.x);
    
        float ReflectionSphereIntensity = lerp(1, ReflectionSphereMap.a, _ReflectionSphereMap_HDR.w);
        ReflectionSphereIntensity = max(ReflectionSphereIntensity, 0);
		ReflectionSphereIntensity = pow(ReflectionSphereIntensity, _ReflectionSphereMap_HDR.y);
        ReflectionSphereIntensity *= _ReflectionSphereMap_HDR.x;
    
        ReflectionSphereMap.xyz = ReflectionSphereMap.xyz * ReflectionSphereIntensity;
        MatCapReflection = ReflectionSphereMap.xyz;
	#endif

	float FresnelTerm = Pow4(1 - saturate(NormalMatS.z)); // NormalMatS.z相当于NoV
	float3 SpecularColor =  EnvironmentBRDFSpecular(G_BRDFData, FresnelTerm);
	float3 SpecularTerm = DirectBRDFSpecular(G_BRDFData, NormalWorM, _MatCapMainLight, ViewDirWorM);
	float3 Specular = SpecularColor * IndirectSpecular;
	Specular += SpecularTerm * SpecularColor;
	Specular += MatCapReflection;
	Specular *= SpecularIntensity;

	if (IsEyeBrow)
	{
		float2 EyeBrowHightLightUV = saturate(i.UV.xy + float2(-0.968750, -0.968750));
		float EyeBrowHightLightMask = EyeBrowHightLightUV.y * EyeBrowHightLightUV.x;
		EyeBrowHightLightMask = EyeBrowHightLightMask != 0.000000;
		Specular += EyeBrowHightLightMask ? RampedLighting * 2.0f : 0.0f;
	}
	
	Specular = lerp(Specular, Specular * RampAddColor, RampAddMap.w);

	float3 SH = SampleSH(NormalWS);
	float3 SkyLight = max(SH, 0) * _GlobalLightParameter.x * G_BRDFData.diffuse;

	float3 NormalVS = mul(unity_MatrixV, float4(NormalWS.xyz, 0.0)).xyz;
	float RimLight = 1 - dot(NormalVS, normalize(_MatCapRimLight.xyz));
	RimLight = pow(RimLight, _MatCapRimLight.w);
	float RimLightMask = min(DefDiffuse * DefDiffuse, 1.0f) * VertexColor.RimMask;
	RimLight = min(RimLight, 1.0f) * RimLightMask;

	float3 RimLightColor = lerp(1, RampedLighting, _MatCapRimColor.a) * _MatCapRimColor.xyz;
	RimLightColor *= RimLight;
	
	float3 OutLighting = G_BRDFData.diffuse;
	OutLighting += Specular;
	OutLighting *= _MatCapLightColor.xyz;
	
	float3 AdditionalLighting = 0;
	#ifdef _ADDITIONAL_LIGHTS
	int additionalLightsCount = GetAdditionalLightsCount();
	for (int index = 0; index < additionalLightsCount; ++index) {
		Light AdditionalLight = GetAdditionalLight(index, i.PositionWS);
		
		float Radiance = max(dot(NormalWS, AdditionalLight.direction), 0);
		Radiance = (Radiance * 0.5f + 0.5f) * 2.356194f;
		Radiance = smoothstep(_MatCapParam.x - 0.000488f, _MatCapParam.x + 0.001464f, Radiance);
		Radiance = saturate(Radiance + ShadowIntensity);
		Radiance *= AdditionalLight.distanceAttenuation;
		
		float3 Lighting = Radiance * AdditionalLight.color;
		float3 AdditionalSpecular = DirectBRDFSpecular(G_BRDFData, NormalWS, AdditionalLight.direction, ViewDirection);
		AdditionalSpecular *= SpecularColor * _GlobalLightParameter.z;
		AdditionalLighting += Lighting * (OutLighting + AdditionalSpecular);
	}
	#endif

	OutLighting += AdditionalLighting * _GlobalLightParameter.y;
	OutLighting += SkyLight;
	OutLighting += RimLightColor;
	OutLighting += RampMap.w * _ShadeAdditiveColor;

	OutLighting *= _MultiplyColor.xyz;
	
	float Alpha = BaseMap.a * _MultiplyColor.a;
	#ifdef _ALPHATEST_ON
		clip(Alpha - _ClipValue);
	#endif
	#ifdef _ALPHAPREMULTIPLY_ON
        OutLighting *= Alpha;
	#endif

	return float4(OutLighting, Alpha);
}
#endif