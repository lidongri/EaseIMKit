//
//  EaseChatViewController.m
//  EaseIM
//
//  Update by zhangchong on 2020/2.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
//#import <AVFoundation/AVFoundation.h>
//#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "EaseChatViewController.h"
#import "EMImageBrowser.h"
#import "EaseDateHelper.h"
#import "EaseMessageModel.h"
#import "EaseMessageCell.h"
#import "EMAudioPlayerUtil.h"
#import "EMMessageTimeCell.h"
#import "EMMsgTouchIncident.h"
#import "EaseChatViewController+EMMsgLongPressIncident.h"
#import "EaseChatViewController+ChatToolBarIncident.h"
#import "UITableView+Refresh.h"
#import "EMConversation+EaseUI.h"
#import "EMSingleChatViewController.h"
#import "EMGroupChatViewController.h"
#import "EMChatroomViewController.h"
#import "EaseIMKitManager+ExtFunction.h"
#import "UIViewController+ComponentSize.h"
#import "EaseHeaders.h"
#import "EaseEnums.h"
#import "EaseDefines.h"
#import "BWLoginModel.h"
#import "LoginViewModel.h"
#import "UserInfoStore.h"
#import "EMChatMessage+EaseUIExt.h"
#import <MJRefresh/MJRefresh.h>

@interface EaseChatViewController ()<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, EMChatManagerDelegate, EMChatBarDelegate, EaseMessageCellDelegate, EaseChatBarEmoticonViewDelegate, EMChatBarRecordAudioViewDelegate, EMMoreFunctionViewDelegate>
{
    EaseChatViewModel *_viewModel;
    EaseMessageCell *_currentLongPressCell;
    UITableViewCell *_currentLongPressCustomCell;
    BOOL _isReloadViewWithModel; //重新刷新会话页面
}
@property (nonatomic, strong) EMMoreFunctionView *longPressView;
@property (nonatomic, strong) dispatch_queue_t msgQueue;
@property (nonatomic, strong) NSMutableArray<EMChatMessage *> *messageList;
@end

@implementation EaseChatViewController

+ (EaseChatViewController *)initWithConversationId:(NSString *)aConversationId
                      conversationType:(EMConversationType)aType
                         chatViewModel:(EaseChatViewModel *)aModel
{
    
    switch (aType) {
        case EMConversationTypeChat:
        {
            return [[EMSingleChatViewController alloc] initSingleChatViewControllerWithCoversationid:aConversationId
                                                                                           chatViewModel:aModel];
        }
            break;
        case EMConversationTypeGroupChat:
        {
            return [[EMGroupChatViewController alloc] initGroupChatViewControllerWithCoversationid:aConversationId
                                                                                           chatViewModel:aModel];
        }
            break;
        case EMConversationTypeChatRoom:
        {
            return [[EMChatroomViewController alloc] initChatRoomViewControllerWithCoversationid:aConversationId
                                                                                   chatViewModel:aModel];
        }
            break;
        default:
            break;
    }
    return nil;
}


- (instancetype)initChatViewControllerWithCoversationid:(NSString *)conversationId
                                       conversationType:(EMConversationType)conType
                                          chatViewModel:(EaseChatViewModel *)viewModel
{
    self = [super init];
    if (self) {
        _currentConversation = [EMClient.sharedClient.chatManager getConversation:conversationId type:conType createIfNotExist:YES];
        _msgQueue = dispatch_queue_create("EMChatMessage.com", NULL);
        _viewModel = viewModel;
        _isReloadViewWithModel = NO;
        [EaseIMKitManager.shared setConversationId:_currentConversation.conversationId];
        if (!_viewModel) {
            _viewModel = [[EaseChatViewModel alloc] init];
        }
    }
    return self;
}

- (void)resetChatVCWithViewModel:(EaseChatViewModel *)viewModel
{
    _viewModel = viewModel;
    _isReloadViewWithModel = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshTableView:YES];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.msgTimelTag = -1;
    [self _setupChatSubviews];
    /*
    //草稿
    if (![[self.currentConversation draft] isEqualToString:@""]) {
        self.chatBar.textView.text = [self.currentConversation draft];
        [self.currentConversation setDraft:@""];
    }*/
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
 
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapTableViewAction:)];
    [self.tableView addGestureRecognizer:tap];
    
    
    //self.view.backgroundColor = UIColor.grayColor;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [EaseIMKitManager.shared markAllMessagesAsReadWithConversation:self.currentConversation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanPopupControllerView) name:CALL_MAKE1V1 object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanPopupControllerView) name:CALL_MAKECONFERENCE object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    //群聊@“我”提醒
    if(self.currentConversation.type == EMConversationTypeGroupChat && [self.currentConversation remindMe]) {
        [self.currentConversation resetRemindMe];
    };
}

- (void)dealloc
{
    [EaseIMKitManager.shared setConversationId:@""];
    [self hideLongPressView];
    [[EMAudioPlayerUtil sharedHelper] stopPlayer];
    if (self.currentConversation.type == EMChatTypeChatRoom) {
        [[EMClient sharedClient].chatManager deleteServerConversation:self.currentConversation.conversationId conversationType:EMConversationTypeChatRoom isDeleteServerMessages:YES completion:nil];
        [[EMClient sharedClient].chatManager deleteConversation:self.currentConversation.conversationId isDeleteMessages:YES completion:nil];
        [[EMClient sharedClient].roomManager leaveChatroom:self.currentConversation.conversationId completion:nil];
    } else {
        /*
        //草稿
        if (self.chatBar.textView.text.length > 0) {
            [self.currentConversation setDraft:self.chatBar.textView.text];
        }*/
    }
    //刷新会话列表
    [[NSNotificationCenter defaultCenter] postNotificationName:CONVERSATIONLIST_UPDATE object:nil];
    [[EMClient sharedClient].chatManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Subviews

- (void)_setupChatSubviews
{
    self.view.backgroundColor = [UIColor clearColor];
    
    self.chatBar = [[EMChatBar alloc] initWithViewModel:_viewModel];
    self.chatBar.delegate = self;
    [self.view addSubview:self.chatBar];
    [self.chatBar Ease_makeConstraints:^(EaseConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    //会话工具栏
    [self _setupChatBarMoreViews];
    
    self.chooseView = [UIView new];
    self.chooseView.backgroundColor = _viewModel.chatViewBgColor;
    [self.view addSubview:self.chooseView];

    [self.chooseView Ease_remakeConstraints:^(EaseConstraintMaker *make) {
        make.height.equalTo(@0);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.chatBar.ease_top);
    }];
    
    self.tableView.backgroundColor = [UIColor colorWithHexString:@"f7f8fa"];
    [self.view addSubview:self.tableView];
    [self.tableView Ease_remakeConstraints:^(EaseConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.chooseView.ease_top).offset(-ceilf([UIScreen mainScreen].bounds.size.width/375.0*40));
    }];
}

-(void)setJianpanStr:(NSString *)jianpanStr
{
    _jianpanStr = jianpanStr;
    
}

-(void)setRole:(NSString *)role
{
    _role = role;
}

-(void)setComeHomeCounselor:(NSInteger)comeHomeCounselor
{
    _comeHomeCounselor = comeHomeCounselor;
    if (comeHomeCounselor == 1) {
        [self.tableView Ease_remakeConstraints:^(EaseConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.bottom.equalTo(self.chooseView.ease_top).offset(-ceilf([UIScreen mainScreen].bounds.size.width/375.0*40));
        }];
    } else {
        [self.tableView Ease_remakeConstraints:^(EaseConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.bottom.equalTo(self.chooseView.ease_top).offset(0);
        }];
    }
}

- (void)_setupChatBarMoreViews
{
    //语音
    NSString *path = [self getAudioOrVideoPath];
    EMChatBarRecordAudioView *recordView = [[EMChatBarRecordAudioView alloc] initWithRecordPath:path];
    recordView.delegate = self;
    self.chatBar.recordAudioView = recordView;
    //表情
    EaseChatBarEmoticonView *moreEmoticonView = [[EaseChatBarEmoticonView alloc] init];
    moreEmoticonView.delegate = self;
    self.chatBar.moreEmoticonView = moreEmoticonView;
    
    //更多
    __weak typeof(self) weakself = self;
    EaseExtMenuModel *photoAlbumExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"photo-album"] funcDesc:@"相册" handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself chatToolBarComponentIncidentAction:EMChatToolBarPhotoAlbum];
    }];
    EaseExtMenuModel *cameraExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"camera"] funcDesc:@"相机" handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself chatToolBarComponentIncidentAction:EMChatToolBarCamera];
    }];
    EaseExtMenuModel *locationExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"location"] funcDesc:@"位置" handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself chatToolBarLocationAction];
    }];
    EaseExtMenuModel *fileExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"icloudFile"] funcDesc:@"文件" handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself chatToolBarFileOpenAction];
    }];
    
    
    
    
    
    NSMutableArray<EaseExtMenuModel*> *extMenuArray = [@[photoAlbumExtModel,cameraExtModel,locationExtModel,fileExtModel] mutableCopy];
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputBarExtMenuItemArray:conversationType:)]) {
        extMenuArray = [self.delegate inputBarExtMenuItemArray:extMenuArray conversationType:_currentConversation.type];
    }
    EMMoreFunctionView *moreFunction = [[EMMoreFunctionView alloc]initWithextMenuModelArray:extMenuArray menuViewModel:[[EaseExtMenuViewModel alloc]initWithType:ExtTypeChatBar itemCount:[extMenuArray count] extFuncModel:_viewModel.extFuncModel]];
    self.chatBar.moreFunctionView = moreFunction;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = [self.dataArray objectAtIndex:indexPath.row];
    NSString *cellString = nil;
    EaseWeakRemind type = EaseWeakRemindMsgTime;
    if ([obj isKindOfClass:[NSString class]]) {
        cellString = (NSString *)obj;
    }
    if ([obj isKindOfClass:[EaseMessageModel class]]) {
        EaseMessageModel *model = (EaseMessageModel *)obj;
        if (model.type == EMMessageTypeExtRecall) {
            if ([model.message.from isEqualToString:EMClient.sharedClient.currentUsername]) {
                cellString = @"您撤回一条消息";
            } else {
                cellString = @"对方撤回一条消息";
            }
            type = EaseWeakRemindSystemHint;
        }
        if (model.type == EMMessageTypeExtNewFriend || model.type == EMMessageTypeExtAddGroup) {
            if ([model.message.body isKindOfClass:[EMTextMessageBody class]]) {
                cellString = ((EMTextMessageBody *)(model.message.body)).text;
                type = EaseWeakRemindSystemHint;
            }else if ([model.message.body isKindOfClass:[EMCustomMessageBody class]])
            {
                cellString = [self getCustomTextWithExt:model];
                type = EaseWeakRemindSystemHint;
            }
        }
    }
    
    if (cellString.length > 0) {
        NSString *identifier = (type == EaseWeakRemindMsgTime) ? @"EMMessageTimeCell" : @"EMMessageSystemHint";
        EMMessageTimeCell *cell = (EMMessageTimeCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        // Configure the cell...
        if (cell == nil) {
            cell = [[EMMessageTimeCell alloc] initWithViewModel:_viewModel remindType:type];
        }
        cell.timeLabel.text = cellString;
        return cell;
    }
    
    EaseMessageModel *model = (EaseMessageModel *)obj;
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellForItem:messageModel:)]) {
        UITableViewCell *customCell = [self.delegate cellForItem:tableView messageModel:model];
        if (customCell) {
            UILongPressGestureRecognizer *customCelllongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(customCellLongPressAction:)];
            [customCell addGestureRecognizer:customCelllongPress];
            return customCell;
        }
    }
    NSString *identifier = [EaseMessageCell cellIdentifierWithDirection:model.direction type:model.type];
    EaseMessageCell *cell = (EaseMessageCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    // Configure the cell...
    if (cell == nil || _isReloadViewWithModel == YES) {
        _isReloadViewWithModel = NO;
        cell = [[EaseMessageCell alloc] initWithDirection:model.direction chatType:model.message.chatType messageType:model.type viewModel:_viewModel];
        cell.delegate = self;
    }
    cell.model = model;
    if (cell.model.message.body.type == EMMessageTypeVoice) {
        cell.model.weakMessageCell = cell;
    }
    return cell;
}

//获取自定义消息文本
-(NSString *)getCustomTextWithExt:(EaseMessageModel *)model{
    EMCustomMessageBody *customBody = (EMCustomMessageBody *)model.message.body;
    EMUserInfo* userInfo = [[UserInfoStore sharedInstance] getUserInfoById:customBody.customExt[@"to"]];
    if ([customBody.event containsString:@"welcome"]) {
        return [NSString stringWithFormat:@"欢迎%@加入房间",userInfo.nickname];
    }
    if(userInfo) {
        BWLoginModel *data = [LoginViewModel shareModel].userInfo;
        NSString *you = @"我";
        NSString *hugText = @"";
        if ( ![data.mobile isEqualToString:model.message.from]) {
            if (![data.mobile isEqualToString:customBody.customExt[@"to"]]) {
                EMUserInfo* info = [[UserInfoStore sharedInstance] getUserInfoById:model.message.from];
                you = info.nickname;
                if ([customBody.event containsString:@"hug"]) {
                    hugText = [NSString stringWithFormat:@"\"%@\"抱了抱\"%@\"",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"add_one"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"认同了\"%@\"",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"thank"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"感谢了\"%@\"",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"applaud"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向\"%@\"鼓掌",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"comfort"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"安慰了\"%@\"",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"heart"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向\"%@\"比心",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"huanhu"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"对\"%@\"欢呼",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"hello"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向\"%@\"说Hi",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"woshou"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向\"%@\"握手",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"zan"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"点赞了\"%@\"",you,userInfo.nickname];
                }else if ([customBody.event containsString:@"friend"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向\"%@\"交朋友",you,userInfo.nickname];
                }else
                {
                    hugText = @"自定义消息";
                }
            } else {
                EMUserInfo* info = [[UserInfoStore sharedInstance] getUserInfoById:model.message.from];
                you = info.nickname;
                if ([customBody.event containsString:@"hug"]) {
                    hugText = [NSString stringWithFormat:@"\"%@\"抱了抱%@",you,@"我"];
                }else if ([customBody.event containsString:@"add_one"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"认同了%@",you,@"我"];
                }else if ([customBody.event containsString:@"thank"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"感谢了%@",you,@"我"];
                }else if ([customBody.event containsString:@"applaud"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向%@鼓掌",you,@"我"];
                }else if ([customBody.event containsString:@"comfort"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"安慰了%@",you,@"我"];
                }else if ([customBody.event containsString:@"heart"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向%@比心",you,@"我"];
                }else if ([customBody.event containsString:@"huanhu"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"对%@欢呼",you,@"我"];
                }else if ([customBody.event containsString:@"hello"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向%@说Hi",you,@"我"];
                }else if ([customBody.event containsString:@"woshou"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向%@握手",you,@"我"];
                }else if ([customBody.event containsString:@"zan"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"点赞了%@",you,@"我"];
                }else if ([customBody.event containsString:@"friend"]){
                    hugText = [NSString stringWithFormat:@"\"%@\"向%@交朋友",you,@"我"];
                }else
                {
                    hugText = @"自定义消息";
                }
            }
        }else
        {
            if ([customBody.event containsString:@"hug"]) {
                hugText = [NSString stringWithFormat:@"%@抱了抱\"%@\"",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"add_one"]){
                hugText = [NSString stringWithFormat:@"%@认同了\"%@\"",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"thank"]){
                hugText = [NSString stringWithFormat:@"%@感谢了\"%@\"",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"applaud"]){
                hugText = [NSString stringWithFormat:@"%@向\"%@\"鼓掌",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"comfort"]){
                hugText = [NSString stringWithFormat:@"%@安慰了\"%@\"",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"heart"]){
                hugText = [NSString stringWithFormat:@"%@向\"%@\"比心",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"huanhu"]){
                hugText = [NSString stringWithFormat:@"%@对\"%@\"欢呼",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"hello"]){
                hugText = [NSString stringWithFormat:@"%@向\"%@\"说Hi",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"woshou"]){
                hugText = [NSString stringWithFormat:@"%@向\"%@\"握手",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"zan"]){
                hugText = [NSString stringWithFormat:@"%@点赞了\"%@\"",you,userInfo.nickname];
            }else if ([customBody.event containsString:@"friend"]){
                hugText = [NSString stringWithFormat:@"%@向\"%@\"交朋友",you,userInfo.nickname];
            }else
            {
                hugText = @"自定义消息";
            }
        }
        return hugText;
    }
    return @"自定义消息";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"indexpath.row : %ld ", (long)indexPath.row);
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.dataArray || [self.dataArray count] == 0 || ([self.dataArray count] - 1) < indexPath.row) return;
    id obj = [self.dataArray objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[EaseMessageModel class]]) {
        EaseMessageModel *model = (EaseMessageModel *)obj;
        if (model.message.body.type == EMMessageTypeVoice && model.weakMessageCell == cell) {
            model.weakMessageCell = nil;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
    [self.chatBar clearMoreViewAndSelectedButton];
    [self hideLongPressView];
}

#pragma mark - EMChatBarDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        BOOL isValid = [self.delegate textView:textView shouldChangeTextInRange:range replacementText:text];
        return isValid;
    }
    return YES;
}

- (void)chatBarSendMsgAction:(NSString *)text
{
    if ((text.length > 0 && ![text isEqualToString:@""])) {
        if (self.chatBar.quoteMessage) {
            NSDictionary *msgTypeDict = @{
                @(EMMessageBodyTypeText): @"txt",
                @(EMMessageBodyTypeImage): @"img",
                @(EMMessageBodyTypeVideo): @"video",
                @(EMMessageBodyTypeVoice): @"audio",
                @(EMMessageBodyTypeCustom): @"custom",
                @(EMMessageBodyTypeCmd): @"cmd",
                @(EMMessageBodyTypeFile): @"file",
                @(EMMessageBodyTypeLocation): @"location",
                @(EMMessageBodyTypeCombine): @"combine",
            };
            [self sendTextAction:text ext:@{@"msgQuote": @{
                @"msgID": self.chatBar.quoteMessage.message.messageId,
                @"msgPreview": self.chatBar.quoteMessage.message.easeUI_quoteShowText,
                @"msgSender": self.chatBar.quoteMessage.message.from,
                @"msgType": msgTypeDict[@(self.chatBar.quoteMessage.message.body.type)]
            }}];
            self.chatBar.quoteMessage = nil;
        } else {
            [self sendTextAction:text ext:nil];
        }
        [self.chatBar clearInputViewText];
    }
}

- (void)chatBarDidShowMoreViewAction
{
    [self hideLongPressView];
    if (self.comeHomeCounselor == 1) {
        [self.tableView Ease_updateConstraints:^(EaseConstraintMaker *make) {
            make.bottom.equalTo(self.chooseView.ease_top).offset(-ceilf([UIScreen mainScreen].bounds.size.width/375.0*40));
        }];
    } else {
        [self.tableView Ease_updateConstraints:^(EaseConstraintMaker *make) {
            make.bottom.equalTo(self.chooseView.ease_top).offset(0);
        }];
    }
    
    [self performSelector:@selector(scrollToBottomRow) withObject:nil afterDelay:0.1];
}

- (NSString *)chatBarQuoteMessageShowContent:(EMChatMessage *)message
{
    if (_delegate && [_delegate respondsToSelector:@selector(chatBarQuoteMessageShowContent:)]) {
        return [_delegate chatBarQuoteMessageShowContent:message];
    }
    return nil;
}

- (NSAttributedString *)quoteViewShowContent:(EMChatMessage *)message
{
    if (_delegate && [_delegate respondsToSelector:@selector(messageCellQuoteViewShowContent:)]) {
        return [_delegate messageCellQuoteViewShowContent:message];
    }
    return nil;
}

#pragma mark - EMChatBarRecordAudioViewDelegate

- (void)chatBarRecordAudioViewStopRecord:(NSString *)aPath
                              timeLength:(NSInteger)aTimeLength
{
    EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithLocalPath:aPath displayName:@"audio"];
    body.duration = (int)aTimeLength;
    if(body.duration < 1){
        [self showHint:EaseLocalizableString(@"voicetooshor", nil)];
        return;
    }
    [self sendMessageWithBody:body ext:nil];
}

#pragma mark - EaseChatBarEmoticonViewDelegate

- (BOOL)didSelectedTextDetele
{
    return [self.chatBar deleteTailText];
}

- (void)didSelectedEmoticonModel:(EaseEmoticonModel *)aModel
{
    if (aModel.type == EMEmotionTypeEmoji) {
        [self.chatBar inputViewAppendText:aModel.name];
    }
    
    if (aModel.type == EMEmotionTypeGif) {
        NSDictionary *ext = @{MSG_EXT_GIF:@(YES), MSG_EXT_GIF_ID:aModel.eId};
//        [self sendTextAction:aModel.name ext:ext];
        
        [self sendTextAction:[NSString stringWithFormat:@"%@",aModel.name] ext:ext];
    }
    
    if (aModel.type == EMEmotionTypePng) {
        //使用gif图的布局
        NSDictionary *ext = @{MSG_EXT_GIF:@(YES), MSG_EXT_GIF_ID:aModel.eId};
//        [self sendTextAction:aModel.name ext:ext];
        [self sendTextAction:[NSString stringWithFormat:@"%@",aModel.name] ext:ext];
        
        
//        [self sendMessageWithBody:aModel ext:ext];
//
//
//        EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:aText];
//        [self sendMessageWithBody:body ext:aExt];
//
    
        
        
    }
}

- (void)didChatBarEmoticonViewSendAction
{
    [self sendTextAction:self.chatBar.textView.text ext:nil];
}

#pragma mark - EaseMessageCellDelegate

- (void)messageCellDidSelected:(EaseMessageCell *)aCell
{
    [self hideLongPressView];
    BOOL isCustom = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectMessageItem:userData:)]) {
        isCustom = [self.delegate didSelectMessageItem:aCell.model.message userData:aCell.model.userDataDelegate];
        if (!isCustom) return;
    }
    //消息事件策略分类
    EMMessageEventStrategy *eventStrategy = [EMMessageEventStrategyFactory getStratrgyImplWithMsgCell:aCell];
    eventStrategy.chatController = self;
    [eventStrategy messageCellEventOperation:aCell];
}
//消息长按事件
- (void)messageCellDidLongPress:(UITableViewCell *)aCell cgPoint:(CGPoint)point
{
    if (aCell != _currentLongPressCell) {
        [self hideLongPressView];
    }
    self.longPressIndexPath = [self.tableView indexPathForCell:aCell];
    __weak typeof(self) weakself = self;
    EaseExtMenuModel *copyExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"copy"] funcDesc:EaseLocalizableString(@"copy", nil) handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself copyLongPressAction];
    }];
    EaseExtMenuModel *deleteExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"delete"] funcDesc:EaseLocalizableString(@"delete", nil) handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself deleteLongPressAction:^(EMChatMessage *deleteMsg) {
            if (deleteMsg) {
                NSUInteger index = [weakself.messageList indexOfObject:deleteMsg];
                if (index != -1) {
                    [weakself.messageList removeObject:deleteMsg];
                }
            }
        }];
    }];
    EaseExtMenuModel *recallExtModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"recall"] funcDesc:EaseLocalizableString(@"recall", nil) handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        [weakself recallLongPressAction];
    }];
//    EaseExtMenuModel *quoteModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"quote"] funcDesc:EaseLocalizableString(@"chat.quote", nil) handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
//        EaseMessageModel *model = [weakself.dataArray objectAtIndex:weakself.longPressIndexPath.row];
//        weakself.chatBar.quoteMessage = model;
//        [weakself.chatBar.textView becomeFirstResponder];
//    }];
    EaseExtMenuModel *quoteModel = [[EaseExtMenuModel alloc]initWithData:[UIImage easeUIImageNamed:@"replyImage"] funcDesc:@"回复" handle:^(NSString * _Nonnull itemDesc, BOOL isExecuted) {
        EaseMessageModel *model = [weakself.dataArray objectAtIndex:weakself.longPressIndexPath.row];
        weakself.chatBar.quoteMessage = model;
        [weakself.chatBar.textView becomeFirstResponder];
    }];
    
    NSMutableArray<EaseExtMenuModel*> *extMenuArray = [[NSMutableArray<EaseExtMenuModel*> alloc]init];
    BOOL isCustomCell = NO;
    [extMenuArray addObject:copyExtModel];
    [extMenuArray addObject:deleteExtModel];
    
    if (![aCell isKindOfClass:[EaseMessageCell class]]) {
        isCustomCell = YES;
        _currentLongPressCustomCell = aCell;
        if ([aCell respondsToSelector:@selector(model)]) {
            id model = [aCell performSelector:@selector(model)];
            if([model respondsToSelector:@selector(message)]) {
                id message = [model performSelector:@selector(message)];
                long long currentTimestamp = [[NSDate new] timeIntervalSince1970] * 1000;
                if (message && [message isKindOfClass:[EMChatMessage class]]) {
                    if (((EMChatMessage*)message).status == EMMessageStatusSucceed && ((EMChatMessage*)message).direction == EMMessageDirectionSend && (currentTimestamp - ((EMChatMessage*)message).timestamp) <= 120000) {
                        [extMenuArray addObject:recallExtModel];
                    }
                    if(((EMChatMessage*)message).status == EMMessageStatusSucceed) {
                        [extMenuArray addObject:quoteModel];
                    }
                }
            }
        }
    } else {
        _currentLongPressCell = (EaseMessageCell*)aCell;
        if (_currentLongPressCell.model.message.status == EMMessageStatusSucceed)
            [extMenuArray addObject:quoteModel];
        long long currentTimestamp = [[NSDate new] timeIntervalSince1970] * 1000;
        if (_currentLongPressCell.model.message.status == EMMessageStatusSucceed && _currentLongPressCell.model.message.direction == EMMessageDirectionSend && (currentTimestamp - _currentLongPressCell.model.message.timestamp) <= 120000) {
            [extMenuArray addObject:recallExtModel];
        }
    }
    if (isCustomCell) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(customCellLongPressExtMenuItemArray:customCell:)]) {
            //自定义cell长按
            extMenuArray = [self.delegate customCellLongPressExtMenuItemArray:extMenuArray customCell:_currentLongPressCustomCell];
        }
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(messageLongPressExtMenuItemArray:message:)]) {
        //默认消息长按
//        extMenuArray = [self.delegate messageLongPressExtMenuItemArray:extMenuArray message:_currentLongPressCell.model.message];
    }
    if ([extMenuArray count] <= 0) {
        return;
    }

    self.longPressView = [[EMMoreFunctionView alloc]initWithextMenuModelArray:extMenuArray menuViewModel:[[EaseExtMenuViewModel alloc]initWithType:isCustomCell ? ExtTypeCustomCellLongPress : ExtTypeLongPress itemCount:[extMenuArray count] extFuncModel:_viewModel.extFuncModel]];
    self.longPressView.delegate = self;
    
    CGSize longPressViewsize = [self.longPressView getExtViewSize];
    self.longPressView.layer.cornerRadius = 8;
    CGRect viewRect = [self.view convertRect:self.view.bounds toView:nil];
    CGRect rect = [aCell convertRect:aCell.bounds toView:nil];
    CGFloat maxWidth = self.view.frame.size.width;
    CGFloat maxHeight = self.tableView.frame.size.height;
    CGFloat xOffset = 0;
    CGFloat yOffset = 0;
    if (!isCustomCell) {
        if (_currentLongPressCell.model.direction == EMMessageDirectionReceive || (_viewModel.msgAlignmentStyle == EaseAlignmentlLeft && _currentLongPressCell.model.message.chatType == EMChatTypeGroupChat)) {
            xOffset = (avatarLonger + 3*componentSpacing + _currentLongPressCell.bubbleView.frame.size.width/2) - (longPressViewsize.width/2);
            if (xOffset < 2*componentSpacing) {
                xOffset = 2*componentSpacing;
            }
        } else {
            xOffset = (maxWidth - avatarLonger - 3*componentSpacing - _currentLongPressCell.bubbleView.frame.size.width/2) - (longPressViewsize.width/2);
            if ((xOffset + longPressViewsize.width) > (maxWidth - componentSpacing)) {
                xOffset = maxWidth - componentSpacing - longPressViewsize.width;
            }
        }
        yOffset = rect.origin.y - longPressViewsize.height + componentSpacing;
    } else {
        xOffset = point.x - longPressViewsize.width/2;
        if ((xOffset + longPressViewsize.width) > (maxWidth - 2*componentSpacing)) {
            xOffset = maxWidth - 2*componentSpacing - longPressViewsize.width;
        }
        if (xOffset < 2*componentSpacing) {
            xOffset = 2*componentSpacing;
        }
        yOffset = point.y - longPressViewsize.height - componentSpacing;
    }
    CGFloat topBoundary = viewRect.origin.y < [self bangScreenSize] ? [self bangScreenSize] : viewRect.origin.y;
    if (yOffset <= topBoundary) {
        yOffset = topBoundary;
        if ((yOffset + longPressViewsize.height) > isCustomCell ? (point.y + componentSpacing) : (rect.origin.y + componentSpacing)) {
            yOffset = isCustomCell ? (point.y + 2*componentSpacing) : (rect.origin.y + rect.size.height - componentSpacing);
        }
        if (!isCustomCell) {
            if (_currentLongPressCell.bubbleView.frame.size.height > (maxHeight - longPressViewsize.height - 2 * componentSpacing)) {
                yOffset = maxHeight / 2;
            }
        } else {
            if (aCell.frame.size.height > (maxHeight - longPressViewsize.height - 4)) {
                yOffset = maxHeight / 2;
            }
        }
    }
    self.longPressView.frame = CGRectMake(xOffset, yOffset, longPressViewsize.width, longPressViewsize.height);
    UIWindow *win = [[[UIApplication sharedApplication] windows] firstObject];
    [win addSubview:self.longPressView];
}

- (void)messageCellDidResend:(EaseMessageModel *)aModel
{
    if (aModel.message.status != EMMessageStatusFailed && aModel.message.status != EMMessageStatusPending) {
        return;
    }
    
    __weak typeof(self) weakself = self;
    [[[EMClient sharedClient] chatManager] resendMessage:aModel.message progress:nil completion:^(EMChatMessage *message, EMError *error) {
        [weakself.tableView reloadData];
        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(didSendMessage:error:)]) {
            [weakself.delegate didSendMessage:message error:error];
        }
    }];
    
    [self.tableView reloadData];
}

//头像点击
- (void)avatarDidSelected:(EaseMessageModel *)model
{
    [self hideLongPressView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(avatarDidSelected:)]) {
        [self.delegate avatarDidSelected:model.userDataDelegate];
    }
}
//头像长按
- (void)avatarDidLongPress:(EaseMessageModel *)model
{
    [self hideLongPressView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(avatarDidLongPress:)]) {
        [self.delegate avatarDidLongPress:model.userDataDelegate];
    }
}

- (void)messageCellDidClickQuote:(EaseMessageCell *)cell
{
    [self hideLongPressView];
    if (_delegate && [_delegate respondsToSelector:@selector(messageCellDidClickQuote:)]) {
        if (![_delegate messageCellDidClickQuote:cell.model.message]) {
            return;
        }
    }
//    NSString *msgId = cell.model.message.ext[@"msgQuote"][@"msgID"];
//    if (msgId.length <= 0) {
//        return;
//    }
//    
//    _searchRowAction.isSearching = YES;
//    _searchRowAction.currentSearchPage = 1;
//    _searchRowAction.messageId = msgId;
//    _highlightMessageId = msgId;
//    BOOL find = NO;
//    
//    for (int i = (int)_dataArray.count - 1; i >= 0; i --) {
//        EaseMessageModel *model = self.dataArray[i];
//        if ([model isKindOfClass:EaseMessageModel.class] && [model.message.messageId isEqualToString:msgId]) {
//            find = YES;
//            if (model.type == EMMessageTypeImage || model.type == EMMessageTypeVideo || model.type == EMMessageTypeFile) {
//                EMMessageEventStrategy *eventStrategy = [EMMessageEventStrategyFactory getStratrgyImplWithMsgType:model.type];
//                eventStrategy.chatController = self;
//                [eventStrategy messageEventOperation:model];
//            } else {
//                NSArray <NSIndexPath *>*indexPaths = [_tableView indexPathsForVisibleRows];
//                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
//                for (NSIndexPath *i in indexPaths) {
//                    if ([i isEqual:indexPath]) {
//                        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
//                        if (cell) {
//                            if ([cell isKindOfClass:EaseMessageCell.class]) {
//                                [((EaseMessageCell *)cell) showHighlight];
//                            }
//                            self.highlightMessageId = nil;
//                        }
//                        break;
//                    }
//                }
//                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
//            }
//            _searchRowAction.isSearching = NO;
//            return;
//        }
//    }
//    if(!find) {
//        [self showHint:EaseLocalizableString(@"not exist message", nil)];
//        return;
//    }
//    [self dropdownRefreshTableViewWithData];
}

- (void)messageCellDidLongPressQuote:(EaseMessageCell *)aCell
{
    [self hideLongPressView];
    if (_delegate && [_delegate respondsToSelector:@selector(messageCellDidLongPressQuote:)]) {
        if (![_delegate messageCellDidLongPressQuote:aCell.model.message]) {
            return;
        }
    }
}

#pragma mark -- EMMoreFunctionViewDelegate
- (void)menuExtItemDidSelected:(EaseExtMenuModel *)menuItemModel extType:(ExtType)extType
{
    if (extType != ExtTypeChatBar) {
        [self hideLongPressView];
    }
}

#pragma mark -- UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}
- (UIView*)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)controller
{
    return self.view;
}
- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)controller
{
    return self.view.frame;
}

#pragma mark - EMChatManagerDelegate

- (void)messagesDidReceive:(NSArray *)aMessages
{
    __weak typeof(self) weakself = self;
    dispatch_async(self.msgQueue, ^{
        NSString *conId = weakself.currentConversation.conversationId;
        NSMutableArray *msgArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [aMessages count]; i++) {
            EMChatMessage *msg = aMessages[i];
            if (![msg.conversationId isEqualToString:conId]) {
                continue;
            }
            [weakself sendReadReceipt:msg];
            [weakself.currentConversation markMessageAsReadWithId:msg.messageId error:nil];
            [msgArray addObject:msg];
            [weakself.messageList addObject:msg];
        }
        NSArray *formated = [weakself formatMessages:msgArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.dataArray addObjectsFromArray:formated];
            if (weakself.tableView.contentSize.height - weakself.tableView.contentOffset.y-weakself.tableView.frame.size.height <=  10) {
                //如果tableview滑动到底部，收到消息就滚动到底部
                [weakself refreshTableView:YES];
            } else {
                //如果tableview没有滑动到底部，收到消息就不滚动到底部
                [weakself refreshTableView:NO];
            }
        });
    });
}

- (void)messagesInfoDidRecall:(NSArray<EMRecallMessageInfo *> *)aRecallMessagesInfo
{
    [aRecallMessagesInfo enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        EMRecallMessageInfo *recallMessageInfo = (EMRecallMessageInfo *)obj;
        EMChatMessage *msg = recallMessageInfo.recallMessage;
        [self.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[EaseMessageModel class]]) {
                EaseMessageModel *model = (EaseMessageModel *)obj;
                if ([model.message.messageId isEqualToString:msg.messageId]) {
                    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:EaseLocalizableString(@"remoteRecall", nil)];
                    NSString *to = msg.to;
                    NSString *from = msg.from;
                    EMChatMessage *message = [[EMChatMessage alloc] initWithConversationID:from from:from to:to body:body ext:@{MSG_EXT_RECALL:@(YES), MSG_EXT_RECALLBY:recallMessageInfo.recallBy}];
                    message.chatType = (EMChatType)self.currentConversation.type;
                    message.isRead = YES;
                    message.messageId = msg.messageId;
                    message.localTime = msg.localTime;
                    message.timestamp = msg.timestamp;
                    [self.currentConversation insertMessage:message error:nil];
                    EaseMessageModel *replaceModel = [[EaseMessageModel alloc]initWithEMMessage:message];
                    [self.dataArray replaceObjectAtIndex:idx withObject:replaceModel];
                }
            }
        }];
    }];
    [self.tableView reloadData];
}

- (void)msgStatusDidChange:(EMChatMessage *)aMessage
                         error:(EMError *)aError
{
    __weak typeof(self) weakself = self;
    dispatch_async(self.msgQueue, ^{
        NSString *conId = self.currentConversation.conversationId;
        if (![conId isEqualToString:aMessage.conversationId]){
            return ;
        }
        
        __block NSUInteger index = NSNotFound;
        __block EaseMessageModel *reloadModel = nil;
        [self.dataArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[EaseMessageModel class]]) {
                EaseMessageModel *model = (EaseMessageModel *)obj;
                if ([model.message.messageId isEqualToString:aMessage.messageId]) {
                    reloadModel = model;
                    index = idx;
                    *stop = YES;
                    
                    if (index != NSNotFound) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakself.dataArray replaceObjectAtIndex:index withObject:reloadModel];
                            [weakself.tableView reloadData];
                        });

                    }
                }
            }
        }];
        
       
        
    });
}

- (void)onConversationRead:(NSString *)from to:(NSString *)to
{
    if (self.currentConversation.type == EMConversationTypeChat) {
        if (self.tableView.isRefreshing) {
            [self.tableView endRefreshing];
        }
        [self refreshTableView:NO];
    }
}

#pragma mark - KeyBoard

- (void)keyBoardWillShow:(NSNotification *)note
{
    // 获取用户信息
    NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:note.userInfo];
    // 获取键盘高度
    CGRect keyBoardBounds  = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyBoardHeight = keyBoardBounds.size.height;
    
//    if([self.jianpanStr isEqualToString:@"1"]){
//        keyBoardHeight   = keyBoardBounds.size.height - 84;
//    }else {
//        keyBoardHeight   = keyBoardBounds.size.height - 20;
//    }
    keyBoardHeight   = keyBoardBounds.size.height - EMVIEWBOTTOMMARGIN;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BWConsultUpdateOrderButtonNotify" object:[NSString stringWithFormat:@"%f",keyBoardHeight+EMVIEWBOTTOMMARGIN]];
    // 定义好动作
    void (^animation)(void) = ^void(void) {
        [self.chatBar Ease_updateConstraints:^(EaseConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-keyBoardHeight);
        }];
        [self.chatBar.superview layoutIfNeeded];
        [self scrollToBottomRow];
    };
    [self keyBoardWillShow:note animations:animation completion:^(BOOL finished, CGRect keyBoardBounds) {
        if (finished) {
//            [self performSelector:@selector(scrollToBottomRow) withObject:nil afterDelay:0.1];
        }
    }];
}

- (void)keyBoardWillHide:(NSNotification *)note
{
    // 定义好动作
    void (^animation)(void) = ^void(void) {
        [self.chatBar Ease_updateConstraints:^(EaseConstraintMaker *make) {
            make.bottom.equalTo(self.view);
        }];
        [self.chatBar.superview layoutIfNeeded];
        [self scrollToBottomRow];
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BWConsultUpdateOrderButtonNotify" object:[NSString stringWithFormat:@"%f",EMVIEWBOTTOMMARGIN]];
    [self keyBoardWillHide:note animations:animation completion:^(BOOL finished) {
        if (finished) {
//            [self performSelector:@selector(scrollToBottomRow) withObject:nil afterDelay:0.1];
        }
    }];
}

#pragma mark - Gesture Recognizer

//点击消息列表，收起更多功能区
- (void)handleTapTableViewAction:(UITapGestureRecognizer *)aTap
{
    if (aTap.state == UIGestureRecognizerStateEnded) {
        [self.view endEditing:YES];
        [self.chatBar clearMoreViewAndSelectedButton];
        [self hideLongPressView];
        [self scrollToBottomRow];
    }
}

- (void)scrollToBottomRow
{
    NSInteger toRow = -1;
    if ([self.dataArray count] > 0) {
        toRow = self.dataArray.count - 1;
        if (toRow > 0) {
            NSInteger rows = [self.tableView numberOfRowsInSection:0];
            if (toRow < rows) {
                NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toRow inSection:0];
                [self.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }
        }
    }
}
 
#pragma mark - Send Message

- (void)sendTextAction:(NSString *)aText
                    ext:(NSDictionary *)aExt
{
    if(![aExt objectForKey:MSG_EXT_GIF]){
        [self.chatBar clearInputViewText];
    }
    if ([aText length] == 0) {
        return;
    }
    
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:aText];
    [self sendMessageWithBody:body ext:aExt];
}

#pragma mark - Data

- (NSArray *)formatMessages:(NSArray<EMChatMessage *> *)aMessages
{
    NSMutableArray *formated = [[NSMutableArray alloc] init];

    for (int i = 0; i < [aMessages count]; i++) {
        EMChatMessage *msg = aMessages[i];
        if (msg.chatType == EMChatTypeChat && msg.isReadAcked && (msg.body.type == EMMessageBodyTypeText || msg.body.type == EMMessageBodyTypeLocation)) {
            [[EMClient sharedClient].chatManager sendMessageReadAck:msg.messageId toUser:msg.conversationId completion:nil];
        }
        
        if (msg.chatType == EMChatTypeGroupChat && msg.isNeedGroupAck && !msg.isReadAcked) {
            [[EMClient sharedClient].chatManager sendGroupMessageReadAck:msg.messageId toGroup:msg.conversationId content:@"123" completion:nil];
        }
        
        CGFloat interval = (self.msgTimelTag - msg.timestamp) / 1000;
        if (self.msgTimelTag < 0 || interval > 60 || interval < -60) {
            NSString *timeStr = [EaseDateHelper formattedTimeFromTimeInterval:msg.timestamp];
            [formated addObject:timeStr];
            self.msgTimelTag = msg.timestamp;
        }
        EaseMessageModel *model = nil;
        model = [[EaseMessageModel alloc] initWithEMMessage:msg];
        if (!model) {
            model = [[EaseMessageModel alloc]init];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(userData:)]) {
            id<EaseUserDelegate> userData = [self.delegate userData:msg.from];
            model.userDataDelegate = userData;
        }
        
        [formated addObject:model];
    }
    
    return formated;
}

- (void)refreshTableViewWithData:(NSArray<EMChatMessage *> *)messages isInsertBottom:(BOOL)isInsertBottom isScrollBottom:(BOOL)isScrollBottom
{
    __weak typeof(self) weakself = self;
    if (messages && [messages count]) {
        NSMutableArray<EMChatMessage *> *tempMsgs = [[NSMutableArray<EMChatMessage *> alloc]init];
        for (EMChatMessage *message in messages) {
            if (message.body.type != EMMessageTypeCmd) {
                [tempMsgs addObject:message];
            }
        }
        if (isInsertBottom) {
            [weakself.messageList addObjectsFromArray:tempMsgs];
        } else {
            [weakself.messageList insertObjects:tempMsgs atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [tempMsgs count])]];
            EMChatMessage *msg = tempMsgs[0];
            weakself.moreMsgId = msg.messageId;
        }
        
        dispatch_async(self.msgQueue, ^{
            NSArray *formated = [weakself formatMessages:tempMsgs];
            if (isInsertBottom) {
                [weakself.dataArray addObjectsFromArray:formated];
            } else {
                [weakself.dataArray insertObjects:formated atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [formated count])]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakself.tableView.isRefreshing) {
                    [weakself.tableView endRefreshing];
                }
                [weakself refreshTableView:isScrollBottom];
                if (isScrollBottom) {
                    
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakself.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:formated.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                    });
                }
            });
        });
    } else {
        if (weakself.tableView.isRefreshing) {
            [weakself.tableView endRefreshing];
        }
    }
}

- (void)dropdownRefreshTableViewWithData
{
    [self.tableView.mj_header endRefreshing];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadMoreMessageData:currentMessageList:)]) {
        [self.delegate loadMoreMessageData:self.moreMsgId currentMessageList:[self.messageList copy]];
    } else {
        if (self.tableView.isRefreshing) {
            [self.tableView endRefreshing];
        }
    }
}

#pragma mark - Action

- (void)cleanPopupControllerView
{
    [self.view endEditing:YES];
    [self hideLongPressView];
    [self.chatBar clearMoreViewAndSelectedButton];
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    [[EMImageBrowser sharedBrowser] dismissViewController];
    [self stopAudioPlayer];
}

- (void)stopAudioPlayer
{
    [[EMAudioPlayerUtil sharedHelper] stopPlayer];
}

//隐藏长按
- (void)hideLongPressView
{
    [self.longPressView removeFromSuperview];
    [self resetCellLongPressStatus:_currentLongPressCell];
}

//自定义cell长按
- (void)customCellLongPressAction:(UILongPressGestureRecognizer *)aLongPress
{
    if (aLongPress.state == UIGestureRecognizerStateBegan) {
        UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
        CGPoint longLocationForWindow = [aLongPress locationInView:window];
        CGPoint longLocationForTableview = [aLongPress locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:longLocationForTableview];
        [self messageCellDidLongPress:[self.tableView cellForRowAtIndexPath:indexPath] cgPoint:longLocationForWindow];
    }
}

//发送消息体
- (void)sendMessageWithBody:(EMMessageBody *)aBody
                        ext:(NSDictionary * __nullable)aExt
{
    NSString *from = [[EMClient sharedClient] currentUsername];
    NSString *to = self.currentConversation.conversationId;
    EMChatMessage *message = [[EMChatMessage alloc] initWithConversationID:to from:from to:to body:aBody ext:aExt];
    //是否需要发送阅读回执
    if([aExt objectForKey:MSG_EXT_READ_RECEIPT]) {
        message.isNeedGroupAck = YES;
    }
    message.chatType = (EMChatType)self.currentConversation.type;
    
    __weak typeof(self) weakself = self;
    if (self.delegate && [self.delegate respondsToSelector:@selector(willSendMessage:)]) {
        EMChatMessage *callbackMsg = [self.delegate willSendMessage:message];
        if (!callbackMsg || !callbackMsg.messageId || [callbackMsg.messageId isEqualToString:@""])
            return;
        [weakself sendMsgimpl:callbackMsg];
    } else {
        [self sendMsgimpl:message];
    }
}

- (void)sendMsgimpl:(EMChatMessage *)message
{
    __weak typeof(self) weakself = self;
    NSArray *formated = [self formatMessages:@[message]];
    [self.dataArray addObjectsFromArray:formated];
    [self.messageList addObject:message];
    if (!self.moreMsgId)
        //新会话的第一条消息
        self.moreMsgId = message.messageId;
        
    [self refreshTableView:YES];

    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:^(EMChatMessage *message, EMError *error) {
        [weakself msgStatusDidChange:message error:error];
        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(didSendMessage:error:)]) {
            [weakself.delegate didSendMessage:message error:error];
        }
    }];
}

#pragma mark - Public

//发送输入状态
- (void)setEditingStatusVisible:(BOOL)editingStatusVisible{}

//已读回执
- (void)sendReadReceipt:(EMChatMessage *)msg{}

- (void)triggerUserInfoCallBack:(BOOL)isScrollBottom
{
    if (self.tableView.isRefreshing) {
        [self.tableView endRefreshing];
    }
    self.msgTimelTag = 0;
    NSArray *formated = [self formatMessages:self.messageList];
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:formated];
    [self refreshTableView:isScrollBottom];
}

- (void)refreshTableView:(BOOL)isScrollBottom
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.tableView setNeedsLayout];
        [self.tableView layoutIfNeeded];
        if (isScrollBottom) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self scrollToBottomRow];
            });
        }
    });
}

#pragma mark - getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.tableFooterView = [UIView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.estimatedRowHeight = 130;
        _tableView.backgroundColor = [UIColor systemPinkColor];
//        [_tableView enableRefresh:EaseLocalizableString(@"dropRefresh", nil) color:UIColor.redColor];
//        if (@available(iOS 10.0, *)) {
//            [_tableView.refreshControl addTarget:self action:@selector(dropdownRefreshTableViewWithData) forControlEvents:UIControlEventValueChanged];
//        } else {
//            // Fallback on earlier versions
//        }
        _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(dropdownRefreshTableViewWithData)];
    }
    
    return _tableView;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];;
    }
    return _dataArray;
}

- (NSMutableArray<EMChatMessage *> *)messageList
{
    if (!_messageList) {
        _messageList = [[NSMutableArray<EMChatMessage *> alloc]init];
    }
    return _messageList;
}

@end
