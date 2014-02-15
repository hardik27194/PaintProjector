//
//  CylinderProjectViewController.h
//  PaintProjector
//
//  Created by 胡 文杰 on 13-7-21.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMotion/CoreMotion.h>

#import "PaintScreen.h"

#import "GLWrapper.h"
#import "Ultility.h"
#import "TextureManager.h"
#import "ShaderManager.h"
#import "TPPropertyAnimation.h"
//object
#import "Display.h"
#import "Camera.h"
#import "Grid.h"
#import "Cylinder.h"
#import "CylinderProject.h"
#import "ShaderCylinderProject.h"
#import "ShaderCylinder.h"
#import "ShaderNoLitTexture.h"
#import "Scene.h"
#import "PlaneMesh.h"
#import "CylinderMesh.h"
//component
#import "MeshFilter.h"
#import "MeshRenderer.h"
#import "Animation.h"


#import "PlayerView.h"
//#import "ZBarSDK.h"
#import "PlayButton.h"
#import "PaintButton.h"
#import "DownToolBar.h"

//FirstScreenViewController
#import "PaintFrameView.h"
#import "PaintFrameViewGroup.h"
#import "PaintDoc.h"
#import "PaintDocManager.h"

#import "PaintScreenTransitionManager.h"
#import "CustomPercentDrivenInteractiveTransition.h"

#define FarClipDistance 10
#define NearClipDistance 0.0001
#define DeviceWidth 0.154

static const NSString *ItemStatusContext;

typedef NS_ENUM(NSInteger, CylinderProjectViewState) {
    CP_Default,
//    CP_PitchingToTopView,
//    CP_PitchingToBottomView,
//    
//    CP_Projecting,
//    CP_Projected,
//    CP_UnProjecting,
    
    CP_RotateImage,
    CP_RotateViewAxisX,
};

typedef NS_ENUM(NSInteger, PlayState) {
    PS_Playing,
    PS_Stopped,
    PS_Pause,
};

typedef void(^MyCompletionBlock)(void);

@class CylinderProjectViewController;
@protocol CylinderProjectViewControllerDelegate
- (void) willTransitionToGallery;
@end

@interface CylinderProjectViewController : UIViewController
<GLKViewControllerDelegate,
GLKViewDelegate,
UIPrintInteractionControllerDelegate,
UIViewControllerTransitioningDelegate,
PaintScreenTransitionManagerDelegate,
PaintScreenDelegate,
TPPropertyAnimationDelegate,
CustomPercentDrivenInteractiveTransition
//ZBarReaderDelegate
>
{
    void * _baseAddress;
}
@property (weak, nonatomic) PaintScreen* paintScreenVC;
@property (retain, nonatomic) GLKViewController* glkViewController;
@property (weak, nonatomic) IBOutlet GLKView *projectView;
@property (assign, nonatomic) id delegate;

#pragma mark- File
@property (weak, nonatomic) PaintFrameViewGroup *paintFrameViewGroup;

#pragma mark- User Input
@property (assign, nonatomic) CGFloat inputCylinderRadius;
@property (assign, nonatomic) CGFloat inputCylinderImageWidth;
@property (assign, nonatomic) CGFloat inputCylinderImageCenterOnSurfHeight;
#pragma mark- GL
@property (retain, nonatomic) EAGLContext *context;

#pragma mark- Scene
@property (retain, nonatomic) Texture *paintTexture;
@property (retain, nonatomic) Scene *curScene;
@property (retain, nonatomic) CylinderProject *cylinderProjectCur;
@property (retain, nonatomic) CylinderProject *cylinderProjectNext;
@property (retain, nonatomic) CylinderProject *cylinderProjectLast;
@property (retain, nonatomic) Cylinder *cylinder;//圆柱体
@property (assign, nonatomic) CGFloat cylinderProjectDefaultAlphaBlend;

#pragma mark- 交互
@property (retain, nonatomic) CustomPercentDrivenInteractiveTransition *browseNextAction;
@property (retain, nonatomic) CustomPercentDrivenInteractiveTransition *browseLastAction;
#pragma mark- 视角变换
@property (assign, nonatomic) GLKVector3 eyeTop;//视角顶部
@property (assign, nonatomic) GLKVector3 eyeBottom;//视角底部
@property (assign, nonatomic) float eyeTopAspect;//顶视图长宽比
@property (assign, nonatomic) float eyeBottomTopBlend;
@property (assign, nonatomic) float toEyeBottomTopBlend;

#pragma mark- project display helper
@property (assign, nonatomic) BOOL showGrid;//是否显示网格
@property (retain, nonatomic) Grid *grid;//网格

#pragma mark- state
@property (assign, nonatomic) CylinderProjectViewState state;      //状态
@property (assign, nonatomic) PlayState playState;//播放状态
@property (assign, nonatomic) BOOL dirty;//是否重新计算

#pragma mark- interaction
- (IBAction)handlePanCylinderProjectView:(UIPanGestureRecognizer *)sender;

#pragma mark- main category
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *allViews;
@property (weak, nonatomic) IBOutlet UIImageView *screenMask;
@property (weak, nonatomic) IBOutlet DownToolBar *toolBar;

#pragma mark- viewMode
@property (retain, nonatomic) Camera *topCamera;
@property (assign, nonatomic) GLKMatrix4 bottomCameraProjMatrix;
@property (assign, nonatomic) BOOL isTopViewMode;
@property (weak, nonatomic) IBOutlet UIButton *sideViewButton;
@property (weak, nonatomic) IBOutlet UIButton *topViewButton;

- (IBAction)sideViewButtonTouchUp:(UIButton *)sender;
- (IBAction)topViewButtonTouchUp:(UIButton *)sender;

#pragma mark- cylinder coordinate
- (CGRect)getCylinderMirrorFrame;
- (CGRect)getCylinderMirrorTopFrame;

#pragma mark- paintDoc
//@property (weak, nonatomic) PaintDoc *curPaintDoc;
-(void)viewPaintDoc:(PaintDoc*)paintDoc;
- (void)openPaintDoc:(PaintDoc*)paintDoc;

#pragma mark- file action
@property (weak, nonatomic) IBOutlet PlayButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *paintButton;
@property (weak, nonatomic) IBOutlet UIButton *printButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

- (IBAction)galleryButtonTouchUp:(id)sender;
- (IBAction)paintButtonTouchUp:(UIButton *)sender;
- (IBAction)printButtonTouchUp:(UIButton *)sender;
- (IBAction)shareButtonTouchUp:(UIButton *)sender;

#pragma mark-  CoreMotion
@property (retain, nonatomic)CMMotionManager *motionManager;
@property (assign, nonatomic)float lastPitch;

#pragma mark- video
@property (retain, nonatomic)AVAsset *asset;
@property (retain, nonatomic)AVAssetReader *assetReader;
@property (retain, nonatomic) AVPlayer *player;
@property (retain, nonatomic) AVPlayerItem *playerItem;
@property (assign, nonatomic) CMTime playTime;//播放到的时刻

- (void)syncPlayUI;
- (IBAction)playButtonTouchUp:(UIButton *)sender;
- (IBAction)playbackButtonTouchUp:(UIButton *)sender;
@end
