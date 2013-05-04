//
//  ANPost.m
//  AppNet
//
//  Created by Ahmed Khalil on 4/3/13.
//  Copyright (c) 2013 ChaiONE. All rights reserved.
//

#import "ANPost.h"

static NSDateFormatter *dateFormater;

@implementation ANPost

- (id)initWithJSONDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        
        if (!dateFormater) {
            dateFormater = [[NSDateFormatter alloc] init];
            [dateFormater setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        }
        
        _createdAt = [dateFormater dateFromString:[dict valueForKey:@"created_at"]];
        _text = [[dict valueForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        _name = [[dict valueForKeyPath:@"user.name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        _avatarImageUrl = [dict valueForKeyPath:@"user.avatar_image.url"];
//        _avatarImageWidth = [[dict valueForKeyPath:@"user.avatar_image.width"] floatValue];
//        _avatarImageHeight = [[dict valueForKeyPath:@"user.avatar_image.height"] floatValue];
    }
    return self;
}

@end
