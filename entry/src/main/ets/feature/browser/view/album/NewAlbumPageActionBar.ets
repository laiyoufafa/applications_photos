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

import {Action} from '../../../../common/model/browser/operation/Action.ets'
import {ActionBar} from '../../../../common/view/actionbar/ActionBar.ets'
import {ActionBarProp} from '../../../../common/model/browser/operation/ActionBarProp.ets'
import {ActionBarMode, ActionBarSelectionMode} from '../../../../common/model/browser/operation/ActionBarMode.ets'
import {Logger} from '../../utils/Logger'

@Component
export struct NewAlbumPageActionBar {
    onMenuClicked: Function;
    private logger: Logger = new Logger('NewAlbumPageActionBar');

    private createActionBar(): ActionBarProp {
        let actionBarProp: ActionBarProp = new ActionBarProp();
        actionBarProp
            .setLeftAction(Action.CANCEL)
            .setMode(ActionBarMode.STANDARD_MODE)
            .setSelectionMode(ActionBarSelectionMode.SINGLE)
            .setTitle($r('app.string.title_select_photos'));

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