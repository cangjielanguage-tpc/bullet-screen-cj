/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package ohos_app_cangjie_entry

internal import ohos.base.LengthProp
internal import ohos.base.Color
internal import ohos.component.Column
internal import ohos.component.VerticalAlign
internal import ohos.component.ViewBuilder// Macro expansion dependency class.
internal import ohos.component.LegalCallCheck// Macro expansion dependency class.
import ohos.state_manage.ViewStackProcessor  // Macro expansion dependency class.
internal import ohos.component.If// Macro expansion dependency class.
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
import stdx.encoding.json.JsonValue
import ohos.router.Router
import ohos.prompt_action.*


var testFile = "x.json"

var Landscape_screen = "横屏"
var showS: Array<String> = ["显示FPS", "不显示FPS"]
var showIndex: Int64 = 0

@Entry
@Component
class Index {
    @State
    var index: Int64 = 0
    func build() {
            Column {
                Row{

                    Button("弹幕LLT用例")
                    .onClick({ ent =>
                            Router.push(url: "MyView")
                        })
                }
                Row {
                    Button("z.json")
                    .onClick({ ent =>
                        testFile = "z.json"
                    })
                    Button("x.json")
                    .onClick({ ent =>
                        testFile = "x.json"
                    })
                }
                Row {
                    Button(Landscape_screen)
                    .onClick({ _ =>
                        if (Landscape_screen == '竖屏') {
                            globalWindow?.setPreferredOrientation(DANMAOrientation.PORTRAIT)
                            Landscape_screen = "横屏"
                        } else {
                            globalWindow?.setPreferredOrientation(DANMAOrientation.LANDSCAPE)
                            Landscape_screen = "竖屏"
                        }
                    })
                    Button(showS[index])
                    .onClick({ _ =>
                        if (showIndex == 0) {
                            showIndex = 1
                            index = 1
                        } else {
                            showIndex = 0
                            index = 0
                        }
                    })
                }
            }
            .width(100.percent)
            .height(100.percent)
    }
}
