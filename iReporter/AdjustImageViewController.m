//
//  AdjustImageViewController.m
//  iReporter
//
//  Created by 文杰 胡 on 13-2-3.
//  Copyright (c) 2013年 Marin Todorov. All rights reserved.
//

#import "AdjustImageViewController.h"

@interface AdjustImageViewController ()

@end

@implementation AdjustImageViewController
@synthesize adjustImageDoneButton;
@synthesize delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _adjustedScale = 1;
    _adjustedTranslate = CGPointZero;
}

- (void)viewDidUnload
{
    [self setAdjustImageDoneButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)adjustDoneButtonTapped:(UIButton *)sender {
    adjustImageDoneButton.hidden = true;
    CALayer* layer = [self.view layer];
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext(); 
    //crop image
    NSLog(@"translate x:%.1f y:%.1f", _adjustedTranslate.x, _adjustedTranslate.y);
    CGRect cropRect = CGRectMake(_adjustedTranslate.x, _adjustedTranslate.y, self.view.frame.size.width / _adjustedScale, self.view.frame.size.height / _adjustedScale);
    adjustImageDoneButton.hidden = false;
    
    [delegate adjustImageDone:[UIImage imageWithCGImage:CGImageCreateWithImageInRect(viewImage.CGImage, cropRect)]];    
    [self dismissViewControllerAnimated:true completion:^{[delegate adjustImageViewControllerDismissed];}];    
}
- (IBAction)handlePinchGRAdjustImageView:(id)sender {
    [HandleGestureRecognizer handleScale:sender];    
    _adjustedScale = [HandleGestureRecognizer newScale];
}

- (IBAction)handlePanGRAdjustImageView:(UIPanGestureRecognizer *)sender {
    [HandleGestureRecognizer handleMove:sender];        
    _adjustedTranslate = [HandleGestureRecognizer newTranslate];    
}
@end