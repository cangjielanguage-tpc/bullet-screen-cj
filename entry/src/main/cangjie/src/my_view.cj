package ohos_app_cangjie_entry

internal import ohos.base.LengthProp
internal import ohos.base.Color
internal import ohos.component.Column
internal import ohos.component.ViewBuilder // Macro expansion dependency class.
internal import ohos.component.LegalCallCheck // Macro expansion dependency class.
import ohos.state_manage.ViewStackProcessor // Macro expansion dependency class.
internal import ohos.component.If // Macro expansion dependency class.
internal import ohos.component.Row
internal import ohos.component.Button
internal import ohos.component.px2vp
internal import ohos.component.lpx2px
internal import ohos.component.Stack
internal import ohos.component.Flex
internal import ohos.component.FlexParams
internal import ohos.component.FlexDirection
internal import ohos.component.FlexAlign
internal import ohos.component.ItemAlign
internal import ohos.component.Text
internal import ohos.component.CustomView
internal import ohos.component.CJEntry
internal import ohos.component.loadNativeView
internal import ohos.state_manage.SubscriberManager
internal import ohos.state_manage.ObservedProperty
internal import ohos.state_manage.LocalStorage
internal import danmaku.*
import ohos.resource_manager.ResourceManager
import ohos.ability.getStageContext
import ohos.state_macro_manage.Entry
import ohos.state_macro_manage.Component
import ohos.state_macro_manage.Builder
import ohos.state_macro_manage.State
import ohos.state_macro_manage.r
import ohos.hilog.*
import ohos.display.*
import std.collection.*
import std.math.*
import encoding.json.JsonValue
import ohos.component.VerticalAlign
import std.sync.Timer
import std.time.Duration
import ohos.component.FontWeight
import ohos.component.TextAlign
import ohos.component.TouchType
import ohos.image.PixelMap
import ohos.image.createPixelMap
import ohos.image.createImageSource

@Entry
@Component
class MyView {
    @State
    var isVisible: Bool = true
    @State
    var color: Int64 = -1
    @State
    var TextList: Array<String> = ["hide", "show", "pause", "resume", "发送一条(纯文本)", "发送一条(图文)", "定时发送", "GIF", "横竖切换"]
    @State
    var model: DanmakuViewModel = DanmakuViewModel()
    var mContext: DanmakuContext = DanmakuContext.create()
    private var mParser: ?BaseDanmakuParser = None
    private var mCacheStufferAdapter: Proxy = Pro()
    @State
    var pixel: ?Array<PixelMap> = Option<Array<PixelMap>>.None
    @State
    var bottomHeight: Float64 = 0.0
    @State
    var btnHeight: Float64 = 0.0
    var display: ?Display = Option<Display>.None
    var timer: ?Timer = Option<Timer>.None

    func getModel():DanmakuViewModel {
        this.model
    }

    func viewInit() {
        this.model.setWidth(lpx2px(720.lpx).getOrThrow().value)
        this.model.setHeight(lpx2px(720.lpx).getOrThrow().value)
        let maxLinesPair: HashMap<Int64, Int64> = HashMap<Int64, Int64>()
        maxLinesPair.put(BaseDanmaku.TYPE_SCROLL_RL, 5) // 滚动弹幕最大显示5行
        // 设置是否禁止重叠
        let overlappingEnablePair: HashMap<Int64, Bool> = HashMap<Int64, Bool>()
        overlappingEnablePair.put(BaseDanmaku.TYPE_SCROLL_RL, true)
        overlappingEnablePair.put(BaseDanmaku.TYPE_FIX_TOP, true)
        this.mContext.setDanmakuStyle(DANMAKU_STYLE_STROKEN, 3.0)
        this.mContext.setDuplicateMergingEnabled(false)
        this.mContext.setScrollSpeedFactor(1.2)
        this.mContext.setScaleTextSize(1.2)
        this.mContext.setCacheStuffer(SpannedCacheStuffer(), cacheStufferAdapter: this.mCacheStufferAdapter) // 图文混排使用SpannedCacheStuffer
        this.mContext.setMaximumLines(maxLinesPair)
        this.mContext.preventOverlapping(overlappingEnablePair)
        this.mContext.setDanmakuMargin(40)
        this.mParser = this.createParser()
        this.model.setCallback(DanmaEntryCall(this))
        this.model.setOnDanmakuClickListener(OnDanMu(this))
        this.model.prepare(this.mParser.getOrThrow(), this.mContext)
        this.model.showFPS(showIndex == 0)
        this.model.backgroundColor(Color.GRAY)
    }

    private func createParser(): BaseDanmakuParser {
        let parser: BaseDanmakuParser = if (testFile == "x.json") {
            ArktsDanmakuParser()
        } else {
            BaseDanmakuParser.getDefaultJsonDanmakuParser()
        }
        var arr: Array<Byte> = Array<Byte>()
        if (let Some(v) <- globalAbilityContext) {
            let stageContext = getStageContext(v)
            let rm: ResourceManager = ResourceManager.getResourceManager(stageContext)
            arr = rm.getRawFileContent(testFile)
        }
        let mjson: JsonValue = String.fromUtf8(arr) |> JsonValue.fromStr
        parser.load(JSONSource(mjson))
        return parser
    }

    protected func aboutToAppear() {
        this.viewInit()
        this.pixel = savaGifToca("RRR.gif")
    }

    protected func aboutToDisappear() {

    }

    @Builder
    func buildText(i: Int64, clickCallBack: (i: Int64) -> Unit) {
        Text(this.TextList[i])
            .layoutWeight(8)
            .fontWeight(FontWeight.Normal)
            .textAlign(TextAlign.Center)
            .borderRadius(1)
            .fontSize(22)
            .backgroundColor(if (this.color == i) {
                Color.GRAY
            } else {
                Color.WHITE
            })
            .onClick({
                ent => clickCallBack(i)
            })
            .onTouch(
                {
                    event =>
                    if (event.eventType.toString() == TouchType.Down.toString()) {
                        this.color = i
                    }
                    if (event.eventType.toString() == TouchType.Up.toString() || event.eventType.toString() ==
                        TouchType.Move.toString()) {
                        this.color = -1
                    }
                }
            )
        if (i < this.TextList.size - 1) {
            Text("").layoutWeight(1)
        }
    }

    @Builder
    func BtuView() {
        Column() {
            Row() {
                this.buildText(
                    0,
                    {
                        i => this.model.hide()
                    }
                )
                this.buildText(
                    1,
                    {
                        i => this.model.show()
                    }
                )
                this.buildText(
                    2,
                    {
                        i => this.model.pause()
                    }
                )
                this.buildText(
                    3,
                    {
                        i => this.model.resume()
                    }
                )
                this.buildText(
                    4,
                    {
                        i => this.addDanmaku(false)
                    }
                )
                this.buildText(
                    5,
                    {
                        i => this.addDanmaKuShowTextAndImage(false)
                    }
                )
                this.buildText(
                    6,
                    {
                        i => if (this.TextList[6] == '定时发送' || this.TextList[6] == 'Schedule to send') {
                            timer = Timer.repeat(Duration.millisecond * 300, Duration.millisecond * 1000,
                                {=> this.addDanmaku(true)})
                            this.TextList[6] = "取消定时"
                        } else {
                            timer.getOrThrow().cancel()
                            this.TextList[6] = "定时发送"
                        }
                    }
                )
                this.buildText(7, { i =>
                  addDanmaKuShowGif(false)
                })
                this.buildText(
                    8,
                    {
                        i => if (Landscape_screen == '竖屏') {
                            globalWindow?.setPreferredOrientation(DANMAOrientation.PORTRAIT)
                            Landscape_screen = "横屏"
                        } else {
                            globalWindow?.setPreferredOrientation(DANMAOrientation.LANDSCAPE)
                            Landscape_screen = "竖屏"
                        }
                    }
                )
            }
            .opacity(0.8)
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(0x8acc0000)
        }
        .width(100.percent)
        .height(this.bottomHeight)
        .onClick({
            ent => this.isVisible = !this.isVisible
        })
    }

    private func addDanmaku(isLive: Bool): Unit {
        let danmaku: BaseDanmaku = this.mContext.mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL).getOrThrow()
        danmaku.text = "你好 华为仓颉.." + "${SystemClock.uptimeMillis()}"
        danmaku.padding = 5.0
        danmaku.priority = 0 // 可能会被各种过滤器过滤并隐藏显示
        danmaku.isLive = isLive
        danmaku.setTime(this.model.getCurrentTime() + 1200)
        danmaku.textSize = 25.0 * (this.mParser.getOrThrow().getDisplayer().getOrThrow().getDensity() * 0.8)
        danmaku.textColor = 0xffff0000
        danmaku.textShadowColor = 0xffffffff
        danmaku.borderColor = 0x00ff0000
        this.model.addDanmaku(danmaku)
    }

    private func addDanmaKuShowTextAndImage(isLive: Bool): Unit {
        let danmaku: BaseDanmaku = this.mContext.mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL).getOrThrow()
        danmaku.image = ImgObj("resource://RAWFILE/startIcon.png", 33.0, 33.0)
        danmaku.text = "仓颉你好.."
        danmaku.padding = 5.0
        danmaku.priority = 1 // 一定会显示, 一般用于本机发送的弹幕
        danmaku.isLive = isLive
        danmaku.setTime(this.model.getCurrentTime() + 1200)
        danmaku.textSize = 25.0 * (this.mParser.getOrThrow().getDisplayer().getOrThrow().getDensity() * 0.8)
        danmaku.textColor = 0xffff0000
        danmaku.textShadowColor = 0
        danmaku.underlineColor = 0xff00ff00
        this.model.addDanmaku(danmaku)
    }

    private func addDanmaKuShowGif(isLive: Bool): Unit {
        let danmaku: BaseDanmaku = this.mContext.mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL).getOrThrow()
        danmaku.setPixelMapList(ArrayList<PixelMap>(pixel.getOrThrow()))
        danmaku.setIsAnimation(true)
        danmaku.image = ImgObj("resource://RAWFILE/RRR.gif", 99.0, 99.0)
        danmaku.text = ""
        danmaku.padding = 0.0
        danmaku.priority = 1 // 一定会显示, 一般用于本机发送的弹幕
        danmaku.isLive = isLive
        danmaku.setTime(this.model.getCurrentTime() + 1200)
        danmaku.textColor = 0
        this.model.addDanmaku(danmaku)
    }

    private func savaGifToca(gifName: String): Array<PixelMap> {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(globalAbilityContext.getOrThrow()))
        let value: Array<UInt8> = resourceManager.getRawFileContent(gifName)
        return createImageSource(value).createPixelMapList()
    }

    func build() {
        Stack() {
            Flex(FlexParams(direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center)) {
                if (this.isVisible) {
                    Row()
                        .width(100.percent)
                        .height(60)
                        .backgroundColor(0x8a006161)
                        .opacity(0.8)
                        .position(x: 0, y: 0)
                    }
                DanmakuView(model: this.model)
                if (this.isVisible) {
                    Row() {
                        this.BtuView()
                    }
                    .height(btnHeight)
                }
            }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(Color.BLACK)
            .onClick({
                    ent => this.isVisible = !this.isVisible
                })
            .onAreaChange({
                old, new =>
                    let bottomHeight = round(px2vp(new.height.px).getOrThrow().value)
                    let BtuViewHeight = (bottomHeight / 2.0) - 193.84
                    btnHeight = BtuViewHeight
                    this.bottomHeight = if (BtuViewHeight >= 195.0) {BtuViewHeight} else { 195.0 }
            })
        }
    }
}

class OnDanMu <: OnDanmakuClickListener {
    private var that: MyView

    init(that: MyView) {
        this.that = that
    }

    public func onDanmakuClick(danmakus: IDanmakus): Bool {
        danmakus.last().isSome()
    }

    public func onDanmakuLongClick(danmakus: IDanmakus): Bool {
        return false
    }

    public func onViewClick(view: IDanmakuView): Bool {
        return false
    }
}
