/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {MediaItem} from './MediaItem'
import {AbsDataSource} from '../AbsDataSource'
import {GetItemsCallback} from './GetItemsCallback'
import {GetMediaCountCallback} from './GetMediaCountCallback'
import {Logger} from '../../../utils/Logger.ets'
import { BroadCastConstants } from '../../common/BroadCastConstants.ets';
import { BroadCast } from '../../../utils/BroadCast.ets';
import {BroadCastManager} from '../../common/BroadCastManager.ets'
import {Constants} from '../../common/Constants.ets'
import {PendingTask} from './PendingTask'
import {PendingCondition} from './PendingCondition'
import {TraceControllerUtils} from '../../../utils/TraceControllerUtils.ets'
import {AlbumDefine} from '../AlbumDefine.ets'
import {BrowserDataFactory} from '../interface/BrowserDataFactory.ets'
import {BrowserDataInterface} from '../interface/BrowserDataInterface'

export class MediaDataSource extends AbsDataSource {
    // Number of first pictures loaded during initialization
    private static INIT_FIRST_PATCH_LOAD_COUNT = 50;

    // logger
    logger: Logger = new Logger('MediaDataSource');
    initDataTraceName = 'PhotoGridPageInitData';

    // Album list, all photos, etc. may involve album aggregation display, so multiple albums are required
    photoDataImpl: BrowserDataInterface;

    // Number of elements in layout
    size = 0;

    // Number of media in the dataset
    mediaCount = 0;

    // Is the quantity changed
    isCountChanged = false

    // Is the quantity changed
    isCountReduced = false

    // Save the amount of data of a window size
    items: MediaItem[] = [];

    // window Size
    windowSize = 0;

    // start point
    activeStart = 0;

    // end point
    activeEnd = 0;

    // layoutIndex to dataIndex
    dataIndexes: number[] = [];

    // dataIndex to layoutIndex
    layoutIndexes: number[] = [];
    broadCast: BroadCast;
    photosBroadCast: BroadCast;

    // The BroadCast of the application process. Event registration and destruction should be paired
    appBroadCast: BroadCast = BroadCastManager.getInstance().getBroadCast();

    // Whether to delay updating data
    isPendingUpdateData = true;

    // During initialization, the task to data updates before the delay when count returns
    pendingUpdateData: PendingTask;

    // Request time of the first batch of data
    firstPatchDataRequestTime: number;
    albumName: string = AlbumDefine.ALBUM_NAME_ALL;

    deviceId: string = undefined;

    constructor(windowSize: number) {
        super();
        this.photoDataImpl = BrowserDataFactory.getFeature(BrowserDataFactory.TYPE_ALBUM);
        this.windowSize = windowSize;
        this.activeEnd = windowSize;
        this.items = new Array(windowSize);
        this.appBroadCast.on(BroadCastConstants.PHOTO_BROWSER_ACTIVE, this.onPhotoBrowserActive.bind(this));
    }

    totalCount(): number {
        this.logger.info(`totalCount: ${this.size}`);
        return this.size;
    }

    getData(index: number): any {
        this.updateSlidingWindow(this.dataIndexes[index]);
        let result: any = this.getWrappedData(index);
        this.logger.debug(`getData, index: ${index}`);
        this.logger.debug(`getData item: ${JSON.stringify(result.mediaItem)}`);
        return result;
    }

    // get raw MediaItem data
    getRawData(dataIndex: number): MediaItem {
        if (dataIndex < this.activeStart || dataIndex >= this.activeEnd) {
            return undefined;
        }
        return this.items[dataIndex - this.activeStart];
    }

    // get DataIndex with item
    getDataIndex(item: MediaItem): number {
        for (let i = 0; i < this.items.length; i++) {
            if (this.items[i] != undefined && this.items[i].uri == item.uri) {
                return i + this.activeStart;
            }
        }
        return Constants.NOT_FOUND;
    }

    getMediaCount(): number {
        return this.mediaCount;
    }

    setDeviceId(deviceId: string): void {
        this.deviceId = deviceId;
        this.logger.debug(`setDeviceId ${this.deviceId}`);
    }

    // Initialize the first batch of data
    initData() {
        TraceControllerUtils.startTrace(this.initDataTraceName);
        this.logger.info('initData');
        this.pendingUpdateData = new PendingTask(<PendingCondition> {
            shouldPending: () => {
                return this.isPendingUpdateData;
            }
        });
        let start = 0;
        let limit = MediaDataSource.INIT_FIRST_PATCH_LOAD_COUNT;
        this.firstPatchDataRequestTime = Date.now();
        this.lastUpdateTime = this.firstPatchDataRequestTime;
        let firstPatchDataCallback: any = {
            callback: (assets: MediaItem[]) => {
                TraceControllerUtils.finishTraceWithTaskId('getMediaItems', this.firstPatchDataRequestTime);
                this.logger.info(`took  ${(Date.now() - this.firstPatchDataRequestTime)}\
                 milliseconds to load first batch: ${(assets == null ? 0 : assets.length)}`);
                this.updateMediaData(this.firstPatchDataRequestTime, start, assets);
                let secondPatchDataCallback: GetItemsCallback = new GetItemsCallback(this, limit);
                this.photoDataImpl.getData(secondPatchDataCallback, {
                    name: this.albumName,
                    start: limit,
                    count: this.windowSize - limit,
                    deviceId: this.deviceId
                });
            }
        };
        TraceControllerUtils.startTraceWithTaskId('getMediaItems', this.firstPatchDataRequestTime);
        this.photoDataImpl.getData(firstPatchDataCallback,
            {name: this.albumName, start: start, count: limit, deviceId: this.deviceId});
        this.loadData();
    }

    // Query quantity
    loadData() {
        this.logger.info(`loadData`);

        let initCountCallback: GetMediaCountCallback = new GetMediaCountCallback(this);
        this.photoDataImpl.getMediaItemCount(initCountCallback, { name: this.albumName, deviceId: this.deviceId });
    }

    // update media count
    updateMediaCount(requestTime: number, count: number): void {
        TraceControllerUtils.startTraceWithTaskId('updateMediaCount', requestTime);
        this.logger.info(`updateMediaCount requestTime: ${requestTime}, count: ${count}`);
        this.lastUpdateTime = requestTime;

        this.updateSize(requestTime, count);

        TraceControllerUtils.finishTraceWithTaskId('updateMediaCount', requestTime);
        if (this.isPendingUpdateData) {
            this.isPendingUpdateData = false;
            this.pendingUpdateData.flush();
        }
    }

    /**
     * Update related variables of count
     *
     * @param requestTime
     * @param count
     */
    updateSize(requestTime: number, count: number): void {
        this.logger.info(`updateSize, old size: ${this.size}, new size: ${count}`)
        this.isCountChanged = count != this.size;
        this.isCountReduced = count < this.size;
        this.mediaCount = count;
        this.size = this.mediaCount;
        this.dataIndexes = [];
        this.layoutIndexes = [];
        for (let i = 0; i < this.size; i++) {
            this.dataIndexes.push(i);
            this.layoutIndexes.push(i);
        }

        this.updateCountPostProcess();
    }

    /**
     * run after update count，Adjust sliding windows and query items as needed
     */
    updateCountPostProcess(): void {
        this.logger.info('updateCountPostProcess');
        // Exclude initData
        if (this.hasNewChange) {
            // when the total count less to activeEnd, the window need to change
            if (this.activeEnd > this.mediaCount) {
                let newActiveStart = Math.max(0, this.activeStart - (this.activeEnd - this.mediaCount));
                let newActiveEnd = newActiveStart + this.windowSize;
                // data reuse
                if (newActiveEnd > this.activeStart) {
                    this.dataReuse(newActiveStart, this.activeStart, newActiveEnd);
                }
                this.activeStart = newActiveStart;
                this.activeEnd = newActiveEnd;
                this.logger.info(`updateSlidingWindow, newActiveStart:
                ${this.activeStart} , newActiveEnd:${this.activeEnd}`);
            }

            if (this.mediaCount == 0) {
                this.hasNewChange = false;
                this.onDataReloaded();
            } else {
                // dirty data, need to get data again
                this.logger.info('dirty data, need to get data again');
                let callback: GetItemsCallback = new GetItemsCallback(this, this.activeStart);
                this.photoDataImpl.getData(callback, {
                    name: this.albumName,
                    start: this.activeStart,
                    count: this.windowSize,
                    deviceId: this.deviceId
                });
            }
        }
        this.emitCountUpdateCallbacks();
    }

    emitCountUpdateCallbacks(): void {
        this.mCallbacks['updateCount'] && this.mCallbacks['updateCount'](this.mediaCount);
        this.broadCast && this.broadCast.emit(Constants.ON_LOADING_FINISHED, [this.mediaCount]);
        this.notifySizeLoadingFinished(this.mediaCount);
    }

    // Update data in data callback
    updateMediaData(requestTime: number, start: number, mediaItems: MediaItem[]): void {
        if (requestTime == this.firstPatchDataRequestTime && this.isPendingUpdateData && this.size == 0) {
            this.logger.info('the callback of mediaItems is earlier than that of count.');
            this.updateCountThroughMediaItems(requestTime, mediaItems);
            this.mediaDataUpdateExecutor(requestTime, start, mediaItems);
            TraceControllerUtils.finishTrace(this.initDataTraceName);
        } else if (this.isPendingUpdateData) {
            this.logger.info('isPendingUpdateData execute start');
            this.pendingUpdateData.execute(() => {
                this.mediaDataUpdateExecutor(requestTime, start, mediaItems);
                TraceControllerUtils.finishTrace(this.initDataTraceName);
            });
        } else {
            this.mediaDataUpdateExecutor(requestTime, start, mediaItems);
            TraceControllerUtils.finishTrace(this.initDataTraceName);
        }
    }

    /**
     * Update count through items
     *
     * @param requestTime
     * @param mediaItems mediaItems
     */
    updateCountThroughMediaItems(requestTime: number, mediaItems: MediaItem[]): void {
        this.logger.info('updateCountThroughMediaItems');
        this.updateSize(0, mediaItems == null ? 0 : mediaItems.length);
    }

    /**
     * Actual execution function of items update
     *
     * @param requestTime
     * @param start items
     * @param mediaItems mediaItems
     */
    mediaDataUpdateExecutor(requestTime: number, start: number, mediaItems: MediaItem[]): void {
        TraceControllerUtils.startTraceWithTaskId('updateMediaData', requestTime);
        this.logger.info(`updateMediaData requestTime: ${requestTime}, start: ${start}`);
        if (this.lastUpdateTime < this.lastChangeTime && this.isActive) {
            this.logger.info('request data expired, request again!');
            this.loadData();
        } else {
            this.hasNewChange = false;
        }

        if (mediaItems == undefined || mediaItems.length == 0) {
            this.logger.error('results are empty!');
            return;
        }

        if (start >= this.activeEnd || start + mediaItems.length <= this.activeStart) {
            this.logger.info('results are not in active window');
            return;
        }

        this.logger.info(`updateMediaData mediaItems.length: ${mediaItems.length}`);
        let fromIndex = Math.max(start, this.activeStart);
        let endIndex = Math.min(this.activeEnd, start + mediaItems.length);
        this.logger.info(`updateMediaData listeners size ${this.listeners.length}`)

        for (let i = fromIndex; i < endIndex; i++) {
            this.items[i - this.activeStart] = mediaItems[i - start];
            this.logger.debug(`updateMediaData ${this.layoutIndexes[i]}`);
//            !this.isCountChanged && this.onDataChanged(this.layoutIndexes[i]);
        }
        if (this.isCountChanged) {
            if (this.photosBroadCast && this.isCountReduced) {
                this.photosBroadCast.emit(BroadCastConstants.ON_DATA_RELOADED, [])
            } else if (this.broadCast) {
                this.broadCast.emit(BroadCastConstants.ON_DATA_RELOADED, [])
            } else {
                this.onDataReloaded();
            }

            this.isCountChanged = false;
            this.isCountReduced = false;
        } else {
            for (let i = fromIndex; i < endIndex; i++) {
                this.onDataChanged(this.layoutIndexes[i]);
            }
        }
        TraceControllerUtils.finishTraceWithTaskId('updateMediaData', requestTime);
        this.notifyDataLoadingFinished();
    }

    // Update sliding window
    public updateSlidingWindow(dataIndex: number): void {
        if (dataIndex == Constants.INVALID || dataIndex == undefined) {
            return;
        }
        let windowCenter = Math.round((this.activeStart + this.activeEnd) / 2);
        if (Math.abs(dataIndex - windowCenter) < Constants.STEP) {
            return;
        }
        if (dataIndex < windowCenter && this.activeStart == 0) {
            return;
        }
        if (dataIndex > windowCenter && this.activeEnd >= this.mediaCount) {
            return;
        }
        let newActiveStart = this.getWindowActiveStart(dataIndex, windowCenter);
        let newActiveEnd = newActiveStart + this.windowSize;
        let requestStart = newActiveStart;
        let requestCount = this.windowSize;

        if (newActiveEnd < this.activeStart || newActiveStart > this.activeEnd) {
            let limit = MediaDataSource.INIT_FIRST_PATCH_LOAD_COUNT;
            let start = Math.max(0, (newActiveStart + newActiveEnd) / 2 - limit / 2);
            this.firstPatchDataRequestTime = Date.now();
            this.lastUpdateTime = this.firstPatchDataRequestTime;
            let firstPatchDataCallback: any = {
                callback: (assets: MediaItem[]) => {
                    TraceControllerUtils.finishTraceWithTaskId('getMediaItems', this.firstPatchDataRequestTime);
                    this.logger.info(`took  ${(Date.now() - this.firstPatchDataRequestTime)}\
                     milliseconds to load first batch: ${(assets == null ? 0 : assets.length)}`);
                    this.updateMediaData(this.firstPatchDataRequestTime, start, assets);
                    let secondPatchDataCallback: GetItemsCallback = new GetItemsCallback(this, newActiveStart);
                    this.photoDataImpl.getData(secondPatchDataCallback, {
                        name: this.albumName,
                        start: newActiveStart,
                        count: this.windowSize,
                        deviceId: this.deviceId
                    });
                }
            };
            TraceControllerUtils.startTraceWithTaskId('getMediaItems', this.firstPatchDataRequestTime);
            this.photoDataImpl.getData(firstPatchDataCallback,
                {name: this.albumName, start: start, count: limit, deviceId: this.deviceId });
        }

        if (newActiveEnd < this.activeEnd && newActiveEnd > this.activeStart) {
            requestCount = this.activeStart - newActiveStart;
            this.dataReuse(newActiveStart, this.activeStart, newActiveEnd);
        }
        if (newActiveStart > this.activeStart && newActiveStart < this.activeEnd) {
            requestStart = this.activeEnd;
            requestCount = newActiveEnd - this.activeEnd;
            this.dataReuse(newActiveStart, newActiveStart, this.activeEnd);
        }
        this.activeStart = newActiveStart;
        this.activeEnd = newActiveEnd;
        this.logger.info(`updateSlidingWindow, trigger data fetch dataIndex: ${dataIndex}`);
        this.logger.info(`trigger data fetch newActiveStart: ${this.activeStart}, newActiveEnd: ${this.activeEnd}`);
        this.logger.info(`trigger data fetch start: ${requestStart}, count: ${requestCount}`);
        let callback: GetItemsCallback = new GetItemsCallback(this, requestStart);
        this.photoDataImpl.getData(callback,
            {name: this.albumName, start: requestStart, count: requestCount, deviceId: this.deviceId });
    }

    private getWindowActiveStart(dataIndex: number, windowCenter: number): number{
        let isForward = (dataIndex > windowCenter);
        let halfWinSize = Math.round(this.windowSize / 2);
        // The end of the window does not exceed the total amount of data when the window moves forward.
        if (isForward) {
            let stepSize = Math.min(Constants.STEP, Math.abs(this.mediaCount - this.activeEnd));
            return (this.activeStart + stepSize);
        } else {
            return Math.max(0, dataIndex - halfWinSize);
        }
    }

    /**
     * data Reuse
     *
     * @param newActiveStart
     * @param startIndex
     * @param endIndex
     */
    private dataReuse(newActiveStart: number, startIndex: number, endIndex: number): void {
        let newData: MediaItem[] = new Array(this.windowSize);
        for (let i = startIndex; i < endIndex; i++) {
            newData[i - newActiveStart] = this.items[i - this.activeStart];
        }
        this.items = newData;
    }

    getMediaItemSafely(index: number): MediaItem{
        let mediaItem: MediaItem = this.items[index];
        if (mediaItem == null) {
            this.logger.error(`invalid data, index:${index}, active Start:${this.activeStart}, End:${this.activeEnd}`);
            mediaItem = new MediaItem(null);
        }
        return mediaItem;
    }

    // Forced refresh interface
    forceUpdate() {
        this.onDataReloaded();
    }

    // Packaging data for the view layer
    getWrappedData(index: number): any {
        let mediaItemIndex: number = this.dataIndexes[index] - this.activeStart;
        if (mediaItemIndex < 0 || mediaItemIndex >= this.items.length) {
            return undefined;
        }
        let result = {
            mediaItem: this.getMediaItemSafely(mediaItemIndex),
            viewIndex: index
        };
        return result;
    }

    setAlbumName(name: string) {
        this.logger.info(`setAlbumName: ${name}`)
        this.albumName = name;
    }

    setBroadCast(broadCastParam: BroadCast) {
        this.broadCast = broadCastParam;
    }

    setPhotoBroadCast(broadCastParam: BroadCast) {
        this.photosBroadCast = broadCastParam;
    }

    releasePhotoBroadCast() {
        this.photosBroadCast = null;
    }

    onPhotoBrowserActive(isActive: boolean, transition: string): void {
        if (transition == Constants.PHOTO_TRANSITION_ALBUM || transition == Constants.PHOTO_TRANSITION_CAMERA) {
            if (isActive) {
                this.logger.info('onPhotoBrowserActive')
                this.onActive();
            } else {
                this.onInActive();
            }
        }
    }

    getIndexByMediaItem(item: MediaItem): number {
        for(let index = 0; index < this.items.length; index++) {
            if (item.uri == this.items[index].uri) {
                this.items[index] = item
                return index;
            }
        }
        return -1;
    }

    deleteData(uris: string[]): void {
      try {
          this.loadData();
      } catch(err) {
          this.logger.info(`deleteData items err: ${err} `);
      }
      this.logger.info(`deleteData items ${this.items.length} `);
    }

    getIndexByUri(uri: string): number {
        for (let index = 0; index < this.items.length; index++) {
            if (uri == this.items[index].uri) {
                return index;
            }
        }
        return -1;
    }

    getPositionByIndex(index: number): number {
        return index;
    }

    onChange(mediaType: string) {
        if(this.deviceId == '' || this.deviceId == undefined) {
            if (mediaType == 'image' || mediaType == 'video' || mediaType == 'album') {
                this.logger.debug(`local onChange ${mediaType}`);
                super.onChange(mediaType);
            }
        } else {
            if (mediaType == 'remote') {
                this.logger.debug(`remote onChange`);
                super.onChange(mediaType);
            }
        }
    }
}