//
//  Map.m
//  Bastion
//
//  Created by Kayhan Feroze Qaiser on 10/02/2015.
//
//

#import <Foundation/Foundation.h>
#import "Map.h"
#import "Tile.h"
#import "Ritter.h"
#import "Peasant.h"
#import "Baum.h"
#import "Hovel.h"
#import "GamePlayer.h"
#import "Hud.h"
#import "Media.h"
#import "MessageLayer.h"

@implementation Map {
    SPSprite* _tilesSprite;
    SPSprite* _unitsSprite;
    SPSprite* _villagesSprite;

    MessageLayer* _messageLayer;
    
    float _gridWidth;
    float _gridHeight;
    float _tileWidth;
    float _tileHeight;
    float _offsetHeight;
    
}

@synthesize messageLayer = _messageLayer;
@synthesize currentPlayer = _currentPlayer;
@synthesize mePlayer = _mePlayer;
@synthesize hud = _hud;


-(id)initWithRandomMap:(NSMutableArray *)players hud:(Hud *)hud
{
    if (self=[super init]) {
        //custom code here

        _messageLayer = [MessageLayer sharedMessageLayer];
        
        //currently we are not using the array players and game Engine is updating us with the current player
        
        _gridWidth = 20;
        _gridHeight = 20;
        _tileWidth = 54;
        _tileHeight = 57;
        _offsetHeight = 40;

        _hud = hud;

        
        _tilesSprite = [SPSprite sprite];
        [self addChild:_tilesSprite];
        _unitsSprite = [SPSprite sprite];
        _unitsSprite.x = -28;
        _unitsSprite.y = -28;
        [self addChild:_unitsSprite];
        
        //unused so far
        _villagesSprite = [SPSprite sprite];
        [self addChild:_villagesSprite];
        
        
        [self makeBasicMap];
        [self setNeighbours];
        [self makePlayer1Tiles: [players objectAtIndex:0]];
        [self makePlayer2Tiles: [players objectAtIndex:1]];

        [self addTrees];
        [self addMeadows];
        
        [self showPlayersTeritory];
        
    }
    return self;
}

- (void)makeBasicMap
{
    for (int j  = 0 ; j<_gridWidth; j++) {
        for (int i  = 0 ; i<_gridHeight; i++) {
            int xOffset = j%2 * _tileWidth/2;
            SPPoint *p = [SPPoint pointWithX:i*_tileWidth+xOffset y:j*_offsetHeight];
            Tile *t = [[Tile alloc] initWithPosition:p structure:GRASS];
            [_tilesSprite addChild:t];
        }
    }
}

- (void)makePlayer1Tiles:(GamePlayer*)player1
{
    Tile* villageTile;
    int i = 0;
    int j = 0;
    
    for (Tile* t in _tilesSprite) {
        
        if (j>9 && j<15) {
            if (i<15 && i>9) {
                t.village = villageTile.village;
                [t setColor:villageTile.village.player.color];
                if (j == 12 && i == 10) {
                    Peasant* u = [[Peasant alloc] initWithTile:t];
                    [_unitsSprite addChild:u];
                    t.unit = u;
                }
            }
        }
        
        if (j == 10 && i == 10) {
            [t addVillage:HOVEL];
            villageTile = t;
            t.village.player = player1;
        }
        
        i++;
        if (i == _gridWidth) {
            i=0;
            j++;
        }
    }
}

- (void)makePlayer2Tiles:(GamePlayer*)player2
{
    Tile* villageTile;
    int i = 0;
    int j = 0;
    
    for (Tile* t in _tilesSprite) {
        
        if (j == 4 && i == 5) {
            [t addVillage:HOVEL];
            villageTile = t;
            t.village.player = player2;
        }
        
        if (j>3 && j<7) {
            if (i<10 && i>4) {
                t.village = villageTile.village;
                [t setColor:villageTile.village.player.color];
                if (j == 12 && i == 10) {
                    Peasant* u = [[Peasant alloc] initWithTile:t];
                    [_unitsSprite addChild:u];
                    t.unit = u;
                }
            }
        }
        i++;
        if (i == _gridWidth) {
            i=0;
            j++;
        }
    }
}

- (void)setNeighbours
{
    for (int j  = 1 ; j<_gridWidth - 1; j++) {
        for (int i  = 1 ; i<_gridHeight - 1; i++) {
            int tIndex = i + j*_gridWidth;
            
            Tile* t = (Tile*)[_tilesSprite childAtIndex:tIndex];
            for (int k = 0; k<6; k++) {
                int nIndex = 0;
                if (k == 0) nIndex = tIndex - _gridWidth;
                else if (k == 1) nIndex = tIndex + 1;
                else if (k == 2) nIndex = tIndex + _gridWidth;
                else if (k == 3) nIndex = tIndex + _gridWidth-1;
                else if (k == 4) nIndex = tIndex - 1;
                else if (k == 5) nIndex = tIndex - _gridWidth - 1;

                if (j%2 == 1 && k!=1 && k!=4) nIndex++;
                
                [t setNeighbour:k tile:(Tile*)[_tilesSprite childAtIndex:nIndex]];

            }
        }
    }
    
}

-(void)addTrees
{
    for (int j  = 1 ; j<80; j++) {
        int index = arc4random() % [_tilesSprite numChildren];
        Tile* t = (Tile*)[_tilesSprite childAtIndex:index];
        if (t.getStructureType == GRASS && t.unit==nil && !t.isVillage) {
            [t addStructure:BAUM];
        }
    }
}
-(void)addMeadows
{
    for (int j  = 1 ; j<40; j++) {
        int index = arc4random() % [_tilesSprite numChildren];
        Tile* t = (Tile*)[_tilesSprite childAtIndex:index];
        if (t.getStructureType == GRASS && t.unit==nil && !t.isVillage) {
            [t addStructure:MEADOW];
        }
    }
}

- (void)treeGrowthPhase
{
    NSLog(@"Tree Growth Phase");
    for (Tile* tile in _tilesSprite) {
        Structure* s = [tile getStructure];
        if (s.sType == BAUM) {
            Baum* b = (Baum*)s;
            //only grow near a tree if it not newly grown.
            if (!b.newlyGrown) {
                for (Tile* nTile in [tile getNeighbours]) {
                    if ([nTile canHaveTree]) {
                        int num = arc4random() % 10;
                        if (num==0) [nTile addStructure:BAUM];
                    }
                }
            }
        }
    }
}


- (void)upgradeVillageWithTile:(Tile*)tile
{
    BOOL actionPossible = true;
    
    if ([self isMyTurn]) {
        if (_currentPlayer.woodPile<8) actionPossible = false;
    }
    
    if (actionPossible == false) {
        return;
    }
    
    //get the tiles of the old village and set the village to the new one after upgrading
    NSMutableArray* tiles = [self getTilesforVillage:tile];
    [tile upgradeVillage];
    for (Tile* t in tiles) {
        t.village = tile.village;
    }
    
    if ([self isMyTurn]) {
        _currentPlayer.woodPile -= 8;
        [self updateHud];
        [_messageLayer sendMoveWithType:UPGRADEVILLAGE tile:tile destTile:nil];
    }
}

- (NSMutableArray*)getTilesforVillage:(Tile*)tile
{
    NSMutableArray* tiles = [NSMutableArray array];
    Village* v = tile.village;
    
    for (Tile*t in _tilesSprite) {
        if (t.village == v) [tiles addObject:t];
    }
    
    return tiles;
}


- (void)showPlayersTeritory
{
    for (Tile* t in _tilesSprite) {
        if (t.village!=nil) {
            [t setColor:t.village.player.color];
        }
    }
}



- (void)buyUnitFromTile:(Tile*)villageTile tile:(Tile*)destTile
{
    BOOL actionPossible = true;
    if ([self isMyTurn]) {
        if (villageTile.village != destTile.village) actionPossible = false;
        if (![destTile canHaveUnit]) actionPossible = false;
    }
    
    if (actionPossible == false) return;
    
    Peasant* r = [[Peasant alloc] initWithTile:destTile];
    [_unitsSprite addChild:r];
    destTile.unit = r;
    
    if ([self isMyTurn]) {
        _currentPlayer.goldPile-=10;
        [self updateHud];
        [_messageLayer sendMoveWithType:BUYUNIT tile:villageTile destTile:destTile];
    }
}

//completes the move to new tile
- (void)moveUnitWithTile:(Tile*)unitTile tile:(Tile*)destTile
{
    Unit* unit = unitTile.unit;
    
    BOOL movePossible = true;
    if ([self isMyTurn]) {
        if (unit.movesCompleted) {
            movePossible = false;
        }
        if ([unitTile neighboursContainTile:destTile] == false) {
            movePossible = false;
        }
        //if (destTile.getStructureType == BAUM && u.uType == RITTER) movePossible = false;
        if (destTile.isVillage) movePossible = false;
        if (unit.distTravelled == unit.stamina) {
            movePossible = false;
        }
        
        if (unitTile.village != destTile.village) {
            //[self takeOverTile:unitTile tile:destTile];
            movePossible = false;
        }
    }
    
    if (!movePossible) {
        NSLog(@"move impossible");
        [Media playSound:@"sound.caf"];
        return;
    }
    
    //if the move is possible we continue here
    
    if (destTile.getStructureType == BAUM) {
        [self chopTree:destTile];
    }

    
    //the last thing we do is update the coordinates and reset the selected unit's Tile
    unit.x = destTile.x;
    unit.y = destTile.y;
    unitTile.unit = nil;
    destTile.unit = unit;
    
    unit.distTravelled++;
    
    //need to refresh the colour, where should this actually be done?
    [self showPlayersTeritory];
    
    if ([self isMyTurn]) {
        [_messageLayer sendMoveWithType:MOVEUNIT tile:unitTile destTile:destTile];
    }
}

- (void)takeOverTile:(Tile*)unitTile tile:(Tile*)destTile
{
    destTile.village = unitTile.village;
    
}

- (void)chopTree:(Tile*)tile
{
    [tile removeStructure];
    if ([self isMyTurn]) {
        _currentPlayer.woodPile++;
        [self updateHud];
    }
}

- (void)buildMeadow:(Tile*)tile
{
    [tile addStructure:MEADOW];
    
}

- (void)updateHud
{
    [_hud update];
}

- (void)createRandomMap
{
    
}

- (void)endTurnUpdates
{
    //update the trees
    for (Tile* tile in _tilesSprite) {
        Structure* s = [tile getStructure];
        if (s.sType == BAUM) {
            Baum* b = (Baum*)s;
            b.newlyGrown = false;
        }
    }
    
}

- (BOOL)isMyTurn
{
    return _currentPlayer == _mePlayer;
}



@end