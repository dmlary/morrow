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
    path: "/entity-list",
    component: () =>
      import(/* webpackChunkName: "entity-list" */ "../views/EntityList.vue")
  },
  {
    path: "/entity-view",
    component: () =>
      import(/* webpackChunkName: "entity-view" */ "@/views/EntityView.vue")
  }
];

const router = new VueRouter({
  routes
});

export default router;
