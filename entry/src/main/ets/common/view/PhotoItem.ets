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
import Matrix4 from '@ohos.matrix4'
import router from '@system.router'
import {MediaItem} from '../../common/model/browser/photo/MediaItem.ets'
import {EventPipeline} from '../../common/model/browser/photo/EventPipeline.ets'
import {BroadCast} from '../../common/utils/BroadCast'
import {Logger} from '../utils/Logger'
import {Constants as PhotoConstants} from '../../common/model/browser/photo/Constants'
import {MediaLibraryAccess} from '../../common/access/MediaLibraryAccess'
import {ScreenManager} from '../model/common/ScreenManager'
import {Constants} from '../model/common/Constants.ets';

@Component
export struct PhotoItem {
    @State @Watch('onViewDataChanged') item: MediaItem = new MediaItem(null);
    @State matrix: any = Matrix4.identity().copy();
    @State direction: PanDirection = PanDirection.Vertical;
    @Consume broadCast: BroadCast;
    @State transitionId: string = 'null';
    @State visible: Visibility = Visibility.Hidden;
    @State objectFit: ImageFit = ImageFit.Contain;
    @State thumbnail: string = '';
    @State ratio: number = 1.0;
    @State showError: boolean = false;
    @Consume isPullingDown: boolean;
    @Consume pageFrom: number;
    @Consume('transitionIndex') @Watch('onTransitionChange') updateTransition: number;
    position: number;
    transitionTag: string;
    private eventPipeline: EventPipeline;
    private logger: Logger = new Logger('PhotoItem');
    private animationOption: any = null;
    private animationEndMatrix: any = null;
    @State usePixmap: boolean = true;
    private releasePixmap: Function;

    onTransitionChange() {
        this.logger.info(`onTransitionChange , ${this.updateTransition} ${this.position}`);
        if (this.updateTransition == this.position) {
            this.transitionId = this.transitionTag + this.item.uri;
            this.visible = Visibility.Visible;
        } else {
            this.transitionId = 'null';
            this.visible = Visibility.Hidden;
            this.isPullingDown = false;
        }
        // reset matrix
        this.matrix = Matrix4.identity().copy();
        this.eventPipeline.reset();
    }

    private aboutToAppear(): void {
        this.logger.info(`photoItem aboutToAppear ${this.item.uri}`);
        this.eventPipeline = new EventPipeline(this.broadCast, this.item);
        this.matrix = Matrix4.identity().copy();
        // register event handling
        this.broadCast.on(PhotoConstants.TOUCH_EVENT + this.item.uri, (matrix: any) => {
            this.matrix = matrix;
        });

        this.broadCast.on(PhotoConstants.DIRECTION_CHANGE + this.item.uri, (direction: PanDirection) => {
            this.logger.info(`direction: ${direction}`);
            this.direction = direction;
        });

        this.broadCast.on(PhotoConstants.ANIMATION_EVENT + this.item.uri, (animationOption: any, animationEndMatrix: any) => {
            this.logger.info(`animationOption: ${JSON.stringify(animationOption)}`);
            this.animationOption = animationOption;
            this.animationEndMatrix = animationEndMatrix;
        });
        this.onTransitionChange();
        this.onViewDataChanged();
    }

    private aboutToDisappear(): void {
        this.logger.info(`aboutToDisappear ${this.item.uri}`);
        // clean up event registration
        this.broadCast.off(PhotoConstants.TOUCH_EVENT + this.item.uri, null);
        this.broadCast.off(PhotoConstants.DIRECTION_CHANGE + this.item.uri, null);
        this.broadCast.off(PhotoConstants.ANIMATION_EVENT + this.item.uri, null);
        this.isPullingDown = false;
        this.releasePixmap(this.item.uri);
        this.logger.info(`aboutToDisappear ${this.item.uri} end`);
    }

    onViewDataChanged(): void {
        this.logger.info(`onViewDataChanged start`);
        if (this.item.orientation == PhotoConstants.ROTATE_ONCE || this.item.orientation == PhotoConstants.ROTATE_THRICE) {
            let componentWidth = vp2px(ScreenManager.getInstance().getWinWidth());
            let componentHeight = vp2px(ScreenManager.getInstance().getWinHeight());
            let widthScale = componentWidth / (this.item.width == 0 ? PhotoConstants.DEFAULT_SIZE : this.item.width);
            let heightScale = componentHeight / (this.item.height == 0 ? PhotoConstants.DEFAULT_SIZE : this.item.height);
            let screenScale = widthScale > heightScale ? heightScale : widthScale;
            let reWidthScale = componentWidth / (this.item.height == 0 ? PhotoConstants.DEFAULT_SIZE : this.item.height);
            let reHeightScale = componentHeight / (this.item.width == 0 ? PhotoConstants.DEFAULT_SIZE : this.item.width);
            let reScale = reWidthScale > reHeightScale ? reHeightScale : reWidthScale;
            let scale = screenScale / reScale;

            this.matrix = Matrix4.identity().scale({
                x: scale,
                y: scale
            }).copy();
            this.logger.debug(`onViewDataChanged scale:${scale}, componentSize:${componentWidth}x${componentHeight}\
                width: ${this.item.width}, height: ${this.item.height}`);
            this.eventPipeline && this.eventPipeline.setDefaultScale(scale);
        } else {
            this.matrix = Matrix4.identity().copy();
            this.objectFit = ImageFit.Contain;
            this.eventPipeline && this.eventPipeline.setDefaultScale(1);
        }
        this.eventPipeline && this.eventPipeline.onDataChanged(this.item)
        this.logger.debug(`onViewDataChanged usePixmap:${this.usePixmap}, thumbnail:${JSON.stringify(this.thumbnail)}`);
    }

    getVideoPlayIcon() {
        if (vp2px(Constants.NUMBER_1) >= Constants.NUMBER_1 && vp2px(Constants.NUMBER_1) < Constants.NUMBER_2) {
            return $r('app.media.ic_video_play_btn_hdpi')
        } else if (vp2px(Constants.NUMBER_1) == Constants.NUMBER_2) {
            return $r('app.media.ic_video_play_btn_xhdpi')
        } else if (vp2px(Constants.NUMBER_1) == Constants.NUMBER_3) {
            return $r('app.media.ic_video_play_btn_xxhdpi')
        } else {
            return $r('app.media.ic_video_play_btn_xxxhdpi')
        }
    }

    build() {
        Stack() {
            Image('placeholder')
                .visibility(Visibility.Hidden)
                .onComplete(() => {
                    this.eventPipeline.onComponentSizeChanged();
                })
                .onError(() => {
                    this.eventPipeline.onComponentSizeChanged();
                })
            Flex({
                direction: FlexDirection.Row,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Image(this.thumbnail)
                    .objectFit(this.objectFit)
                    .rotate({ x: 0, y: 0, z: 1, angle: this.item.orientation })
                    .transform(this.matrix)
                    .autoResize(false)
//                    .sharedTransition(this.transitionId, {duration: PhotoConstants.SHARE_TRANSITION_DURATION}) TODO: delete dynamic effect
                    .onComplete(() => {
                        this.logger.debug(`onComplete finish index: ${this.position}, uri: ${this.item.uri}`);
                        this.showError = false;
                    })
                    .onError(() => {
                        this.logger.debug(`image show error`);
                        this.showError = true;
                    })
            }
            .width('100%')
            .height('100%')
            .onClick(() => {
                this.broadCast.emit(PhotoConstants.TOGGLE_BAR, [null]);
            })
                .gesture(
                    GestureGroup(GestureMode.Parallel,
                    PinchGesture({
                        fingers: 2,
                        distance: 1
                    })
                    .onActionStart((event: GestureEvent) => {
                        this.logger.debug('PinchGesture onActionStart');
                        if (this.isPullingDown) {
                            this.logger.debug('Not allow to pinch when pullingDown');
                            return;
                        }
                        this.logger.debug(`PinchGesture onActionStart scale:\
                            ${event.scale}, cx: ${event.pinchCenterX}, cy: ${event.pinchCenterY}`);
                        if (this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_IMAGE) {
                            this.eventPipeline.onScaleStart(event.scale, event.pinchCenterX, event.pinchCenterY);
                        }
                    })
                        .onActionUpdate((event) => {
                            this.logger.debug(`PinchGesture onActionUpdate scale: ${event.scale}`);
                            if (this.isPullingDown) {
                                this.logger.debug('Not allow to pinch when pullingDown');
                                return;
                            }
                            if (this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_IMAGE) {
                                this.eventPipeline.onScale(event.scale);
                            }
                        })
                        .onActionEnd(() => {
                            this.logger.debug('PinchGesture onActionEnd');
                            if (this.isPullingDown) {
                                this.logger.debug('Not allow to pinch when pullingDown');
                                return;
                            }
                            if (this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_IMAGE) {
                                this.eventPipeline.onScaleEnd();
                                if (this.animationOption != null) {
                                    animateTo({
                                        duration: this.animationOption.duration,
                                        curve: this.animationOption.curve,
                                        onFinish: () => {
                                            this.eventPipeline.onAnimationEnd(this.animationEndMatrix);
                                            this.animationOption = null;
                                            this.animationEndMatrix = null;
                                        }
                                    }, () => {
                                        this.matrix = this.animationEndMatrix;
                                    })
                                }
                            }
                        }),
                    PanGesture({
                        direction: this.direction
                    })
                        .onActionStart((event: GestureEvent) => {
                            this.logger.debug(`PanGesture start offsetX:\
                                    ${vp2px(event.offsetX)}, offsetY: ${vp2px(event.offsetY)}`);
                            this.eventPipeline.onMoveStart(vp2px(event.offsetX), vp2px(event.offsetY));
                        })
                        .onActionUpdate((event: GestureEvent) => {
                            this.logger.debug(`PanGesture update offsetX:\
                                    ${vp2px(event.offsetX)}, offsetY: ${vp2px(event.offsetY)}`);
                                this.eventPipeline.onMove(vp2px(event.offsetX), vp2px(event.offsetY));
                        })
                        .onActionEnd((event: GestureEvent) => {
                            this.logger.debug(`PanGesture end offsetX:\
                                    ${vp2px(event.offsetX)}, offsetY: ${vp2px(event.offsetY)}`);
                                this.eventPipeline.onMoveEnd(vp2px(event.offsetX), vp2px(event.offsetY));
                            if (this.animationOption != null) {
                                animateTo({
                                    duration: this.animationOption.duration,
                                    curve: this.animationOption.curve,
                                    onFinish: () => {
                                        this.eventPipeline.onAnimationEnd(this.animationEndMatrix);
                                        this.animationOption = null;
                                        this.animationEndMatrix = null;
                                    }
                                }, () => {
                                    this.matrix = this.animationEndMatrix;
                                })
                            }
                        }),
                    TapGesture({
                        count: 2
                    })
                        .onAction((event: GestureEvent) => {
                            if (this.isPullingDown) {
                                this.logger.debug('Not allow to double tap when pullingDown');
                                return;
                            }
                            this.logger.debug(`onDoubleTap event: ${JSON.stringify(event)}`);
                            if (this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_VIDEO) {
                                return;
                            }
                            this.eventPipeline.onDoubleTap(event.fingerList[0].localX, event.fingerList[0].localY);
                            if (this.animationOption != null) {
                                this.logger.debug('TapGesture animateTo start');
                                animateTo({
                                    duration: this.animationOption.duration,
                                    curve: this.animationOption.curve,
                                    onFinish: () => {
                                        this.eventPipeline.onAnimationEnd(this.animationEndMatrix);
                                        this.animationOption = null;
                                        this.animationEndMatrix = null;
                                    }
                                }, () => {
                                    this.matrix = this.animationEndMatrix;
                                })
                            }
                        })
                    )
            )
            .clip(true)
                .width('100%')
                .height('100%')
                .onTouch((event) => {
                    this.eventPipeline.onTouch(event);
                })
            // TODO Remind users when pictures of other devices cannot be show
            if ((this.showError || this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_VIDEO) &&
                this.pageFrom == Constants.ENTRY_FROM.DISTRIBUTED) {
                Row() {
                    Text((this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_VIDEO) ?
                        $r('app.string.no_distributed_photo_show_video') :
                        $r('app.string.no_distributed_photo_show_image'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .fontFamily($r('app.string.id_text_font_family_regular'))
                        .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                }.margin({top: (this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_VIDEO) ? $r('app.float.input_text_notify_margin') : 0})
            }
            Row() {
                Image(this.getVideoPlayIcon()).objectFit(ImageFit.Contain).width($r('app.float.icon_video_size'))
                    .height($r('app.float.icon_video_size')).onClick(() => {
                    if (this.item != undefined) {
                        router.push({
                            uri: 'feature/browser/view/photo/VideoBrowser',
                            params: {
                                uri: this.item.uri,
                                dateTaken: this.item.dateTaken,
                                previewUri: this.thumbnail
                            }
                        })
                    }
                }).visibility(this.isPullingDown ? Visibility.None : this.isVideoPlayBtnShow())
            }
        }
    }

    isVideoPlayBtnShow(): Visibility {
        this.logger.debug(`isVideoPlayBtnShow: ${this.item.mediaType}`);
        return ((this.item != undefined)
            && (this.item.mediaType == MediaLibraryAccess.MEDIA_TYPE_VIDEO)) ? Visibility.Visible : Visibility.None;
    }
}
