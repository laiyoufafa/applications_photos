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
import inputConsumer from '@ohos.multimodalInput.inputConsumer';
import { Logger } from '../../utils/Logger';

export class MultimodalInputManager {
    logger: Logger = new Logger('MultimodalInputManager');

    //win + N
    leftKeyOptions: any = {
        'preKeys': [],
        'finalKey': 2014,
        'isFinalKeyDown': true,
        'finalKeyDownDuration': 0
    };

    //win + I
    rightKeyOptions: any = {
        'preKeys': [],
        'finalKey': 2015,
        'isFinalKeyDown': true,
        'finalKeyDownDuration': 0
    };
    escKeyOptions: any = {
        'preKeys': [],
        'finalKey': 2070,
        'isFinalKeyDown': true,
        'finalKeyDownDuration': 0
    };

    async registerListener(callback) {
        this.logger.debug(`registerListener start`);
        inputConsumer.on('key', this.leftKeyOptions, (data) => {
            this.logger.debug(`notificationRegister data: ${JSON.stringify(data)}`);
            callback(0);
        });
        inputConsumer.on('key', this.rightKeyOptions, (data) => {
            this.logger.debug(`controlRegister data: ${JSON.stringify(data)}`);
            callback(1);
        });
        inputConsumer.on('key', this.escKeyOptions, (data) => {
            this.logger.debug(`escRegister data: ${JSON.stringify(data)}`);
            callback(2);
        });
        this.logger.debug(`registerListener end`);
    }

    async unregisterListener() {
        this.logger.debug(`unregisterListener start`);
        inputConsumer.off('key', this.leftKeyOptions, (data) => {
            this.logger.debug(`notificationUnregister data: ${JSON.stringify(data)}`);
        });
        inputConsumer.off('key', this.rightKeyOptions, (data) => {
            this.logger.debug(`controlUnregister data: ${JSON.stringify(data)}`);
        });
        inputConsumer.off('key', this.escKeyOptions, (data) => {
            this.logger.debug(`escUnregister data: ${JSON.stringify(data)}`);
        });
        this.logger.debug(`unregisterListener end`);
    }
}

let mMultimodalInputManager = new MultimodalInputManager();

export default mMultimodalInputManager as MultimodalInputManager;