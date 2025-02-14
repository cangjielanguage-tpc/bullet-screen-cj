package ohos_app_cangjie_entry

internal import ohos.base.LengthProp
internal import ohos.base.Color
internal import ohos.component.Column
internal import ohos.component.VerticalAlign
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
import std.collection.*
import std.math.*
import std.runtime.*
import encoding.json.JsonValue
import ohos.router.Router
import ohos.prompt_action.*

@Entry
@Component
class Index {
    func build() {
            Column {
                Row{

                    Button("弹幕LLT用例")
                    .onClick({ ent =>
                            Router.push(url: "MyView")
                        })
                }
                Row {
                    Button("MemoryInfo.maxHeapSize")
                    .onClick({ ent =>
                        PromptAction.showToast(message: "------------------- ret = ${MemoryInfo.maxHeapSize / 1024 / 1024}MB")
                    })
                }
                Row {
                    Button("MemoryInfo.allocatedHeapSize")
                    .onClick({ ent =>
                        PromptAction.showToast(message: "------------------- ret = ${MemoryInfo.allocatedHeapSize/ 1024} KB")
                    })
                }
            }
            .width(100.percent)
            .height(100.percent)
    }
}
