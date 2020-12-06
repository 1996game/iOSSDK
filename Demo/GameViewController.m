//
//  GameViewController.m
//  Demo
//
//  Created by 云梦互娱 on 19/10/2020.
//

#import "GameViewController.h"
#import "GameScene.h"

@implementation GameViewController

static NSString *__cid;

- (void)reportChara
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"区服" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 1; i <= 5; i++) {
        NSString *serverName = [NSString stringWithFormat:@"ios%d区", i];
        UIAlertAction *area = [UIAlertAction actionWithTitle:serverName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            __cid =  [[YMSDK shared] characterIdByUid:@"10068" andServerId:serverName];
            
            //上报角色信息
            [[YMSDK shared] reportAsyncByCharacterId:__cid updateName:@"玩家角色名称" andLevel:@"100"];
        }];
        [alertController addAction:area];
    }

    [self presentViewController:alertController animated:true completion:nil];
}

- (void)payment
{
    NSString *orderId = [NSString stringWithFormat:@"%d", arc4random()];
    NSInteger price = 600;
    NSString *title = @"6元宝";

    [[YMSDK shared] paymentByCharacterId:__cid price:price title:title description:nil forOrderId:orderId];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Load the SKScene from 'GameScene.sks'
    GameScene *scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
    
    // Set the scale mode to scale to fit the window
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    SKView *skView = (SKView *)self.view;
    
    // Present the scene
    [skView presentScene:scene];
    
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    UIButton *btnReportChara = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 100, 20)];
    [btnReportChara setTitle:@"登录区服" forState:UIControlStateNormal];
    [btnReportChara addTarget:self action:@selector(reportChara) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnPay = [[UIButton alloc] initWithFrame:CGRectMake(110, 5, 50, 20)];
    [btnPay setTitle:@"充值" forState:UIControlStateNormal];
    [btnPay addTarget:self action:@selector(payment) forControlEvents:UIControlEventTouchUpInside];
    
    [[self view] addSubview:btnReportChara];
    [[self view] addSubview:btnPay];
    
    //首先订阅YMSDKDidFinalAuthNotification通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinalAuth) name:YMSDKDidFinalAuthNotification object:nil];
    
    //调用 auth 方法进行身份认证 （如果需要用户进行登录，则会在登录界面打开时发送YMSDKWillAuthNotification通知，可按需订阅此通知做资源优化）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[YMSDK shared] auth];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinalAuth) name:YMSDKDidFinalAuthNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExit) name:YMSDKDidExitNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompletionPayment:) name:YMSDKDidCompletionPaymentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCancelPayment:) name:YMSDKDidCancelPaymentNotification object:nil];
}

- (void)alert:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:true completion:nil];
    });
}

- (void)didFinalAuth
{
    //NSString * __nonnull openid  = [[YMSDK shared] openId]; //玩家账号的唯一标识符
    //NSString * __nullable latestServerId = [[YMSDK shared] latestServerId]; //该账号最近一次登录的区服名称，如果未登录过区服则为nil
    //NSDictionary * __nullable realnameInfo = [[YMSDK shared] realnameInfo]; //用户实名信息
    //bool isInvalidRealname = [[YMSDK shared] isInvalidRealname]; //获取一个值，该值反映当前登录的用户是否未进行实名
    //[[YMSDK shared] exit];
    [self alert:[NSString stringWithFormat:@"%@ 登录成功", YMSDK.shared.openId]];
}

- (void)didExit
{
    [self alert:@"退出成功"];
}

- (void)didCompletionPayment:(NSNotification *)notification
{
    [self alert:[NSString stringWithFormat:@"订单 '%@' 支付成功", notification.object]];
}

- (void)didCancelPayment:(NSNotification *)notification
{
    [self alert:[NSString stringWithFormat:@"订单 '%@' 取消支付", notification.object]];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
