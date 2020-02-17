import Vue from "vue";
import axios from "./plugins/axios";
import App from "./App.vue";
import store from "./store";
import vuetify from "./plugins/vuetify";
import "roboto-fontface/css/roboto/roboto-fontface.css";
import "@mdi/font/css/materialdesignicons.css";
import router from "./router";
import VueLodash from "vue-lodash";
Vue.use(VueLodash, { name: "$lodash" });

import EntityCard from "@/components/EntityCard";
Vue.component(EntityCard.name, EntityCard);

import EntityWithTooltip from "@/components/EntityWithTooltip";
Vue.component(EntityWithTooltip.name, EntityWithTooltip);

import EntityAutocomplete from "@/components/EntityAutocomplete";
Vue.component(EntityAutocomplete.name, EntityAutocomplete);

import ComponentFieldInput from "@/components/ComponentFieldInput";
Vue.component(ComponentFieldInput.name, ComponentFieldInput);

import morrow from "@/plugins/morrow";
Vue.use(morrow, { url: process.env.VUE_APP_MORROW_BASE_URL });

Vue.config.productionTip = false;

new Vue({
  store,
  vuetify,
  axios,
  render: h => h(App),
  router,
  data: {},
  method: {}
}).$mount("#app");
