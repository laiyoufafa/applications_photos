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

import {Logger} from '../../utils/Logger.ets';
import {ScreenManager} from '../../model/common/ScreenManager.ets';
import {Constants} from '../../model/common/Constants.ets';

@Observed
export class DeleteProgressParam {
    currentCount: number
    totalCount: number
    message: Resource
}

@CustomDialog
export struct DeleteProgressDialog {
    @StorageLink('isHorizontal') isHorizontal: boolean = ScreenManager.getInstance().isHorizontal();
    @StorageLink('isSidebar') isSidebar: boolean = ScreenManager.getInstance().isSidebar();
    @StorageLink('leftBlank') leftBlank: [number, number, number, number]
        = [0, ScreenManager.getInstance().getStatusBarHeight(), 0, ScreenManager.getInstance().getNaviBarHeight()];
    controller: CustomDialogController
    @Consume deleteProgress: number;
    @Consume deleteProgressParam: DeleteProgressParam;

    logger: Logger = new Logger('ProgressDialog');



    build() {
        Column() {
            Row() {
                Text(this.deleteProgressParam.message)
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontFamily($r('app.string.id_text_font_family_regular'))
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.deleteProgressParam.currentCount}/${this.deleteProgressParam.totalCount}`)
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontFamily($r('app.string.id_text_font_family_regular'))
                    .flexGrow(1)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.deleteProgress}%`)
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontFamily($r('app.string.id_text_font_family_regular'))
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .margin({
                        left: $r('app.float.process_bar_margin_left'),
                        right: $r('app.float.process_bar_margin_left'),
                    })
            }
            .width('100%')

            Row() {
                Progress({ value: 0, total: 100, style: ProgressStyle.Linear })
                    .value(this.deleteProgress)
                    .color($r('app.color.color_control_highlight'))
                    .flexGrow(1)
                    .padding({
                        right: 16
                    })
            }
            .width('100%')
            .margin({ top: $r('app.float.id_icon_margin_horizontal') })
        }
        .padding({
            left: $r('app.float.max_padding_start'),
            right: $r('app.float.max_padding_end'),
            top: $r('app.float.max_padding_start'),
            bottom: $r('app.float.max_padding_end'),
        })
        .border({ radius: $r('sys.float.ohos_id_corner_radius_default_l') })
        .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
        .borderRadius($r('app.float.dialog_border_radius'))
        .width(ScreenManager.getInstance().getColumnsWidth(4))
        .margin({
            right: $r('app.float.dialog_content_margin'),
            left: $r('app.float.dialog_content_margin'),
            bottom: this.isHorizontal || this.isSidebar ? 0 : Constants.DIALOG_BOTTOM_OFFSET + this.leftBlank[3]
        })
    }
}
