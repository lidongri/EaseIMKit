//
//  EaseChatBarEmoticonView.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 2019/1/30.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import "EaseChatBarEmoticonView.h"
#import "UIImage+EaseUI.h"
#import "EaseHeaders.h"
#import "EaseEmojiHelper.h"
#import "LoginViewModel.h"

@interface EaseChatBarEmoticonView()<EMEmoticonViewDelegate>

@property (nonatomic) CGFloat bottomHeight;

@property (nonatomic, strong) NSMutableArray<EaseEmoticonGroup *> *groups;
@property (nonatomic, strong) NSMutableArray<EMEmoticonView *> *emotionViews;
@property (nonatomic, strong) NSMutableArray<UIButton *> *emotionButtons;
@property (nonatomic, strong) UIButton *selectedButton;

@property (nonatomic, strong) UIView *emotionBgView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIScrollView *bottomScrollView;
@property (nonatomic, strong) UIButton *extBtn;
@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, strong) UIButton *sendBtn;

@end

@implementation EaseChatBarEmoticonView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _initDataSource];
        [self _setupSubviews];
        [self segmentedButtonAction:self.emotionButtons[0]];
    }
    
    return self;
}

#pragma mark - Subviews

- (void)_setupSubviews
{
    [self _setupBottomView];
    [self _setupEmotionViews];
}

- (void)_setupBottomView
{
    CGFloat itemWidth = 60;
    NSInteger count = [self.groups count];
    
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [UIColor whiteColor];;
    [self addSubview:self.bottomView];
    [self.bottomView Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.bottom.equalTo(self);
        make.height.Ease_equalTo(self.bottomHeight);
    }];
    self.bottomView.hidden = YES;
    
    self.sendBtn = [[UIButton alloc]init];
    self.sendBtn.layer.cornerRadius = 8;
    [self.sendBtn setTitle:EaseLocalizableString(@"send", nil) forState:UIControlStateNormal];
    [self.sendBtn.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
    [self.sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendBtn setTitleColor:[UIColor colorWithHexString:@"#ADADAD"] forState:UIControlStateDisabled];
    [self.sendBtn addTarget:self action:@selector(sendEmoticonAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.extBtn = [[UIButton alloc] init];
    [self.extBtn setBackgroundImage:[UIImage easeUIImageNamed:@"EmojiExt"] forState:UIControlStateNormal];
    
    self.deleteBtn = [[UIButton alloc]init];
    self.deleteBtn.backgroundColor = [UIColor clearColor];
    [self.deleteBtn setBackgroundImage:[UIImage easeUIImageNamed:@"deleteEmoticon"] forState:UIControlStateNormal];
    [self.deleteBtn setBackgroundImage:[UIImage easeUIImageNamed:@"deleteEmoticonDisable"] forState:UIControlStateDisabled];
    [self.deleteBtn addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.bottomScrollView = [[UIScrollView alloc] init];
    self.bottomScrollView.scrollEnabled = NO;
    self.bottomScrollView.backgroundColor = [UIColor whiteColor];;
    self.bottomScrollView.contentSize = CGSizeMake(itemWidth * count, self.bottomHeight);
    [self addSubview:self.bottomScrollView];
    [self.bottomScrollView Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    for (int i = 0; i < count; i++) {
        UIButton *button = [[UIButton alloc] init];
        button.tag = i;
        [button addTarget:self action:@selector(segmentedButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomScrollView addSubview:button];
        [button Ease_makeConstraints:^(EaseConstraintMaker *make) {
            make.top.equalTo(self.bottomView);
            make.left.equalTo(self.bottomView).offset(i * itemWidth);
            make.width.Ease_equalTo(itemWidth);
            make.height.Ease_equalTo(self.bottomHeight);
        }];
        
        id icon = [self.groups[i] icon];
        if ([icon isKindOfClass:[UIImage class]]) {
            button.imageEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0);
            button.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [button setImage:(UIImage *)icon forState:UIControlStateNormal];
        } else if ([icon isKindOfClass:[NSString class]]) {
            button.titleLabel.font = [UIFont fontWithName:@"AppleColorEmoji" size:18.0];
            [button setTitle:(NSString *)icon forState:UIControlStateNormal];
        }
        [self.emotionButtons addObject:button];
    }
}

- (void)_setupEmotionViews
{
    self.emotionBgView = [[UIView alloc] init];
    self.emotionBgView.backgroundColor = [UIColor colorWithHexString:@"#EAEBEC"];
    [self addSubview:self.emotionBgView];
    [self.emotionBgView Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.bottom.equalTo(self.bottomView.ease_top);
    }];
    
    NSInteger count = [self.groups count];
    for (int i = 0; i < count; i++) {
        EaseEmoticonGroup *emoticonGroup = self.groups[i];
        if (emoticonGroup.type == EMEmotionTypeEmoji) {
            EMEmoticonView *view = [[EMEmoticonView alloc] initWithEmotionGroup:emoticonGroup];
            view.delegate = self;
            view.viewHeight = self.viewHeight - self.bottomHeight-40;
            [self.emotionViews addObject:view];
        } else {
            EMEmoticonView *view = [[EMEmoticonView alloc] initWithEmotionGroup:emoticonGroup];
            view.delegate = self;
            view.viewHeight = self.viewHeight - self.bottomHeight;
            [self.emotionViews addObject:view];
        }
    }
}

#pragma mark - Data

- (void)_initDataSource
{
    _viewHeight = 300;
    _bottomHeight = 0;
    self.groups = [[NSMutableArray alloc] init];
    self.emotionViews = [[NSMutableArray alloc] init];
    self.emotionButtons = [[NSMutableArray alloc] init];
    
//    NSArray *emojis = [EaseEmojiHelper getAllEmojis];
//    NSMutableArray *models1 = [[NSMutableArray alloc] init];
//    for (NSString *emoji in emojis) {
//        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypeEmoji];
//        model.eId = emoji;
//        model.name = emoji;
//        model.original = emoji;
//        [models1 addObject:model];
//    }
//    NSString *tagImgName = [models1[0] name];
//    EaseEmoticonGroup *group1 = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypeEmoji dataArray:models1 icon:tagImgName rowCount:3 colCount:7];
//    [self.groups addObject:group1];
//    
////    [self.groups addObject:[EaseEmoticonGroup getGifGroup]];
//    NSMutableArray *models2 = [[NSMutableArray alloc] init];
//    NSArray *names = @[@"icon_emo_001",@"icon_emo_002",@"icon_emo_003",@"icon_emo_004",@"icon_emo_005",@"icon_emo_006",@"icon_emo_007",@"icon_emo_008",@"icon_emo_009",@"icon_emo_010",@"icon_emo_011",@"icon_emo_012",@"icon_emo_013",@"icon_emo_014",@"icon_emo_015",@"icon_emo_016"];
//
//    NSArray *titles = @[@"害羞",
//                        @"期待",
//                        @"像画吗",
//                        @"冲呀",
//                        @"打卡",
//                        @"爱你",
//                        @"加油",
//                        @"失落",
//                        @"在做了",
//                        @"收到",
//                        @"晚安",
//                        @"讲两句",
//                        @"焦虑",
//                        @"抱抱",
//                        @"马上",
//                        @"早鸭"];
//    
//    int index = 0;
//    for (NSString *name in names) {
//        ++index;
//        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
////        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
//        model.eId = [NSString stringWithFormat:@"em%d",(1000 + index)];
////        model.name = [NSString stringWithFormat:@"[示例%d]", index];
//        model.name = titles[index - 1];
//        model.imgName = [NSString stringWithFormat:@"%@_cover", name];
//        model.original = name;
//        [models2 addObject:model];
//    }
//    NSString *tagImgName1 = [models2[0] imgName];
//
////   NSArray  *gGifGroup = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName] rowCount:2 colCount:4];
//    
//    [self.groups addObject:[[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName1] rowCount:2 colCount:4]];
//    
//    
//    
//    
//    NSMutableArray *models3 = [[NSMutableArray alloc] init];
//    NSArray *names3 = @[@"icon_emo_gif_001",@"icon_emo_gif_002",@"icon_emo_gif_003",@"icon_emo_gif_004",@"icon_emo_gif_005",@"icon_emo_gif_006",@"icon_emo_gif_007",@"icon_emo_gif_008",@"icon_emo_gif_009",@"icon_emo_gif_010",@"icon_emo_gif_011",@"icon_emo_gif_012",@"icon_emo_gif_013",@"icon_emo_gif_014",@"icon_emo_gif_015",@"icon_emo_gif_016",@"icon_emo_gif_017",@"icon_emo_gif_018",@"icon_emo_gif_019",@"icon_emo_gif_020",@"icon_emo_gif_021",@"icon_emo_gif_022",@"icon_emo_gif_023",@"icon_emo_gif_024",@"icon_emo_gif_025",@"icon_emo_gif_026",@"icon_emo_gif_027",@"icon_emo_gif_028",@"icon_emo_gif_029",@"icon_emo_gif_030",@"icon_emo_gif_031",@"icon_emo_gif_032"];
//
//
//    NSArray *titles3 = @[@"谢谢",
//                        @"爱你",
//                        @"哈哈哈",
//                        @"在干嘛",
//                        @"嗨",
//                        @"来了",
//                        @"OK",
//                        @"嗯嗯",
//                        @"开会",
//                        @"什么事",
//                        @"晚安",
//                        @"抱抱",
//                        @"累",
//                        @"稍等",
//                        @"辛苦了",
//                        @"生气",
//                        @"达成共识",
//                        @"盯",
//                        @"多喝烫水",
//                        @"疯狂点赞",
//                        @"干饭",
//                        @"功德+1",
//                        @"加油",
//                        @"假期愉快",
//                        @"冥想",
//                        @"你好呀",
//                        @"请过目",
//                        @"哇哦",
//                        @"歪，在吗",
//                        @"早上好",
//                        @"注意保暖",
//                        @"注意防暑"];
//    
//    int index3 = 0;
//    for (NSString *name in names3) {
//        ++index3;
//        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypeGif];
////        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
//        model.eId = [NSString stringWithFormat:@"em%d",(2000 + index3)];
////        model.name = [NSString stringWithFormat:@"[示例%d]", index];
//        model.name = titles3[index3 - 1];
//        model.imgName = [NSString stringWithFormat:@"%@_cover", name];
//        model.original = name;
//        [models3 addObject:model];
//    }
//    NSString *tagImgName3 = [models3[0] imgName];
//
////   NSArray  *gGifGroup = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName] rowCount:2 colCount:4];
//    
//    [self.groups addObject:[[EaseEmoticonGroup alloc] initWithType:EMEmotionTypeGif dataArray:models3 icon:[UIImage easeUIImageNamed:tagImgName3] rowCount:2 colCount:4]];
    
    NSMutableArray *models = [[NSMutableArray alloc] init];
    //图片表情
    NSArray *names = @[@"icon_emo_001",@"icon_emo_002",@"icon_emo_003",@"icon_emo_004",@"icon_emo_005",@"icon_emo_006",@"icon_emo_007",@"icon_emo_008",@"icon_emo_009",@"icon_emo_010",@"icon_emo_011",@"icon_emo_012",@"icon_emo_013",@"icon_emo_014",@"icon_emo_015",@"icon_emo_016"];

    NSArray *titles = @[@"害羞",
                        @"期待",
                        @"像画吗",
                        @"冲呀",
                        @"打卡",
                        @"爱你",
                        @"加油",
                        @"失落",
                        @"在做了",
                        @"收到",
                        @"晚安",
                        @"讲两句",
                        @"焦虑",
                        @"抱抱",
                        @"马上",
                        @"早鸭"];
    
    int index = 0;
    for (NSString *name in names) {
        ++index;
        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
//        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
        model.eId = [NSString stringWithFormat:@"em%d",(1000 + index)];
//        model.name = [NSString stringWithFormat:@"[示例%d]", index];
        model.name = titles[index - 1];
        model.imgName = [NSString stringWithFormat:@"%@_cover", name];
        model.original = name;
        [models addObject:model];
    }
    //动图表情
    NSArray *names3 = @[@"icon_emo_gif_001",@"icon_emo_gif_002",@"icon_emo_gif_003",@"icon_emo_gif_004",@"icon_emo_gif_005",@"icon_emo_gif_006",@"icon_emo_gif_007",@"icon_emo_gif_008",@"icon_emo_gif_009",@"icon_emo_gif_010",@"icon_emo_gif_011",@"icon_emo_gif_012",@"icon_emo_gif_013",@"icon_emo_gif_014",@"icon_emo_gif_015",@"icon_emo_gif_016",@"icon_emo_gif_017",@"icon_emo_gif_018",@"icon_emo_gif_019",@"icon_emo_gif_020",@"icon_emo_gif_021",@"icon_emo_gif_022",@"icon_emo_gif_023",@"icon_emo_gif_024",@"icon_emo_gif_025",@"icon_emo_gif_026",@"icon_emo_gif_027",@"icon_emo_gif_028",@"icon_emo_gif_029",@"icon_emo_gif_030",@"icon_emo_gif_031",@"icon_emo_gif_032"];


    NSArray *titles3 = @[@"谢谢",
                        @"爱你",
                        @"哈哈哈",
                        @"在干嘛",
                        @"嗨",
                        @"来了",
                        @"OK",
                        @"嗯嗯",
                        @"开会",
                        @"什么事",
                        @"晚安",
                        @"抱抱",
                        @"累",
                        @"稍等",
                        @"辛苦了",
                        @"生气",
                        @"达成共识",
                        @"盯",
                        @"多喝烫水",
                        @"疯狂点赞",
                        @"干饭",
                        @"功德+1",
                        @"加油",
                        @"假期愉快",
                        @"冥想",
                        @"你好呀",
                        @"请过目",
                        @"哇哦",
                        @"歪，在吗",
                        @"早上好",
                        @"注意保暖",
                        @"注意防暑"];
    int index3 = 0;
    for (NSString *name in names3) {
        ++index3;
        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypeGif];
//        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
        model.eId = [NSString stringWithFormat:@"em%d",(2000 + index3)];
//        model.name = [NSString stringWithFormat:@"[示例%d]", index];
        model.name = titles3[index3 - 1];
        model.imgName = [NSString stringWithFormat:@"%@_cover", name];
        model.original = name;
        [models addObject:model];
    }
    NSString *tagImgName1 = [models[0] imgName];
    
    [self.groups addObject:[[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models icon:[UIImage easeUIImageNamed:tagImgName1] rowCount:2 colCount:5]];
}

#pragma mark - EMEmoticonViewDelegate

- (void)emoticonViewDidSelectedModel:(EaseEmoticonModel *)aModel
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedEmoticonModel:)]) {
        //保存到本地最近使用的字典里边
        NSArray *dicArray = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"BWLoginUser%@",LoginViewModel.shareModel.userInfo.mobile]];
        NSMutableArray *muArray = [NSMutableArray arrayWithArray:dicArray];
        BOOL exitBag = NO;
        int exitIndex = 0;
        for (int i = 0; i < muArray.count; i ++) {
            NSMutableDictionary *muDic = muArray[i];
            if ([muDic[@"eId"] isEqualToString:aModel.eId]) {
                exitBag = YES;
                exitIndex = i;
                break;
            }
        }
        if (!exitBag) {
            //选的动图不是最近使用的动图
            if (muArray.count > 0) {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                dic[@"eId"] = aModel.eId;
                dic[@"name"] = aModel.name;
                dic[@"imgName"] = aModel.imgName;
                dic[@"original"] = aModel.original;
                [muArray insertObject:dic atIndex:0];
                while (muArray.count > 5) {
                    [muArray removeLastObject];
                }
            } else {
                muArray = [[NSMutableArray alloc] init];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                dic[@"eId"] = aModel.eId;
                dic[@"name"] = aModel.name;
                dic[@"imgName"] = aModel.imgName;
                dic[@"original"] = aModel.original;
                [muArray addObject:dic];
            }
        }else
        {
            //选的动图是最近使用的动图
            if (exitIndex > 0) {
                //说明选的不是第一个，需要把选的放在第一位
                [muArray removeObjectAtIndex:exitIndex];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                dic[@"eId"] = aModel.eId;
                dic[@"name"] = aModel.name;
                dic[@"imgName"] = aModel.imgName;
                dic[@"original"] = aModel.original;
                [muArray insertObject:dic atIndex:0];
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:muArray forKey:[NSString stringWithFormat:@"BWLoginUser%@",LoginViewModel.shareModel.userInfo.mobile]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.delegate didSelectedEmoticonModel:aModel];
    }
}

#pragma mark - Action

- (void)sendEmoticonAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChatBarEmoticonViewSendAction)]) {
        [self.delegate didChatBarEmoticonViewSendAction];
    }
}

- (void)segmentedButtonAction:(UIButton *)aButton
{
    NSInteger tag = aButton.tag;
    if (self.selectedButton && self.selectedButton.tag == tag) {
        return;
    }
    
    if (self.selectedButton) {
        EMEmoticonView *oldView = self.emotionViews[self.selectedButton.tag];
        [oldView removeFromSuperview];
        
        self.selectedButton.selected = NO;
        self.selectedButton.backgroundColor = [UIColor whiteColor];
        self.selectedButton = nil;
    }
    
    aButton.selected = YES;
    aButton.backgroundColor = [UIColor colorWithHexString:@"#F2F2F2"];
    self.selectedButton = aButton;
    
    if (tag == 0) {
        [self.bottomView addSubview:self.extBtn];
        [self.extBtn Ease_makeConstraints:^(EaseConstraintMaker *make) {
            make.top.equalTo(self.bottomView).offset(11);
            make.right.equalTo(self.bottomView.ease_right).offset(-22);
            make.width.height.Ease_equalTo(@18);
        }];
        [self.bottomScrollView Ease_remakeConstraints:^(EaseConstraintMaker *make) {
            make.left.equalTo(self);
            make.right.equalTo(self.extBtn.ease_left);
            make.bottom.equalTo(self);
            make.height.Ease_equalTo(self.bottomHeight);
        }];
//        [self addSubview:self.sendBtn];
//        [self.sendBtn Ease_makeConstraints:^(EaseConstraintMaker *make) {
//            make.bottom.equalTo(self.bottomView.ease_top).offset(-12);
//            make.right.equalTo(self.bottomView.ease_right).offset(-12);
//            make.width.Ease_equalTo(@40);
//            make.height.Ease_equalTo(@30);
//        }];
//        [self addSubview:self.deleteBtn];
//        [self.deleteBtn Ease_makeConstraints:^(EaseConstraintMaker *make) {
//            make.bottom.equalTo(self.bottomView.ease_top).offset(-12);
//            make.right.equalTo(self.sendBtn.ease_left).offset(-22);
//            make.width.Ease_equalTo(@28);
//            make.height.Ease_equalTo(@28);
//        }];
    } else {
        [self.sendBtn removeFromSuperview];
        [self.extBtn removeFromSuperview];
        [self.deleteBtn removeFromSuperview];
        [self.bottomScrollView Ease_remakeConstraints:^(EaseConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    
    //TODO:code
    EMEmoticonView *view = self.emotionViews[tag];
    [self.emotionBgView addSubview:view];
    if (view.emotionGroup.type == EMEmotionTypeEmoji) {
        [view Ease_makeConstraints:^(EaseConstraintMaker *make) {
            make.left.equalTo(self.emotionBgView);
            make.top.equalTo(self.emotionBgView);
            make.right.equalTo(self.emotionBgView);
            make.bottom.equalTo(self.emotionBgView.ease_bottom).offset(-40);
        }];
    } else {
        [view Ease_makeConstraints:^(EaseConstraintMaker *make) {
            make.edges.equalTo(self.emotionBgView);
        }];
    }
}

- (void)deleteAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedTextDetele)]) {
        BOOL isEditing = [self.delegate didSelectedTextDetele];
        [self textDidChange:isEditing];
    }
}

- (void)textDidChange:(BOOL)isEditing
{
    if (!isEditing) {
        self.sendBtn.backgroundColor = [UIColor whiteColor];
        self.sendBtn.enabled = NO;
        self.deleteBtn.enabled = NO;
    } else {
        [self.sendBtn setBackgroundColor:[UIColor colorWithHexString:@"#04AEF0"]];
        self.sendBtn.enabled = YES;
        self.deleteBtn.enabled = YES;
    }
}

@end
