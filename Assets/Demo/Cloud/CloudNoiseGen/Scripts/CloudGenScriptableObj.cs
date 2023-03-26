using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[CreateAssetMenu(fileName = "createNoise",menuName = "Create/Gen3DNoiseTexture")]
public class CloudGenScriptableObj : ScriptableObject
{
    public string noiseName = "customNoiseName";
    public int resolution = 32;
    public CloudNoiseGen.Mode mode;
    public CloudNoiseGen.NoiseSettings noiseSettings;
    
}
