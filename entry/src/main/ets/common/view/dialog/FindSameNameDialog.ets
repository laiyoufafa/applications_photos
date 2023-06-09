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
import {DialogCallback} from '../../model/common/DialogUtil'
import { Logger } from '../../utils/Logger.ets'
import {DateUtil} from '../../../common/utils/DateUtil.ets'
import {FindSameOperation} from '../../model/browser/operation/ProcessMenuOperation.ets'
import {ScreenManager} from '../../model/common/ScreenManager.ets';
import {Constants} from '../../model/common/Constants.ets';

@Observed
export class FindSameNameParam {
    sourceFileAsset: any
    targetFileAsset: any
    replaceFunc: Function
    skipFunc: Function
    cancelFunc: Function
    singlePhoto: boolean
    doSameFunc: Function
}

@CustomDialog
export struct FindSameNameDialog {
    @StorageLink('isHorizontal') isHorizontal: boolean = ScreenManager.getInstance().isHorizontal();
    @StorageLink('isSidebar') isSidebar: boolean = ScreenManager.getInstance().isSidebar();
    @StorageLink('leftBlank') leftBlank: [number, number, number, number]
        = [0, ScreenManager.getInstance().getStatusBarHeight(), 0, ScreenManager.getInstance().getNaviBarHeight()];
    @State isDoSameAction: boolean = false;
    @Consume dialogCallback: DialogCallback;
    @Consume dialogMessage: Resource;
    @Consume findSameNameParam: FindSameNameParam;

    sourceDetails: any;
    targetDetails: any;
    logger: Logger = new Logger('FindSameNameDialog');
    controller: CustomDialogController;
    dataTime: string;
    targetDataTime: string;
    timeConvert = 1000;

    getTitle(name) {
        this.logger.info(`getTitle ${name}`);
        if (name) {
            let index = name.lastIndexOf('.');
            if (index == -1) {
                return name;
            }
            return name.substr(0, index);
        } else {
            return '';
        }
    }

    aboutToAppear() {
        this.sourceDetails = this.findSameNameParam.sourceFileAsset;
        this.targetDetails = this.findSameNameParam.targetFileAsset;
        let localizedDate = DateUtil.getLocalizedDate(this.sourceDetails.dateModified * this.timeConvert);
        let localizedTime = DateUtil.getLocalizedTime(this.sourceDetails.dateModified * this.timeConvert);
        this.dataTime = `${localizedDate} ${localizedTime}`;
        let targetDate = DateUtil.getLocalizedDate(this.targetDetails.dateModified * this.timeConvert);
        let targetTime = DateUtil.getLocalizedTime(this.targetDetails.dateModified * this.timeConvert);
        this.targetDataTime = `${targetDate} ${targetTime}`;
    }

    build() {
        Column() {
            Row() {
                Text($r('app.string.find_same_name'))
                    .fontSize($r('sys.float.ohos_id_text_size_headline7'))
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
            }.alignItems(VerticalAlign.Center)
            .height($r('app.float.dialog_title_height'))

            Row() {
                Column() {
                    Text($r('app.string.target_has_same_name', this.getTitle(this.sourceDetails.displayName)))
                        .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                        .maxLines(3)
                }
            }.margin({
                bottom: $r('app.float.same_name_date_dialog_bottom') })

            Row() {
                Column() {
                    Text($r('app.string.source_file_location'))
                        .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                }
            }.margin({
                bottom: $r('app.float.same_name_date_dialog_bottom') })

            Row() {
                Column() {
                    Text($r('app.string.file_size_location', `${(this.sourceDetails.size/(1024 * 1024)).toFixed(2)}MB`))
                        .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                }
            }.margin({
                bottom: $r('sys.float.ohos_id_text_paragraph_margin_s'), left: $r('app.float.same_name_date_dialog_left') })

            Row() {
                Column() {
                    Text($r('app.string.file_time_location', this.dataTime))
                        .fontSize($r('app.float.same_name_date_size'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                }
            }.margin({
                bottom: $r('app.float.same_name_date_dialog_bottom'), left: $r('app.float.same_name_date_dialog_left') })

            Row() {
                Column() {
                    Text($r('app.string.target_file_location'))
                        .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                }
            }.margin({
                bottom: $r('app.float.same_name_date_dialog_bottom') })

            Row() {
                Column() {
                    Text($r('app.string.file_size_location', `${(this.targetDetails.size/(1024 * 1024)).toFixed(2)}MB`))
                        .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                }
            }.margin({
                bottom: $r('sys.float.ohos_id_text_paragraph_margin_s'), left: $r('app.float.same_name_date_dialog_left')})

            Row() {
                Column() {
                    Text($r('app.string.file_time_location', this.targetDataTime))
                        .fontSize($r('app.float.same_name_date_size'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                }
            }.margin({
                bottom: $r('sys.float.ohos_id_text_paragraph_margin_s'), left: $r('app.float.same_name_date_dialog_left')})

            Row() {
                Image(this.isDoSameAction ? $r('app.media.ic_gallery_public_checkbox_filled')
                                          : $r('app.media.ic_checkbox_off_overlay'))
                .height($r('app.float.icon_size'))
                    .width($r('app.float.icon_size'))
                    .margin({
                        right: $r('app.float.details_dialog_button_margin_right') })
                .onClick(() => {
                    this.isDoSameAction = !this.isDoSameAction
                })

                Text($r('app.string.do_same_action'))
                    .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                    .fontFamily($r('app.string.id_text_font_family_regular'))
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
            }
            .visibility(this.findSameNameParam.singlePhoto ? Visibility.None : Visibility.Visible)
            .margin({
                bottom: $r('app.float.same_name_date_dialog_bottom') })

            Stack({alignContent: Alignment.Top}) {
                Row() {
                    Button() {
                        Text($r('app.string.replace_action'))
                            .fontSize($r('sys.float.ohos_id_text_size_button1'))
                            .fontColor($r('app.color.color_control_highlight'))
                            .width(this.findSameNameParam.singlePhoto ? '50%' : `${100/3}%`)
                            .textAlign(TextAlign.Center)
                            .fontWeight(FontWeight.Medium)
                    }
                    .margin({
                        left: $r('app.float.details_dialog_button_margin_left'),
                        right: $r('app.float.details_dialog_button_margin_right')
                    })
                    .backgroundColor($r('app.color.transparent'))
                    .height($r('app.float.details_dialog_button_height'))
                    .onClick(() => {
                        this.logger.debug(`replaceCallback`);
                        if (this.isDoSameAction) {
                            this.findSameNameParam.doSameFunc
                            && this.findSameNameParam.doSameFunc(FindSameOperation.REPLACE);
                        }
                        this.findSameNameParam.replaceFunc && this.findSameNameParam.replaceFunc();
                        this.controller.close();
                    })

                    Row() {
                        Divider()
                            .vertical(true)
                            .strokeWidth(2)
                            .height($r('app.float.dialog_divider_height'))
                            .color($r('sys.color.ohos_id_color_list_separator'))
                    }
                    .height($r('app.float.details_dialog_button_height'))
                    .alignItems(VerticalAlign.Center)

                    if (!this.findSameNameParam.singlePhoto) {
                        Button() {
                            Text($r('app.string.skip_action'))
                                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                                .fontColor($r('app.color.color_control_highlight'))
                                .width(`${100/3}%`)
                                .textAlign(TextAlign.Center)
                                .fontWeight(FontWeight.Medium)
                        }
                        .margin({
                            left: $r('app.float.details_dialog_button_margin_left'),
                            right: $r('app.float.details_dialog_button_margin_right')
                        })
                        .backgroundColor($r('app.color.transparent'))
                        .height($r('app.float.details_dialog_button_height'))
                        .onClick(() => {
                            this.logger.debug(`skipCallback`);
                            if (this.isDoSameAction) {
                                this.findSameNameParam.doSameFunc
                                && this.findSameNameParam.doSameFunc(FindSameOperation.SKIP);
                            }
                            this.findSameNameParam.skipFunc && this.findSameNameParam.skipFunc();
                            this.controller.close();
                        })

                        Row() {
                            Divider()
                                .vertical(true)
                                .strokeWidth(2)
                                .height($r('app.float.dialog_divider_height'))
                                .color($r('sys.color.ohos_id_color_list_separator'))
                        }
                        .height($r('app.float.details_dialog_button_height'))
                        .alignItems(VerticalAlign.Center)
                    }

                    Button() {
                        Text($r('app.string.action_cancel'))
                            .fontSize($r('sys.float.ohos_id_text_size_button1'))
                            .fontColor($r('app.color.color_control_highlight'))
                            .width(this.findSameNameParam.singlePhoto ? '50%' : `${100/3}%`)
                            .textAlign(TextAlign.Center)
                            .fontWeight(FontWeight.Medium)
                    }
                    .margin({
                        left: $r('app.float.details_dialog_button_margin_left'),
                        right: $r('app.float.details_dialog_button_margin_right')
                    })
                    .backgroundColor($r('app.color.transparent'))
                    .height($r('app.float.details_dialog_button_height'))
                    .onClick(() => {
                        this.logger.debug(`cancelFunc`);
                        this.findSameNameParam.cancelFunc && this.findSameNameParam.cancelFunc();
                        this.controller.close();
                    })
                }
            }
            .width('100%')
            .height($r('app.float.details_dialog_button_area_height'))
        }.padding({ left: $r('app.float.dialog_content_margin'), right: $r('app.float.dialog_content_margin') })
        .alignItems(HorizontalAlign.Start).borderRadius($r('app.float.dialog_border_radius'))
        .width(ScreenManager.getInstance().getColumnsWidth(4))
        .backgroundColor($r('app.color.white'))
        .margin({
            right: $r('app.float.dialog_content_margin'),
            left: $r('app.float.dialog_content_margin'),
            bottom: this.isHorizontal || this.isSidebar ? 0 : Constants.DIALOG_BOTTOM_OFFSET + this.leftBlank[3]
        })
    }
}
