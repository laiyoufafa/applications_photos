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
import {Logger} from '../../../utils/Logger.ets'
import {MenuOperation} from './MenuOperation'
import {MenuContext} from './MenuContext'
import {ScreenManager} from '../../common/ScreenManager'

export class GotoPhotosMenuOperation implements MenuOperation {
    private logger: Logger = new Logger('GotoPhotosMenuOperation');
    private menuContext: MenuContext;

    constructor(menuContext: MenuContext) {
        this.menuContext = menuContext;
    }

    doAction(): void {
        if (this.menuContext == null) {
            this.logger.error('menuContext is null, return');
            return;
        }
        let jumpSourceToMain = this.menuContext.jumpSourceToMain;
        this.logger.info(`router to pages/index, jumpSource: ${jumpSourceToMain}` );
        let leftPos = ScreenManager.getInstance().isSidebar();
        router.replace({
            uri: leftPos === true ? 'product/pad/view/index' : 'product/phone/view/index',
            params: {
                jumpSource: jumpSourceToMain,
            }
        });
    }
}