/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package ohos_app_cangjie_entry

internal import ohos.base.AppLog
internal import ohos.ability.AbilityContext
internal import ohos.ability.AbilityStage
internal import ohos.ability.LaunchReason
internal import ohos.window.Orientation as DANMAOrientation
internal import ohos.window.Window

public var globalAbilityContext: Option<AbilityContext> = Option<AbilityContext>.None

var globalWindow: ?Window = None

class MainAbility <: Ability {
    public init() {
        super()
        registerSelf()
    }

    public override func onCreate(want: Want, launchParam: LaunchParam): Unit {
        AppLog.info("MainAbility OnCreated.${want.abilityName}")
        globalAbilityContext = Option<AbilityContext>.Some(this.context)
        match (launchParam.launchReason) {
            case LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
    }

    public override func onWindowStageCreate(windowStage: WindowStage): Unit {
        let m = windowStage.getMainWindow()
        globalWindow = m
        AppLog.info("MainAbility onWindowStageCreate.")
        windowStage.loadContent("Index")
    }
}
