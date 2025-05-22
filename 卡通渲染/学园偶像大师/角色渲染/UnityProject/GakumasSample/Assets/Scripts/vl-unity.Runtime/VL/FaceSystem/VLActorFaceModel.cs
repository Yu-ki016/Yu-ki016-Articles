using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using VL.Core;

namespace VL.FaceSystem
{
    public class VLActorFaceModel : MonoBehaviour
    {
        public Mesh mesh;
        public Transform rootBone;
        public Transform[] bones;
        public Bounds bounds;
        public Bounds localBounds;
        public int blendShapeLength;
        public IReadOnlyList<VLActorFaceBindVertex> bindVertices;
        public Matrix4x4[] bindposes;
        public BlendShapeWeight blendShapeWeights;
        public uint[] boneWeightAndIndices;
        public Material[] sharedMaterials;
        public BlendShapeData[] blendShapes;
    }

}

