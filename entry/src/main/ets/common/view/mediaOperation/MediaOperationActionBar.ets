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
import {Action} from '../../model/browser/operation/Action.ets'
import {ActionBar} from '../../../common/view/actionbar/ActionBar'
import {ActionBarProp} from '../../model/browser/operation/ActionBarProp'
import {ActionBarMode} from '../../model/browser/operation/ActionBarMode'
import {ScreenManager} from '../../model/common/ScreenManager.ets'
import {MediaOperationType} from '../../model/common/MediaOperationType'

@Component
export struct MediaOperationActionBar {
    @Consume pageType:string;

    onMenuClicked : Function;
    logger: Logger = new Logger('MediaOperationActionBar');

    @StorageLink('isHorizontal') isHorizontal: boolean = ScreenManager.getInstance().isHorizontal();

    private createActionBar(): ActionBarProp {
        let menuList: Array<Action> = new Array<Action>();
        let actionBarProp: ActionBarProp = new ActionBarProp();
        menuList.push(Action.NEW);
        actionBarProp
            .setHasTabBar(false)
            .setTitle((this.pageType == MediaOperationType.Move) ? $r('app.string.move_to') : $r('app.string.copy_to'))
            .setMode(ActionBarMode.STANDARD_MODE)
            .setMenuList(menuList)
            .setLeftAction(Action.CANCEL);
        return actionBarProp;
    }

    build() {
        Column() {
            ActionBar({
                isShowBar: true,
                actionBarProp: this.createActionBar(),
                onMenuClicked: this.onMenuClicked
            })
        }
    }
}