/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public enum DanmakuConfigTag {
    | FT_DANMAKU_VISIBILITY
    | FB_DANMAKU_VISIBILITY
    | L2R_DANMAKU_VISIBILITY
    | R2L_DANMAKU_VISIBILIY
    | SPECIAL_DANMAKU_VISIBILITY
    | TYPEFACE
    | TRANSPARENCY
    | SCALE_TEXTSIZE
    | MAXIMUM_NUMS_IN_SCREEN
    | DANMAKU_STYLE
    | DANMAKU_BOLD
    | COLOR_VALUE_WHITE_LIST
    | USER_ID_BLACK_LIST
    | USER_HASH_BLACK_LIST
    | SCROLL_SPEED_FACTOR
    | BLOCK_GUEST_DANMAKU
    | DUPLICATE_MERGING_ENABLED
    | MAXIMUN_LINES
    | OVERLAPPING_ENABLE
    | ALIGN_BOTTOM
    | DANMAKU_MARGIN
    | DANMAKU_SYNC

    public operator func ==(that: DanmakuConfigTag): Bool {
        match ((this, that)) {
            case (FT_DANMAKU_VISIBILITY, FT_DANMAKU_VISIBILITY) => true
            case (FB_DANMAKU_VISIBILITY, FB_DANMAKU_VISIBILITY) => true
            case (L2R_DANMAKU_VISIBILITY, L2R_DANMAKU_VISIBILITY) => true
            case (R2L_DANMAKU_VISIBILIY, R2L_DANMAKU_VISIBILIY) => true
            case (SPECIAL_DANMAKU_VISIBILITY, SPECIAL_DANMAKU_VISIBILITY) => true
            case (TYPEFACE, TYPEFACE) => true
            case (TRANSPARENCY, TRANSPARENCY) => true
            case (SCALE_TEXTSIZE, SCALE_TEXTSIZE) => true
            case (MAXIMUM_NUMS_IN_SCREEN, MAXIMUM_NUMS_IN_SCREEN) => true
            case (DANMAKU_STYLE, DANMAKU_STYLE) => true
            case (DANMAKU_BOLD, DANMAKU_BOLD) => true
            case (COLOR_VALUE_WHITE_LIST, COLOR_VALUE_WHITE_LIST) => true
            case (USER_ID_BLACK_LIST, USER_ID_BLACK_LIST) => true
            case (USER_HASH_BLACK_LIST, USER_HASH_BLACK_LIST) => true
            case (SCROLL_SPEED_FACTOR, SCROLL_SPEED_FACTOR) => true
            case (BLOCK_GUEST_DANMAKU, BLOCK_GUEST_DANMAKU) => true
            case (DUPLICATE_MERGING_ENABLED, DUPLICATE_MERGING_ENABLED) => true
            case (MAXIMUN_LINES, MAXIMUN_LINES) => true
            case (OVERLAPPING_ENABLE, OVERLAPPING_ENABLE) => true
            case (ALIGN_BOTTOM, ALIGN_BOTTOM) => true
            case (DANMAKU_MARGIN, DANMAKU_MARGIN) => true
            case (DANMAKU_SYNC, DANMAKU_SYNC) => true
            case _ => false
        }
    }

    public func isVisibilityRelatedTag(tag: DanmakuConfigTag): Bool {
        return (tag == DanmakuConfigTag.FT_DANMAKU_VISIBILITY || tag == DanmakuConfigTag.FB_DANMAKU_VISIBILITY
            || tag == DanmakuConfigTag.L2R_DANMAKU_VISIBILITY || tag == DanmakuConfigTag.R2L_DANMAKU_VISIBILIY
            || tag == DanmakuConfigTag.SPECIAL_DANMAKU_VISIBILITY || tag == DanmakuConfigTag.COLOR_VALUE_WHITE_LIST
            || tag == DanmakuConfigTag.USER_ID_BLACK_LIST)
    }
}


public class DanmakuContext {
    public init() {}
    public static func create(): DanmakuContext {
        return DanmakuContext()
    }

    /**
     * 默认字体
     */
    public var mFont: String = ""

    /**
     * paint alpha:0-255
     */
    public var transparency: Int64 = AlphaValue.MAX
    public var scaleTextSize: Float64 = 1.0
    public var margin: Int64 = 0

    /**
     * 弹幕显示隐藏设置
     */
    public var FTDanmakuVisibility: Bool = true
    public var FBDanmakuVisibility: Bool = true
    public var L2RDanmakuVisibility: Bool = true
    public var R2LDanmakuVisibility: Bool = true
    public var SpecialDanmakuVisibility: Bool = true

    var mFilterTypes: ArrayList<Int64> = ArrayList<Int64>()

    /**
     * 同屏弹幕数量 -1 按绘制效率自动调整 0 无限制 n 同屏最大显示n个弹幕
     */
    public var maximumNumsInScreen: Int64 = -1

    /**
     * 默认滚动速度系数
     */
    public var scrollSpeedFactor: Float64 = 1.0
    public var danmakuSync: ?AbsDanmakuSync = None
    var mColorValueWhiteList: ArrayList<Int64> = ArrayList<Int64>()
    var mUserIdBlackList: ArrayList<Int64> = ArrayList<Int64>()
    var mUserHashBlackList: ArrayList<String> = ArrayList<String>()
    private var mCallbackList: ?ArrayList<ConfigChangedCallback> = None
    private var mBlockGuestDanmaku: Bool = false
    private var mDuplicateMergingEnable: Bool = false
    private var mIsAlignBottom: Bool = false
    private var mCacheStuffer: ?BaseCacheStuffer = None
    private var mIsMaxLinesLimited: Bool = true
    private var mIsPreventOverlappingEnabled: Bool = true
    public var mDisplayer: AbsDisplayer<DanmakuCanvas2D, String> = OhcjDisplayer()
    public var mGlobalFlagValues: GlobalFlagValues = GlobalFlagValues()
    public var mDanmakuFilters: DanmakuFilters = DanmakuFilters()
    public var mDanmakuFactory: DanmakuFactory = DanmakuFactory.create()
    private var mBaseComparator: BaseComparator = BaseComparator()

    public func getBaseComparator(): BaseComparator {
        return mBaseComparator
    }

    public func setBaseComparator(baseComparator: BaseComparator): Unit {
        mBaseComparator = baseComparator
    }

    public func getDisplayer():AbsDisplayer<DanmakuCanvas2D, String> {
        return mDisplayer
    }

    /**
     * set typeface
     *
     * @param font
     */
    public func setTypeface(font: String): DanmakuContext {
        if (mFont != font) {
            mFont = font
            mDisplayer.clearTextHeightCache()
            mDisplayer.setTypeFace(font)
            notifyConfigureChanged(DanmakuConfigTag.TYPEFACE)
        }
        return this
    }

    public func setDanmakuTransparency(p: Float64): DanmakuContext {
        let newTransparency: Int64 = Int64(p * Float64(AlphaValue.MAX))
        if (newTransparency != transparency) {
            transparency = newTransparency
            mDisplayer.setTransparency(newTransparency)
            notifyConfigureChanged(DanmakuConfigTag.TRANSPARENCY, p)
        }
        return this
    }

    public func setScaleTextSize(p: Float64): DanmakuContext {
        if (scaleTextSize != p) {
            scaleTextSize = p
            mDisplayer.clearTextHeightCache()
            mDisplayer.setScaleTextSizeFactor(p)
            mGlobalFlagValues.updateMeasureFlag()
            mGlobalFlagValues.updateVisibleFlag()
            notifyConfigureChanged(DanmakuConfigTag.SCALE_TEXTSIZE, p)
        }
        return this
    }

    public func setDanmakuMargin(m: Int64): DanmakuContext {
        if (margin != m) {
            margin = m
            mDisplayer.setMargin(m)
            mGlobalFlagValues.updateFilterFlag()
            mGlobalFlagValues.updateVisibleFlag()
            notifyConfigureChanged(DanmakuConfigTag.DANMAKU_MARGIN, m)
        }
        return this
    }

    public func setMarginTop(m: Int64): DanmakuContext {
        mDisplayer.setAllMarginTop(m)
        return this
    }

    /**
     * @return 是否显示顶部弹幕
     */
    public func getFTDanmakuVisibility(): Bool {
        return FTDanmakuVisibility
    }

    /**
     * 设置是否显示顶部弹幕
     *
     * @param visible
     */
    public func setFTDanmakuVisibility(visible: Bool): DanmakuContext {
        setDanmakuVisible(visible, BaseDanmaku.TYPE_FIX_TOP)
        setFilterData(DanmakuFilters.TAG_TYPE_DANMAKU_FILTER, mFilterTypes)
        mGlobalFlagValues.updateFilterFlag()
        if (FTDanmakuVisibility != visible) {
            FTDanmakuVisibility = visible
            notifyConfigureChanged(DanmakuConfigTag.FT_DANMAKU_VISIBILITY, visible)
        }
        return this
    }

    private func setFilterData(tag: String, data: Any, primary!: Bool = true): Unit {
        let filter: ?Any = mDanmakuFilters.get(tag, primary)
        if (let Some(v) <- filter) {
            if (let Some(fil) <- v as IDanmakuFilter<Any>) {
                fil.setData(data)
            }
        }
    }

    private func setDanmakuVisible(visible: Bool, t: Int64): Unit {
        if (visible) {
            mFilterTypes.remove(t)
        } else if (!mFilterTypes.contains(t)) {
            mFilterTypes.append(t)
        }
    }

    /**
     * @return 是否显示底部弹幕
     */
    public func getFBDanmakuVisibility(): Bool {
        return FBDanmakuVisibility
    }

    /**
     * 设置是否显示底部弹幕
     *
     * @param visible
     */
    public func setFBDanmakuVisibility(visible: Bool): DanmakuContext {
        setDanmakuVisible(visible, BaseDanmaku.TYPE_FIX_BOTTOM)
        setFilterData(DanmakuFilters.TAG_TYPE_DANMAKU_FILTER, mFilterTypes)
        mGlobalFlagValues.updateFilterFlag()
        if (FBDanmakuVisibility != visible) {
            FBDanmakuVisibility = visible
            notifyConfigureChanged(DanmakuConfigTag.FB_DANMAKU_VISIBILITY, visible)
        }
        return this
    }

    /**
     * @return 是否显示左右滚动弹幕
     */
    public func getL2RDanmakuVisibility(): Bool {
        return L2RDanmakuVisibility
    }

    /**
     * 设置是否显示左右滚动弹幕
     *
     * @param visible
     */
    public func setL2RDanmakuVisibility(visible: Bool): DanmakuContext {
        setDanmakuVisible(visible, BaseDanmaku.TYPE_SCROLL_LR)
        setFilterData(DanmakuFilters.TAG_TYPE_DANMAKU_FILTER, mFilterTypes)
        mGlobalFlagValues.updateFilterFlag()
        if (L2RDanmakuVisibility != visible) {
            L2RDanmakuVisibility = visible
            notifyConfigureChanged(DanmakuConfigTag.L2R_DANMAKU_VISIBILITY, visible)
        }
        return this
    }

    /**
     * @return 是否显示右左滚动弹幕
     */
    public func getR2LDanmakuVisibility(): Bool {
        return R2LDanmakuVisibility
    }

    /**
     * 设置是否显示右左滚动弹幕
     *
     * @param visible
     */
    public func setR2LDanmakuVisibility(visible: Bool): DanmakuContext {
        setDanmakuVisible(visible, BaseDanmaku.TYPE_SCROLL_RL)
        setFilterData(DanmakuFilters.TAG_TYPE_DANMAKU_FILTER, mFilterTypes)
        mGlobalFlagValues.updateFilterFlag()
        if (R2LDanmakuVisibility != visible) {
            R2LDanmakuVisibility = visible
            notifyConfigureChanged(DanmakuConfigTag.R2L_DANMAKU_VISIBILIY, visible)
        }
        return this
    }

    /**
     * @return 是否显示特殊弹幕
     */
    public func getSpecialDanmakuVisibility(): Bool {
        return SpecialDanmakuVisibility
    }

    /**
     * 设置是否显示特殊弹幕
     *
     * @param visible
     */
    public func setSpecialDanmakuVisibility(visible: Bool): DanmakuContext {
        setDanmakuVisible(visible, BaseDanmaku.TYPE_SPECIAL)
        setFilterData(DanmakuFilters.TAG_TYPE_DANMAKU_FILTER, mFilterTypes)
        mGlobalFlagValues.updateFilterFlag()
        if (SpecialDanmakuVisibility != visible) {
            SpecialDanmakuVisibility = visible
            notifyConfigureChanged(DanmakuConfigTag.SPECIAL_DANMAKU_VISIBILITY, visible)
        }
        return this
    }

    /**
     * 设置同屏弹幕密度 -1自动 0无限制
     *
     * @param maxSize
     * @return
     */
    public func setMaximumVisibleSizeInScreen(maxSize: Int64): DanmakuContext {
        maximumNumsInScreen = maxSize
        // 无限制
        if (maxSize == 0) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_QUANTITY_DANMAKU_FILTER)
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_ELAPSED_TIME_FILTER)
            notifyConfigureChanged(DanmakuConfigTag.MAXIMUM_NUMS_IN_SCREEN, maxSize)
            return this
        }
        // 自动调整
        if (maxSize == -1) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_QUANTITY_DANMAKU_FILTER)
            mDanmakuFilters.registerFilter(DanmakuFilters.TAG_ELAPSED_TIME_FILTER)
            notifyConfigureChanged(DanmakuConfigTag.MAXIMUM_NUMS_IN_SCREEN, maxSize)
            return this
        }
        setFilterData(DanmakuFilters.TAG_QUANTITY_DANMAKU_FILTER, maxSize)
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.MAXIMUM_NUMS_IN_SCREEN, maxSize)
        return this
    }

    /**
     * 设置描边样式
     *
     * @param style DANMAKU_STYLE_NONE DANMAKU_STYLE_SHADOW or
     *            DANMAKU_STYLE_STROKEN or DANMAKU_STYLE_PROJECTION
     * @param values
     *        DANMAKU_STYLE_SHADOW 阴影模式下，values传入阴影半径
     *        DANMAKU_STYLE_STROKEN 描边模式下，values传入描边宽度
     *        DANMAKU_STYLE_PROJECTION
     *            投影模式下，values传入offsetX, offsetY, alpha
     *                offsetX/offsetY: x/y 方向上的偏移量
     *                alpha: 投影透明度 [0...255]
     * @return
     */
    public func setDanmakuStyle(style: Int64, values: Array<Float64>): DanmakuContext {
        mDisplayer.setDanmakuStyle(style, values)
        notifyConfigureChanged(DanmakuConfigTag.DANMAKU_STYLE, style, values)
        return this
    }

    /**
     * 设置是否粗体显示,对某些字体无效
     *
     * @param bold
     * @return
     */
    public func setDanmakuBold(bold: Bool): DanmakuContext {
        mDisplayer.setFakeBoldText(bold)
        notifyConfigureChanged(DanmakuConfigTag.DANMAKU_BOLD, bold)
        return this
    }

    /**
     * 设置色彩过滤弹幕白名单
     * @param colors
     * @return
     */
    public func setColorValueWhiteList(colors: Array<Int64>): DanmakuContext {
        mColorValueWhiteList.clear()
        if (colors.size == 0) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_TEXT_COLOR_DANMAKU_FILTER)
        } else {
            mColorValueWhiteList.appendAll(colors)
            setFilterData(DanmakuFilters.TAG_TEXT_COLOR_DANMAKU_FILTER, mColorValueWhiteList)
        }
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.COLOR_VALUE_WHITE_LIST, mColorValueWhiteList)
        return this
    }

    public func getColorValueWhiteList(): ArrayList<Int64> {
        return mColorValueWhiteList
    }

    /**
     * 设置屏蔽弹幕用户hash
     * @param hashes
     * @return
     */
    public func setUserHashBlackList(hashes: Array<String>): DanmakuContext {
        mUserHashBlackList.clear()
        if (hashes.size == 0) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_USER_HASH_FILTER)
        } else {
            mUserHashBlackList.appendAll(hashes)
            setFilterData(DanmakuFilters.TAG_USER_HASH_FILTER, mUserHashBlackList)
        }
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.USER_HASH_BLACK_LIST, mUserHashBlackList)
        return this
    }

    public func removeUserHashBlackList(hashes: Array<String>): DanmakuContext {
        if (hashes.size == 0) {
            return this
        }
        for (i in 0..hashes.size) {
            mUserHashBlackList.remove(i)
        }
        setFilterData(DanmakuFilters.TAG_USER_HASH_FILTER, mUserHashBlackList)
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.USER_HASH_BLACK_LIST, mUserHashBlackList)
        return this
    }

    /**
     * 添加屏蔽用户
     * @param hashes
     * @return
     */
    public func addUserHashBlackList(hashes: Array<String>): DanmakuContext {
        if (hashes.size == 0) {
            return this
        }
        mUserHashBlackList.appendAll(hashes)
        setFilterData(DanmakuFilters.TAG_USER_HASH_FILTER, mUserHashBlackList)
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.USER_HASH_BLACK_LIST, mUserHashBlackList)
        return this
    }

    public func getUserHashBlackList(): ArrayList<String> {
        return mUserHashBlackList
    }

    /**
     * 设置屏蔽弹幕用户id , 0 表示游客弹幕
     * @param ids
     * @return
     */
    public func setUserIdBlackList(ids: Array<Int64>): DanmakuContext {
        mUserIdBlackList.clear()
        if (ids.size == 0) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_USER_ID_FILTER)
        } else {
            mUserIdBlackList.appendAll(ids)
            setFilterData(DanmakuFilters.TAG_USER_ID_FILTER, mUserIdBlackList)
        }
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.USER_ID_BLACK_LIST, mUserIdBlackList)
        return this
    }

    public func removeUserIdBlackList(ids: Array<Int64>): DanmakuContext {
        if (ids.size == 0) {
            return this
        }
        for (i in 0..ids.size) {
            mUserIdBlackList.remove(ids[i])
        }
        setFilterData(DanmakuFilters.TAG_USER_ID_FILTER, mUserIdBlackList)
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.USER_ID_BLACK_LIST, mUserIdBlackList)
        return this
    }

    /**
     * 添加屏蔽用户
     * @param ids
     * @return
     */
    public func addUserIdBlackList(ids: Array<Int64>): DanmakuContext {
        if (ids.size == 0) {
            return this
        }
        mUserIdBlackList.appendAll(ids)
        setFilterData(DanmakuFilters.TAG_USER_ID_FILTER, mUserIdBlackList)
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.USER_ID_BLACK_LIST, mUserIdBlackList)
        return this
    }

    public func getUserIdBlackList(): ArrayList<Int64> {
        return mUserIdBlackList
    }

    /**
     * 设置是否屏蔽游客弹幕
     * @param block true屏蔽，false不屏蔽
     * @return
     */
    public func blockGuestDanmaku(block: Bool): DanmakuContext {
        if (mBlockGuestDanmaku != block) {
            mBlockGuestDanmaku = block
            if (block) {
                setFilterData(DanmakuFilters.TAG_GUEST_FILTER, block)
            } else {
                mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_GUEST_FILTER)
            }
            mGlobalFlagValues.updateFilterFlag()
            notifyConfigureChanged(DanmakuConfigTag.BLOCK_GUEST_DANMAKU, block)
        }
        return this
    }

    /**
     * 设置弹幕滚动速度系数,只对滚动弹幕有效
     * @param p
     * @return
     */
    public func setScrollSpeedFactor(p: Float64): DanmakuContext {
        if (scrollSpeedFactor != p) {
            scrollSpeedFactor = p
            mDanmakuFactory.updateDurationFactor(p)
            mGlobalFlagValues.updateMeasureFlag()
            mGlobalFlagValues.updateVisibleFlag()
            notifyConfigureChanged(DanmakuConfigTag.SCROLL_SPEED_FACTOR, p)
        }
        return this
    }

    /**
     * 设置是否启用合并重复弹幕
     * @param enable
     * @return
     */
    public func setDuplicateMergingEnabled(enable: Bool): DanmakuContext {
        if (mDuplicateMergingEnable != enable) {
            mDuplicateMergingEnable = enable
            mGlobalFlagValues.updateFilterFlag()
            notifyConfigureChanged(DanmakuConfigTag.DUPLICATE_MERGING_ENABLED, enable)
        }
        return this
    }

    public func isDuplicateMergingEnabled(): Bool {
        return mDuplicateMergingEnable
    }

    public func alignBottom(enable: Bool): DanmakuContext {
        if (mIsAlignBottom != enable) {
            mIsAlignBottom = enable
            notifyConfigureChanged(DanmakuConfigTag.ALIGN_BOTTOM, enable)
            mGlobalFlagValues.updateVisibleFlag()
        }
        return this
    }

    public func isAlignBottom(): Bool {
        return mIsAlignBottom
    }

    /**
     * 设置最大显示行数
     * @param pairs map<K,V> 设置null取消行数限制
     * K = (BaseDanmaku.TYPE_SCROLL_RL|BaseDanmaku.TYPE_SCROLL_LR|BaseDanmaku.TYPE_FIX_TOP|BaseDanmaku.TYPE_FIX_BOTTOM)
     * V = 最大行数
     * @return
     */
    public func setMaximumLines(pairs: HashMap<Int64, Int64>): DanmakuContext {
        mIsMaxLinesLimited = pairs.isEmpty()
        if (pairs.isEmpty()) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_MAXIMUN_LINES_FILTER, false)
        } else {
            setFilterData(DanmakuFilters.TAG_MAXIMUN_LINES_FILTER, pairs, primary: false)
        }
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.MAXIMUN_LINES, pairs)
        return this
    }

    public func setOverlapping(pairs: HashMap<Int64, Bool>): DanmakuContext {
        return preventOverlapping(pairs)
    }

    /**
     * 设置防弹幕重叠
     * @param pairs map<K,V> 设置null恢复默认设置,默认为允许重叠
     * K = (BaseDanmaku.TYPE_SCROLL_RL|BaseDanmaku.TYPE_SCROLL_LR|BaseDanmaku.TYPE_FIX_TOP|BaseDanmaku.TYPE_FIX_BOTTOM)
     * V = true|false 是否重叠
     * @return
     */
    public func preventOverlapping(pairs: HashMap<Int64, Bool>): DanmakuContext {
        mIsPreventOverlappingEnabled = pairs.isEmpty()
        if (pairs.isEmpty()) {
            mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_OVERLAPPING_FILTER, false)
        } else {
            setFilterData(DanmakuFilters.TAG_OVERLAPPING_FILTER, pairs, primary: false)
        }
        mGlobalFlagValues.updateFilterFlag()
        notifyConfigureChanged(DanmakuConfigTag.OVERLAPPING_ENABLE, pairs)
        return this
    }

    public func isMaxLinesLimited(): Bool {
        return mIsMaxLinesLimited
    }

    public func isPreventOverlappingEnabled(): Bool {
        return mIsPreventOverlappingEnabled
    }

    /**
     * 设置缓存绘制填充器，默认使用{@link SimpleTextCacheStuffer}只支持纯文字显示, 如果需要图文混排请设置{@link SpannedCacheStuffer}
     * 如果需要定制其他样式请扩展{@link SimpleTextCacheStuffer}|{@link SpannedCacheStuffer}
     * @param cacheStuffer
     * @param cacheStufferAdapter
     */
    public func setCacheStuffer(cacheStuffer: BaseCacheStuffer, cacheStufferAdapter: Proxy): DanmakuContext {
        mCacheStuffer = cacheStuffer
        if (let Some(v) <- mCacheStuffer) {
            v.setProxy(cacheStufferAdapter)
            mDisplayer.setCacheStuffer(v)
        }
        return this
    }

    public func setDanmakuSync(danmakuSync: AbsDanmakuSync): DanmakuContext {
        this.danmakuSync = danmakuSync
        return this
    }

    // TODO..
    //    public func setCachingPolicy(cachingPolicy: CachingPolicy): DanmakuContext {
    //        this.cachingPolicy = cachingPolicy
    //        return this
    //    }

    public func registerConfigChangedCallback(listener: ConfigChangedCallback): Unit {
        var arr: ArrayList<ConfigChangedCallback>
        if (mCallbackList.isNone()) {
            arr = ArrayList<ConfigChangedCallback>()
            mCallbackList = arr
        } else {
            arr = mCallbackList.getOrThrow()
        }
        for (i in 0..arr.size where listener == arr[i]) {
            return
        }
        arr.append(listener)
    }

    public func unregisterConfigChangedCallback(listener: ?ConfigChangedCallback): Unit {
        if (listener.isNone() || mCallbackList.isNone()) {
            return
        }
        let realListener = listener()
        let realMCallbackList = mCallbackList()
        for (i in 0..realMCallbackList.size where realListener == realMCallbackList[i]) {
            mCallbackList().remove(i)
            return
        }
    }

    public func unregisterAllConfigChangedCallbacks(): Unit {
        if (let Some(v) <- mCallbackList) {
            v.clear()
            mCallbackList = None
        }
    }

    private func notifyConfigureChanged(tag: DanmakuConfigTag, values: Array<Any>): Unit {
        if (let Some(v) <- mCallbackList) {
            for (i in 0..v.size) {
                v[i].onDanmakuConfigChanged(this, tag, values)
            }
        }
    }

    public func registerFilter(filter: BaseDanmakuFilter<Any>): DanmakuContext {
        mDanmakuFilters.registerFilter(filter)
        mGlobalFlagValues.updateFilterFlag()
        return this
    }

    public func unregisterFilter(filter: BaseDanmakuFilter<Any>): DanmakuContext {
        mDanmakuFilters.unregisterFilter(filter)
        mGlobalFlagValues.updateFilterFlag()
        return this
    }

    public func resetContext(): DanmakuContext {
        mDisplayer = OhcjDisplayer()
        mGlobalFlagValues = GlobalFlagValues()
        mDanmakuFilters.clear()
        mDanmakuFactory = DanmakuFactory.create()
        return this
    }
}
