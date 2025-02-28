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
 * 类名 - BaseDanmaku
 * 功能 - 抽象弹幕基类
 */
public abstract class BaseDanmaku <: Hashable & Comparable<BaseDanmaku> & ToString & Equatable<BaseDanmaku> {
    
    /*
     * 从右到左的弹幕类型
     */
    public static let TYPE_SCROLL_RL: Int64 = 1
    
    /*
     * 从左到右的弹幕类型
     */
    public static let TYPE_SCROLL_LR: Int64 = 6
    
    /*
     * 顶部弹幕类型
     */
    public static let TYPE_FIX_TOP: Int64 = 5
    
    /*
     * 底部弹幕类型
     */
    public static let TYPE_FIX_BOTTOM: Int64 = 4
    
    /*
     * 特殊弹幕类型
     */
    public static let TYPE_SPECIAL: Int64 = 7
    
    /**
     * 偏移时间
     */
    public var timeOffset: Int64 = 0

    /**
     * 文本
     */
    public var text: String = ""

    /**
     * 多行文本: 如果有包含换行符需事先拆分到lines
     */
    public var lines: ?Array<String> = None

    /**
     * 文本颜色
     */
    public var textColor: UInt32 = 0

    /**
     * Z轴角度
     */
    public var rotationZ: Float64 = 0.0

    /**
     * Y轴角度
     */
    public var rotationY: Float64 = 0.0

    /**
     * 阴影/描边颜色
     */
    public var textShadowColor: UInt32 = 0

    /**
     * 下划线颜色,0表示无下划线
     */
    public var underlineColor: UInt32 = 0

    /**
     * 字体大小
     */
    public var textSize: Float64 = 65.0

    /**
     * 边框的颜色,0表示无边框
     */
    public var borderColor: UInt32 = 0

    /**
     * 内边距(像素)
     */
    public var padding: Float64 = 0.0

    /**
     * 弹幕优先级,0为低优先级,>0为高优先级不会被过滤器过滤
     */
    public var priority: UInt8 = 0

    /**
     * 存活时间(毫秒)
     */
    public var duration: DanmakuDuration = DanmakuDuration(0)

    /**
     * 索引/编号
     */
    public var index: Int64 = 0
    
    /**
     * 是否是直播弹幕
     */
    public var isLive: Bool = false

    /**
     * 透明度
     */
    protected var alpha: Int64 = ALPHA_MAX
    
    /*
     * 设置时间
     *
     * @param time - 传入时间
     *
     */
    public func setTime(time: Int64): Unit
    
    /*
     * 设置 pixelMap 集合到弹幕对象中，一般应用于 gif 动图
     *
     * @param pixelMapList - pixelMap 集合
     *
     */
    public func setPixelMapList(pixelMapList: ArrayList<PixelMap>): Unit
    
    /*
     * 设置是否为动图展示，前提是有 pixelMap 集合并且大小大于 1，否则为只展示第一帧
     *
     * @param isAnimation - 是否为动图展示
     *
     */
    public func setIsAnimation(isAnimation: Bool): Unit
}

/*
 * 类名 - DanmakuContext
 * 功能 - DanmakuContext Context 上下文对象
 */
public class DanmakuContext {
    /*
     * DanmakuContext 无参构造方法
     */
    public init()
    
    /*
     * 静态方法创建 DanmakuContext 对象
     *
     * @return 返回 DanmakuContext 对象
     */
    public static func create(): DanmakuContext

    /*
     * 设置字体
     *
     * @param font - 传入自定义字体
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setTypeface(font: String): DanmakuContext
    
    /*
     * 设置透明度
     *
     * @param p - 传入透明度值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuTransparency(p: Float64): DanmakuContext

    /*
     * 设置文本字体大小
     *
     * @param p - 传入文本字体大小值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setScaleTextSize(p: Float64): DanmakuContext
    
    /*
     * 设置外边距
     *
     * @param p - 传入外边距值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuMargin(m: Int64): DanmakuContext
    
    /*
     * 设置外边距顶部
     *
     * @param p - 传入外边距顶部值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setMarginTop(m: Int64): DanmakuContext
    
    /*
     * 设置弹幕样式
     *
     * @param style - 传入描边样式，可传递的值有：
     *
     * DANMAKU_STYLE_DEFAULT: Int64 = -1 默认样式
     * DANMAKU_STYLE_NONE: Int64 = 0 无样式
     * DANMAKU_STYLE_SHADOW: Int64 = 1 阴影样式，values 传入阴影半径
     * DANMAKU_STYLE_STROKEN: Int64 = 2 描边样式，values 传入描边宽度
     * DANMAKU_STYLE_STROKEN: Int64 = 3 投影样式，values 传入 offsetX X轴偏移量, offsetY Y轴偏移量, alpha 透明度
     *
     * @param values - 传入数值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuStyle(style: Int64, values: Array<Float64>): DanmakuContext
    
    /*
     * 设置是否粗体显示(cj 侧支持的字体)
     *
     * @param bold - 是否粗体
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuBold(bold: Bool): DanmakuContext
    
    /*
     * 设置弹幕滚动速度系数,只对滚动弹幕有效
     *
     * @param p - 弹幕滚动系数值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setScrollSpeedFactor(p: Float64): DanmakuContext
    
    /*
     * 设置是否启用合并重复弹幕
     *
     * @param enable - 是否启用合并重复弹幕
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDuplicateMergingEnabled(enable: Bool): DanmakuContext
    
    /*
     * 判断是否启用合并重复弹幕
     *
     * @return 返回是否启用合并重复弹幕
     */
    public func isDuplicateMergingEnabled(): Bool
    
    /*
     * 设置是否底部对齐
     *
     * @param enable - 是否底部对齐
     *
     * @return 返回 DanmakuContext 对象
     */
    public func alignBottom(enable: Bool): DanmakuContext
    
    /*
     * 判断是否底部对齐
     *
     * @return 返回是否底部对齐
     */
    public func isAlignBottom(): Bool
    
    /*
     * 设置最大显示行数
     * @param pairs map<K,V> 设置null取消行数限制
     * K = (BaseDanmaku.TYPE_SCROLL_RL|BaseDanmaku.TYPE_SCROLL_LR|BaseDanmaku.TYPE_FIX_TOP|BaseDanmaku.TYPE_FIX_BOTTOM)
     * V = 最大行数
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setMaximumLines(pairs: HashMap<Int64, Int64>): DanmakuContext
    
    /*
     * 判断是否设置行数限制
     *
     * @return 返回是否设置行数限制
     */
    public func isMaxLinesLimited(): Bool
    
    /**
     * 设置防弹幕重叠
     * @param pairs map<K,V> 设置null恢复默认设置,默认为允许重叠
     * K = (BaseDanmaku.TYPE_SCROLL_RL|BaseDanmaku.TYPE_SCROLL_LR|BaseDanmaku.TYPE_FIX_TOP|BaseDanmaku.TYPE_FIX_BOTTOM)
     * V = true|false 是否重叠
     *
     * @return 返回 DanmakuContext 对象
     */
    public func preventOverlapping(pairs: HashMap<Int64, Bool>): DanmakuContext
    
    /*
     * 判断是否设置放重叠
     *
     * @return 返回是否设置放重叠
     */
    public func isPreventOverlappingEnabled(): Bool
    
    /**
     * 设置缓存绘制填充器，默认使用 SimpleTextCacheStuffer 只支持纯文字显示, 如果需要图文混排请设置 SpannedCacheStuffer
     * 
     * @param BaseCacheStuffer 抽象基类
     * @param cacheStufferAdapter 缺省参数，默认为 None
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setCacheStuffer(cacheStuffer: BaseCacheStuffer, cacheStufferAdapter!: ?Proxy = None): DanmakuContext
    
    /*
     * 重置 DanmakuContext 对象
     *
     * @return 返回重置后的 DanmakuContext 对象
     */
    public func resetContext(): DanmakuContext
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
    public func setWidth (width: Float64) : Unit

    /*
     * 功能 - 设置高度
     * 
     * 参数 height - 高度
     * 返回值 - unit
     */
    public func setHeight (height: Float64) : Unit

    /*
     * 功能 - 获取宽度
     * 
     * 返回值 Float64 - 宽度 
     */
    public override func getWidth () : Float64

    /*
     * 功能 - 获取高度
     * 
     * 返回值 Float64 - 高度 
     */
    public override func getHeight () : Float64

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
     * 返回值 Float64 - 宽度
     */
    public override func getViewWidth () : Float64

    /*
     * 功能 - 获取视图高度
     * 
     * 返回值 Float64 - 高度
     */
    public override func getViewHeight () : Float64

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

