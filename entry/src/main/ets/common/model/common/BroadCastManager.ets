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
import {BroadCast} from '../../utils/BroadCast.ets'
import {Constants} from './Constants'

export class BroadCastManager {
    private logger: Logger = new Logger('BroadCastManager');

    // The global BroadCast of the application process. Event registration and destruction should be paired
    private appBroadCast: BroadCast;

    private constructor() {
        this.logger.info('constructor');
        this.appBroadCast = new BroadCast();
    }

    public static getInstance(): BroadCastManager {
        if (AppStorage.Get(Constants.APP_KEY_EVENT_BUS) == null) {
            AppStorage.SetOrCreate(Constants.APP_KEY_EVENT_BUS, new BroadCastManager());
        }
        return AppStorage.Get(Constants.APP_KEY_EVENT_BUS);
    }

    public getBroadCast(): BroadCast {
        return this.appBroadCast;
    }
}
