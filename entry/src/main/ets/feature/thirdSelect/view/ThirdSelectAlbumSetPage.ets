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

import router from '@system.router'
import app from '@system.app'
import {ThirdAlbumGridItem} from './/ThirdAlbumGridItem.ets'
import {Action} from '../../../common/model/browser/operation/Action.ets'
import {ThirdSelectedPageActionBar} from './ThirdSelectedPageActionBar'
import {ActionBarProp} from '../../../common/model/browser/operation/ActionBarProp.ets'
import {AlbumSetDataSource} from '../../../common/model/browser/album/AlbumSetDataSource.ets'
import {Logger} from '../utils/Logger'
import {SelectUtil} from '../../../common/model/browser/photo/SelectUtil'
import {Constants} from '../../../common/model/common/Constants.ets'
import {ThirdSelectManager} from '../../../common/model/browser/SelectManager.ets'
import {BroadCast} from '../../../common/utils/BroadCast'
import {NoPhotoComponent} from '../../../common/view/NoPhotoComponent'
import {ScreenManager} from '../../../common/model/common/ScreenManager'
import {AlbumDefine} from '../../../common/model/browser/AlbumDefine.ets'
import {BroadCastConstants} from '../../../common/model/common/BroadCastConstants'
import {BroadCastManager} from '../../../common/model/common/BroadCastManager'

// Third Select AlbumSet Page
@Entry
@Component
export struct ThirdSelectAlbumSetPage {
    @State isEmpty: boolean = false;
    albums: AlbumSetDataSource;
    @Provide selectedCount: number = 0;
    @Provide broadCast: BroadCast = new BroadCast();
    @Provide('isSelectedMode') isMultiPick: boolean = false;
    @Provide maxSelectCount: number = Constants.DEFAULT_MAX_THIRD_SELECT_COUNT;
    @Provide moreMenuList: Array<Action> = new Array<Action>();
    isFromWallpaper = false; // Whether the current interface is opened from the wallpaper
    type: string;
    isFromFa: boolean;
    selectManager: ThirdSelectManager;
    @State gridRowCount: number = 3;
    isActive = false;
    logger: Logger = new Logger('ThirdSelectAlbumSetPage');
    @StorageLink('isSplitMode') isSplitMode: boolean = ScreenManager.getInstance().isSplitMode();
    @StorageLink('leftBlank') leftBlank: [number, number, number, number]
        = [0, ScreenManager.getInstance().getStatusBarHeight(), 0, ScreenManager.getInstance().getNaviBarHeight()];
    @StorageLink('isSidebar') isSidebar: boolean = ScreenManager.getInstance().isSidebar();
    private appBroadCast: BroadCast = BroadCastManager.getInstance().getBroadCast();

    private aboutToAppear(): void {
        this.albums = new AlbumSetDataSource(this.broadCast);
        let param = router.getParams();
        if (param != null) {
            this.isMultiPick = param.isMultiPick;
            this.type = param.type;
            if (param.isFromFa != undefined || param.isFromFa != null) {
                this.isFromFa = param.isFromFa;
            }
            this.isFromWallpaper = param.isFromWallpaper;
            if (this.isFromWallpaper) {
                this.maxSelectCount = param.remainingOfWallpapers;
            }
        }
        this.selectManager = new ThirdSelectManager();
        this.onMenuClicked = this.onMenuClicked.bind(this);
        this.logger.info(`isMultiPick: ${this.isMultiPick}`);
        this.logger.info(`type: ${this.type}`);
        this.logger.info(`ThirdSelectAlbumSetPage isFromWallpaper: ${this.isFromWallpaper}`);
        this.logger.info(`ThirdSelectAlbumSetPage maxSelectCount: ${this.maxSelectCount}`);
        this.selectManager.setIsMultiPick(this.isMultiPick ? true : false);
        this.selectManager.setType(this.type);
        AppStorage.SetOrCreate(Constants.THIRD_SELECT_MANAGER, this.selectManager);
        this.broadCast.on(Constants.ON_LOADING_FINISHED, (size: number) => {
            this.logger.info(`ON_LOADING_FINISHED size: ${size}`);
            this.isEmpty = size == 0;
        });
        if (this.isMultiPick) {
            this.selectManager.registerCallback('thirdSelectUpdateCount', (newState: number) => {
                this.logger.info(`thirdSelectUpdateCount ${newState}`);
                this.selectedCount = newState;
            });
        }

        this.initGridRowCount();
    }

    private initGridRowCount(): void {
        let contentWidth = ScreenManager.getInstance().getWinWidth();
        let maxCardWidth = Constants.ALBUM_SET_COVER_SIZE * Constants.GRID_MAX_SIZE_RATIO;
        this.gridRowCount = Math.ceil((contentWidth - Constants.ALBUM_SET_MARGIN * 2 + Constants.ALBUM_SET_GUTTER)
            / (maxCardWidth + Constants.ALBUM_SET_GUTTER));
        this.logger.info(`initGridRowCount gridRowCount: ${this.gridRowCount}`);
    }

    private onPageShow() {
        this.appBroadCast.emit(BroadCastConstants.THIRD_ROUTE_PAGE, []);
        this.onActive();
    }

    private onPageHide() {
        this.onInActive();
    }

    private onActive() {
        if (!this.isActive) {
            this.logger.info('onActive');
            this.isActive = true;
            this.albums && this.albums.onActive();
        }
    }

    private onInActive() {
        if (this.isActive) {
            this.logger.info('onInActive');
            this.isActive = false;
            this.albums && this.albums.onInActive();
        }
    }

    onMenuClicked(action: Action) {
        this.logger.info(`onMenuClicked, action: ${action.actionID}`);
        switch (action) {
            case Action.CANCEL:
                this.logger.info('click cancel');
                let abilityResult = {
                    'resultCode': 0,
                    'want': {
                        'parameters': {
                            'select-item-list': ''
                        }
                    }
                };
                globalThis.photosAbilityContext.terminateSelfWithResult(abilityResult).then((result) => {
                    this.logger.info(`terminateSelfWithResult result: ${result}`);
                });
                break;
            case Action.OK:
                this.logger.info('click ok');
                this.setPickResult();
                break
            default:
                break;
        }
    }

    build() {
        Flex({
            direction: FlexDirection.Column,
            justifyContent: FlexAlign.Start,
            alignItems: ItemAlign.Start
        }) {
            ThirdSelectedPageActionBar({ leftAction: Action.CANCEL, isMultiPick: this.isMultiPick,
                title: ActionBarProp.SINGLE_UNSELECT_TITLE, onMenuClicked: this.onMenuClicked })
            Stack() {
                if (this.isEmpty) {
                    NoPhotoComponent({ title: $r('app.string.title_no_albums') })
                }
                Grid() {
                    LazyForEach(this.albums, (item) => {
                        if (item.name != AlbumDefine.ALBUM_NAME_RECYCLE) {
                            if (this.albums.mediaSetList.indexOf(item) == 0) {
                                GridItem() {
                                    ThirdAlbumGridItem({
                                        item: item,
                                        isBigCard: true,
                                        isMultiPick: this.isMultiPick,
                                        isFromWallpaper: this.isFromWallpaper,
                                        maxSelectCount: this.maxSelectCount,
                                        isFromFa: this.isFromFa
                                    })
                                }.columnStart(0).columnEnd(1)
                            } else {
                                GridItem() {
                                    ThirdAlbumGridItem({
                                        item: item,
                                        isBigCard: false,
                                        isMultiPick: this.isMultiPick,
                                        isFromWallpaper: this.isFromWallpaper,
                                        maxSelectCount: this.maxSelectCount,
                                        isFromFa: this.isFromFa
                                    })
                                }
                            }
                        }
                    }, item => item.name)
                }
                .columnsTemplate('1fr '.repeat(this.gridRowCount))
                    .padding({
                        left: $r('app.float.max_padding_start'),
                        right: $r('app.float.max_padding_end'),
                        top: $r('app.float.album_set_page_padding_top'),
                        bottom: $r('app.float.album_set_page_padding_end')
                    })
                    .columnsGap($r('app.float.album_set_grid_column_gap'))
                    .rowsGap($r('app.float.album_set_grid_row_gap'))
            }
        }
        .backgroundColor($r('app.color.default_background_color'))
            .margin({
                top: this.leftBlank[1],
                bottom: this.leftBlank[3]
            })
    }

    private setPickResult(): void {
        if (this.isFromFa) {
            return;
        }
        let uriArray = SelectUtil.getUriArray(this.selectManager.clickedSet);
        let abilityResult = {
            'resultCode': 0,
            'want': {
                'parameters': {
                    'select-item-list': uriArray
                }
            }
        };
        this.logger.info(`uri: ${uriArray}`);
        globalThis.photosAbilityContext.terminateSelfWithResult(abilityResult).then((result) => {
            this.logger.info(`terminateSelfWithResult result: ${result}`);
        });
    }
}