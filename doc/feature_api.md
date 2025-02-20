# 弹幕设计文档

## 介绍
    bullet-screen-cj 是一款弹幕框架，支持发送纯文本弹幕、设置弹幕在屏幕的显示区域、控制弹幕播放状态等功能

### 1 弹幕

##### 1.1 主要接口

```cangjie
/*
 * 类名 - DanmakuView
 * 功能 - DanmakuView UI自定义组件
 */
public class DanmakuView {
    /*
     * 构造 -  构造函数， 需要传入DanmakuView UI自定义组件控制器参数
     * 
     * 参数 model - DanmakuViewModel
     */
    public init(model!：DanmakuViewModel)
}


/*
 * 类名 - DanmakuViewModel
 * 功能 - DanmakuView UI自定义组件控制器
 */
public class DanmakuViewModel <: IDanmakuView & IDanmakuViewController {

    /*
     * 功能 - 设置背景颜色
     * 
     * 参数 color - 颜色
     * 返回值 Unit - unit
     */
    public func backgroundColor (color: UInt32) : Unit

    /*
     * 功能 - 设置背景颜色
     * 
     * 参数 color - 颜色
     * 返回值 Unit - unit
     */
    public func backgroundColor (color: Color) : Unit

    /*
     * 功能 - 是否已准备就绪
     * 
     * 返回值 Bool - 准备完成返回true
     */
    public override func isPrepared () : Bool

    /*
     * 功能 - 是否已暂停
     * 
     * 返回值 Bool - 暂停返回true
     */
    public override func isPaused () : Bool

    /*
     * 功能 - 显示 FPS
     * 
     * 参数 show - 显示为true
     * 返回值 Unit - unit
     */
    public override func showFPS (show: Bool) : Unit

    /*
     * 功能 - 添加弹幕
     * 
     * 参数 item - 弹幕类
     * 返回值 Unit - unit
     */
    public override func addDanmaku (item: BaseDanmaku) : Unit

    /*
     * 功能 - 使弹幕无效
     * 
     * 参数 item - 弹幕类
     * 参数 remeasure - 是否重新检测
     * 返回值 Unit - unit
     */
    public override func invalidateDanmaku (item: BaseDanmaku, remeasure: Bool) : Unit

    /*
     * 功能 - 删除所有弹幕
     * 
     * 参数 isClearDanmakusOnScreen - 是否清屏
     * 返回值 Unit - unit
     */
    public override func removeAllDanmakus (isClearDanmakusOnScreen: Bool) : Unit

    /*
     * 功能 - 删除所有弹幕
     * 
     * 返回值 Unit - Unit
     */
    public override func removeAllLiveDanmakus () : Unit

    /*
     * 功能 - 获取当前可见弹幕
     * 
     * 返回值 ?IDanmakus - 弹幕的Option类型
     */
    public override func getCurrentVisibleDanmakus () : ?IDanmakus

    /*
     * 功能 - 设置回调函数
     * 
     * 参数 callback - 回调函数DanmakuCallBack
     * 返回值 Unit - unit
     */
    public override func setCallback (callback: DanmakuCallBack) : Unit

    /*
     * 功能 - 获取当前时间
     * 
     * 返回值 Int64 - 时间的int64表示
     */
    public override func getCurrentTime () : Int64

    /*
     * 功能 - 获取配置类
     * 
     * 返回值 ?DanmakuContext - DanmakuContext
     */
    public override func getConfig () : ?DanmakuContext

    /*
     * 功能 - 获取IDanmakuView
     * 
     * 返回值 IDanmakuView - IDanmakuView
     */
    public override func getView () : IDanmakuView

    /*
     * 功能 - 设置宽度
     * 
     * 参数 width - 宽度
     * 返回值 - Unit
     */
    public func setWidth (width: Int64)

    /*
     * 功能 - 设置高度
     * 
     * 参数 height - 高度
     * 返回值 - unit
     */
    public func setHeight (height: Int64)

    /*
     * 功能 - 获取宽度
     * 
     * 返回值 Int64 - 宽度 
     */
    public override func getWidth () : Int64

    /*
     * 功能 - 获取高度
     * 
     * 返回值 Int64 - 高度 
     */
    public override func getHeight () : Int64

    /*
     * 功能 - 设置可见性
     * 
     * 参数 visibility - 是否可见
     * 返回值 Unit - unit
     */
    public override func setVisibility (visibility: Bool) : Unit

    /*
     * 功能 - 是否已显示
     * 
     * 返回值 Bool - 显示返回true
     */
    public override func isShown () : Bool

    /*
     * 功能 - 自定义组件准备
     * 
     * 参数 parser - BaseDanmakuParser的子类，需要使用者继承该类
     * 参数 config - 配置类DanmakuContext
     * 返回值 Unit - unit
     */
    public override func prepare (parser: BaseDanmakuParser, config: DanmakuContext) : Unit

    /*
     * 功能 - 指定的时间点
     * 
     * 参数 ms - 毫秒值
     * 返回值 Unit - unit
     */
    public override func seekTo (ms: Int64) : Unit

    /*
     * 功能 - 开始播放
     * 
     * 返回值 Unit - unit
     */
    public override func start () : Unit

    /*
     * 功能 - 指定的时间点开始播放
     * 
     * 参数 position - 时间点
     * 返回值 Unit - unit
     */
    public override func start (position: Int64) : Unit

    /*
     * 功能 - 停止播放
     * 
     * 返回值 Unit - unit
     */
    public override func stop () : Unit

    /*
     * 功能 - 暂停播放
     * 
     * 返回值 Unit - unit
     */
    public override func pause () : Unit

    /*
     * 功能 - 重新开始
     * 
     * 返回值 Unit - unit
     */
    public override func resume () : Unit

    /*
     * 功能 - 释放资源
     * 
     * 返回值 Unit - unit
     */
    public override func release () : Unit

    /*
     * 功能 - 转换
     * 
     * 返回值 Unit - unit 
     */
    public override func toggle () : Unit

    /*
     * 功能 - 显示
     * 
     * 返回值 Unit - unit 
     */
    public override func show () : Unit

    /*
     * 功能 - 隐藏
     * 
     * 返回值 Unit - unit 
     */
    public override func hide () : Unit

    /*
     * 功能 - 显示并恢复绘图任务
     * 
     * 参数 position - 时间点毫秒值
     * 返回值 Unit - unit
     */
    public override func showAndResumeDrawTask (position: Int64) : Unit

    /*
     * 功能 - 隐藏并暂停绘图任务
     * 
     * 返回值 Int64 - 成功返回1
     */
    public override func hideAndPauseDrawTask () : Int64

    /*
     * 功能 - 清除屏幕上的弹幕
     * 
     * 返回值 Unit - unit
     */
    public override func clearDanmakusOnScreen () : Unit

    /*
     * 功能 - 设置弹幕点击的监听器
     * 
     * 参数 listener - OnDanmakuClickListener
     * 返回值 Unit - unit
     */
    public override func setOnDanmakuClickListener (listener: OnDanmakuClickListener) : Unit

    /*
     * 功能 - 设置弹幕点击的监听器
     * 
     * 参数 listener - OnDanmakuClickListener
     * 参数 xOff - xoff
     * 参数 yOff - yOff
     * 返回值 Unit - unit
     */
    public override func setOnDanmakuClickListener (listener: OnDanmakuClickListener, xOff: Float64, yOff: Float64) : Unit

    /*
     * 功能 - 获取在弹幕点击监听器
     * 
     * 返回值 OnDanmakuClickListener - 监听器
     */
    public override func getOnDanmakuClickListener () : OnDanmakuClickListener

    /*
     * 功能 - 获取x轴偏移量
     * 
     * 返回值 Float64 - x轴偏移量
     */
    public override func getXOff () : Float64

    /*
     * 功能 - 获取y轴偏移量
     * 
     * 返回值 Float64 - y轴偏移量
     */
    public override func getYOff () : Float64

    /*
     * 功能 - 强制渲染
     * 
     * 返回值 Unit - unit
     */
    public override func forceRender () : Unit

    /*
     * 功能 - 视图是否准备完毕
     * 
     * 返回值 Bool - 准备完成返回true
     */
    public override func isViewReady () : Bool

    /*
     * 功能 - 获取视图的宽度
     * 
     * 返回值 Int64 - 宽度
     */
    public override func getViewWidth () : Int64

    /*
     * 功能 - 获取视图高度
     * 
     * 返回值 Int64 - 高度
     */
    public override func getViewHeight () : Int64

    /*
     * 功能 - 渲染弹幕
     * 
     * 返回值 Int64 - 成功渲染返回1 
     */
    public override func drawDanmakus () : Int64

    /*
     * 功能 - 清空自定义组件资源
     * 
     * 返回值 Unit - unit
     */
    public override func clear () : Unit
}


```

