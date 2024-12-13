//
//  EaseEmoticonGroup.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 2019/1/31.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import "EaseEmoticonGroup.h"
#import "EaseHeaders.h"
#import "UIImage+EaseUI.h"
#import "HorizontalLayout.h"
#import "BWCommonUseEmoticonView.h"
#import "LoginViewModel.h"

EaseEmoticonGroup *gGifGroup = nil;
EaseEmoticonGroup *gGifGroup3 = nil;

@implementation EaseEmoticonModel

- (instancetype)initWithType:(EMEmotionType)aType
{
    self = [super init];
    if (self) {
        _type = aType;
    }
    
    return self;
}

@end


@implementation EaseEmoticonGroup

- (instancetype)initWithType:(EMEmotionType)aType
                   dataArray:(NSArray<EaseEmoticonModel *> *)aDataArray
                        icon:(UIImage *)aIcon
                    rowCount:(NSInteger)aRowCount
                    colCount:(NSInteger)aColCount
{
    self = [super init];
    if (self) {
        _type = aType;
        _dataArray = aDataArray;
        _icon = aIcon;
        _rowCount = aRowCount;
        _colCount = aColCount;
    }
    
    return self;
}

+ (instancetype)getGifGroup
{
    //    if (gGifGroup) {
    //        return gGifGroup;
    //    }
        
        NSMutableArray *models2 = [[NSMutableArray alloc] init];
    //    NSArray *names = @[@"icon_002",@"icon_007",@"icon_010",@"icon_012",@"icon_013",@"icon_018",@"icon_019",@"icon_020",@"icon_021",@"icon_022",@"icon_024",@"icon_027",@"icon_029",@"icon_030",@"icon_035",@"icon_040"];
        
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
    //        EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypeGif];
            EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
            model.eId = [NSString stringWithFormat:@"em%d",(1000 + index)];
    //        model.name = [NSString stringWithFormat:@"[示例%d]", index];
            model.name = titles[index - 1];
            model.imgName = [NSString stringWithFormat:@"%@_cover", name];
            model.original = name;
            [models2 addObject:model];
        }
        NSString *tagImgName = [models2[0] imgName];
    //    gGifGroup = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypeGif dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName] rowCount:2 colCount:4];
    //    gGifGroup = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName] rowCount:2 colCount:4];
        gGifGroup = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName] rowCount:2 colCount:4];
        
        
        return gGifGroup;
}

+ (instancetype)getGifGroup1
{
    
    NSMutableArray *models3 = [[NSMutableArray alloc] init];
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
        [models3 addObject:model];
    }
    NSString *tagImgName3 = [models3[0] imgName];

//   NSArray  *gGifGroup = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypePng dataArray:models2 icon:[UIImage easeUIImageNamed:tagImgName] rowCount:2 colCount:4];
    
    gGifGroup3 = [[EaseEmoticonGroup alloc] initWithType:EMEmotionTypeGif dataArray:models3 icon:[UIImage easeUIImageNamed:tagImgName3] rowCount:2 colCount:4];
    
    
    return gGifGroup3;
    
    
}

@end


@implementation EMEmoticonCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupSubviews];
    }
    
    return self;
}

#pragma mark - Subviews

- (void)_setupSubviews
{
    self.backgroundColor = [UIColor clearColor];
    
    self.imgView = [[UIImageView alloc] init];
    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imgView];
    [self.imgView Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self);
    }];
    
    self.label = [[UILabel alloc] init];
    self.label.textColor = [UIColor grayColor];
    self.label.font = [UIFont systemFontOfSize:14];
    [self addSubview:self.label];
    [self.label Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.top.equalTo(self.imgView.ease_bottom).offset(5);
        make.centerX.equalTo(self);
        make.bottom.equalTo(self);
        make.height.greaterThanOrEqualTo(@14);
    }];
}

#pragma mark - Setter

- (void)setModel:(EaseEmoticonModel *)model
{
    _model = model;
    
    if (model.type == EMEmotionTypeEmoji) {
        self.label.font = [UIFont fontWithName:@"AppleColorEmoji" size:29.0];
    }
    self.label.text = model.name;
    
    if ([model.imgName length] > 0) {
        self.imgView.image = [UIImage easeUIImageNamed:model.imgName];
    }
}

@end


@interface EMEmoticonView()<UICollectionViewDataSource, UICollectionViewDelegate,BWCommonUseEmoticonViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic) CGSize itemSize;

@property (nonatomic) CGFloat itemMargin;
@property (nonatomic,strong) NSMutableArray *commonArray;

@end

@implementation EMEmoticonView

-(NSMutableArray *)commonArray
{
    if (!_commonArray) {
        _commonArray = [[NSMutableArray alloc] init];
    }
    return _commonArray;
}

- (instancetype)initWithEmotionGroup:(EaseEmoticonGroup *)aEmotionGroup
{
    self = [super init];
    if (self) {
        _emotionGroup = aEmotionGroup;
        
        _viewHeight = 170;
        _itemMargin = 8;
        CGFloat width = ([UIScreen mainScreen].bounds.size.width - (_itemMargin * (aEmotionGroup.colCount + 1))) / aEmotionGroup.colCount;
        CGFloat height = (_viewHeight - (_itemMargin * (aEmotionGroup.rowCount + 1))) / aEmotionGroup.rowCount;
        _itemSize = CGSizeMake(width, height);
        
        NSMutableArray *dicArray = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"BWLoginUser%@",LoginViewModel.shareModel.userInfo.mobile]];
        if (self.commonArray.count > 0) {
            [self.commonArray removeAllObjects];
        }
        for (int i = 0; i < dicArray.count; i ++) {
            NSDictionary *dic = dicArray[i];
            EaseEmoticonModel *model = [[EaseEmoticonModel alloc] initWithType:EMEmotionTypePng];
            model.eId = [NSString stringWithFormat:@"%@",dic[@"eId"]];
            model.name = [NSString stringWithFormat:@"%@",dic[@"name"]];
            model.imgName = [NSString stringWithFormat:@"%@",dic[@"imgName"]];
            model.original = [NSString stringWithFormat:@"%@",dic[@"original"]];
            [self.commonArray addObject:model];
        }
        
        [self _setupSubviews];
    }
    
    return self;
}

#pragma mark - Subviews

- (void)_setupSubviews
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
//    HorizontalLayout *layout = [[HorizontalLayout alloc] initWithOffset:([UIScreen mainScreen].bounds.size.width - _itemSize.width * 7)/8 yOffset:(_viewHeight - _itemSize.height * 3)/4];
//    layout.itemSize = CGSizeMake(_itemSize.width, _itemSize.height);
//    layout.rowCount = 7;
//    layout.columCount = 5;
//    layout.itemCountSum = 35;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:_emotionGroup.type == EMEmotionTypeEmoji ? flowLayout : flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.alwaysBounceHorizontal = NO;
//    self.collectionView.pagingEnabled = _emotionGroup.type == EMEmotionTypeEmoji ? YES : NO;
    //    self.collectionView.userInteractionEnabled = YES;
    [self.collectionView registerClass:[EMEmoticonCell class] forCellWithReuseIdentifier:@"EMEmoticonCell"];
    [_collectionView registerClass:[BWCommonUseEmoticonView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BWCommonUseEmoticonView"];
    [self addSubview:self.collectionView];
    [self.collectionView Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.emotionGroup.type == EMEmotionTypeEmoji) {
        if ([self.emotionGroup.dataArray count] < 35) {
            return 1;
        }
        if ([self.emotionGroup.dataArray count] % 35 == 0) {
            return [self.emotionGroup.dataArray count] / 21;
        }
        return [self.emotionGroup.dataArray count] / 35 + 1;
    } else {
        return 1;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.emotionGroup.type == EMEmotionTypeEmoji) {
        if ([self.emotionGroup.dataArray count] < 35) {
            return [self.emotionGroup.dataArray count];
        }
        return 35;
    } else {
        return [self.emotionGroup.dataArray count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EMEmoticonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EMEmoticonCell" forIndexPath:indexPath];
    long count = indexPath.section * 35 + indexPath.row;
    if (count >= [self.emotionGroup.dataArray count]) {
        cell.model = [[EaseEmoticonModel alloc]initWithType:EMEmotionTypeEmoji];
        return cell;
    }
    cell.model = self.emotionGroup.dataArray[indexPath.section * 35 + indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    EMEmoticonCell *cell = (EMEmoticonCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (self.delegate && [self.delegate respondsToSelector:@selector(emoticonViewDidSelectedModel:)]) {
        [self.delegate emoticonViewDidSelectedModel:cell.model];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.itemSize;
}

// 设置UIcollectionView整体的内边距（这样item不贴边显示）
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // 上 左 下 右
    return UIEdgeInsetsMake(self.itemMargin, self.itemMargin, self.itemMargin+EMVIEWBOTTOMMARGIN, self.itemMargin);
}

//设置minimumLineSpacing：cell上下之间最小的距离
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemMargin;
}

// 设置minimumInteritemSpacing：cell左右之间最小的距离
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemMargin;
}

// 要先设置表头大小
- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.commonArray.count > 0) {
        CGSize size = CGSizeMake(UIScreen.mainScreen.bounds.size.width, 179);
        return size;
    } else {
        return CGSizeZero;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ((kind == UICollectionElementKindSectionHeader) && (self.commonArray.count > 0)) {
        BWCommonUseEmoticonView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                    withReuseIdentifier:@"BWCommonUseEmoticonView"
                                                                                           forIndexPath:indexPath];
        headView.delegate = self;
        headView.dataArray = [self.commonArray mutableCopy];
        return headView;
    }else {
        UICollectionReusableView *reusableView = nil;
        return reusableView;
    }
    return nil;
}

#pragma mark - BWCommonUseEmoticonViewDelegate
-(void)BWCommonUseEmoticonViewDidSelectedModel:(EaseEmoticonModel *)model
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(emoticonViewDidSelectedModel:)]) {
        [self.delegate emoticonViewDidSelectedModel:model];
    }
}

@end
