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

import {Logger} from '../../utils/Logger'
import {Action} from '../../../../common/model/browser/operation/Action'
import {ToolBar} from '../../../../common/view/actionbar/ToolBar'

@Component
export struct AlbumSetPageToolBar {
    @Provide isShowBar: boolean = true;
    @Provide toolMenuList: Array<Action> = new Array<Action>();
    @Consume isAlbumSetSelectedMode: boolean;
    @Consume('selectedCount') @Watch('updateToolbar') selectedAlbumsCount: number;

    @Consume isDisableRename: boolean;
    @Consume isDisableDelete: boolean;

    onMenuClicked : Function;
    logger: Logger = new Logger('AlbumSetPageToolBar');

    private aboutToAppear() : void {
        this.logger.info('aboutToAppear');
        this.updateToolbar();
    }

    private updateToolbar() : void {
        this.logger.info('updateToolbar');
        if (this.isAlbumSetSelectedMode) {
            this.logger.info('pushToolbar');
            this.toolMenuList = [];
            this.toolMenuList.push(
                ((!this.isDisableRename && this.selectedAlbumsCount == 1) ? Action.RENAME : Action.RENAME_INVALID),
                ((!this.isDisableDelete && this.selectedAlbumsCount > 0) ? Action.DELETE :Action.DELETE_INVALID));
        }
    }

    build() {
        ToolBar({
            onMenuClicked: this.onMenuClicked
        })
    }
}