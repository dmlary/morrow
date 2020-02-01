import Vue from "vue";
import VueRouter from "vue-router";

Vue.use(VueRouter);

const routes = [
  /*
  {
    path: "/",
    name: "home",
    component: Home
  }, */
  {
    path: "/settings",
    component: () => import("@/views/Settings.vue")
  },
  {
    path: "/entity/:id(.*)",
    component: () =>
      import(/* webpackChunkName: "entity-view" */ "@/views/EntityView.vue")
  }
];

const router = new VueRouter({
  routes
});

export default router;
