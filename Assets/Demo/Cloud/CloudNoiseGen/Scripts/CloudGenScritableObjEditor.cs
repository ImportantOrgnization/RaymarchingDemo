using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
[CustomEditor(typeof(CloudGenScriptableObj))]
public class CloudGenScritableObjEditor : Editor
{
    private CloudGenScriptableObj obj;
    private void OnEnable()
    {
        obj = target as CloudGenScriptableObj;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Generate Noise Texture"))
        {
            var path = AssetDatabase.GetAssetPath(obj);
            path = path.Replace(obj.name + ".asset", "new3dNoise.asset");
            CloudNoiseGen.perlin = obj.noiseSettings;
            CloudNoiseGen.worley = obj.noiseSettings;
            var t3d = CloudNoiseGen.InitializeNoise( obj.noiseName, obj.resolution, obj.mode);
            AssetDatabase.CreateAsset(t3d,path);
            AssetDatabase.Refresh();
            
        }
    }
}
