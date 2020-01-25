<template>
  <v-app id="app">
    <v-app-bar app clipped-left>
      <v-app-bar-nav-icon @click.stop="drawer = !drawer" />
      <v-toolbar-title>
        <span class="font-weight-black">morrow</span>
        <span class="font-weight-light">engine</span>
      </v-toolbar-title>
      <v-spacer />

      <entity-autocomplete
        width="100px"
        class="mt-4"
        v-model="search"
        @input="show_entity"
        v-slot="{ item }"
        placeholder="Entity ID"
        dense
      >
        <entity-with-tooltip :id="item" v-slot="{ on }" left>
          <span class="entity" v-on="on">{{ item }}</span>
        </entity-with-tooltip>
      </entity-autocomplete>
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

        <v-list-item>
          <v-switch
            small
            dense
            label="Dark Theme"
            v-model="$vuetify.theme.dark"
          />
        </v-list-item>
      </v-list>
    </v-navigation-drawer>
    <v-content>
      <router-view :key="$route.fullPath" />
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
    search: "",
    navagation: [
      { route: "/entity-view", title: "Entity Viewer", icon: "mdi-magnify" },
      { route: "/settings", title: "Settings", icon: "mdi-settings-box" }
    ]
  }),
  methods: {
    show_entity() {
      if (this.search == null) {
        return;
      }
      var path = "/entity/" + this.search;
      if (this.$router.path == path) {
        return;
      }
      this.$router.push(path);
    }
  },
  created() {
    this.$vuetify.theme.dark = true;
  }
};
</script>

<style>
/* this doesn't seem to be working :-/ */
.v-tooltip_content {
  opacity: 1 !important;
}
</style>
