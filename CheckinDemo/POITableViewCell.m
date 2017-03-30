//
//  POITableViewCell.m
//  CheckinDemo
//
//  Created by eidan on 2017/3/29.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "POITableViewCell.h"

@interface POITableViewCell ()


@end

@implementation POITableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectedImageView.hidden = YES;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
