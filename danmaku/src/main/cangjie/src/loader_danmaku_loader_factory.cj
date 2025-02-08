/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakuLoaderFactory {
    public static let TAG_BILI: String = "bili"
    public static let TAG_ACFUN: String = "acfun"

    public static func create(tag: String): ?ILoader {
        return None
    }
}
