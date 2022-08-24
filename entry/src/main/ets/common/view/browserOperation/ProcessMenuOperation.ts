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

import { AsyncCallback } from '../../model/common/AsyncCallback'
import { Logger } from '../../utils/Logger'
import { MenuOperationCallback } from './MenuOperationCallback'
import { MenuOperation } from './MenuOperation'
import { MenuContext } from './MenuContext'
import { BroadCastConstants } from '../../model/common/BroadCastConstants';
import { BrowserDataFactory } from '../../interface/BrowserDataFactory'
import { StringUtil } from '../../utils/StringUtil'
import { TraceControllerUtils } from '../../utils/TraceControllerUtils';

export enum FindSameOperation {
    NONE,
    REPLACE,
    SKIP
}

export class ProcessMenuOperation implements MenuOperation, AsyncCallback<String[]>, MenuOperationCallback {
    // Number of data operated in a batch
    readonly BATCH_SIZE: number = 1;

    // Maximum progress
    readonly MAX_PROGRESS: number = 100;
    menuContext: MenuContext;
    uris: string[];
    count: number;
    onOperationEnd: Function;

    // Total batches operated
    totalBatches: number;

    // Currently operated batch
    currentBatch: number = 0;
    successBatch: number = 0;
    isCancelled: boolean = false;
    startTime: number;
    isPause: boolean = false;
    isError: boolean = false;
    findSameOperation: number = FindSameOperation.NONE;
    logger: Logger = new Logger('ProcessMenuOperation');
    requestTime: number;

    constructor(menuContext: MenuContext) {
        this.menuContext = menuContext;
        this.requestTime = Date.now();
    }

    doAction(): void {

    }

    // Asynchronous callback for getSelection
    callback(uris: string[]): void {

    }

    onCompleted(): void {
        this.logger.info(`onCompleted ${this.isPause}`);
        this.successBatch++;
        if (!this.isPause) {
            this.cyclicOperation();
        }
    }

    onError(): void {
        this.logger.error(`Operate the ${this.currentBatch} batch data error, total ${this.totalBatches} batches`);
        this.isError = true;
        this.cyclicOperation();
    }

    // Operate a batch of data
    requestOneBatchOperation(): void {

    }

    // Start processing operation
    processOperation(): void {
        this.logger.info('processOperation start');
        TraceControllerUtils.startTraceWithTaskId('ProgressOperation', this.requestTime);
        if (this.uris == null) {
            this.logger.error('Invalid callback data, uris is null!');
            return;
        }
        let length = this.uris.length;
        this.logger.info(`selected count: ${this.count}, uris's length: ${length}`);
        // Batch deletion
        this.totalBatches = Math.floor(length / this.BATCH_SIZE) + ((length % this.BATCH_SIZE) ? 1 : 0);
        this.logger.info(`The count to be operate is ${length}, operate in ${this.totalBatches} batches`);
        if (this.isCancelled) {
            this.isCancelled = false;
        }
        this.startTime = Date.now();
        this.requestOneBatchOperation();
    }

    // Batch circular deletion
    cyclicOperation() {
        this.logger.info('cyclicOperation');
        this.menuContext.broadCast.emit(BroadCastConstants.UPDATE_PROGRESS,
            [this.getExpectProgress(), this.currentBatch]);

        if (this.isCancelled) {
            this.onProcessDone();
        }

        if (this.currentBatch >= this.totalBatches || this.isError) {
            this.onProcessDone();
        } else {
            this.requestOneBatchOperation();
        }
    }

    onProcessDone(): void {
        this.menuContext.broadCast.emit(BroadCastConstants.UPDATE_PROGRESS, [100]);
        this.findSameOperation = FindSameOperation.NONE
        if (this.startTime != null) {
            let operateCount = this.currentBatch >= this.totalBatches ? this.count : this.currentBatch * this.BATCH_SIZE;
            let costTime = Date.now() - this.startTime;
            this.logger.debug(`process data operate done, operate ${operateCount} items, cost time ${costTime} ms,\
            average ${(costTime / operateCount)} ms/item.`);
        }
        this.isCancelled = false;
        TraceControllerUtils.finishTraceWithTaskId('ProgressOperation', this.requestTime);
        this.onOperationEnd && this.onOperationEnd(this.isError, this.successBatch, this.count);
    }

    // Operate cancel callback
    onOperateCancelled(): void {
        this.logger.info('Operate Cancel');
        this.isCancelled = true;
        this.onProcessDone();
    }

    // Operate cancel callback
    onOperatePause(): void {
        this.logger.info('Operate Pause');
        this.isPause = true;
    }

    // Calculate the operation progress according to the batch
    getExpectProgress(): number {
        this.logger.info('getExpectProgress');
        let progress = Math.min(
        Math.floor(this.MAX_PROGRESS * this.currentBatch * this.BATCH_SIZE / this.count), this.MAX_PROGRESS);
        return progress;
    }

    setFindSameOperation(newOperation: number): void {
        this.logger.info(`setFindSameOperation ${newOperation}`);
        this.findSameOperation = newOperation
    }

    async getFileCopyOrMoveInfo(uri: string, albumInfo: any, deviceId?) {
        this.logger.debug('getFileCopyOrMoveInfo start');
        let dataImpl = BrowserDataFactory.getFeature(BrowserDataFactory.TYPE_PHOTO);

        let fileAsset = await dataImpl.getDataById(StringUtil.getIdFromUri(uri), deviceId);
        let targetAsset = await dataImpl.getDataByName(fileAsset.displayName, albumInfo);
        if (targetAsset == null || targetAsset == undefined) {
            this.logger.debug('targetAsset not found');
        }

        return { sourceAsset: fileAsset, targetAsset: targetAsset };
    }
}