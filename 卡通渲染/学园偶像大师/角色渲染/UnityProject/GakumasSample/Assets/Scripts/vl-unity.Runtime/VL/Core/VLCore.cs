using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VL.Core
{
    [Serializable]
    public class BlendShapeData
    {
        public string blendShapeName;
        public BlendShapeLayout[] blendShapeVertices;
    }

    [Serializable]
    public struct BlendShapeLayout
    {
        public int vertIndex;
        public Vector3 position;
    }

    public class VLActorFaceBindVertex
    {
        public int vertexIndex;
        public Vector3 basePosition;
    }
    public struct BlendShapeWeight
    {
        public const int BlendShapeWeightMax = 192;
        public BlendShapeWeight16 w0;
        public BlendShapeWeight16 w1;
        public BlendShapeWeight16 w2;
        public BlendShapeWeight16 w3;
        public BlendShapeWeight16 w4;
        public BlendShapeWeight16 w5;
        public BlendShapeWeight16 w6;
        public BlendShapeWeight16 w7;
        public BlendShapeWeight16 w8;
        public BlendShapeWeight16 w9;
        public BlendShapeWeight16 w10;
        public BlendShapeWeight16 w11;
    }

    public struct BlendShapeWeight16
    {
        public float w0;
        public float w1;
        public float w2;
        public float w3;
        public float w4;
        public float w5;
        public float w6;
        public float w7;
        public float w8;
        public float w9;
        public float w10;
        public float w11;
        public float w12;
        public float w13;
        public float w14;
    }

}

