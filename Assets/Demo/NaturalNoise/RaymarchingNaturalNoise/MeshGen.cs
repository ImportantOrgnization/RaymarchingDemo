using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshGen : MonoBehaviour
{
    public int size = 1025;
    private Mesh mesh;
    public Material material;
    private void OnEnable()
    {
        if (!mesh)
        {
            List<Vector3> vertices = new List<Vector3>();
            List<int> indices = new List<int>();
            List<Vector2> uvs = new List<Vector2>();
            var tempVar = - (float) size / 2;
            var bottomLeft = new Vector3(tempVar,0,tempVar);
            for (int iz = 0; iz < size; iz++)
            {
                for (int ix = 0; ix < size; ix++)
                {
                    var worldPos = bottomLeft + new Vector3(ix, 0, iz);
                    vertices.Add(worldPos);

                    var uv = new Vector2((float) ix / size, (float) iz / size);
                    uvs.Add(uv);
                }
            }

            for (int iz = 0; iz < size - 1; iz++)
            {
                for (int ix = 0; ix < size - 1; ix++)
                {
                    var orig = iz * size + ix;
                    var top = orig + size;
                    var topRight = top + 1;
                    var right = orig + 1;
                    indices.Add(orig);
                    indices.Add(top);
                    indices.Add(right);
                    indices.Add(top);
                    indices.Add(topRight);
                    indices.Add(right);
                }
            }
            
            Mesh newMesh = new Mesh();
            newMesh.SetVertices(vertices);
            newMesh.SetIndices(indices,MeshTopology.Triangles,0,true);
            newMesh.SetUVs(0,uvs);
            newMesh.RecalculateNormals();
            this.mesh = mesh;

            if (!this.GetComponent<MeshFilter>())
            {
                this.gameObject.AddComponent<MeshFilter>();
            }

            if (!this.GetComponent<MeshRenderer>())
            {
                this.gameObject.AddComponent<MeshRenderer>();
            }

            var mf = this.GetComponent<MeshFilter>();
            var mr = this.GetComponent<MeshRenderer>();
            mf.sharedMesh = mesh;
            mr.sharedMaterial = material;
        }
    }
}
