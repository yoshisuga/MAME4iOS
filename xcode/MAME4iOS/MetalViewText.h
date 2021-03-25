//
//  MetalViewText.h
//  Wombat
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//
#import "MetalView.h"

//
// MetalViewText - an extenstion to MetalView to draw text
@interface MetalView (Text)

-(CGSize)sizeText:(NSString*)text height:(CGFloat)height;

-(void)drawText:(NSString*)text at:(CGPoint)xy height:(CGFloat)height color:(VertexColor)color;

@end



