<template>
  <v-tooltip :left="left" :bottom="bottom" transition="fade-transition">
    <template v-slot:activator="{ on }">
      <slot v-bind:on="on">
        <span class="entity" v-on="on">{{ id }}</span>
      </slot>
    </template>

    <v-card class="compact-entity" max-width="600px">
      <v-card-text>
        <h3>{{ id }}</h3>
        <v-divider />

        <v-row no-gutters justify="start" v-if="base.length > 0">
          <v-col>
            <span v-if="area">{{ area }} |</span>
            <span v-for="b in base" :key="id + b">
              {{ b }}
            </span>
          </v-col>
        </v-row>

        <v-simple-table dense>
          <template v-slot:default>
            <tbody>
              <template v-for="component in components">
                <template v-for="(field, field_name) in component.fields">
                  <tr
                    no-gutters
                    v-if="component.name != 'metadata' && field.modified"
                    :key="id + component.id + field_name"
                  >
                    <td class="component-field">
                      {{ component.name }}.{{ field_name }}
                    </td>
                    <td>
                      <pre>{{ field.value }}</pre>
                    </td>
                  </tr>
                </template>
              </template>
            </tbody>
          </template>
        </v-simple-table>
      </v-card-text>
    </v-card>
  </v-tooltip>
</template>

<script>
export default {
  name: "entity-with-tooltip",
  props: {
    id: {
      type: String,
      required: true
    },
    link: Boolean,
    left: Boolean,
    bottom: Boolean
  },
  data: () => ({
    components: []
  }),
  computed: {
    base: function() {
      var metadata = this.get_component("metadata");
      return metadata ? metadata.fields.base.value : [];
    },
    area: function() {
      var metadata = this.get_component("metadata");
      return metadata ? metadata.fields.area.value : null;
    }
  },
  mounted: function() {
    this.get_entity(this.id).then(response => {
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
    },
    get_entity(id) {
      var url = process.env.VUE_APP_BACKEND_URL + "/entity/";
      return this.axios.get(url + id);
    }
  }
};
</script>

<style>
.compact-entity {
  opacity: 1 !important;
}

.component {
  border-top: 2px solid gray;
}
.row.field {
  border-left: 2px solid gray;
}

td.component-field {
  vertical-align: top;
}

.entity {
  color: var(--v-primary-base);
}
</style>
