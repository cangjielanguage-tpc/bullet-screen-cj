package ohos_app_cangjie_entry

internal import ohos.base.LengthProp
internal import ohos.base.Color
internal import ohos.component.Column
internal import ohos.component.ViewBuilder// 宏依赖
internal import ohos.component.LegalCallCheck// 宏依赖
import ohos.state_manage.ViewStackProcessor  // 宏依赖
internal import ohos.component.If// 宏依赖
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

@Entry
@Component
class MyView {
    @State
    var isVisible: Bool = true
    @State
    var color: Int64 = -1
    @State
    var TextList: Array<String> = ["hide", "show", "pause", "resume", "发送一条(纯文本)", "发送一条(图文)", "定时发送", "GIF"]
    @State
    var model: DanmakuViewModel = DanmakuViewModel()
    var mContext: DanmakuContext = DanmakuContext.create()
    private var mParser: ?BaseDanmakuParser = None
    private var mCacheStufferAdapter: Proxy = Pro()
    private var path: String = ""
    @State var bottomHeight: Float64 = 0.0
    var display: ?Display = Option<Display>.None
    var timer: ?Timer = Option<Timer>.None

    func getModel():DanmakuViewModel {
        this.model
    }

    func viewInit() {
        this.model.setWidth(720 * 2)
        this.model.setHeight(720 * 2)
        let maxLinesPair: HashMap<Int64, Int64> = HashMap<Int64, Int64>()
        maxLinesPair.put(BaseDanmaku.TYPE_SCROLL_RL, 5) // 滚动弹幕最大显示5行
        // 设置是否禁止重叠
        let overlappingEnablePair: HashMap<Int64, Bool> = HashMap<Int64, Bool>()
        overlappingEnablePair.put(BaseDanmaku.TYPE_SCROLL_RL, true)
        overlappingEnablePair.put(BaseDanmaku.TYPE_FIX_TOP, true)
//        this.mContext = DanmakuContext.create()
        this.mContext.setDanmakuStyle(DANMAKU_STYLE_STROKEN, 3.0)
        this.mContext.setDuplicateMergingEnabled(false)
        this.mContext.setScrollSpeedFactor(1.2)
        this.mContext.setScaleTextSize(1.2)
        this.mContext.setCacheStuffer(SpannedCacheStuffer(), this.mCacheStufferAdapter)// 图文混排使用SpannedCacheStuffer
        this.mContext.setMaximumLines(maxLinesPair)
        this.mContext.preventOverlapping(overlappingEnablePair)
        this.mContext.setDanmakuMargin(40)
//        let that = this
        this.mParser = this.createParser()
        this.model.setCallback(DanmaEntryCall(this))
        this.model.setOnDanmakuClickListener(OnDanMu(this))
        this.model.prepare(this.mParser.getOrThrow(), this.mContext)
        this.model.showFPS(true)
        this.model.backgroundColor(Color.GRAY)
    }

    private func createParser(): BaseDanmakuParser {
        let parser: MyDanmakuParser = MyDanmakuParser();
        var arr: Array<Byte> = Array<Byte>()
        if (let Some(v) <- globalAbilityContext) {
            let stageContext = getStageContext(v)
            let rm: ResourceManager = ResourceManager.getResourceManager(stageContext)
            arr = rm.getRawFileContent("x.json")
        }
        let mjson: JsonValue = String.fromUtf8(arr) |> JsonValue.fromStr
        parser.load(JSONSource(mjson))
        return parser;
    }

    protected func aboutToAppear() {
        this.display = getDefaultDisplaySync()
        this.viewInit()
    }

    @Builder
    func buildText(i: Int64, clickCallBack: () -> Unit) {
        Text(this.TextList[i])
          .layoutWeight(8)
//          .fontWeight(FontWeight.Normal)
//          .textAlign(TextAlign.Center)
          .borderRadius(1)
          .fontSize(if (i <= 3) {24} else {30})
          .backgroundColor(if(this.color == i) { Color.GRAY }else { Color.WHITE})
          .onClick({ ent =>
            clickCallBack();
          })
//          .onTouch({ event =>
//            if (event.type === TouchType.Down) {
//              this.color = i;
//            }
//            if (event.type === TouchType.Up || event.type === TouchType.Move) {
//              this.color = -1;
//            }
//          })
//        if (i < this.TextList.length - 1) {
//          Text().layoutWeight(1);
//        }
    }

    @Builder
    func BtuView() {
        Column() {
          Row() {
            this.buildText(0, { =>
              this.model.hide();
            });
            this.buildText(1, { =>
              this.model.show();
            });
            this.buildText(2, { =>
              this.model.pause();
            });
            this.buildText(3, { =>
              this.model.resume();
            });
          }
          .opacity(0.8)
          .width(100.percent)
          .height(60)
          .backgroundColor(0x8acc0000)

        Row() {
            this.buildText(4, { =>
              this.addDanmaku(false);
            });
            this.buildText(5, { =>
              this.addDanmaKuShowTextAndImage(false);
            });
            this.buildText(6, { =>
              if (this.TextList[6] == '定时发送' || this.TextList[6] == 'Schedule to send') {
                timer = Timer.repeat(Duration.millisecond * 300, Duration.millisecond * 1000, { => this.addDanmaku(true)})
                this.TextList[6] = "取消定时"
              } else {
                timer.getOrThrow().cancel()
                this.TextList[6] = "定时发送"
              }
            });
//            this.buildText(7, { =>
//              this.addDanmaKuShowGif(false);
//            });
          }
          .opacity(0.8)
          .width(100.percent)
          .height(60)
          .backgroundColor(0x8acc0000)
        }
        .width(100.percent)
//        .height(this.bottomHeight)
//        .height(this.bottomHeight)
        .onClick({ent =>
//          this.isVisible = !this.isVisible
        })
      }

  private func addDanmaku(isLive: Bool): Unit {
    let danmaku: BaseDanmaku = this.mContext.mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL).getOrThrow()
    danmaku.text = "李总上线了.." + "${SystemClock.uptimeMillis()}"
    danmaku.padding = 5.0
    danmaku.priority = 0 // 可能会被各种过滤器过滤并隐藏显示
    danmaku.isLive = isLive
    danmaku.setTime(this.model.getCurrentTime() + 1200)
    danmaku.textSize = 25.0 * (this.mParser.getOrThrow().getDisplayer().getOrThrow().getDensity() * 0.8)
    danmaku.textColor = 0xffff0000
    danmaku.textShadowColor = 0xffffffff
    danmaku.borderColor = 0xff00ff00
    this.model.addDanmaku(danmaku)
  }

  private func addDanmaKuShowTextAndImage(isLive: Bool): Unit {
    let danmaku: BaseDanmaku = this.mContext.mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL).getOrThrow()
    danmaku.text = "<img src=\"resource://RAWFILE/startIcon.png\" width=\"" + "33" + "\" height=\"" + "33" + "\"/>" + "李总上线了.."
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

    func build() {
        Stack() {
            Flex(FlexParams(direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center)) {
                Stack() {
                    if (this.isVisible) {
                        Row()
                        .width(100.percent)
                        .height(60)
                        .backgroundColor(0x8a006161)
                        .opacity(0.8)
                        .position(x: 0, y: 0)
                    }
                }.width(100.percent)
                .height(60)
//                Row {
                DanmakuView(model: this.model)//.backgroundColor(Color.GRAY)
//                }
//                .width(100.percent)
//                .height(100.percent)
//                Stack() {
                    if (this.isVisible) {
                        Row() {
                            this.BtuView()
                        }
                        .alignItems(VerticalAlign.Bottom)
//                        .position(x: 0, y: 0)  // TODO
                    }
//                }.width(100.percent)
//                .height(60)
            }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(Color.BLACK)
            .onClick({ ent =>
                this.isVisible = !this.isVisible
            })
            .onAreaChange({ old, new =>
//                let bottomHeight = round(new.height)
//                let BtuViewHeight = (bottomHeight / 2.0) - 200.0/**(px2vp(360.px).getOrThrow().value)*/
                this.bottomHeight = 195.0 //if (BtuViewHeight >= 195.0) {BtuViewHeight} else { 195.0 }
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
//    console.log('DFM onDanmakuClick: danmakus size:' + danmakus.size())
//    let latest: BaseDanmaku =
//    if (null != latest) {
////      console.log('DFM onDanmakuClick: text of latest danmaku:' + latest.text)
//      return true
//    }
//    return false
        danmakus.last().isSome()
  }

  public func onDanmakuLongClick(danmakus: IDanmakus): Bool {
    return false
  }

  public func onViewClick(view: IDanmakuView): Bool {
    // this.that.isVisible = true
    return false
  }
}
