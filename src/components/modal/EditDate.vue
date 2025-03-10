<template>
  <Modal v-if="photos.length > 0" @close="close">
    <template #title>
      {{ t("memories", "Edit Date/Time") }}
    </template>

    <template #buttons>
      <NcButton @click="save" class="button" type="error" v-if="longDateStr">
        {{ t("memories", "Update Exif") }}
      </NcButton>
    </template>

    <div v-if="longDateStr">
      <span v-if="photos.length > 1"> [{{ t("memories", "Newest") }}] </span>
      {{ longDateStr }}

      <div class="fields">
        <NcTextField
          :value.sync="year"
          class="field"
          @input="newestChange()"
          :label="t('memories', 'Year')"
          :label-visible="true"
          :placeholder="t('memories', 'Year')"
        />
        <NcTextField
          :value.sync="month"
          class="field"
          @input="newestChange()"
          :label="t('memories', 'Month')"
          :label-visible="true"
          :placeholder="t('memories', 'Month')"
        />
        <NcTextField
          :value.sync="day"
          class="field"
          @input="newestChange()"
          :label="t('memories', 'Day')"
          :label-visible="true"
          :placeholder="t('memories', 'Day')"
        />
        <NcTextField
          :value.sync="hour"
          class="field"
          @input="newestChange(true)"
          :label="t('memories', 'Time')"
          :label-visible="true"
          :placeholder="t('memories', 'Hour')"
        />
        <NcTextField
          :value.sync="minute"
          class="field"
          @input="newestChange(true)"
          :label="t('memories', 'Minute')"
          :placeholder="t('memories', 'Minute')"
        />
      </div>

      <div v-if="photos.length > 1" class="oldest">
        <span> [{{ t("memories", "Oldest") }}] </span>
        {{ longDateStrLast }}

        <div class="fields">
          <NcTextField
            :value.sync="yearLast"
            class="field"
            :label="t('memories', 'Year')"
            :label-visible="true"
            :placeholder="t('memories', 'Year')"
          />
          <NcTextField
            :value.sync="monthLast"
            class="field"
            :label="t('memories', 'Month')"
            :label-visible="true"
            :placeholder="t('memories', 'Month')"
          />
          <NcTextField
            :value.sync="dayLast"
            class="field"
            :label="t('memories', 'Day')"
            :label-visible="true"
            :placeholder="t('memories', 'Day')"
          />
          <NcTextField
            :value.sync="hourLast"
            class="field"
            :label="t('memories', 'Time')"
            :label-visible="true"
            :placeholder="t('memories', 'Hour')"
          />
          <NcTextField
            :value.sync="minuteLast"
            class="field"
            :label="t('memories', 'Minute')"
            :placeholder="t('memories', 'Minute')"
          />
        </div>
      </div>

      <div v-if="processing" class="info-pad">
        {{
          t("memories", "Processing … {n}/{m}", {
            n: photosDone,
            m: photos.length,
          })
        }}
      </div>
    </div>

    <div v-else>
      {{
        t("memories", "Loading data … {n}/{m}", {
          n: photosDone,
          m: photos.length,
        })
      }}
    </div>
  </Modal>
</template>

<script lang="ts">
import { defineComponent } from "vue";
import { IPhoto } from "../../types";

import NcButton from "@nextcloud/vue/dist/Components/NcButton";
const NcTextField = () => import("@nextcloud/vue/dist/Components/NcTextField");

import { showError } from "@nextcloud/dialogs";
import { emit } from "@nextcloud/event-bus";
import Modal from "./Modal.vue";
import axios from "@nextcloud/axios";
import * as utils from "../../services/Utils";
import * as dav from "../../services/DavRequests";
import { API } from "../../services/API";

export default defineComponent({
  name: "EditDate",
  components: {
    NcButton,
    NcTextField,
    Modal,
  },

  data: () => ({
    photos: [] as IPhoto[],
    photosDone: 0,
    processing: false,

    longDateStr: "",
    year: "0",
    month: "0",
    day: "0",
    hour: "0",
    minute: "0",
    second: "0",

    longDateStrLast: "",
    yearLast: "0",
    monthLast: "0",
    dayLast: "0",
    hourLast: "0",
    minuteLast: "0",
    secondLast: "0",
  }),

  methods: {
    emitRefresh(val: boolean) {
      this.$emit("refresh", val);
    },

    async open(photos: IPhoto[]) {
      this.photos = photos;
      if (photos.length === 0) {
        return;
      }
      this.photosDone = 0;
      this.longDateStr = "";

      const calls = photos.map((p) => async () => {
        try {
          const res = await axios.get<any>(
            API.Q(API.IMAGE_INFO(p.fileid), "basic=1")
          );
          if (typeof res.data.datetaken !== "number") {
            console.error("Invalid date for", p.fileid);
            return;
          }
          p.datetaken = res.data.datetaken * 1000;
        } catch (error) {
          console.error("Failed to get date info for", p.fileid, error);
        } finally {
          this.photosDone++;
        }
      });

      for await (const _ of dav.runInParallel(calls, 10)) {
        // nothing to do
      }

      // Remove photos without datetaken
      this.photos = this.photos.filter((p) => p.datetaken !== undefined);

      // Sort photos by datetaken descending
      this.photos.sort((a, b) => b.datetaken - a.datetaken);

      // Get date of newest photo
      let date = new Date(this.photos[0].datetaken);
      this.year = date.getUTCFullYear().toString();
      this.month = (date.getUTCMonth() + 1).toString();
      this.day = date.getUTCDate().toString();
      this.hour = date.getUTCHours().toString();
      this.minute = date.getUTCMinutes().toString();
      this.second = date.getUTCSeconds().toString();
      this.longDateStr = utils.getLongDateStr(date, false, true);

      // Get date of oldest photo
      if (this.photos.length > 1) {
        date = new Date(this.photos[this.photos.length - 1].datetaken);
        this.yearLast = date.getUTCFullYear().toString();
        this.monthLast = (date.getUTCMonth() + 1).toString();
        this.dayLast = date.getUTCDate().toString();
        this.hourLast = date.getUTCHours().toString();
        this.minuteLast = date.getUTCMinutes().toString();
        this.secondLast = date.getUTCSeconds().toString();
        this.longDateStrLast = utils.getLongDateStr(date, false, true);
      }
    },

    newestChange(time = false) {
      if (this.photos.length === 0) {
        return;
      }

      // Set the last date to have the same offset to newest date
      try {
        const date = new Date(this.photos[0].datetaken);
        const dateLast = new Date(
          this.photos[this.photos.length - 1].datetaken
        );

        const dateNew = this.getDate();
        const offset = dateNew.getTime() - date.getTime();
        const dateLastNew = new Date(dateLast.getTime() + offset);

        this.yearLast = dateLastNew.getUTCFullYear().toString();
        this.monthLast = (dateLastNew.getUTCMonth() + 1).toString();
        this.dayLast = dateLastNew.getUTCDate().toString();

        if (time) {
          this.hourLast = dateLastNew.getUTCHours().toString();
          this.minuteLast = dateLastNew.getUTCMinutes().toString();
          this.secondLast = dateLastNew.getUTCSeconds().toString();
        }
      } catch (error) {}
    },

    close() {
      this.photos = [];
    },

    async saveOne() {
      // Make PATCH request to update date
      try {
        this.processing = true;
        const fileid = this.photos[0].fileid;
        await axios.patch<any>(API.IMAGE_SETEXIF(fileid), {
          raw: {
            DateTimeOriginal: this.getExifFormat(this.getDate()),
          },
        });
        emit("files:file:updated", { fileid });
        this.emitRefresh(true);
        this.close();
      } catch (e) {
        if (e.response?.data?.message) {
          showError(e.response.data.message);
        } else {
          showError(e);
        }
      } finally {
        this.processing = false;
      }
    },

    async saveMany() {
      if (this.processing) {
        return;
      }

      // Get difference between newest and oldest date
      const date = new Date(this.photos[0].datetaken);
      const dateLast = new Date(this.photos[this.photos.length - 1].datetaken);
      const diff = date.getTime() - dateLast.getTime();

      // Get new difference between newest and oldest date
      let dateNew: Date;
      let dateLastNew: Date;
      let diffNew: number;

      try {
        dateNew = this.getDate();
        dateLastNew = this.getDateLast();
        diffNew = dateNew.getTime() - dateLastNew.getTime();
      } catch (e) {
        showError(e);
        return;
      }

      // Validate if the old is still old
      if (diffNew < 0) {
        showError("The newest date must be newer than the oldest date");
        return;
      }

      // Mark processing
      this.processing = true;
      this.photosDone = 0;

      // Create PATCH requests
      const calls = this.photos.map((p) => async () => {
        try {
          let pDate = new Date(p.datetaken);

          // Fallback to start date if invalid date
          if (isNaN(pDate.getTime())) {
            pDate = date;
          }

          const offset = date.getTime() - pDate.getTime();
          const scale = diff > 0 ? diffNew / diff : 0;
          const pDateNew = new Date(dateNew.getTime() - offset * scale);
          await axios.patch<any>(API.IMAGE_SETEXIF(p.fileid), {
            raw: {
              DateTimeOriginal: this.getExifFormat(pDateNew),
            },
          });
          emit("files:file:updated", { fileid: p.fileid });
        } catch (e) {
          if (e.response?.data?.message) {
            showError(e.response.data.message);
          } else {
            showError(e);
          }
        } finally {
          this.photosDone++;
        }
      });

      for await (const _ of dav.runInParallel(calls, 10)) {
        // nothing to do
      }
      this.processing = false;
      this.emitRefresh(true);
      this.close();
    },

    async save() {
      if (this.photos.length === 0) {
        return;
      }

      if (this.photos.length === 1) {
        return await this.saveOne();
      }

      return await this.saveMany();
    },

    getExifFormat(date: Date) {
      const year = date.getUTCFullYear().toString().padStart(4, "0");
      const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
      const day = date.getUTCDate().toString().padStart(2, "0");
      const hour = date.getUTCHours().toString().padStart(2, "0");
      const minute = date.getUTCMinutes().toString().padStart(2, "0");
      const second = date.getUTCSeconds().toString().padStart(2, "0");
      return `${year}:${month}:${day} ${hour}:${minute}:${second}`;
    },

    getDate() {
      const dateNew = new Date();
      const year = parseInt(this.year, 10);
      const month = parseInt(this.month, 10) - 1;
      const day = parseInt(this.day, 10);
      const hour = parseInt(this.hour, 10);
      const minute = parseInt(this.minute, 10);
      const second = parseInt(this.second, 10) || 0;

      if (isNaN(year)) throw new Error("Invalid year");
      if (isNaN(month)) throw new Error("Invalid month");
      if (isNaN(day)) throw new Error("Invalid day");
      if (isNaN(hour)) throw new Error("Invalid hour");
      if (isNaN(minute)) throw new Error("Invalid minute");
      if (isNaN(second)) throw new Error("Invalid second");

      dateNew.setUTCFullYear(year);
      dateNew.setUTCMonth(month);
      dateNew.setUTCDate(day);
      dateNew.setUTCHours(hour);
      dateNew.setUTCMinutes(minute);
      dateNew.setUTCSeconds(second);
      return dateNew;
    },

    getDateLast() {
      const dateNew = new Date();
      const year = parseInt(this.yearLast, 10);
      const month = parseInt(this.monthLast, 10) - 1;
      const day = parseInt(this.dayLast, 10);
      const hour = parseInt(this.hourLast, 10);
      const minute = parseInt(this.minuteLast, 10);
      const second = parseInt(this.secondLast, 10) || 0;

      if (isNaN(year)) throw new Error("Invalid last year");
      if (isNaN(month)) throw new Error("Invalid last month");
      if (isNaN(day)) throw new Error("Invalid last day");
      if (isNaN(hour)) throw new Error("Invalid last hour");
      if (isNaN(minute)) throw new Error("Invalid last minute");
      if (isNaN(second)) throw new Error("Invalid last second");

      dateNew.setUTCFullYear(year);
      dateNew.setUTCMonth(month);
      dateNew.setUTCDate(day);
      dateNew.setUTCHours(hour);
      dateNew.setUTCMinutes(minute);
      dateNew.setUTCSeconds(second);
      return dateNew;
    },
  },
});
</script>

<style scoped lang="scss">
.fields {
  .field {
    width: 4.1em;
    display: inline-block;
  }

  :deep label {
    font-size: 0.8em;
    padding: 0 !important;
    padding-left: 3px !important;
  }
}

.oldest {
  margin-top: 10px;
}

.info-pad {
  margin-top: 6px;
  margin-bottom: 2px;

  &.warn {
    color: #f44336;
    font-size: 0.8em;
    line-height: 1em;
  }
}
</style>
