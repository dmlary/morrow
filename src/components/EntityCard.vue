<template>
  <v-card min-width="500px">
    <v-card-title>{{ id }}</v-card-title>
    <v-card-text>
      <v-row wrap>
        <v-col cols="12" sm="3" md="2" xl="1">base entities</v-col>
        <v-col v-if="base.length > 0">
          <entity-with-tooltip
            v-for="b in base"
            :key="b"
            :id="b"
            v-slot="{ on }"
            bottom
          >
            <v-chip
              small
              class="mx-1 secondary lighten-1 black--text"
              v-on="on"
              @click="$router.push('/entity/' + b)"
            >
              {{ b }}
            </v-chip>
          </entity-with-tooltip>
        </v-col>
        <v-col v-else>none</v-col>
      </v-row>
      <v-divider />
      <template v-for="component in components">
        <component-row
          class="component"
          :component="component"
          :key="component.id"
        />
      </template>
    </v-card-text>
  </v-card>
</template>

<script>
export default {
  name: "entity-card",
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data: () => ({
    components: []
  }),
  computed: {
    base: function() {
      var metadata = this.get_component("metadata");
      return metadata ? metadata.fields.base.value : [];
    }
  },
  mounted: function() {
    var url = process.env.VUE_APP_BACKEND_URL + "/entity/" + this.id;
    this.axios.get(url).then(response => {
      this.components = response.data.components.sort((a, b) =>
        a.name > b.name ? 1 : -1
      );
    });
  },
  methods: {
    get_component(name) {
      return this._.find(this.components, function(comp) {
        return comp.name == name;
      });
    }
  }
};
</script>

<style>
.component {
  border-top: 2px solid gray;
}
.row.field {
  border-left: 2px solid gray;
}
.tooltip.tooltip-after-open {
  opacity: 1;
}
</style>
