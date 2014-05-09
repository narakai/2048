//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Grid.h"

@implementation MainScene {
    Grid *_grid;
    CCLabelTTF *_scoreLable;
    CCLabelTTF *_highscoreLable;
}

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    [_grid addObserver:self forKeyPath:@"score" options:0 context:NULL];
    //update high score
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"highscore" options:0 context:NULL];
    [self updateHighscore];
}

//observe if value has been changed. update highscore
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"score"]) {
        _scoreLable.string = [NSString stringWithFormat:@"%d", _grid.score];
    } else if ([keyPath isEqualToString:@"highscore"]){
        [self updateHighscore];
    }
}

-(void)dealloc{
    [_grid removeObserver:self forKeyPath:@"score"];
}

-(void)updateHighscore{
    NSNumber *newHighscore = [[NSUserDefaults standardUserDefaults] objectForKey:@"highscore"];
    if (newHighscore) {
        _highscoreLable.string = [NSString stringWithFormat:@"%d", [newHighscore intValue]];
    }
}

@end
