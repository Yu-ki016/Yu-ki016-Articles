using System.Collections.Generic;
using System.IO;
using Unity.Collections;
using UnityEngine;
using UnityPMXExporter;
using VL.FaceSystem;
using static UnityEditor.Rendering.CameraUI;
using Object = UnityEngine.Object;

public class ModelLoader : MonoBehaviour
{
    // Start is called before the first frame update
    public string ShaderFile;
    public string BodyFile;
    public string FaceFile;
    public string HairFile;
    public string PMXPath;

    public List<Shader> ShaderList = new List<Shader>();

    public GameObject Body;
    public GameObject Face;
    public GameObject Hair;

    public List<Object> AssetHolder = new List<Object>();

    public Transform ConnectBone;
    public Light DirectionalLight;

    void Start()
    {
        if (ShaderFile != "")
        {
            var shader_ab = AssetBundle.LoadFromFile(ShaderFile);
            ShaderList.AddRange(shader_ab.LoadAllAssets<Shader>());
        }
        else
        {
            Debug.Log($"ShaderFile is None !");
        }

        if (BodyFile != "" && File.Exists(BodyFile))
        {
            var body_ab = AssetBundle.LoadFromFile(BodyFile);
            foreach (var ab in body_ab.LoadAllAssets())
            {
                if(ab is GameObject go)
                {
                    Body = Instantiate(go);
                    ConnectBone = Body.transform.Find("Reference/Hips/Spine/Spine1/Spine2/Neck/Head");
                }
                AssetHolder.Add(ab);
            }
        }
        else
        {
            Debug.Log($"BodyFile is None !");
        }

        if (FaceFile != "" && File.Exists(FaceFile))
        {
            var face_ab = AssetBundle.LoadFromFile(FaceFile);
            foreach (var ab in face_ab.LoadAllAssets())
            {
                if (ab is GameObject go)
                {
                    Face = Instantiate(go);
                    var vl = Face.GetComponentInChildren<VLActorFaceModel>();
                    var skinned = vl.gameObject.AddComponent<SkinnedMeshRenderer>();
                    var mesh = vl.mesh;
                    byte[] bonesPerVertex = new byte[mesh.vertexCount];
                    for (int i = 0; i < bonesPerVertex.Length; i++)
                    {
                        bonesPerVertex[i] = 1;
                    }
                    BoneWeight1[] weights = new BoneWeight1[mesh.vertexCount];
                    for (int i = 0; i < weights.Length; i++)
                    {
                        weights[i].boneIndex = 0;
                        weights[i].weight = 1;
                    }

                    var bonesPerVertexArray = new NativeArray<byte>(bonesPerVertex, Allocator.Temp);
                    var weightsArray = new NativeArray<BoneWeight1>(weights, Allocator.Temp);
                    mesh.SetBoneWeights(bonesPerVertexArray, weightsArray);

                    skinned.sharedMesh = vl.mesh;
                    skinned.bones = vl.bones;
                    mesh.bindposes = vl.bindposes;
                    foreach (var bs in vl.blendShapes)
                    {
                        var del_ver = new Vector3[mesh.vertexCount];
                        foreach (var ver in bs.blendShapeVertices)
                        {
                            del_ver[ver.vertIndex] = ver.position;
                        }
                        mesh.AddBlendShapeFrame(bs.blendShapeName, 1, del_ver, null, null);
                    }
                    skinned.localBounds = vl.localBounds;
                    skinned.rootBone = vl.rootBone;
                    skinned.materials = vl.sharedMaterials;
                    if (ConnectBone)
                    {
                        Face.transform.SetParent(ConnectBone, false);
                        skinned.bones[0] = ConnectBone;
                        skinned.rootBone = ConnectBone;
                    }
                }
                AssetHolder.Add(ab);
            }
        }
        else
        {
            Debug.Log($"FaceFile is None !");
        }

        if (HairFile != "" && File.Exists(HairFile))
        {
            var hair_ab = AssetBundle.LoadFromFile(HairFile);
            foreach (var ab in hair_ab.LoadAllAssets())
            {
                if (ab is GameObject go)
                {
                    Hair = Instantiate(go);
                    if (ConnectBone)
                    {
                        Hair.transform.SetParent(ConnectBone, false);
                        SkinnedMeshRenderer skinned = Hair.GetComponentInChildren<SkinnedMeshRenderer>();
                        skinned.bones[0] = ConnectBone;
                        skinned.rootBone = ConnectBone;
                    }
                }
                AssetHolder.Add(ab);
            }
        }
        else
        {
            Debug.Log($"HairFile is None !");
        }

        var path = Path.GetDirectoryName(PMXPath);
        var name = Path.GetFileName(PMXPath);
        if (Directory.Exists(path) && Body && Face && Hair)
        {
            var outPath = string.IsNullOrEmpty(name) ? $"{path}/Model.pmx" : PMXPath;
            ModelExporter.ExportModel(Body, outPath, colorSpace:RenderTextureReadWrite.sRGB);
            Debug.Log($"Export model to {outPath}");
        }
        else
        {
            Debug.Log($"Export Failed \nDirectory Exists:{Directory.Exists(PMXPath)} \nBody:{Body} \nFace:{Face} \nHair:{Hair}");
        }
        Shader.SetGlobalFloat("_SkinSaturation", 1);
    }

    public Color MatCapParam;
    public Color MatCapRimColor;
    public Color VLSpecColor;
    public Color EyeHightlightColor;
    public Color FadeParam;
    public float OutlineWidth;
    public Vector4 MatCapRimLight;


    void Update()
    {
        var dir = -DirectionalLight.transform.forward;
        Shader.SetGlobalFloat("_SkinSaturation", 1);
        Shader.SetGlobalColor("_MatCapLightColor", DirectionalLight.color);
        Shader.SetGlobalVector("_MatCapRimColor", MatCapRimColor);
        Shader.SetGlobalVector("_VLSpecColor", VLSpecColor);
        Shader.SetGlobalVector("_MatCapParam", MatCapParam);
        Shader.SetGlobalVector("_MatCapMainLight", dir);
        Shader.SetGlobalVector("_MatCapRimLight", MatCapRimLight);
        Shader.SetGlobalVector("_HeadDirection", Face.transform.forward);
        Shader.SetGlobalVector("_HeadUpDirection", Face.transform.up);
        Shader.SetGlobalVector("_EyeHightlightColor", EyeHightlightColor);
        Shader.SetGlobalVector("_OutlineParam", new Color(OutlineWidth, 0, 0, 0));
        Shader.SetGlobalVector("_FadeParam", FadeParam);
    }
}
