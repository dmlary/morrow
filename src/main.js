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

import CompactEntity from "@/components/CompactEntity";
Vue.component(CompactEntity.name, CompactEntity);

Vue.config.productionTip = false;

new Vue({
  store,
  vuetify,
  axios,
  render: h => h(App),

  data: {},
  components: { EntityCard },

  router,
  method: {}
}).$mount("#app");
