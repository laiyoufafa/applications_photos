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
import { logDebug, logWarn, logError } from '../utils/LoggerUtils';
import { AlbumDataItem } from '../data/AlbumDataItem'
import { MediaConstants } from '../constants/MediaConstants'
import mediaModel from '../model/MediaModel'
import { getAlbumDisplayName, getFetchOptions } from '../helper/MediaDataHelper'

const TAG = "AlbumDataImpl"

export class AlbumDataImpl {
    private blackList: string[] = []
    private selectType: number = MediaConstants.SELECT_TYPE_ALL
    private deviceId: string = ''

    setBlackList(blackList: string[]) {
        this.blackList = blackList
    }

    setSelectType(selectType: number) {
        this.selectType = selectType
    }

    setDeviceId(deviceId: string) {
        this.deviceId = deviceId
    }

    async reloadAlbumItemData(): Promise<AlbumDataItem[]> {
        let albumDataItems = []
        for (let i = 0;i < MediaConstants.ALBUM_DEFAULT_SORT_LIST.length; i++) {
            await this.getAlbumItem(MediaConstants.ALBUM_DEFAULT_SORT_LIST[i], albumDataItems)
        }
        await this.getCommonAlbumItem(albumDataItems)
        await this.getAlbumItem(MediaConstants.ALBUM_ID_RECYCLE, albumDataItems)
        return albumDataItems
    }

    private async getCommonAlbumItem(albumDataItems: AlbumDataItem[]): Promise<void> {
        let fetchOption: MediaLib.MediaFetchOptions = await getFetchOptions(this.selectType, "", this.deviceId)
        if (fetchOption == undefined) {
            return
        }
        fetchOption.selections = `(${fetchOption.selections}) and (${MediaLib.FileKey.ALBUM_NAME} <> ? and ${MediaLib.FileKey.ALBUM_NAME} <> ?)`
        fetchOption.selectionArgs.push('Camera', 'Screenshots')
        let albums: MediaLib.Album[] = await mediaModel.getAlbums(fetchOption)
        for (let i = 0;i < albums.length; i++) {
            let album: MediaLib.Album = albums[i]
            if (this.blackList.indexOf(album.albumId.toString()) >= 0) {
                continue
            }
            let fetchFileResult: MediaLib.FetchFileResult = await album.getFileAssets()
            try {
                let count = fetchFileResult.getCount()
                if (count == 0) {
                    continue
                }
                let item = new AlbumDataItem(album.albumId.toString(), count, album.albumName, this.selectType, this.deviceId)
                item.update(await fetchFileResult.getFirstObject())
                albumDataItems.push(item)
            } catch (err) {
                logError(TAG, `on err: ${JSON.stringify(err)}`)
            } finally {
                fetchFileResult.close()
            }
        }
    }

    private async getAlbumItem(id: string, albumDataItems: AlbumDataItem[]): Promise<void> {
        if (this.blackList.indexOf(id) >= 0) {
            logDebug(TAG, `no need as in black list`)
            return
        }
        if (this.deviceId.length > 0 && (id != MediaConstants.ALBUM_ID_SNAPSHOT && id != MediaConstants.ALBUM_ID_CAMERA)) {
            logDebug(TAG, `no need`)
            return
        }
        let fetchOption: MediaLib.MediaFetchOptions = await getFetchOptions(this.selectType, id, this.deviceId)
        if (fetchOption == undefined) {
            logWarn(TAG, `${id} fetchOption is undefined`)
            return
        }
        let item = await mediaModel.getAllMediaItem(id, fetchOption, false)
        if (item.counts == 0) {
            logWarn(TAG, `${id} is empty`)
            return
        }

        let displayName = await getAlbumDisplayName(id)
        let albumItem: AlbumDataItem = new AlbumDataItem(id, item.counts, displayName, this.selectType, this.deviceId)
        albumItem.update(item.fileAsset)
        albumDataItems.push(albumItem)
        return
    }
}