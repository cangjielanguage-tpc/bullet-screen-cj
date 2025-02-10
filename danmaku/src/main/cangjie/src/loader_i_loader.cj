/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public interface ILoader {
    func getDataSource(): IDataSource

    /**
     * @param uri 弹幕文件地址(http:// file://)
     */
    func load(uri: String): Unit
}
