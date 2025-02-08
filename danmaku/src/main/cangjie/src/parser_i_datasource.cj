/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

let SCHEME_HTTP_TAG: String = "http"
let SCHEME_HTTPS_TAG: String = "https"
let SCHEME_FILE_TAG: String = "file"

public interface IDataSource<T> {
    func data(): T

    func release(): Unit
}
