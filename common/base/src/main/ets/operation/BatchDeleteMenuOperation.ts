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

import { logInfo, logWarn } from '../utils/LoggerUtils'
import { ItemDataSource } from '../vm/ItemDataSource';
import { MenuContext } from './MenuContext'
import { BroadcastConstants } from '../constants/BroadcastConstants';
import { ProcessMenuOperation } from './ProcessMenuOperation';
import { MediaDataItem } from '../data/MediaDataItem';

const TAG = "BatchDeleteMenuOperation"

export class BatchDeleteMenuOperation extends ProcessMenuOperation {
    constructor(menuContext: MenuContext) {
        super(menuContext);
    }

    doAction(): void{
        logInfo(TAG, 'delete doAction');
        if (this.menuContext == null) {
            logWarn(TAG, 'menuContext is null, return');
            return;
        }

        let dataSource: ItemDataSource = this.menuContext.dataSource;
        if (dataSource == null) {
            this.count = this.menuContext.items.length
        } else {
            this.count = dataSource.getSelectedCount();
        }
        if (this.count <= 0) {
            logWarn(TAG, 'count <= 0, return');
            return;
        }

        this.confirmCallback = this.confirmCallback.bind(this);
        this.cancelCallback = this.cancelCallback.bind(this);

        let resource: Resource = this.getDeleteMessageResource(dataSource)
        this.menuContext.broadCast.emit(BroadcastConstants.SHOW_DELETE_DIALOG, [resource, this.confirmCallback, this.cancelCallback]);
    }

    getDeleteMessageResource(dataSource: ItemDataSource): Resource{
        let resource: Resource
        if (dataSource && dataSource.isSelect()) {
            resource = $r('app.string.recycle_all_files_tips')
        } else if (this.count == 1) {
            resource = $r('app.string.recycle_single_file_tips')
        } else {
            resource = $r('app.string.recycle_files_tips', this.count)
        }
        return resource
    }

    confirmCallback(): void {
        logInfo(TAG, 'Batch delete confirm');
        // 1. Variable initialization
        this.onOperationEnd = this.menuContext.onOperationEnd;

        // 2. onDeleteStart exit selection mode
        let onOperationStart: Function = this.menuContext.onOperationStart;
        onOperationStart && onOperationStart();

        this.menuContext.broadCast.emit(BroadcastConstants.DELETE_PROGRESS_DIALOG,
            [$r('app.string.action_delete'), this.count]);

        // 3. selectManager gets the URI of the data and starts processing deletion in the callback
        let dataSource: ItemDataSource = this.menuContext.dataSource;
        if (dataSource == null) {
            this.items = this.menuContext.items
        } else {
            this.items = dataSource.getSelectedItems()
        }
        this.processOperation()
    }

    requestOneBatchOperation() {
        let item = this.items[this.currentBatch] as MediaDataItem
        item.onDelete().then(() => {
            this.currentBatch++
            this.menuContext.broadCast.emit(BroadcastConstants.UPDATE_PROGRESS, [this.getExpectProgress(), this.currentBatch]);
            this.cyclicOperation()
        })
    }

    cancelCallback(): void {
        logInfo(TAG, 'Batch delete cancel');
    }
}