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

import {Logger} from '../../utils/Logger.ets'
import {ActionBarProp} from '../../model/browser/operation/ActionBarProp.ets'
import {Action} from '../../model/browser/operation/Action.ets'
import {ActionBarButton} from './ActionBarButton.ets'

// MenuPanel，Right menu button panel
@Component
export struct MenuPanel {
    @State @Watch('onActionBarPropChanged') actionBarProp: ActionBarProp = new ActionBarProp();
    @State menuList: Action[] = [];
    onMenuClicked: Function;
    logger: Logger = new Logger('MenuPanel');

    private aboutToAppear(): void {
        this.logger.info('aboutToAppear.');
        this.onActionBarPropChanged();
    }

    private onActionBarPropChanged(): void {
        this.menuList = this.actionBarProp.getMenuList();
        this.logger.info(`onActionBarPropChanged, menu's size: ${this.menuList.length}`);
        this.menuList.forEach((menu: Action) => {
            this.logger.info(`ActionId: ${menu.actionID}`)
        })
    }

    private onBuildDone(): void {
        this.logger.info(`onBuildDone, menu's size: ${this.menuList.length}`);
    }

    build() {
        Row() {
            ForEach(this.menuList, (menu: Action) => {
                ActionBarButton({
                    res: menu.iconRes,
                    action: menu,
                    onMenuClicked: this.onMenuClicked,
                    isLeft: false,
                    isAutoTint: menu.isAutoTint,
                    colorMode: this.actionBarProp.getColorMode()
                })
            }, menu => (menu.actionType ? menu.actionType.id : menu.actionID))
        }
        .alignItems(VerticalAlign.Center)
            .margin(
                {
                    right: $r('app.float.default_actionbar_padding_right')
                })
    }
}