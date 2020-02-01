<template>
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
</template>

<script>
export default {
  name: "compact-entity",
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

    /* XXX alright, to correctly eliminate those values that come from the
     * base, we'd need to duplicate the logic from ruby to js to merge two
     * entities/component fields.  Instead, we need to make the web server
     * return the base value for each component/field, if there is one. */
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
</style>
