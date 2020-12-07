# YMiOSSDK
## 快速开始
-----
### 引入框架包
1. 从当前网站上master分支下载解压获得 `IOSSDK.framework` 开发包
2. 将开发包移动到项目工程的根目录下，并将其拖拽到 `xcode` 的 `Frameworks` 文件夹中
3. 打开 `xcode` 项目的 `TARGETS` 在 `Frameworks, Libraries, and Embedded Content` 中找到 `YMSDK.framework` 将其 `Embed` 选项设置为 `Embed & Sign` 并添加以下几个包的引用
*****
  - `Security.framework`
  
  - `UIKit.framework`
  
  - `WebKit.framework`
  
### 配置支付和SDK初始化
> 配置 `App Scheme` 查询片段 编辑 `Info.plist` 文件，插入以下代码：

``` xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>weixin</string>
  <string>alipay</string>
</array>
```

> 根据游戏自身的 `App Scheme` 为SDK配置支付跳转

``` xml
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>{AppScheme}.1996yx.com</string>
		</array>
	</dict>
</array>
```

> 打开 `AppDelegate.m` 文件，在 `application:didFinishLaunchingWithOptions` 消息定义中插入以下代码

``` objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    YMConfiguration *configuration = [[YMConfiguration alloc] initWithAppId:@"{appid}" andAppKey:@"{appkey}" andScheme:@"{AppScheme}"];
    
    [[YMSDK shared] initWithConfig:configuration andApplication:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}
```
> 首先初始化 `YMConfiguration` 其中 `AppId`, `AppKey` 是平台对接参数，在对接时由平台提供，可当作常量传入， `AppScheme` 为支付跳转方案，传入在第2个步骤设置的值即可。
>> 然后调用SDK的 `initWithConfig` 消息，将 `YMConfiguration` 实例以及委托中的 `application`, `launchOptions` 入参即可完成初始化， ***初始化完成后无需再进行初始化， 可通过 `[YMSDK shared]` 调用和访问 SDK 中的全部功能***
  
### 用户登录

1. **身份认证**
> 开发者可通过 `[YMSDK auth]` 消息调用身份认证， 玩家登录成功后会通过 `YMSDKDidFinalAuthNotification` 通知回调给订阅者，示例代码如下: *在首次进入游戏时，应先将游戏资源加载完毕后再调用身份认证*

``` objective-c
//首先订阅YMSDKDidFinalAuthNotification通知
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinalAuth) name:YMSDKDidFinalAuthNotification object:nil];

//调用 auth 方法进行身份认证 （如果需要用户进行登录，则会在登录界面打开时发送YMSDKWillAuthNotification通知，可按需订阅此通知做资源优化）
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
[[YMSDK shared] auth];
});
```
>> *此示例通过GCD延迟1秒后调用，这样做可使用户获得更平滑的体验，也可以直接调用 `[[YMSDK shared] auth]` ，但需要注意该消息不是**线程安全**的*

2. **用户信息**

> 身份认证完成后可通过以下调用获取用户的相关信息：

``` objective-c
NSString * __nonnull openid  = [[YMSDK shared] openId]; //玩家账号的唯一标识符
NSString * __nullable latestServerId = [[YMSDK shared] latestServerId]; //该账号最近一次登录的区服名称，如果未登录过区服则为nil
NSDictionary * __nullable realnameInfo = [[YMSDK shared] realnameInfo]; //用户实名信息
bool isInvalidRealname = [[YMSDK shared] isInvalidRealname]; //获取一个值，该值反映当前登录的用户是否未进行实名
```

3. **退出登录**

> 调用以下代码完成退出登录

``` objective-c
[[YMSDK shared] exit];
```
- *成功返回 0 失败返回 -1*

> 通过订阅 `YMSDKDidExitNotification` 通知执行退出登录的相关逻辑 
``` objective-c
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExit) name:YMSDKDidExitNotification object:nil];
```
- *当用户退出登录后SDK会重置状态机，切换为初始化后的状态，这时在重新调用身份认证之前，调用其他接口都会失败*

### 信息上报

0. 角色唯一标识符 `characterId `
> 用于为平台跟踪是玩家的哪个角色进行的某个操作

1. 角色上报
> 当用户登录成功后，在进入游戏服务器后调用角色上报接口获取 `characterId` 角色唯一标识符
``` objective-c
static NSString *__cid;
__cid =  [[YMSDK shared] characterIdByUid:@"10068" andServerId:serverName];
```
> 1. `Uid`:  角色唯一标识   *对于一个服务器领域中，每个角色有且仅有一个uid*
> 2. `ServerId`: 服务器唯一标识  *推荐传入服务器名称作为标识，确认不重复且一致即可*
>> 返回 `characterId` **作为调用支付和角色信息上报的凭据，只需在角色登录的时候调用一次即可**

2. 角色信息更新

> 当玩家角色升级或使用了改名卡   *该消息为异步操作，不会阻塞当前线程*
``` objective-c
//上报角色信息
[[YMSDK shared] reportAsyncByCharacterId:__cid updateName:@"玩家角色名称" andLevel:@"100级"];
```
> 1. `CharacterId`: 通过角色上报接口获取的角色标识
> 2. `Name`: 角色名称
> 3. `Level`: 角色等级
>>  返回 0 表示成功， -1 表示传入了空的参数或未进行登录

### 支付

1. 支付调用

> 玩家购买元宝、礼包或其他增值产品，需要进行支付时调用  *[该消息为异步操作，不会阻塞线程]*
``` objective-c
NSString *orderId = [NSString stringWithFormat:@"%d", arc4random()];
NSInteger price = 600;
NSString *title = @"6元宝";

[[YMSDK shared] paymentByCharacterId:__cid price:price title:title description:nil forOrderId:orderId];
```
> 1. `CharacterId`: 通过角色上报接口获取的角色标识
> 2. `price`: 价格，**单位为分**
> 3. `title `: 商品名称
> 4. `description `: 商品描述（可以为空）
> 5. `orderId `: 订单标识, 后台服务器通过该标识通知开发商发货
>> 返回 0 表示成功， -1 表示传入了非法参数或未进行登录

### 支付通知

1. 取消支付回调
> 通过订阅 `YMSDKDidCancelPaymentNotification` 通知获取取消支付的回调
``` objective-c 
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCancelPayment:) name:YMSDKDidCancelPaymentNotification object:nil];
```

2. 支付成功回调
> 通过订阅 `YMSDKDidCompletionPaymentNotification` 通知获取取消支付的回调
``` objective-c 
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCancelPayment:) name: YMSDKDidCompletionPaymentNotification object:nil];
```

3. 通知荷载的订单标识对象
> 在订阅通知回调后，可以通过 `NSNotification` 对象的 `object` 获取到订单ID
``` objective-c
- (void)didCompletionPayment:(NSNotification *)notification
{
    [self alert:[NSString stringWithFormat:@"订单 '%@' 支付成功", notification.object]];
}

- (void)didCancelPayment:(NSNotification *)notification
{
    [self alert:[NSString stringWithFormat:@"订单 '%@' 取消支付", notification.object]];
}
```

### 调用时序图
![时序图][tsi]

