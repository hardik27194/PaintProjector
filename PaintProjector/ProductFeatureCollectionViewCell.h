//
//  ProductFeatureCollectionViewCell.h
//  PaintProjector
//
//  Created by 胡 文杰 on 2/23/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductFeatureCollectionViewCell : UICollectionViewCell
//@property (assign, nonatomic) id delegate;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UILabel *tryLabel;
- (IBAction)resetButtonTouchUp:(UIButton *)sender;

@end

//@protocol ProductFeatureCollectionViewCellDelegate
//@end
