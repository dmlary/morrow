import Vue from "vue";
import Vuetify from "vuetify";
import "vuetify/dist/vuetify.min.css";
import "@mdi/font/css/materialdesignicons.css";

Vue.use(Vuetify);

export default new Vuetify({
  icons: {
    iconfont: "mdi"
  },
  rtl: false,
  theme: {
    dark: true,
    themes: {
      dark: {
        primary: "#21CFF3",
        accent: "#FF4081",
        secondary: "#ffe18d",
        success: "#4CAF50",
        info: "#2196F3",
        warning: "#FB8C00",
        error: "#FF5252"
      },
      light: {
        primary: "#1976D2",
        accent: "#e91e63",
        secondary: "#30b1dc",
        success: "#4CAF50",
        info: "#2196F3",
        warning: "#FB8C00",
        error: "#FF5252"
      }
    },
    options: {
      customProperties: true
    }
  }
});
