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
import MediaLib from '@ohos.multimedia.mediaLibrary';
import mediaModel from '@ohos/base/src/main/ets/model/MediaModel'
import { logInfo, logWarn, logError } from '@ohos/base/src/main/ets/utils/LoggerUtils';
import { ItemDataSource } from '@ohos/base/src/main/ets/vm/ItemDataSource';
import { AlbumDataItem } from '@ohos/base/src/main/ets/data/AlbumDataItem';
import { BroadcastConstants } from '@ohos/base/src/main/ets/constants/BroadcastConstants';
import { MenuOperationCallback } from '@ohos/base/src/main/ets/operation/MenuOperationCallback'
import { MenuOperation } from '@ohos/base/src/main/ets/operation/MenuOperation'
import { MenuContext } from '@ohos/base/src/main/ets/operation/MenuContext'
import { getResourceString } from '@ohos/base/src/main/ets/utils/ResourceUtils';
import { showToast } from '@ohos/base/src/main/ets/utils/UiUtil';
import { getFetchOptions } from '@ohos/base/src/main/ets/helper/MediaDataHelper';

const TAG = "AlbumSetRenameMenuOperation"

export class AlbumSetRenameMenuOperation implements MenuOperation, MenuOperationCallback {
    private menuContext: MenuContext;
    private onOperationEnd: Function;
    private item: AlbumDataItem;

    constructor(menuContext: MenuContext) {
        this.menuContext = menuContext;
    }

    doAction(): void {
        if (this.menuContext == null) {
            logWarn(TAG, 'menuContext is null, return');
            return;
        }
        let dataSource: ItemDataSource = this.menuContext.dataSource;
        let count: number
        let items: any[]
        if (dataSource == null) {
            count = this.menuContext.items.length
            items = this.menuContext.items
        } else {
            count = dataSource.getSelectedCount();
            items = dataSource.getSelectedItems();
        }
        if (count != 1) {
            logWarn(TAG, 'count is invalid');
            return;
        }

        this.item = items[0] as AlbumDataItem

        this.confirmCallback = this.confirmCallback.bind(this);
        this.cancelCallback = this.cancelCallback.bind(this);

        logInfo(TAG, `The name of clicked album is ${this.item.displayName}`);

        this.menuContext.broadCast.emit(BroadcastConstants.SHOW_RENAME_PHOTO_DIALOG,
            [this.item.displayName, this.confirmCallback, this.cancelCallback]);
    }

    private async confirmCallback(newName: string) {
        logInfo(TAG, `AlbumSet rename confirm and the new name is: ${newName}`);

        this.onOperationEnd = this.menuContext.onOperationEnd;
        let onOperationStart: Function = this.menuContext.onOperationStart;
        onOperationStart && onOperationStart();

        this.rename(newName);
    }

    private async rename(name) {
        try {
            let fetchOption: MediaLib.MediaFetchOptions = await  getFetchOptions(this.item.selectType, this.item.id, "")
            let albums: MediaLib.Album[] = await mediaModel.getAlbums(fetchOption)
            if (albums.length == 0) {
                getResourceString($r('app.string.name_already_use')).then((message: string) => {
                    showToast(message)
                })
                logWarn(TAG, `album is miss`)
                this.onError();
                return
            }
            albums[0].albumName = name
            await albums[0].commitModify()
            this.onCompleted();
        } catch (error) {
            logError(TAG, `AlbumSet rename failed: ${error}`);
            this.onError();
        }
    }

    private cancelCallback(): void {
        logInfo(TAG, 'AlbumSet rename cancel');
    }

    onCompleted(): void{
        logInfo(TAG, 'Rename data succeed!');
        this.onOperationEnd && this.onOperationEnd();
    }

    onError(): void{
        logError(TAG, 'Rename data failed!');
        this.onOperationEnd && this.onOperationEnd();
    }
}