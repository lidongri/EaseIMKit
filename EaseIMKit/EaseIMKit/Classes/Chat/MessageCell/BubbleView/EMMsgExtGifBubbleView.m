//
//  EMMsgExtGifBubbleView.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 2019/2/14.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import "EMMsgExtGifBubbleView.h"
#import "EaseEmoticonGroup.h"

@implementation EMMsgExtGifBubbleView

- (instancetype)initWithDirection:(EMMessageDirection)aDirection
                             type:(EMMessageType)aType
                        viewModel:(EaseChatViewModel *)viewModel
{
    self = [super initWithDirection:aDirection type:aType viewModel:viewModel];
    if (self) {
        self.gifView = [[EaseAnimatedImgView alloc] init];
        self.gifView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.gifView];
        [self.gifView Ease_makeConstraints:^(EaseConstraintMaker *make) {
            make.edges.equalTo(self);
            make.width.height.lessThanOrEqualTo(@100);
        }];
    }
    
    return self;
}

#pragma mark - Setter

- (void)setModel:(EaseMessageModel *)model
{
    EMMessageType type = model.type;
    if (type == EMMessageTypeExtGif) {
        NSString *name = [(EMTextMessageBody *)model.message.body text];
        EaseEmoticonGroup *group = [EaseEmoticonGroup getGifGroup];
        EaseEmoticonGroup *group3 = [EaseEmoticonGroup getGifGroup1];
        NSString *strID = model.message.ext[MSG_EXT_GIF_ID];
        if (strID.length > 2) {
            strID = [strID substringFromIndex:2];
        }
        if ([strID integerValue] > 2000) {
            //说明是gif图
            for (EaseEmoticonModel *model in group3.dataArray) {
                if ([model.name isEqualToString:name] || [[NSString stringWithFormat:@"[%@]",model.name] isEqualToString:name]) {
                    NSString *path = [[NSBundle mainBundle] pathForResource:@"EaseIMKit" ofType:@"bundle"];
                    NSString *gifPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",model.original]];
                    NSData *imageData = [NSData dataWithContentsOfFile:gifPath];
                    self.gifView.animatedImage = [EaseAnimatedImg animatedImageWithGIFData:imageData];
                    self.image = [UIImage imageNamed:@""];
                    
                    break;
                }
            }
        } else {
            //不是gif图
            for (EaseEmoticonModel *model in group.dataArray) {
                if ([model.name isEqualToString:name] || [[NSString stringWithFormat:@"[%@]",model.name] isEqualToString:name]) {
                    NSString *path = [[NSBundle mainBundle] pathForResource:@"EaseIMKit" ofType:@"bundle"];
                    NSString *gifPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",model.original]];
                    self.gifView.image = [UIImage imageNamed:gifPath];
                    self.image = [UIImage imageNamed:@""];
                    
                    break;
                }
            }
        }
    }
}

@end
