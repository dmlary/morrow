<template>
  <v-app id="app">
    <v-app-bar app clipped-left>
      <v-app-bar-nav-icon @click.stop="drawer = !drawer" />
      <v-toolbar-title>
        <span class="font-weight-black">morrow</span>
        <span class="font-weight-light">engine</span>
      </v-toolbar-title>
    </v-app-bar>

    <v-navigation-drawer v-model="drawer" app clipped>
      <v-list dense>
        <template v-for="item in navagation">
          <v-list-item :to="item.route" :key="item.route">
            <v-list-item-action>
              <v-icon>{{ item.icon }}</v-icon>
            </v-list-item-action>
            <v-list-item-content>
              <v-list-item-title>{{ item.title }}</v-list-item-title>
            </v-list-item-content>
          </v-list-item>
        </template>
      </v-list>
    </v-navigation-drawer>
    <v-content>
      <router-view />
    </v-content>
  </v-app>
</template>

<script>
export default {
  components: {},
  props: {
    source: String
  },
  data: () => ({
    drawer: null,
    navagation: [
      { route: "/entity-list", title: "Entity List", icon: "mdi-view-list" },
      { route: "/entity-view", title: "Entity Viewer", icon: "mdi-magnify" },
      { route: "/settings", title: "Settings", icon: "mdi-settings-box" }
    ]
  }),
  created() {
    this.$vuetify.theme.dark = true;
  }
};
</script>
