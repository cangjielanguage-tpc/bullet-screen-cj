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
     * 从右到左的滚动弹幕类型
     */
    public static let TYPE_SCROLL_RL: Int64 = 1
    
    /*
     * 从左到右的滚动弹幕类型
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
     * Z轴偏转角度
     */
    public var rotationZ: Float64 = 0.0

    /**
     * Y轴偏转角度
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
     * 表示弹幕的存活时长，实参的单位是毫秒。
     */
    public var duration: DanmakuDuration = DanmakuDuration(0)

    /**
     * 表示弹幕的唯一索引/编号。
     */
    public var index: Int64 = 0
    
    /**
     * 是否是直播弹幕
     */
    public var isLive: Bool = false

    /*
     * 设置弹幕开始渲染的时间
     *
     * @param time - 传入时间
     *
     */
    public func setTime(time: Int64): Unit
    
    /*
     * 设置 pixelMap 集合到弹幕对象中，一般应用于 gif 动图
     *
     * @param pixelMapList - pixelMap 集合，若pixelMapList为空则不加载帧
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
     * 设置字体，默认值是"sans-serif"
     *
     * @param font - 传入自定义字体，参照ohos.font（自定义字体）
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setTypeface(font: String): DanmakuContext
    
    /*
     * 设置透明度，透明度和值成正比，建议取值范围0-255。
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
     * @param p - 传入外边距值，单位是px像素
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuMargin(m: Int64): DanmakuContext
    
    /*
     * 设置顶部的外边距
     *
     * @param p - 传入外边距顶部值，单位是px像素
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
     * DANMAKU_STYLE_PROJECTION: Int64 = 3 投影样式，values 传入 offsetX X轴偏移量, offsetY Y轴偏移量, alpha 透明度
     *
     * @param values - 传入数值
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuStyle(style: Int64, values: Array<Float64>): DanmakuContext
    
    /*
     * 设置是否粗体显示,跟setTypeface接口设置的字体有效性强相关，如字体设置无效则加粗无效。
     *
     * @param bold - 是否粗体
     *
     * @return 返回 DanmakuContext 对象
     */
    public func setDanmakuBold(bold: Bool): DanmakuContext
    
    /*
     * 设置弹幕滚动速度系数,只对滚动弹幕（TYPE_SCROLL_LR，TYPE_SCROLL_RL）有效
     *
     * @param p - 弹幕滚动系数值，系数越大，弹幕滚动速度越慢
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
     * 设置最大显示行数，添加弹幕时，若设置priority大于0时，不受行数的限制。
     * @param pairs map<K,V> 如果为空则行数不受限制
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
     * 设置弹幕是否防重叠
     * @param pairs map<K,V> 如果为空则默认为允许重叠
     * K = (BaseDanmaku.TYPE_SCROLL_RL|BaseDanmaku.TYPE_SCROLL_LR|BaseDanmaku.TYPE_FIX_TOP|BaseDanmaku.TYPE_FIX_BOTTOM)
     * V = true|false 是否防重叠
     *
     * @return 返回 DanmakuContext 对象
     */
    public func preventOverlapping(pairs: HashMap<Int64, Bool>): DanmakuContext
    
    /*
     * 判断是否设置防重叠
     *
     * @return 返回是否设置防重叠
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
public class DanmakuViewModel <: IDanmakuView {

    /*
     * 功能 - 设置背景颜色
     * 
     * 参数 color - RGB的十六进制颜色值
     * 返回值 Unit
     */
    public func backgroundColor (color: UInt32) : Unit

    /*
     * 功能 - 设置背景颜色
     * 
     * 参数 color - 颜色类，参照ohos.color
     * 返回值 Unit
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
     * 参数 show - 是否显示
     * 返回值 Unit
     */
    public override func showFPS (show: Bool) : Unit

    /*
     * 功能 - 添加弹幕，BaseDanmaku类是抽象弹幕类， 如需创建弹幕请参阅 BaseDanmakuParser
     * 
     * 参数 item - 弹幕类
     * 返回值 Unit
     */
    public override func addDanmaku (item: BaseDanmaku) : Unit

    /*
     * 功能 - 使弹幕无效
     * 
     * 参数 item - 弹幕类
     * 参数 remeasure - 是否重新检测
     * 返回值 Unit
     */
    public override func invalidateDanmaku (item: BaseDanmaku, remeasure: Bool) : Unit

    /*
     * 功能 - 删除所有弹幕
     * 
     * 参数 isClearDanmakusOnScreen - 是否清屏
     * 返回值 Unit
     */
    public override func removeAllDanmakus (isClearDanmakusOnScreen: Bool) : Unit

    /*
     * 功能 - 删除所有弹幕
     * 
     * 返回值 Unit
     */
    public override func removeAllLiveDanmakus () : Unit

    /*
     * 功能 - 设置回调函数
     * 
     * 参数 callback - 回调函数DanmakuCallBack
     * 返回值 Unit
     */
    public override func setCallback (callback: DanmakuCallBack) : Unit

    /*
     * 功能 - 获取当前时间，单位是毫秒
     * 
     * 返回值 Int64 - 时间的int64表示
     */
    public override func getCurrentTime () : Int64

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
     * 返回值 Unit
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
     * 返回值 Unit
     */
    public override func prepare (parser: BaseDanmakuParser, config: DanmakuContext) : Unit

    /*
     * 功能 - 指定的时间点
     * 
     * 参数 ms - 毫秒值
     * 返回值 Unit
     */
    public override func seekTo (ms: Int64) : Unit

    /*
     * 功能 - 开始播放
     * 
     * 返回值 Unit
     */
    public override func start () : Unit

    /*
     * 功能 - 指定的时间点开始播放
     * 
     * 参数 position - 时间点，单位毫秒
     * 返回值 Unit
     */
    public override func start (position: Int64) : Unit

    /*
     * 功能 - 停止播放并释放弹幕资源，resume无法恢复。
     * 
     * 返回值 Unit
     */
    public override func stop () : Unit

    /*
     * 功能 - 暂停播放
     * 
     * 返回值 Unit
     */
    public override func pause () : Unit

    /*
     * 功能 - 继续播放
     * 
     * 返回值 Unit
     */
    public override func resume () : Unit

    /*
     * 功能 - 释放资源并停止播放，resume无法恢复。
     * 
     * 返回值 Unit
     */
    public override func release () : Unit

    /*
     * 功能 - 转换播放状态。
     * 
     * 返回值 Unit 
     */
    public override func toggle () : Unit

    /*
     * 功能 - 显示
     * 
     * 返回值 Unit 
     */
    public override func show () : Unit

    /*
     * 功能 - 隐藏
     * 
     * 返回值 Unit 
     */
    public override func hide () : Unit

    /*
     * 功能 - 清除当前已播放的弹幕
     * 
     * 返回值 Unit
     */
    public override func clearDanmakusOnScreen () : Unit

    /*
     * 功能 - 设置弹幕点击的监听器
     * 
     * 参数 listener - OnDanmakuClickListener
     * 返回值 Unit
     */
    public override func setOnDanmakuClickListener (listener: OnDanmakuClickListener) : Unit

    /*
     * 功能 - 设置弹幕点击的监听器
     * 
     * 参数 listener - OnDanmakuClickListener
     * 参数 xOff - xoff，X轴偏移量
     * 参数 yOff - yOff，Y轴偏移量
     * 返回值 Unit
     */
    public override func setOnDanmakuClickListener (listener: OnDanmakuClickListener, xOff: Float64, yOff: Float64) : Unit
}

/*
 * 类名 - BaseDanmakuParser
 * 功能 - BaseDanmaku解析器
 */
public abstract class BaseDanmakuParser {
    
    /*
     * 功能 - 提供一个默认的json格式弹幕解析器。格式请参考 entry/src/main/resources/rawfile/z.json
     * 
     * 返回值 BaseDanmakuParser - BaseDanmakuParser
     */
    public static func getDefaultJsonDanmakuParser(): BaseDanmakuParser
    
    /*
     * 功能 - 加载数据源
     *
     * 参数 IDataSource - 弹幕数据源
     * 返回值 BaseDanmakuParser - BaseDanmakuParser
     */
    public func load(source: IDataSource): BaseDanmakuParser
}

/*
 * 类名 - IDataSource
 * 功能 - 弹幕数据源
 */
public interface IDataSource {
    
    /*
     * 功能 - 获取数据源封装类型
     * 
     * 返回值 Any - 数据源封装类型
     */
    func data(): Any
    
    /*
     * 功能 - 释放资源
     * 
     * 返回值 Unit
     */
    func release(): Unit
}
```

