//
//  POITableViewCell.h
//  CheckinDemo
//
//  Created by eidan on 2017/3/29.
//  Copyright © 2017年 Amap. All rights reserved.
//

#define POITableViewCellIdentifier      @"POITableViewCellIdentifier"

#import <UIKit/UIKit.h>

@interface POITableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *infoLabel;
@property (nonatomic, weak) IBOutlet UIImageView *selectedImageView;

@end
