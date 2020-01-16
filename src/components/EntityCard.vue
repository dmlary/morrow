<template>
  <v-card min-width="500px">
    <v-card-title>
      <v-tooltip bottom fluid>
        <template v-slot:activator="{ on }">
          <div v-on="on">{{ id }}</div>
        </template>
        <compact-entity :id="id" />
      </v-tooltip>
    </v-card-title>
    <v-divider />
    <v-card-text>
      <v-row wrap>
        <v-col cols="12" sm="3" md="2" xl="1">base entities</v-col>
        <v-col v-if="base.length > 0">
          <v-chip small v-for="b in base" :key="b" class="mx-1">
            <!-- XXX fix this, tooltip should be on chip -->
            <v-tooltip bottom fluid>
              <template v-slot:activator="{ on }">
                <div v-on="on">{{ b }}</div>
              </template>
              <compact-entity :id="b" />
            </v-tooltip>
          </v-chip>
        </v-col>
        <v-col v-else>none</v-col>
      </v-row>
      <v-divider />
      <div
        class="component"
        v-for="component in components"
        :key="component.id"
      >
        <v-row wrap no-gutters class="mb-2">
          <v-col cols="12" md="2" class="font-weight-bold">
            <v-tooltip top>
              <template v-slot:activator="{ on }">
                <div v-on="on">{{ component.name }}</div>
              </template>
              <pre v-if="component.desc.indexOf('\n') != -1">
                {{ component.desc }}
              </pre>
              <div v-else>{{ component.desc }}</div>
            </v-tooltip>
          </v-col>

          <v-col cols="12" md="10">
            <v-row
              class="field"
              wrap
              no-gutters
              v-for="(data, name) in component.fields"
              :key="component.id + name"
            >
              <v-tooltip top transition="fade-transition">
                <template v-slot:activator="{ on }">
                  <v-col v-on="on" class="ml-2" cols="2">{{ name }}</v-col>
                </template>
                <div style="white-space: pre;">{{ data.desc }}</div>
              </v-tooltip>
              <v-col
                :class="
                  `${
                    data.modified
                      ? 'primary--text text--lighten-1'
                      : 'grey--text'
                  }`
                "
              >
                <v-tooltip
                  bottom
                  fluid
                  transition="fade-transition"
                  v-if="data.type === 'entity' && data.value"
                >
                  <template v-slot:activator="{ on }">
                    <div v-on="on">{{ data.value }}</div>
                  </template>
                  <compact-entity :id="data.value" />
                </v-tooltip>
                <span v-else>
                  {{ data.value ? data.value : "nil" }}
                </span>
              </v-col>
            </v-row>
          </v-col>
        </v-row>
      </div>
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
