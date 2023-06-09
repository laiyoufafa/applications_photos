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

import {Logger} from './Logger.ets'
import i18n from '@ohos.i18n';

export class DateUtil {
    // logger
    private static logger: Logger = new Logger('DateUtil');
    private static LANGUAGE_LOCALES_MAP = {
        'zh': 'zh-CN',
        'en': 'en-US'
    };
    public static readonly MILLISECONDS_PER_SECOND: number = 1000;
    public static readonly SECONDS_PER_MINUTE: number = 60;
    public static readonly SECONDS_PER_HOUR: number = 3660;

    // Get the date after localization (year-month-day)
    public static getLocalizedDate(milliseconds: number): string {
        let locales: string = this.getLocales();
        return new Intl.DateTimeFormat(locales, {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        }).format(new Date(milliseconds));
    }

    // Gets the localization date of the photo page grouping data
    public static getGroupDataLocalizedDate(milliseconds: number): Resource {
        let date = new Date(milliseconds);
        let today = new Date();
        if (date.getFullYear() == today.getFullYear() && date.getMonth() == today.getMonth()) {
            if (date.getDate() == today.getDate()) {
                return $r('app.string.date_today');
            }
            if (today.getDate() - date.getDate() == 1) {
                return $r('app.string.date_yesterday');
            }
        }
        return $r('app.string.common_place_holder', this.getLocalizedDate(milliseconds));
    }

    public static getLocalizedYear(milliseconds: number): Resource {
        let locales: string = this.getLocales();
        let yearText = new Intl.DateTimeFormat(locales, {
            year: 'numeric'
        }).format(new Date(milliseconds));
        return $r('app.string.common_place_holder', yearText.toString());
    }

    public static getLocalizedYearAndMonth(milliseconds: number): string {
        let locales: string = this.getLocales();
        return new Intl.DateTimeFormat(locales, {
            year: 'numeric',
            month: 'long'
        }).format(new Date(milliseconds));
    }

    public static getLocalizedTime(milliseconds: number): string {
        let locales: string = this.getLocales();
        let is24HourClock = i18n.is24HourClock();
        return new Intl.DateTimeFormat(locales, { hour12: !is24HourClock,
            hour: (is24HourClock ? '2-digit' : 'numeric'), minute: '2-digit' }).format(new Date(milliseconds));
    }

    private static getLocales(): string {
        let language = AppStorage.Get('languageCode').toString();
        let locales: string = this.LANGUAGE_LOCALES_MAP['en'];
        if (this.LANGUAGE_LOCALES_MAP[language]) {
            locales = this.LANGUAGE_LOCALES_MAP[language];
        }
        return locales;
    }

    // Format duration
    public static getFormattedDuration(milliSecond: number): string {
        if (milliSecond == null) {
            this.logger.error('getFormattedDuration, input is null!');
            return '00:00';
        }
        if (milliSecond <= 0) {
            this.logger.error('getFormattedDuration, input is negative number!');
            return '00:00';
        }
        if (milliSecond < this.MILLISECONDS_PER_SECOND) {
            return '00:01';
        }
        let seconds = Math.floor(milliSecond / this.MILLISECONDS_PER_SECOND);
        let hourTime: number = Math.floor(seconds / this.SECONDS_PER_HOUR);
        let minuteTime: number = Math.floor(Math.floor(seconds / this.SECONDS_PER_MINUTE) % this.SECONDS_PER_MINUTE);
        let secondTime: number = Math.floor(seconds % this.SECONDS_PER_MINUTE);
        if (hourTime > 0) {
            return `${hourTime}:${this.checkTime(minuteTime)}:${this.checkTime(secondTime)}`;
        } else {
            return `${this.checkTime(minuteTime)}:${this.checkTime(secondTime)}`;
        }
    }

    private static checkTime(time: number): string{
        if (time < 0) {
            this.logger.error('checkTime, input is negative number!');
            return '00';
        }
        let formatTime: string = time.toString();
        if (time < 10) {
            let zeroString = '0';
            formatTime = zeroString.concat(formatTime);
        }
        return formatTime;
    }

    public static isTheSameDay(startTime: number, endTime: number): boolean {
        if (startTime == null || endTime == null) {
            return false;
        }
        const startTimeMs = new Date(startTime).setHours(0, 0, 0, 0);
        const endTimeMs = new Date(endTime).setHours(0, 0, 0, 0);
        return startTimeMs === endTimeMs ? true : false;
    }

    public static isTheSameYear(startTime: number, endTime: number): boolean {
        if (startTime == null || endTime == null) {
            return false;
        }
        const startYear = new Date(startTime).getFullYear();
        const endYear = new Date(endTime).getFullYear();
        return startYear === endYear ? true : false;
    }
}