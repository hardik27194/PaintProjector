//
//  CylinderProjectViewController.m
//  PaintProjector
//
//  Created by 胡 文杰 on 13-7-21.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "CylinderProjectViewController.h"
#import "Resources.h"
#import "UIView+Tag.h"
@interface CylinderProjectViewController ()

@property (assign, nonatomic)GLKVector2 touchDirectionBegin;
@property (assign, nonatomic)float translateImageX;//圆柱体中图片横向移动

//VC切换动画效果管理器
@property (nonatomic) PaintScreenTransitionManager *transitionManager;
@end

@implementation CylinderProjectViewController

//core motion

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    DebugLog(@"initWithCoder");
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    DebugLog(@"[ viewWillAppear ]");
    //用于解决启动闪黑屏的问题
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"launchImage2.png"]];
    
    DebugLog(@"setupInputParams");
    [self setupInputParams];
    
    [self setupGL];
    
    [self setupScene];
    
    //run completion block
    [self allViewUserInteractionEnable:true];
}

- (void)viewDidAppear:(BOOL)animated{
    DebugLog(@"[ viewDidAppear ]");
    //screenmask遮罩问题
//    self.screenMask.hidden = false;
}

-(void)viewWillDisappear:(BOOL)animated{
    DebugLog(@"[ viewWillDisappear ]");
}

-(void)viewDidDisappear:(BOOL)animated{
    DebugLog(@"[ viewDidDisappear ]");
    [self tearDownGL];
}

- (void)viewDidLoad
{
    DebugLog(@"[ viewDidLoad ]");
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //通知注册事件对app退到后台进行响应
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(willResignActiveNotification:)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [self allViewUserInteractionEnable:true];
    
    self.transitionManager = [[PaintScreenTransitionManager alloc]init];
    self.transitionManager.delegate = self;
    
    //创建glkViewController
    self.glkViewController = [[GLKViewController alloc]init];
    self.glkViewController.view = self.projectView;
    self.glkViewController.delegate = self;
    // then add the glkview as the subview of the parent view
    //    [self.view addSubview:_myGlkViewController.view];
    // add the glkViewController as the child of self
    [self addChildViewController:self.glkViewController];
    [self.glkViewController didMoveToParentViewController:self];
    

    //创建context
    self.context = [self createBestEAGLContext];
    [self.context setDebugLabel:@"CylinderProjectView Context"];
    
    self.projectView.context = self.context;
    self.projectView.delegate = self;
    
    self.browseNextAction = [[CustomPercentDrivenInteractiveTransition alloc]init];
    self.browseNextAction.delegate = self;
    self.browseNextAction.name = @"browseNext";
    self.browseLastAction = [[CustomPercentDrivenInteractiveTransition alloc]init];
    self.browseLastAction.delegate = self;
    self.browseLastAction.name = @"browseLast";
    
    //TODO: 关闭水平监测，查内存持续增长问题
//    [self initMotionDetect];
}

- (void)viewDidUnload{
    DebugLog(@"[ viewDidUnload ]");
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    DebugLog(@"[ dealloc ]");
}


#pragma mark- 主程序
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
-(void)willResignActiveNotification:(id)sender{
//    DebugLog(@"willResignActiveNotification sender:%@", sender);
    self.playTime = [self.player currentTime];
}
-(void)didEnterBackgroundNotification{
    DebugLog(@"didEnterBackgroundNotification");
}

#pragma mark- 工具栏
- (void)transitionToGallery{
    //打开从paintCollectionVC transition 时添加的view
    UIImageView *tempView = (UIImageView *)[self.view subViewWithTag:100];
    if (tempView) {
        //刷新的当前图片
        NSString *path = [[Ultility applicationDocumentDirectory]stringByAppendingPathComponent:self.paintFrameViewGroup.curPaintDoc.thumbImagePath];
        tempView.image = [UIImage imageWithContentsOfFile:path];
        [UIView animateWithDuration:0.5 animations:^{
            tempView.alpha = 1;
        }completion:^(BOOL finished) {
        }];
    }
    
    TPPropertyAnimation *animClip = [self.cylinderProjectCur.animation.clips valueForKey:@"fadeOutAnimClip"];
    self.cylinderProjectCur.animation.clip = animClip;
    [self.cylinderProjectCur.animation play];
}

- (IBAction)galleryButtonTouchUp:(id)sender {
    //do some work
    if (self.topViewButton.hidden) {
        self.topViewButton.hidden = false;
        self.sideViewButton.hidden = true;

        TPPropertyAnimation *animClip = [Camera.mainCamera.animation.clips valueForKey:@"topToBottomAnimClip"];
        [animClip setCompletionBlock:^{
            [self transitionToGallery];
        }];
        Camera.mainCamera.animation.clip = animClip;
        Camera.mainCamera.animation.target = self;
        [Camera.mainCamera.animation play];
    }
    else{
        [self transitionToGallery];
    }
}

- (IBAction)printButtonTouchUp:(UIButton *)sender {
    [self exportToAirPrint];
}

- (IBAction)shareButtonTouchUp:(UIButton *)sender {
}

- (void)transitionToPaint{
    TPPropertyAnimation *clip = [self.cylinder.animation.clips valueForKey:@"reflectionFadeInOutAnimClip"];
    clip.duration = 0.5;
    clip.fromValue = [NSNumber numberWithFloat:1];
    clip.toValue = [NSNumber numberWithFloat:0];
    [self.cylinder.animation play];
    
    //变换动画
    //更新临时view
    NSString *path = [self.paintFrameViewGroup curPaintDoc].thumbImagePath;
    path = [[Ultility applicationDocumentDirectory] stringByAppendingPathComponent:path];
    ImageView *tempImageView = (ImageView *)[self.view subViewWithTag:100];
    tempImageView.image = nil;
    tempImageView.image = [UIImage imageWithContentsOfFile:path];
    tempImageView.alpha = 0;
    [UIView animateWithDuration:0.5 animations:^{
        tempImageView.alpha = 1;
    }completion:^(BOOL finished) {
    }];
    
    //确定fromView的锚点，和放大缩小的尺寸
    CGRect rect = [self willGetCylinderMirrorFrame];
    CGFloat scale = self.view.frame.size.width / rect.size.width;
    CGPoint rectCenter = CGPointMake(rect.origin.x + rect.size.width * 0.5, rect.origin.y + rect.size.height * 0.5);
    rectCenter = CGPointMake(rectCenter.x, rectCenter.y - 27);
    UIView *fromView = self.view;
    fromView.layer.anchorPoint = CGPointMake(rectCenter.x / fromView.frame.size.width, rectCenter.y / fromView.frame.size.height);
    fromView.layer.position = rectCenter;
    
    [UIView animateWithDuration:0.8 animations:^{
        [fromView.layer setValue:[NSNumber numberWithFloat:scale] forKeyPath:@"transform.scale"];
    } completion:^(BOOL finished) {
        [self openPaintDoc:self.paintFrameViewGroup.curPaintDoc];
    }];
    
}

- (IBAction)paintButtonTouchUp:(UIButton *)sender {
    //do some work
    if (self.topViewButton.hidden) {
        self.topViewButton.hidden = false;
        self.sideViewButton.hidden = true;
        
        TPPropertyAnimation *animClip = [Camera.mainCamera.animation.clips valueForKey:@"topToBottomAnimClip"];
        [animClip setCompletionBlock:^{
            [self transitionToPaint];
        }];
        Camera.mainCamera.animation.clip = animClip;
        Camera.mainCamera.animation.target = self;
        [Camera.mainCamera.animation play];
    }
    else{
        [self transitionToPaint];
    }
}


#pragma mark- 内容CylinderProject View
- (void)setupInputParams{
    //根据ipad2的尺寸进行设定
    self.inputCylinderRadius = 0.019;
    //设定虚拟平面
    self.inputCylinderImageWidth = 0.037;
    self.inputCylinderImageCenterOnSurfHeight = 0.035; //default 0.035
    
}

-(void)initSceneCameras{
    float eyeTopZ = -0.065;
    self.eyeBottom = GLKVector3Make(0, 0.4, -0.35);//GLKVector3Make(0, 0.4, -0.35)
    //顶视图视口比例
    self.eyeTopAspect = fabsf(self.projectView.bounds.size.width / (self.projectView.bounds.size.height + ToSeeCylinderTopPixelOffset));
    
    Camera.mainCamera.name = @"mainCamera";
    Camera.mainCamera.position = self.eyeBottom;
    Camera.mainCamera.focus = GLKVector3Make(0, 0, eyeTopZ);
    
    //如果中心点反向，则up向量反向
    if (Camera.mainCamera.focus.z >= 0) {
        Camera.mainCamera.up = GLKVector3Make(0, 0, -1);
    }
    else{
        Camera.mainCamera.up = GLKVector3Make(0, 0, 1);
    }
    Camera.mainCamera.nearClip = NearClipDistance;
    Camera.mainCamera.farClip = FarClipDistance;
    Camera.mainCamera.aspect = self.eyeTopAspect;
    Camera.mainCamera.fov = GLKMathDegreesToRadians(29);
    Camera.mainCamera.backgroundColor = GLKVector4Make(90.0/255.0, 230.0/255.0, 71.0 / 255.0, 1);
    Camera.mainCamera.cullingMask = Culling_Everything;
    self.bottomCameraProjMatrix = Camera.mainCamera.projMatrix;
    
    self.eyeTop = GLKVector3Make(0, -self.eyeBottom.z, eyeTopZ);
    float orthoWidth = DeviceWidth;
    float orthoHeight = DeviceWidth / self.eyeTopAspect;
    
    self.topCamera = [[Camera alloc]initOrthorWithPosition:self.eyeTop
                                                     focus:GLKVector3Make(0, 0, eyeTopZ)
                                                        up:GLKVector3Make(0, 0, 1)
                                                orthoWidth:orthoWidth
                                               orthoHeight:orthoHeight
                                                  nearClip:NearClipDistance
                                                   farClip:FarClipDistance];
    
    self.topCamera.name = @"topCamera";
    RenderTexture *renderTex = [[RenderTexture alloc]initWithWidth:1024 height:1024];
    [renderTex create];
    self.topCamera.targetTexture = renderTex;
    self.topCamera.cullingMask = Culling_Reflection;
    
    //add camera by rendering sequence
    [self.curScene addCamera:self.topCamera];
    [self.curScene addCamera:Camera.mainCamera];
    
    self.eyeBottomTopBlend = 0.0;
    
    TPPropertyAnimation *topToBottomAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"eyeBottomTopBlend"];
    topToBottomAnimClip.name = @"topToBottomAnimClip";
    topToBottomAnimClip.delegate = self;
    topToBottomAnimClip.fromValue = [NSNumber numberWithFloat:1];
    topToBottomAnimClip.toValue = [NSNumber numberWithFloat:0];
    topToBottomAnimClip.duration = 1;
    topToBottomAnimClip.timing = TPPropertyAnimationTimingEaseOut;
    Camera.mainCamera.animation = [Animation animationWithAnimClip:topToBottomAnimClip];
    
    TPPropertyAnimation *bottomToTopAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"eyeBottomTopBlend"];
    bottomToTopAnimClip.name = @"bottomToTopAnimClip";
    bottomToTopAnimClip.delegate = self;
    bottomToTopAnimClip.fromValue = [NSNumber numberWithFloat:0];
    bottomToTopAnimClip.toValue = [NSNumber numberWithFloat:1];
    bottomToTopAnimClip.duration = 1;
    bottomToTopAnimClip.timing = TPPropertyAnimationTimingEaseOut;
    [Camera.mainCamera.animation addClip:bottomToTopAnimClip];
}

- (void)createCylinder{
    //create cylinder
    ShaderCylinder *shaderCylinder = [[ShaderCylinder alloc]init];
    Material *matMain = [[Material alloc]initWithShader:shaderCylinder];
    Texture *texMain = [[Texture alloc]init];
    texMain.texID = [TextureManager textureInfoFromImageName:@"cylinderMain.png" reload:false].name;
    matMain.mainTexture = texMain;
    CylinderMesh *mesh = [[CylinderMesh alloc]initWithRadius:self.inputCylinderRadius sides:60 height:0.068];
    [mesh create];
    MeshFilter *meshFilter = [[MeshFilter alloc]initWithMesh:mesh];
    MeshRenderer *meshRenderer = [[MeshRenderer alloc]initWithMeshFilter:meshFilter];
    meshRenderer.sharedMaterial = matMain;
    
    //cap
    //    BaseEffect *effect = [[BaseEffect alloc]init];
    ShaderNoLitTexture *shaderNoLitTex = [[ShaderNoLitTexture alloc]init];
    Material *matCap = [[Material alloc]initWithShader:shaderNoLitTex];
    Texture *texCap = [[Texture alloc]init];
    texCap.texID = [TextureManager textureInfoFromImageName:@"cylinderCap.png" reload:false].name;
    matCap.mainTexture = texCap;
    [meshRenderer.sharedMaterials addObject:matCap];
    
    Cylinder *cylinder = [[Cylinder alloc]init];
    cylinder.name = @"cylinder";
    cylinder.renderer = meshRenderer;
    cylinder.layerMask = Layer_Default;
    cylinder.eye = Camera.mainCamera.position;
    cylinder.reflectionTex = self.topCamera.targetTexture;
    cylinder.reflectionTexUVSpace = GLKVector4Make(self.topCamera.focus.x - self.topCamera.orthoWidth * 0.5,
                                                   self.topCamera.focus.y - self.topCamera.orthoHeight * 0.5 + self.topCamera.position.z,
                                                   self.topCamera.orthoWidth,
                                                   self.topCamera.orthoHeight);
    meshRenderer.delegate = cylinder;
    
    TPPropertyAnimation *clip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"reflectionStrength"];
    clip.name = @"reflectionFadeInOutAnimClip";
    clip.delegate = self;
    clip.timing = TPPropertyAnimationTimingEaseInEaseOut;
    clip.target = cylinder;
    
    Animation *anim = [Animation animationWithAnimClip:clip];
    cylinder.animation = anim;
    
    self.cylinder = cylinder;
    [self.curScene addEntity:cylinder];
    
}

- (void)createCylinderProject{
    
    ShaderCylinderProject *shaderCylinderProject = [[ShaderCylinderProject alloc]init];
    Material *matCylinderProject = [[Material alloc]initWithShader:shaderCylinderProject];
    
    NSString *path = [[Ultility applicationDocumentDirectory] stringByAppendingPathComponent:self.paintFrameViewGroup.curPaintDoc.thumbImagePath];
    matCylinderProject.mainTexture = [Texture textureFromImagePath:path reload:true];
    PlaneMesh *planeMesh = [[PlaneMesh alloc]initWithRow:100 column:100];
    [planeMesh create];
    MeshFilter *meshFilter = [[MeshFilter alloc]initWithMesh:planeMesh];
    MeshRenderer *meshRenderer = [[MeshRenderer alloc]initWithMeshFilter:meshFilter];
    meshRenderer.sharedMaterial = matCylinderProject;
    
    CylinderProject *cylinderProject = [[CylinderProject alloc]init];

    cylinderProject.name = @"cylinderProject";
    cylinderProject.renderer = meshRenderer;
    cylinderProject.radius = self.inputCylinderRadius;
    cylinderProject.eye = Camera.mainCamera.position;
    cylinderProject.imageWidth = self.inputCylinderImageWidth;
    cylinderProject.imageCenterOnSurfHeight = self.inputCylinderImageCenterOnSurfHeight;
    cylinderProject.imageRatio = self.view.bounds.size.height / self.view.bounds.size.width;
    cylinderProject.layerMask = Layer_Reflection;
    cylinderProject.alphaBlend = self.cylinderProjectDefaultAlphaBlend;
    
    TPPropertyAnimation *fadeInAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"alphaBlend"];
    fadeInAnimClip.name = @"fadeInAnimClip";
    fadeInAnimClip.delegate = self;
    fadeInAnimClip.toValue = [NSNumber numberWithFloat:1];
    fadeInAnimClip.fromValue = [NSNumber numberWithFloat:0];
    fadeInAnimClip.duration = 1;
    fadeInAnimClip.timing = TPPropertyAnimationTimingEaseOut;

    
    Animation *anim = [Animation animationWithAnimClip:fadeInAnimClip];
    cylinderProject.animation = anim;
    
    TPPropertyAnimation *fadeOutAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"alphaBlend"];
    fadeOutAnimClip.name = @"fadeOutAnimClip";
    fadeOutAnimClip.delegate = self;
    fadeOutAnimClip.toValue = [NSNumber numberWithFloat:0];
    fadeOutAnimClip.fromValue = [NSNumber numberWithFloat:1];
    fadeOutAnimClip.duration = 1;
    fadeOutAnimClip.timing = TPPropertyAnimationTimingEaseOut;
    [fadeOutAnimClip setCompletionBlock:^{
        [self.delegate willTransitionToGallery];
    }];

    [anim addClip:fadeOutAnimClip];
    
    
    TPPropertyAnimation *browseAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"translateX"];
    browseAnimClip.name = @"browseAnimClip";
    browseAnimClip.delegate = self;
    browseAnimClip.timing = TPPropertyAnimationTimingEaseOut;
    [anim addClip:browseAnimClip];
  
    
    meshRenderer.delegate = cylinderProject;
    self.cylinderProjectCur = cylinderProject;
    [self.curScene addEntity:cylinderProject];
    
}

- (void)setupScene {
    
    DebugLog(@"init Scene");
    Scene *scene = [[Scene alloc]init];
    self.curScene = scene;
    
    DebugLog(@"init Scene Cameras");
    [self initSceneCameras];
    
    //设定输入图片参数
//    if (self.paintFrameViewGroup.curPaintDoc != nil) {
//        NSString *path = [[Ultility applicationDocumentDirectory] stringByAppendingPathComponent:self.paintFrameViewGroup.curPaintDoc.thumbImagePath];
//        self.paintTexture = [Texture textureFromImagePath:path reload:true];
//    }
    
    DebugLog(@"init Scene Entities ");
    [self createCylinderProject];
    
    [self createCylinder];
    
    [self initOtherParams];
    
    [self.curScene flushAll];
    DebugLog(@"init Scene finished");
    
    DebugLog(@"updateRenderViewParams");
    [self updateRenderViewParams];
}

-(void)initOtherParams{

}

#pragma mark- 操作主屏幕CylinderProject View
- (void)rotateViewInAxisX:(float)percent{
    self.eyeBottomTopBlend = MIN(1, MAX(0, self.toEyeBottomTopBlend + percent));
}

- (CGFloat)getPercent:(UIPanGestureRecognizer *)sender{
//    CGFloat fullTranslation = 200;
//    float percent = fabsf(translation.x) / fullTranslation;
//    percent = MAX(0, MIN(percent, 1));
//
    CGPoint center = self.view.center;
    CGPoint touchPoint =  [sender locationInView:self.view];
    GLKVector2 touchDirection = GLKVector2Make(touchPoint.x - center.x, touchPoint.y - center.y);
    touchDirection = GLKVector2Normalize(touchDirection);
    
    CGFloat angle = acosf(GLKVector2DotProduct(touchDirection, self.touchDirectionBegin));
    CGFloat percent = MAX(0, MIN(angle / (M_PI) , 1));
    
    return percent;
}

- (IBAction)handlePanCylinderProjectView:(UIPanGestureRecognizer *)sender {
    //顶视图模式下忽略圆柱体区域的触摸手势
    if (!self.sideViewButton.hidden) {
        //ignoreCylinderRectTouch
        CGPoint location = [sender locationInView:sender.view];
        CGRect cylinderTopRect = [self getCylinderMirrorTopFrame];
        if(CGRectContainsPoint(cylinderTopRect, location)){
            return;
        }
    }
    
    CGPoint touchPoint = CGPointZero;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            touchPoint = [sender locationInView:self.view];
            self.touchDirectionBegin = GLKVector2Make(touchPoint.x - self.view.center.x, touchPoint.y - self.view.center.y);
            self.touchDirectionBegin = GLKVector2Normalize(self.touchDirectionBegin);
        }
            break;
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [sender translationInView:sender.view];
            CGFloat percent = 0.0;
            if (translation.x > 0) {
                if (self.browseLastAction.interactionEnable) {
//                    DebugLog(@"browse last");
                    percent = [self getPercent:sender];
                    [self.browseLastAction updateInteractiveTransition:percent];
                }
 
            }
            else if (translation.x < 0) {
                if (self.browseNextAction.interactionEnable) {
//                    DebugLog(@"browse next");
                    percent = [self getPercent:sender];
                    [self.browseNextAction updateInteractiveTransition:percent];
                }
            }
        }
            break;
        case UIGestureRecognizerStateEnded:{
            CGFloat percent;
            CGPoint translation = [sender translationInView:sender.view];
            if (translation.x > 0) {
//                DebugLog(@"end browse last");
                percent = [self getPercent:sender];
                if (percent > self.browseLastAction.completeThresold) {
                    if ([self.paintFrameViewGroup lastPaintDoc]) {
                        [self.browseLastAction finishInteractiveTransition];
                    }
                    else{
                        [self.browseLastAction cancelInteractiveTransition];
                    }
                }
                else{
                    [self.browseLastAction cancelInteractiveTransition];
                }
            }
            else if (translation.x < 0) {
//                DebugLog(@"end browse next");
                percent = [self getPercent:sender];
                if (percent > self.browseNextAction.completeThresold) {
                    if ([self.paintFrameViewGroup nextPaintDoc]) {
                        [self.browseNextAction finishInteractiveTransition];
                    }
                    else{
                        [self.browseNextAction cancelInteractiveTransition];
                    }
                }
                else{
                    [self.browseNextAction cancelInteractiveTransition];
                }
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:{
        }
            break;
        default:
            break;
    }
}

#pragma mark- 绘图设置



- (void)updateRenderViewParams{
    Camera.mainCamera.position = GLKVector3Lerp(self.eyeBottom, self.eyeTop, self.eyeBottomTopBlend);
    GLKMatrix4 matrix = [Ultility MatrixLerpFrom:self.bottomCameraProjMatrix to:self.topCamera.projMatrix blend:self.eyeBottomTopBlend];
    Camera.mainCamera.projMatrix = matrix;
}

#pragma mark- 更新
- (void)glkViewControllerUpdate:(GLKViewController *)controller{
//    DebugLog(@"glkViewControllerUpdate");

    //重新设置投影地面的参数
    [self updateRenderViewParams];
    
    [self.curScene update];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
//    DebugLog(@"drawInRect");
    [self.curScene render];
}

#pragma mark- Opengles Shader相关
-(EAGLContext *)createBestEAGLContext{
    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (context == nil) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if(context == nil){
            DebugLog(@"Failed to create ES context");
        }
    }
    
    return context;
}

- (void)initGLState{
    glViewport(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    [GLWrapper.current blendFunc:BlendFuncAlphaBlendPremultiplied];
}

- (void)setupGL {
    DebugLog(@"setupGL");
    
    [GLWrapper initialize];
    
    [EAGLContext setCurrentContext:self.context];
    [self initGLState];
    
    [Resources initialize];
    
    [TextureManager initialize];

    Display.main = [[Display alloc]initWithGLKView:self.projectView];
}

- (void)tearDownGL {
    DebugLog(@"tearDownGL");
    
    [GLWrapper destroy];
    
    [EAGLContext setCurrentContext:self.context];
    
    [Resources unloadAllAsset];
    
    [TextureManager destroy];
    
    Display.main = nil;
    
    Camera.mainCamera = nil;
    
}

#pragma mark- UI动画
- (void)allViewUserInteractionEnable:(BOOL)enable{
    for (UIView* view in self.allViews) {
        view.userInteractionEnabled = enable;
    }
}

- (void)switchDownToolBarFrom:(DownToolBar*)fromView completion: (void (^) (void))block1 to:(DownToolBar*)toView completion: (void (^) (void)) block2{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (fromView != NULL) {
            fromView.center = CGPointMake(fromView.center.x, self.view.bounds.size.height + fromView.bounds.size.height * 0.5);
        }
    }completion:^(BOOL finished){//显示TransformBar
        if (block1 != NULL) {
            block1();
        }
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (toView != NULL) {
                toView.center = CGPointMake(toView.center.x, self.view.bounds.size.height - toView.bounds.size.height * 0.5);
            }
        }completion:^(BOOL finished){
            if (block2 != NULL) {
                block2();
            }
        }];
    }];
}

#pragma mark- 核心变换
//-(void)viewPaintDoc:(PaintDoc*)paintDoc{
//    self.curPaintDoc = paintDoc;
//    //TODO:导致CylinderProject dismiss后不能被release
//    //TODO:当新建图片时thumbImage为nil,而thumbImagePath有数值
//    if (self.paintTexture) {
//        self.paintTexture.texID = [TextureManager textureInfoFromFileInDocument:paintDoc.thumbImagePath reload:true].name;
//    }
//}

//主题Logo
//- (void)loadLogoWithAnimation:(BOOL)anim{
//}

- (void)reloadLogo{
}


//在project plane上生成图片
-(void)closeImage{

}

//在project plane上生成视频影像
-(void)anamorphVideo{
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"Collection/jerryfish1" withExtension:@"mov"];
    
    self.asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    [self generateImage];

    self.playState = PS_Stopped;
}
#pragma mark- 视频
- (IBAction)playbackButtonTouchUp:(UIButton *)sender {
    [self.player play];
}

- (void)textureFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
//    glBindTexture(GL_TEXTURE_2D, self.paintTexture);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 520, 520, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
//    self.paintTexture.texID = [TextureManager textureInfoFromCGImage:newImage].name;
    
    CGImageRelease(newImage);
}

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }
    
    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
    CGImageCreate(width, height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create and return an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

- (void) readNextMovieFrame
{
    //readNextMovieFrame
    switch (self.assetReader.status) {
        case AVAssetReaderStatusReading:{
//            DebugLog(@"AVAssetReaderStatusReading");
            AVAssetReaderTrackOutput * output = [self.assetReader.outputs objectAtIndex:0];
            CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
            if (sampleBuffer)
            {
                [self textureFromSampleBuffer:sampleBuffer];
                
                CMSampleBufferInvalidate(sampleBuffer);
                CFRelease(sampleBuffer);
                sampleBuffer = NULL;
            }
            else{
                //退到后台会导致output copyNextSampleBuffer null
                DebugLog(@"no sampleBuffer");
            }
        }
            break;
        case AVAssetReaderStatusCompleted:{
            DebugLog(@"AVAssetReaderStatusCompleted");
            self.assetReader = nil;
            
            //loop循环播放
            dispatch_async(dispatch_get_main_queue(),^{
                [self readMovie];
            });
        }
        case AVAssetReaderStatusFailed:{
            DebugLog(@"AVAssetReaderStatusFailed: %@", [self.assetReader.error description]);
            //退到后台会导致Failed
            self.assetReader = nil;
            
            //loop循环播放
            dispatch_async(dispatch_get_main_queue(),^{
                [self readMovie];
            });
        }
            break;                                    
        case AVAssetReaderStatusCancelled:{
            self.assetReader = nil;
        }
            break;            
        default:
            break;
    }
}

- (void)readMovie{
    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    if (tracks.count == 1) {
        AVAssetTrack *track = [tracks objectAtIndex:0];
        NSMutableDictionary* videoSettings = [[NSMutableDictionary alloc] init];
        [videoSettings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        //audio
//        [videoSettings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:videoSettings];
        NSError * error = nil;
        self.assetReader = [[AVAssetReader alloc]initWithAsset:self.asset error:&error];
        if (error){
            DebugLog(@"Error loading file: %@", [error localizedDescription]);
        }
        
        [self.assetReader addOutput:output];
        //test
        Float64 durationSeconds = CMTimeGetSeconds([self.asset duration]);
        self.assetReader.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(durationSeconds * 0.67, 24), CMTimeMakeWithSeconds((durationSeconds/3.0), 24));
        
        if ([self.assetReader startReading]) {
            self.playState = PS_Playing;
            [self.playButton setIsPlaying:true];
        }
        else{
            DebugLog(@"assetReader startReading failed");
        }
    }
    //audio
    NSError *error;
    
    AVKeyValueStatus status = [self.asset statusOfValueForKey:@"tracks" error:&error];
    
    if (status == AVKeyValueStatusLoaded) {
        self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
        [self.playerItem addObserver:self forKeyPath:@"status"
                             options:0 context:&ItemStatusContext];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.playerItem];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self.player play];
    }
    else {
        // You should deal with the error appropriately.
        DebugLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
    }
    
//    NSArray *soundTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
//    if (soundTracks.count >=1) {
//        AVAssetTrack *soundTrack = [soundTracks objectAtIndex:0];
//
//    }
}

//截取静态图片
-(void)generateImage{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self.asset];
    
//    Float64 durationSeconds = CMTimeGetSeconds([self.asset duration]);
//    CMTime midpoint = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
    CMTime midpoint = CMTimeMakeWithSeconds( 0.0, 600);
    NSError *error;
    CMTime actualTime;
    
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
    
    if (halfWayImage != NULL) {
        
        NSString *actualTimeString = (__bridge NSString *)CMTimeCopyDescription(NULL, actualTime);
        NSString *requestedTimeString = (__bridge NSString *)CMTimeCopyDescription(NULL, midpoint);
        DebugLog(@"Got halfWayImage: Asked for %@, got %@", requestedTimeString, actualTimeString);
        
        // Do something interesting with the image.
        UIImage *image = [UIImage imageWithCGImage:halfWayImage];
//        self.paintTexture.texID = [TextureManager textureInfoFromUIImage:image].name;
//        self.testImageView.backgroundColor = [UIColor colorWithPatternImage:image];
        
        CGImageRelease(halfWayImage);
    }
}

- (void)playVideo{
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^() {
        dispatch_async(dispatch_get_main_queue(),^{
            [self readMovie];
        });
    }];

}
- (void)stopVideo{
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^() {
        dispatch_async(dispatch_get_main_queue(),^{
            [self readMovie];
        });
    }];
    
}

- (void)pauseVideo{
    [self.assetReader cancelReading];
    [self.player pause];
    self.playState = PS_Pause;
    [self.playButton setIsPlaying:false];
}

- (IBAction)playButtonTouchUp:(UIButton *)sender {
    if (self.playState == PS_Stopped) {
        [self playVideo];
    }
    else if (self.playState == PS_Playing) {
        [self pauseVideo];
    }
    else if (self.playState == PS_Pause) {
        [self playVideo];
    }
}

- (void)flushAllUI {
    if(self.eyeBottomTopBlend > 0.0){
        self.topViewButton.hidden = true;
        self.sideViewButton.hidden = false;
    }
    else{
        self.topViewButton.hidden = false;
        self.sideViewButton.hidden = true;
    }
//    [self syncPlayUI];
}

- (void)syncPlayUI {
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    }
    else {
        self.playButton.enabled = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncPlayUI];
                       });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}

- (CGRect)getCylinderMirrorFrame{
    return CGRectMake(311, 300, 145, 145 / 3.0 * 4.0);
}

- (CGRect)getCylinderMirrorTopFrame{
    CGFloat margin = 5;
    return CGRectMake(289 - margin, 220 - margin, 192 + margin * 2, 192 + margin * 2);
}

- (CylinderProject*)dequeueReusableCylinderProject{
    for (Entity *entity in self.curScene.aEntities) {
        if ([entity isKindOfClass:[CylinderProject class]]) {
            CylinderProject *cylinderProject = (CylinderProject *)entity;
            if (!cylinderProject.isActive) {
                cylinderProject.active = true;
                return cylinderProject;
            }
        }
    }
    
    //no inactive cylinderProject, alloc new
    DebugLog(@"no inactive cylinderProject, alloc new");
    CylinderProject *cylinderProjectCopy = [self.cylinderProjectCur copy];
    cylinderProjectCopy.name = @"cylinderProjectCopy";
    [self.curScene addEntity:cylinderProjectCopy];
    
    return cylinderProjectCopy;
}

#pragma mark- CustomPercentDrivenInteractiveTransition
- (void)willUpdatingInteractiveTransition:(CustomPercentDrivenInteractiveTransition*)transition{
//    DebugLog(@"willUpdatingInteractiveTransition");
    if ([transition.name isEqualToString:@"browseNext"]) {
//        DebugLog(@"browsing Next");
        self.cylinderProjectCur.translateX = transition.percentComplete * self.cylinderProjectCur.imageWidth;
        
        //查询是否有下一张图片
        if ([self.paintFrameViewGroup nextPaintDoc]) {
            //清空上一张图片资源
            self.cylinderProjectLast.active = false;
            self.cylinderProjectLast = nil;
            
            if (!self.cylinderProjectNext) {
                self.cylinderProjectNext = [self dequeueReusableCylinderProject];
                TPPropertyAnimation *browseAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"translateX"];
                browseAnimClip.name = @"browseAnimClip";
                browseAnimClip.delegate = self;
                browseAnimClip.timing = TPPropertyAnimationTimingEaseOut;
                [self.cylinderProjectNext.animation removeClip:@"browseAnimClip"];
                [self.cylinderProjectNext.animation addClip:browseAnimClip];
                
                
                NSString *path = [self.paintFrameViewGroup nextPaintDoc].thumbImagePath;
                path = [[Ultility applicationDocumentDirectory] stringByAppendingPathComponent:path];
                self.cylinderProjectNext.renderer.material.mainTexture = [Texture textureFromImagePath:path reload:false];
            }
            
            self.cylinderProjectNext.translateX = (transition.percentComplete - 1) * self.cylinderProjectCur.imageWidth;
        }
        
    }
    else if ([transition.name isEqualToString:@"browseLast"]) {
//        DebugLog(@"browsing Last");
        self.cylinderProjectCur.translateX = -transition.percentComplete * self.cylinderProjectCur.imageWidth;
        
        //查询是否有上一张图片
        if ([self.paintFrameViewGroup lastPaintDoc]) {
            //清空下一张图片资源
            self.cylinderProjectNext.active = false;
            self.cylinderProjectNext = nil;
            
            if (!self.cylinderProjectLast) {
                self.cylinderProjectLast = [self dequeueReusableCylinderProject];
                TPPropertyAnimation *browseAnimClip = [TPPropertyAnimation propertyAnimationWithKeyPath:@"translateX"];
                browseAnimClip.name = @"browseAnimClip";
                browseAnimClip.delegate = self;
                browseAnimClip.timing = TPPropertyAnimationTimingEaseOut;
                [self.cylinderProjectLast.animation removeClip:@"browseAnimClip"];
                [self.cylinderProjectLast.animation addClip:browseAnimClip];
                
                
                NSString *path = [self.paintFrameViewGroup lastPaintDoc].thumbImagePath;
                path = [[Ultility applicationDocumentDirectory] stringByAppendingPathComponent:path];
                self.cylinderProjectLast.renderer.material.mainTexture = [Texture textureFromImagePath:path reload:false];
                
            }
            
            self.cylinderProjectLast.translateX = -(transition.percentComplete - 1) * self.cylinderProjectCur.imageWidth;
        }
    }
}

- (void)willFinishInteractiveTransition:(CustomPercentDrivenInteractiveTransition*)transition completion: (void (^)(void))completion{
    DebugLog(@"willFinishInteractiveTransition");
    
    TPPropertyAnimation *curClip = [self.cylinderProjectCur.animation.clips valueForKey:@"browseAnimClip"];

    if ([transition.name isEqualToString:@"browseNext"]) {
        curClip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectCur.translateX];
        curClip.toValue = [NSNumber numberWithFloat:self.cylinderProjectCur.imageWidth];
        [curClip setCompletionBlock:^{
            DebugLog(@"browse Next anim finished");
            self.cylinderProjectCur.active = false;
            self.cylinderProjectCur = self.cylinderProjectNext;
            self.cylinderProjectNext = nil;
            self.cylinderProjectLast = nil;
            self.paintFrameViewGroup.curPaintIndex ++;
            
            completion();
        }];
        self.cylinderProjectCur.animation.clip = curClip;
        [self.cylinderProjectCur.animation play];
        DebugLog(@"playing browse Next anim");
        
        TPPropertyAnimation *nextClip = [self.cylinderProjectNext.animation.clips valueForKey:@"browseAnimClip"];
        nextClip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectNext.translateX];
        nextClip.toValue = [NSNumber numberWithFloat:0];
        self.cylinderProjectNext.animation.clip = nextClip;
        [self.cylinderProjectNext.animation play];
        
    }
    else if ([transition.name isEqualToString:@"browseLast"]) {

        curClip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectCur.translateX];
        curClip.toValue = [NSNumber numberWithFloat:-self.cylinderProjectCur.imageWidth];
        
        [curClip setCompletionBlock:^{
            DebugLog(@"browse Last anim finished");
            self.cylinderProjectCur.active = false;
            self.cylinderProjectCur = self.cylinderProjectLast;
            self.cylinderProjectNext = nil;
            self.cylinderProjectLast = nil;
            self.paintFrameViewGroup.curPaintIndex --;
            
            completion();
        }];
        self.cylinderProjectCur.animation.clip = curClip;
        [self.cylinderProjectCur.animation play];
        DebugLog(@"playing browse Last anim");
        
        TPPropertyAnimation *lastClip = [self.cylinderProjectLast.animation.clips valueForKey:@"browseAnimClip"];
        lastClip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectLast.translateX];
        lastClip.toValue = [NSNumber numberWithFloat:0];
        self.cylinderProjectLast.animation.clip = lastClip;
        [self.cylinderProjectLast.animation play];
    }
}

- (void)willCancelInteractiveTransition:(CustomPercentDrivenInteractiveTransition *)transition completion: (void (^)(void))completion{
    DebugLog(@"willCancelInteractiveTransition");
    
    TPPropertyAnimation *clip = [self.cylinderProjectCur.animation.clips valueForKey:@"browseAnimClip"];
    if ([transition.name isEqualToString:@"browseNext"]) {
        DebugLog(@"canceling browse Next");
        clip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectCur.translateX];
        clip.toValue = [NSNumber numberWithFloat:0];
        [clip setCompletionBlock:^{
            completion();
        }];
        self.cylinderProjectCur.animation.clip = clip;
        [self.cylinderProjectCur.animation play];
        
        
        TPPropertyAnimation *nextClip = [self.cylinderProjectNext.animation.clips valueForKey:@"browseAnimClip"];
        nextClip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectNext.translateX];
        nextClip.toValue = [NSNumber numberWithFloat:-self.cylinderProjectNext.imageWidth];
        self.cylinderProjectNext.animation.clip = nextClip;
        [self.cylinderProjectNext.animation play];
    }
    else if ([transition.name isEqualToString:@"browseLast"]) {
        DebugLog(@"canceling browse Last");
        clip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectCur.translateX];
        clip.toValue = [NSNumber numberWithFloat:0];
        [clip setCompletionBlock:^{
            completion();
        }];
        self.cylinderProjectCur.animation.clip = clip;
        [self.cylinderProjectCur.animation play];
        
        TPPropertyAnimation *lastClip = [self.cylinderProjectLast.animation.clips valueForKey:@"browseAnimClip"];
        lastClip.fromValue = [NSNumber numberWithFloat:self.cylinderProjectLast.translateX];
        lastClip.toValue = [NSNumber numberWithFloat:self.cylinderProjectLast.imageWidth];
        self.cylinderProjectLast.animation.clip = lastClip;
        [self.cylinderProjectLast.animation play];
    }
}

#pragma mark- TPPropertyAnimationDelegate
-(void)willBeginPropertyAnimation:(TPPropertyAnimation *)propertyAnimation{
    [self allViewUserInteractionEnable:false];
}

-(void)propertyAnimationDidFinish:(TPPropertyAnimation *)propertyAnimation{
    [self allViewUserInteractionEnable:true];
}

#pragma mark- PaintScreenTransitionManagerDelegate
- (CGRect)willGetCylinderMirrorFrame{
    return [self getCylinderMirrorFrame];
}

#pragma mark- UIViewControllerTransitioningDelegate
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    self.transitionManager.isPresenting = YES;
    return self.transitionManager;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    self.transitionManager.isPresenting = NO;
    return self.transitionManager;
}

#pragma mark- 绘画代理PaintScreenDelegate
- (EAGLContext*) createEAGleContextWithShareGroup{
    return [self createBestEAGLContext];
}

- (void) closePaintDoc:(PaintDoc *)paintDoc{
    self.cylinderProjectDefaultAlphaBlend = 1;
    //变换动画
    ImageView *tempImageView = (ImageView *)[self.view subViewWithTag:100];
    tempImageView.alpha = 1;
    
    [self.paintScreenVC dismissViewControllerAnimated:true completion:^{
        //刷新当前画架内容
        NSString *path = [[Ultility applicationDocumentDirectory] stringByAppendingPathComponent:self.paintFrameViewGroup.curPaintDoc.thumbImagePath];
        self.cylinderProjectCur.renderer.material.mainTexture = [Texture textureFromImagePath:path reload:true];
        
        self.cylinder.reflectionStrength = 0;
        TPPropertyAnimation *clip = [self.cylinder.animation.clips valueForKey:@"reflectionFadeInOutAnimClip"];
        clip.duration = 0.5;
        clip.fromValue = [NSNumber numberWithFloat:0];
        clip.toValue = [NSNumber numberWithFloat:1];
        [self.cylinder.animation play];
        

        [UIView animateWithDuration:0.5 animations:^{
            tempImageView.alpha = 0;
        }completion:^(BOOL finished) {
        }];
        
        UIView *fromView = self.view;
        CGRect rect = [self willGetCylinderMirrorFrame];
        CGFloat scale = self.view.frame.size.width / rect.size.width;
        [fromView.layer setValue:[NSNumber numberWithFloat:scale] forKeyPath:@"transform.scale"];
        
        [UIView animateWithDuration:0.8 animations:^{
            [fromView.layer setValue:[NSNumber numberWithFloat:1] forKeyPath:@"transform.scale"];
        } completion:^(BOOL finished) {
        }];
        
    }];
}

#pragma mark-
-(void)openPaintDoc:(PaintDoc*)paintDoc {
//    self.curPaintDoc = paintDoc;
    self.paintScreenVC =  [self.storyboard instantiateViewControllerWithIdentifier:@"paintScreen"];
    self.paintScreenVC.delegate = self;
    self.paintScreenVC.transitioningDelegate = self;
    
    //打开绘图面板动画，从cylinder的中心放大过度到paintScreenViewController
    [self presentViewController:self.paintScreenVC animated:true completion:^{
        DebugLog(@"presentViewController paintScreenVC");
        [self.paintScreenVC openDoc:self.paintFrameViewGroup.curPaintDoc];
    }];
}

- (IBAction)sideViewButtonTouchUp:(UIButton *)sender {
    self.sideViewButton.hidden = true;
    self.topViewButton.hidden = false;
    
    TPPropertyAnimation *animClip = [Camera.mainCamera.animation.clips valueForKey:@"topToBottomAnimClip"];
    Camera.mainCamera.animation.clip = animClip;
    Camera.mainCamera.animation.target = self;
    [Camera.mainCamera.animation play];

}

- (IBAction)topViewButtonTouchUp:(UIButton *)sender {
    self.topViewButton.hidden = true;
    self.sideViewButton.hidden = false;
    
    TPPropertyAnimation *animClip = [Camera.mainCamera.animation.clips valueForKey:@"bottomToTopAnimClip"];
    Camera.mainCamera.animation.clip = animClip;
    Camera.mainCamera.animation.target = self;
    [Camera.mainCamera.animation play];

}

#pragma mark- 打印Print
- (void)exportToAirPrint{
    //TODO:转换到顶视图，在放圆柱体的位置画上圈，并打印
    
    UIImage *image = [Ultility snapshot:self.projectView Context:self.context InViewportSize:self.projectView.bounds.size ToOutputSize:self.projectView.bounds.size];
    
    //convert UIImage to NSData to add it as attachment
    NSData *data = UIImagePNGRepresentation(image);
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    
    if  (pic && [UIPrintInteractionController canPrintData: data] ) {
        
        pic.delegate = self;
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = [NSString stringWithFormat:@"image%lu", (unsigned long)image.hash];
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        pic.printInfo = printInfo;
        pic.showsPageRange = YES;
        pic.printingItem = data;
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
            
            if (!completed && error)
                DebugLog(@"FAILED! due to error in domain %@ with error code %u",error.domain, error.code);
        };
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            //            [pic presentFromBarButtonItem:self.printButton animated:YES completionHandler:completionHandler];
            [pic presentFromRect:self.printButton.frame inView:self.toolBar animated:true completionHandler:completionHandler];
        } else {
            [pic presentAnimated:YES completionHandler:completionHandler];
        }
    }
}
#pragma mark- 陀螺仪代理MotionDelegate
- (void)initMotionDetect{
    self.motionManager = [[CMMotionManager alloc]init];
    NSOperationQueue *aQueue=[[NSOperationQueue alloc]init];
    if (!self.motionManager.deviceMotionAvailable) {
        //pop message box
        DebugLog(@"motion manager not available!");
    }
    
    self.motionManager.deviceMotionUpdateInterval = 0.033;
    if (![self.motionManager isDeviceMotionActive]) {
        [self.motionManager startDeviceMotionUpdatesToQueue:aQueue withHandler:
         ^(CMDeviceMotion *motion, NSError *error){
             if (motion) {
//                 DebugLog(@"attitude yaw: %.1f  pitch: %.1f  roll: %.1f", motion.attitude.yaw, motion.attitude.pitch, motion.attitude.roll);
                 
                 //监测未在动画中到角度的变化到固定值
                 //TODO: do with TPPropertyAnimation
//                 if (self.state == CP_Projected){
//                     if (motion.attitude.pitch < 0.1 && self.lastPitch >= 0.1  && self.eyeBottomTopBlend <1.0) {
//                         self.state = CP_PitchingToTopView;
//                     }
//                     else if (motion.attitude.pitch >= 0.1 && self.lastPitch < 0.1 && self.eyeBottomTopBlend > 0.0){
//                         self.state = CP_PitchingToBottomView;
//                     }
//                 }

                 self.lastPitch = motion.attitude.pitch;

//                 UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
//                 DebugLog(@"UIDeviceOrientation %d", deviceOrientation);
//                 dispatch_async(dispatch_get_main_queue(), ^{
//                     self.eyeTopBottomBlend = MIN(MAX(0, 1 - (self.lastPitch / M_PI_2)), 1) ;
//                 });
             }
         }];
        
    }
}

@end
