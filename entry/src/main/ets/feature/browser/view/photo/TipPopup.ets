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
import {BroadCast} from '../../../../common/utils/BroadCast.ets'
import {Constants as PhotoConstants} from '../../../../common/model/browser/photo/Constants'

@Component
export struct TipPopup{
    @State isShowPop: boolean = false;
    @Consume broadCast: BroadCast;

    aboutToAppear() {
        this.broadCast.on(PhotoConstants.POP_APPEAR, () => {
            this.isShowPop = true;
        });
        this.broadCast.on(PhotoConstants.POP_DISAPPEAR, () => {
            this.isShowPop = false;
        });
    }

    build() {
        Row() {
            Text($r('app.string.video_pause'))
                .fontSize($r('sys.float.ohos_id_text_size_headline7'))
                .fontFamily($r('app.string.id_text_font_family_regular'))
                .fontColor($r('app.color.white'))
                .maxLines(1)
                .textOverflow({overflow:TextOverflow.Ellipsis})
                .align(Alignment.Center)
        }
        .backgroundColor($r('app.color.detail_view_bg_color'))
        .padding($r('app.float.popup_padding'))
        .visibility(this.isShowPop ? Visibility.Visible : Visibility.None)
        .borderRadius(15)
    }
}
