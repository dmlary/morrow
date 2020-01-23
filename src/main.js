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

import ComponentRow from "@/components/ComponentRow";
Vue.component(ComponentRow.name, ComponentRow);

import ComponentEditor from "@/components/ComponentEditor";
Vue.component(ComponentEditor.name, ComponentEditor);

import EntityWithTooltip from "@/components/EntityWithTooltip";
Vue.component(EntityWithTooltip.name, EntityWithTooltip);

import EntityAutocomplete from "@/components/EntityAutocomplete";
Vue.component(EntityAutocomplete.name, EntityAutocomplete);

Vue.config.productionTip = false;

import morrow from "@/plugins/morrow";
Vue.use(morrow, { url: process.env.VUE_APP_BACKEND_URL });

new Vue({
  store,
  vuetify,
  axios,
  render: h => h(App),

  data: {},
  router,
  method: {}
}).$mount("#app");
