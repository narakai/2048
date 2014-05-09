//
//  Grid.m
//  2048
//
//  Created by leon on 14-5-4.
//  Copyright (c) 2014年 Apportable. All rights reserved.
//

#import "Grid.h"
#import "Tile.h"
#import "GameEnd.h"

@implementation Grid {
    CGFloat _columnWidth;
    CGFloat _columbHeight;
    CGFloat _tileMarginVertical;
    CGFloat _tileMarginHorizontal;
    NSMutableArray *_gridArray;
    NSNull *_noTile;
}

static const NSInteger GRID_SIZE = 4;
static const NSInteger START_TILES = 2;
static const NSInteger WIN_TILE = 2048;

-(void)setBackground {
    CCNode *tile = [CCBReader load:@"Tile"];
    _columnWidth = tile.contentSize.width;
    _columbHeight = tile.contentSize.height;
    _tileMarginHorizontal = (self.contentSize.width - (GRID_SIZE * _columnWidth))/(GRID_SIZE + 1);
    _tileMarginVertical = (self.contentSize.height - (GRID_SIZE * _columbHeight))/(GRID_SIZE + 1);
    float x = _tileMarginHorizontal;
    float y = _tileMarginVertical;
    for (int i = 0; i < GRID_SIZE; i++) {
        x = _tileMarginHorizontal;
        for (int j = 0; j < GRID_SIZE; j++) {
            CCNodeColor *backgroundTile = [CCNodeColor nodeWithColor:[CCColor grayColor]];
            backgroundTile.contentSize = CGSizeMake(_columnWidth, _columbHeight);
            backgroundTile.position = ccp(x,y);
            [self addChild:backgroundTile];
            x += _columnWidth + _tileMarginHorizontal;
        }
        y += _columbHeight + _tileMarginVertical;
    }
}

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    [self setBackground];
    _noTile = [NSNull null];
    _gridArray = [NSMutableArray array];
    //store the _noTile value for each index
    for (int i = 0; i < GRID_SIZE; i++) {
        _gridArray[i] = [NSMutableArray array];
        for (int j = 0; j < GRID_SIZE; j++) {
            _gridArray[i][j] = _noTile;
        }
    }
    [self spawnStartTiles];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeDown];
    
}

-(CGPoint)positionForColumn:(NSInteger)column row:(NSInteger)row{
    NSInteger x = _tileMarginHorizontal + column * (_tileMarginHorizontal + _columnWidth);
    NSInteger y = _tileMarginVertical + row * (_tileMarginVertical + _columbHeight);
    return CGPointMake(x, y);
}

-(void)addTileAtColumn:(NSInteger)column row:(NSInteger)row{
    Tile *tile = (Tile*)[CCBReader load:@"Tile"];
    _gridArray[column][row] = tile;
    tile.scale = 0.f;
    [self addChild:tile];
    tile.position = [self positionForColumn:column row:row];
    CCActionDelay *delay = [CCActionDelay actionWithDuration:0.3f];
    CCActionScaleTo *scaleUp = [CCActionScaleTo actionWithDuration:0.2f scale:1.f];
    CCActionSequence *sequence = [CCActionSequence actionWithArray:@[delay,scaleUp]];
    [tile runAction:sequence];
}

-(void)spawnRandomTile{
    BOOL spawned = FALSE;
    while (!spawned) {
        NSInteger randomRow = arc4random()%GRID_SIZE;
        NSInteger randomColumn = arc4random()%GRID_SIZE;
        BOOL positionFree = (_gridArray[randomColumn][randomRow] == _noTile);
        if (positionFree) {
            [self addTileAtColumn:randomColumn row:randomRow];
            spawned = TRUE;
        }
    }
}

-(void)spawnStartTiles{
    for (int i = 0; i < START_TILES; i++) {
        [self spawnRandomTile];
    }
}

-(void)swipeLeft{[self move:ccp(-1, 0)];}
-(void)swipeRight{[self move:ccp(1, 0)];}
-(void)swipeUp{[self move:ccp(0, 1)];}
-(void)swipeDown{[self move:ccp(0, -1)];}


- (void)move:(CGPoint)direction {
    BOOL movedTilesThisRound = FALSE;
    // apply negative vector until reaching boundary, this way we get the tile that is the furthest away
    //bottom left corner
    NSInteger currentX = 0;
    NSInteger currentY = 0;
    // Move to relevant edge by applying direction until reaching border
    while ([self indexValid:currentX y:currentY]) {
        CGFloat newX = currentX + direction.x;
        CGFloat newY = currentY + direction.y;
        if ([self indexValid:newX y:newY]) {
            currentX = newX;
            currentY = newY;
        } else {
            break;  
        }
    }
    // store initial row value to reset after completing each column
    NSInteger initialY = currentY;
    // define changing of x and y value (moving left, up, down or right?)
    NSInteger xChange = -direction.x;
    NSInteger yChange = -direction.y;
    if (xChange == 0) {
        xChange = 1;
    }
    if (yChange == 0) {
        yChange = 1;
    }
    // visit column for column
    while ([self indexValid:currentX y:currentY]) {
        while ([self indexValid:currentX y:currentY]) {
            // get tile at current index
            Tile *tile = _gridArray[currentX][currentY];
            if ([tile isEqual:_noTile]) {
                // if there is no tile at this index -> skip
                currentY += yChange;
                continue;
            }
            // store index in temp variables to change them and store new location of this tile
            NSInteger newX = currentX;
            NSInteger newY = currentY;
            /* find the farthest position by iterating in direction of the vector until we reach border of grid or an occupied cell*/
            while ([self indexValidAndUnoccupied:newX+direction.x y:newY+direction.y]) {
                newX += direction.x;
                newY += direction.y;
            }

            
            BOOL performMove= FALSE;
            if ([self indexValid:newX+direction.x y:newY+direction.y]) {
                NSInteger otherTileX = newX + direction.x;
                NSInteger otherTileY = newY + direction.y;
                Tile *otherTile = _gridArray[otherTileX][otherTileY];
                
                if (tile.value == otherTile.value && !otherTile.mergedThisRound) {
                    [self mergeTileAtIndex:currentX y:currentY withTileAtIndex:otherTileX y:otherTileY];
                    movedTilesThisRound = TRUE;
                } else {
                    performMove = TRUE;
                }
            }
                else {
                    performMove = TRUE;
                }
            
            if (performMove) {
                if (newX != currentX || newY !=currentY) {
                    [self moveTile:tile fromIndex:currentX oldY:currentY newX:newX newY:newY];
                    movedTilesThisRound = TRUE;
                }
            }
                
            
            // move further in this column
            currentY += yChange;
        }
        // move to the next column, start at the inital row
        currentX += xChange;
        currentY = initialY;
    }
    if (movedTilesThisRound) {
        [self nextRound];
    }
}

-(BOOL)indexValid:(NSInteger)x y:(NSInteger)y{
    BOOL indexValid = TRUE;
    indexValid &= x >= 0;
    indexValid &= y >= 0;
    if (indexValid) {
        indexValid &= x < (int)[_gridArray count];
    if (indexValid) {
        indexValid &= y < (int)[(NSMutableArray *) _gridArray[x] count];
    }
    }
    return indexValid;
}

-(void)moveTile:(Tile*) tile fromIndex:(NSInteger)oldX oldY:(NSInteger)oldY newX:(NSInteger)newX newY:(NSInteger)newY{
    _gridArray[newX][newY] = _gridArray[oldX][oldY];
    _gridArray[oldX][oldY] = _noTile;
    CGPoint newPosotion = [self positionForColumn:newX row:newY];
    CCActionMoveTo *moveTo = [CCActionMoveTo actionWithDuration:0.2f position:newPosotion];
    [tile runAction:moveTo];
}

-(BOOL)indexValidAndUnoccupied:(NSInteger)x y:(NSInteger)y{
    BOOL indexValid = [self indexValid:x y:y];
    if (!indexValid) {
        return FALSE;
    }
    BOOL unoccupied = [_gridArray[x][y] isEqual:_noTile];
    return unoccupied;
}

-(void)mergeTileAtIndex:(NSInteger)x y:(NSInteger)y withTileAtIndex:(NSInteger)xOtherTile y:(NSInteger)yOtherTile {
    //update data
    Tile *mergedTile = _gridArray[x][y];
    Tile *otherTile = _gridArray[xOtherTile][yOtherTile];
    self.score += mergedTile.value + otherTile.value;
    // *2
    otherTile.value *= 2;
    _gridArray[x][y] = _noTile;
    otherTile.mergedThisRound = TRUE;
    if (otherTile.value == WIN_TILE) {
        [self win];
    }
    
    //update UI
    CGPoint otherTilePosition = [self positionForColumn:xOtherTile row:yOtherTile];
    CCActionMoveTo *moveTo = [CCActionMoveTo actionWithDuration:0.2f position:otherTilePosition];
    CCActionRemove *remove = [CCActionRemove action];
    CCActionCallBlock *mergeTile = [CCActionCallBlock actionWithBlock:^{
        [otherTile updateValueDisplay];
    }];
    CCActionSequence *sequence = [CCActionSequence actionWithArray:@[moveTo, mergeTile, remove]];
    [mergedTile runAction:sequence];
}

-(void)nextRound{
    [self spawnRandomTile];
    for (int i = 0; i<GRID_SIZE; i++) {
        for (int j = 0; j<GRID_SIZE; j++) {
            Tile *tile = _gridArray[i][j];
            if (![tile isEqual:_noTile]) {
                tile.mergedThisRound = FALSE;
            }
        }
    }
    BOOL movePossible = [self movePossible];
    if (!movePossible) {
        [self lose];
    }
}

-(BOOL)movePossible{
    for (int i = 0; i<GRID_SIZE; i++) {
        for (int j = 0; j<GRID_SIZE; j++) {
            Tile *tile = _gridArray[i][j];
            if ([tile isEqual:_noTile]) {
                return TRUE;
            } else {
                Tile *topNeighbour = [self tileForIndex:i y:j+1];
                Tile *bottomNeighbour = [self tileForIndex:i y:j-1];
                Tile *leftNeighbour = [self tileForIndex:i-1 y:j];
                Tile *rightNeighbour = [self tileForIndex:i+1 y:j];
                NSArray *neighbours = @[topNeighbour, bottomNeighbour, leftNeighbour, rightNeighbour];
                for (id neighbourTile in neighbours) {
                    if (neighbourTile != _noTile) {
                        Tile *neighbour = (Tile*) neighbourTile;
                        if (neighbour.value == tile.value) {
                            return TRUE;
                        }
                    }
                }
            }
        }
    }
    return false;
}

-(id)tileForIndex:(NSInteger)x y:(NSInteger)y{
    if (![self indexValid:x y:y]) {
        return _noTile;
    } else {
        return _gridArray[x][y];
    }
}

-(void)win{
    [self endGameWithMessage:@"You Win!"];
}

-(void)lose{
    [self endGameWithMessage:@"You Lose!"];
}

-(void)endGameWithMessage:(NSString*)message{
    GameEnd *gameEndPopover = (GameEnd*)[CCBReader load:@"GameEnd"];
    gameEndPopover.positionType = CCPositionTypeNormalized;
    gameEndPopover.position = ccp(0.5,0.5);
    gameEndPopover.zOrder = INT_MAX;
    [gameEndPopover setMessage:message score:self.score];
    [self addChild:gameEndPopover];
    
    CCLOG(@"%@", message);
    NSNumber *highScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"highscore"];
    if (self.score > [highScore intValue]) {
        highScore = [NSNumber numberWithInt:self.score];
        [[NSUserDefaults standardUserDefaults] setObject:highScore forKey:@"highscore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
@end
