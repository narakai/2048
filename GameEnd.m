//
//  GameEnd.m
//  2048
//
//  Created by leon on 14-5-6.
//  Copyright (c) 2014年 Apportable. All rights reserved.
//

#import "GameEnd.h"

@implementation GameEnd {
    CCLabelTTF *_messageLable;
    CCLabelTTF *_scoreLable;
}

-(void)newGame{
    CCScene *mainScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:mainScene];
}

-(void)setMessage:(NSString *)message score:(NSInteger)score{
    _messageLable.string = message;
    _scoreLable.string = [NSString stringWithFormat:@"%d", score];
}

@end
