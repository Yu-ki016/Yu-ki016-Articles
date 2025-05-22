using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class SetGlobalAttributes : MonoBehaviour
{
    MaterialPropertyBlock PropertyBlock;
    SkinnedMeshRenderer[] Renderers;
    [Tooltip("x:天光强度;Y:多光源强度;Z:多光源Specular强度")]
    public Vector4 GlobalLightParameter = new Vector4(1.0f, 1.0f, 1.0f, 1.0f);
    public GameObject LightDirectionWS;
    [Tooltip("主光方向，当A通道为0时为Matcap空间;当A通道为1时为世界空间(此时使用上面的LightDirectionWS物体的朝向)")]
    public Vector4 MainLightDirection = new Vector4(0.34f, 0.57f, 0.74f, 0.0f);
    [ColorUsage(true, true)]
    public Color MainLightColor = Color.white;
    [Tooltip("x:明暗交界线的Offset;z:阴影的强度")]
    public Vector4 MatCapParam = new Vector4(0.3f, 1.0f, 1.0f, 0.0f);
    public Vector4 SpecularThreshold = new Vector4(0.1f, 0.5f, 1.0f, 1.0f);
    [Tooltip("xyz:边缘光方向(ViewSpace);w:边缘光范围，值越大范围越小")]
    public Vector4 MatCapRimLight = new Vector4(-0.4f, -0.26f, 0.87f, 10.0f);
    [Tooltip("xyz:边缘光颜色;w:一遍为1，为0时边缘光不会乘上基础颜色")]
    [ColorUsage(true, true)]
    public Color MatCapRimColor = Color.white;
    [Tooltip("整体乘以这个颜色")]
    [ColorUsage(true, true)]
    public Color MultiplyColor = Color.white;
    public Color ShadeMultiplyColor = Color.white;
    public Color ShadeAdditiveColor = Color.black;
    [Tooltip("皮肤颜色饱和度")]
    public float SkinSaturation = 1;
    [ColorUsage(true, true)]
    public Color EyeHightlightColor = Color.white;
    public Cubemap VLSpecCube;
    [ColorUsage(true, true)]
    public Color VLSpecColor = Color.white;
    [ColorUsage(true, true)]
    public Color VLEyeSpecColor = Color.white;
    public Vector4 ReflectionSphereMapHDR = Vector4.one;
    [Tooltip("x:Outline最小宽度;Y:Outline受距离影响的程度;Z和W作用一致都是控制宽度")]
    public Vector4 OutlineParam = new Vector4(0.05f, 5.0f, 0.011f, 0.45f);
    public Transform Head;
    
    void UpdateProperties()
    {
        Vector3 NormalizedLight = Vector3.Normalize(MainLightDirection);
        if (LightDirectionWS && MainLightDirection.w > 0.5f)
        {
            NormalizedLight = LightDirectionWS.transform.up;
        }
        
        Shader.SetGlobalVector("_GlobalLightParameter", GlobalLightParameter);
        Shader.SetGlobalVector("_MatCapMainLight", new Vector4(NormalizedLight.x, NormalizedLight.y, NormalizedLight.z, MainLightDirection.w));
        Shader.SetGlobalVector("_MatCapLightColor", MainLightColor);
        Shader.SetGlobalVector("_MatCapParam", MatCapParam);
        Shader.SetGlobalVector("_MatCapRimLight", MatCapRimLight);
        Shader.SetGlobalVector("_MatCapRimColor", MatCapRimColor);
        Shader.SetGlobalVector("_MultiplyColor", MultiplyColor);
        Shader.SetGlobalVector("_ShadeMultiplyColor", ShadeMultiplyColor);
        Shader.SetGlobalVector("_ShadeAdditiveColor", ShadeAdditiveColor);
        Shader.SetGlobalFloat("_SkinSaturation", SkinSaturation);
        Shader.SetGlobalVector("_EyeHighlightColor", EyeHightlightColor);
        Shader.SetGlobalTexture("_VLSpecCube", VLSpecCube);
        Shader.SetGlobalVector("_VLSpecColor", VLSpecColor);
        Shader.SetGlobalVector("_VLEyeSpecColor", VLEyeSpecColor);
        Shader.SetGlobalVector("_ReflectionSphereMapHDR", ReflectionSphereMapHDR);
        Shader.SetGlobalVector("_OutlineParam", OutlineParam);
        
        Vector4 HeadDirection = new Vector4(0, 0, 1, 0);
        Vector4 HeadUp = new Vector4(0, 1, 0, 0);
        Vector4 HeadRight = new Vector4(1, 0, 0, 0);
        Matrix4x4 HeadXAxisReflectionMatrix = Matrix4x4.identity;
        if (Head)
        {
            HeadDirection = Head.forward;
            HeadUp = Head.up;
            HeadRight = Head.right;
            HeadXAxisReflectionMatrix.SetColumn(0, -HeadRight);
            HeadXAxisReflectionMatrix.SetColumn(1, HeadUp);
            HeadXAxisReflectionMatrix.SetColumn(2, HeadDirection);
            HeadXAxisReflectionMatrix.SetColumn(3, new Vector4(0, 0, 0, 1));
        }
        
        PropertyBlock = new MaterialPropertyBlock();
        PropertyBlock.SetVector("_HeadDirection", HeadDirection);
        PropertyBlock.SetVector("_HeadUpDirection", HeadUp);
        PropertyBlock.SetMatrix("_HeadXAxisReflectionMatrix", HeadXAxisReflectionMatrix);

        if (Renderers != null)
        {
            foreach (SkinnedMeshRenderer SkinnedRenderer in Renderers)
            {
                SkinnedRenderer.SetPropertyBlock(PropertyBlock);
            }
        }
    }
    
    void Start()
    {
        Renderers = GetComponentsInChildren<SkinnedMeshRenderer>();
        UpdateProperties();
    }

    private void OnValidate()
    {
        UpdateProperties();
    }
    
    private void Update()
    {
        UpdateProperties();
    }

}
