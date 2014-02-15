#extension GL_EXT_shader_framebuffer_fetch : require
uniform sampler2D smudgeTexture;
uniform sampler2D maskTexture;
uniform sampler2D noiseTexture;
uniform highp vec4 ParamsExtend;//x:使用pattern y:使用杂色 z:使用涂抹

varying lowp vec4 DestinationColor; 
varying highp vec4 oBrushParam;
varying highp vec4 oBrushParam2;

void main ( )
{
    lowp vec3 paintColor = DestinationColor.rgb;
    lowp vec3 finalColor = paintColor;
    highp float wet = oBrushParam.w;
    
    //flow
    highp float flow = DestinationColor.a;
    lowp float finalAlpha = flow;
    
    //rotation
    highp vec2 texcoord = vec2(0,0);
    highp vec2 pointCoordOffset = gl_PointCoord - vec2(0.5, 0.5);
    texcoord.x = pointCoordOffset.x * cos(oBrushParam.x) +  pointCoordOffset.y * sin(oBrushParam.x);
    texcoord.y = pointCoordOffset.y * cos(oBrushParam.x) -  pointCoordOffset.x * sin(oBrushParam.x);
    
    //round
    texcoord.y /= oBrushParam.z;
    
    //uv
    highp vec2 finalTexcoord = texcoord + vec2(0.5, 0.5);
    finalTexcoord.y = 1.0 - finalTexcoord.y;
    
   
    //blend with curPaintedLayer src_alpha src_alpha_inv
    lowp float shape = 1.0;
//#ifdef Pattern
    if (ParamsExtend.x > 0.0){
        //pattern
        shape = texture2D(maskTexture, finalTexcoord).a;
    }
//#else
    else{
        highp float distUV = length(texcoord);    //(0, 0.5)
        //hardness
        highp float hardness = oBrushParam.y;
        //需要确保 混合(0.5 - insetDistUV)有1个像素的大小 texelSize
        highp float texelSize = 1.0 / oBrushParam2.x;
        highp float blendTexelSize = texelSize;
        highp float hardAlpha = 1.0 - clamp((distUV - (0.5 - blendTexelSize)) / blendTexelSize , 0.0, 1.0);
        //mask
        highp float tcFallOff = clamp(distUV * 2.0, 0.0, 1.0);
        highp float softAlpha = texture2D(maskTexture, vec2(tcFallOff, 0.5)).r;
        shape = hardAlpha * hardness + softAlpha * (1.0 - hardness);
    }
//#endif
    finalAlpha *= shape;

    //smudge
//#ifdef Smudge
    if (ParamsExtend.z > 0.0){
        //blend smudgeColor(preAlpha) with canvasColor using wet
        lowp vec4 absorbColor = texture2D(smudgeTexture, finalTexcoord);
        highp float paintBlend = shape * flow;

        lowp vec3 mixedColor = absorbColor.rgb * wet + (1.0 - wet) * paintColor.rgb;
        lowp float mixedAlpha = absorbColor.a * wet + (1.0 - wet) ;

        finalColor.rgb = mixedColor * paintBlend + gl_LastFragData[0].rgb * (1.0 - paintBlend);
        finalAlpha = mixedAlpha * paintBlend + gl_LastFragData[0].a * (1.0 - paintBlend);
    }
//#endif
    
//#ifdef Dissolve
    if (ParamsExtend.y > 0.0){
        highp float dissolve = 1.0;
//        finalTexcoord = finalTexcoord * noiseScale + noiseOffset;
        dissolve = texture2D(noiseTexture, finalTexcoord).r;
        if (finalAlpha < dissolve) {
            finalAlpha = 0.0;
        }
    }
//#endif
    
    //debug
    gl_FragColor = vec4(finalColor.rgb, finalAlpha);
}

