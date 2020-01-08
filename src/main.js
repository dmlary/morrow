import Vue from "vue";
import axios from "./plugins/axios";
import App from "./App.vue";
import store from "./store";
import vuetify from "./plugins/vuetify";
import "roboto-fontface/css/roboto/roboto-fontface.css";
import "@mdi/font/css/materialdesignicons.css";
import router from "./router";
import VueLodash from "vue-lodash";

Vue.config.productionTip = false;

Vue.use(VueLodash, { name: "lodash" });

new Vue({
  store,
  vuetify,
  axios,
  render: h => h(App),

  data: {},

  router,
  method: {}
}).$mount("#app");
