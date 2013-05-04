//
//  ANPost.h
//  AppNet
//
//  Created by Ahmed Khalil on 4/3/13.
//  Copyright (c) 2013 ChaiONE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANPost : NSObject

@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *avatarImageUrl;
@property (nonatomic, strong) UIImage *avatarImage;
//@property (nonatomic) float avatarImageWidth;
//@property (nonatomic) float avatarImageHeight;


- (id)initWithJSONDictionary:(NSDictionary *)dict;

@end
