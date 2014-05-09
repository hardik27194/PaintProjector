//
//  ModelEntity.m
//  PaintProjector
//
//  Created by kobunketsu on 14-5-4.
//  Copyright (c) 2014年 WenjiHu. All rights reserved.
//

#import "ModelEntity.h"
#import "MeshRenderer.h"
#import "Material.h"
#import "ShaderDiffuse.h"
#import "OpenGLWaveFrontObject.h"
#import "OpenGLWaveFrontGroup.h"
#import "OpenGLTexture3D.h"
#import "RenderSettings.h"

@implementation ModelEntity
- (id)initWithWaveFrontObj:(OpenGLWaveFrontObject *)obj{
    self = [super init];
    if (self) {
        Mesh *mesh = [[Mesh alloc]init];
        
        //map OpenGLWaveFrontObject vertex structure to specific vertex structure
        OBJVertex* vertices = [obj convertVertexStruct];    //malloc in function
        mesh.verticeCount = obj.numberOfVertices;
        mesh.triangleCount = obj.numberOfFaces;
        //subMesh数量
        for (OpenGLWaveFrontGroup *m in obj.groups) {
            [mesh.subMeshTriCounts addObject:[NSNumber numberWithInt:m.numberOfFaces]];
        }

        //组成整个triangles索引的数据组
        short *indices = (short*)malloc(obj.numberOfFaces * 3 * sizeof(short));
        for (OpenGLWaveFrontGroup *m in obj.groups) {
            //遍历三角面
            for (size_t i = 0; i< m.numberOfFaces; ++i) {
                indices[i * 3] = m.faces[i].v1;
                indices[i * 3 + 1] = m.faces[i].v2;
                indices[i * 3 + 2] = m.faces[i].v3;
//                DebugLog(@"subMesh %@ triangle index %d v1:%d v2:%d v3:%d", m.name, i, indices[i * 3], indices[i * 3 + 1] , indices[i * 3 + 2]);
            }
        }
        
        //填充模型数据
        mesh.triangles = [NSData dataWithBytesNoCopy:indices length:obj.numberOfFaces * 3 * sizeof(short) freeWhenDone:YES];
        mesh.vertices = [NSData dataWithBytesNoCopy:vertices length:obj.numberOfVertices * sizeof(OBJVertex) freeWhenDone:YES];
        mesh.vertexAttr = Vertex_Position | Vertex_Texcoord | Vertex_Normal;
        //创建模型数据到内存
        [mesh create];
        //创建模型渲染组件
        MeshFilter *meshFilter = [[MeshFilter alloc]initWithMesh:mesh];
        MeshRenderer *meshRenderer = [[MeshRenderer alloc]initWithMeshFilter:meshFilter];
        self.renderer = meshRenderer;
        self.renderer.delegate = self;
        
        //处理材质
        for (OpenGLWaveFrontGroup *glObjMesh in obj.groups) {
            OpenGLWaveFrontMaterial *glObjMat = glObjMesh.material;
            //创建材质
            ShaderDiffuse *shaderDiffuse = [[ShaderDiffuse alloc]init];
            Material *material = [[Material alloc]initWithShader:shaderDiffuse];
            if (glObjMat.texture != nil) {
                if (glObjMat.texture.filename != nil) {
                    NSString *fileExt = [glObjMat.texture.filename pathExtension];
                    NSString *fileName = [[glObjMat.texture.filename lastPathComponent]stringByDeletingPathExtension];
                    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:fileExt];
                    material.mainTexture = [Texture textureFromImagePath:path reload:true];
                }

            }
            else{

            }

            [self.renderer.sharedMaterials addObject:material];
        }
    }
    return self;
}

- (void)willRenderSubMeshAtIndex:(int)index{
    [super willRenderSubMeshAtIndex:index];
    Material *material = self.renderer.material;
    if (!material) {
        material = self.renderer.sharedMaterial;
    }
    
    [material setMatrix:Camera.current.viewProjMatrix forPropertyName:@"viewProjMatrix"];
    [material setMatrix:self.transform.worldMatrix forPropertyName:@"worldMatrix"];
    [material setVector:GLKVector4Make(-0.5, 0.5, -0.5, 0) forPropertyName:@"vLightPos"];
    [material setVector:renderSettings.Ambient forPropertyName:@"cAmbient"];
}

- (void)update{
    [super update];
    
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(self.transform.scale.x, self.transform.scale.y, self.transform.scale.z);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeWithQuaternion(self.transform.rotate);
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(self.transform.translate.x, self.transform.translate.y, self.transform.translate.z);
    
    self.transform.worldMatrix = GLKMatrix4Multiply(translateMatrix, GLKMatrix4Multiply(rotateMatrix, scaleMatrix));
}
@end