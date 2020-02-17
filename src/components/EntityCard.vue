<template>
  <div>
    <v-card min-width="500px">
      <v-card-title>
        {{ id }}
        <v-spacer></v-spacer>
        <v-text-field
          dense
          v-model="search"
          append-icon="mdi-filter-outline"
          label="filter"
          single-line
          hide-details
          clearable
        />
      </v-card-title>

      <v-card-text>
        <v-data-table
          :headers="headers"
          :items="component_fields"
          item-key="_key"
          group-by="_comp_id"
          :hide-default-footer="true"
          :hide-default-header="true"
          :disable-pagination="true"
          :search="search"
          :sort-by="[ '_comp_name', '_field' ]"
          dense
        >
          <template #group.header="{ group: comp_id, toggle: toggle }">
            <td colspan="3" @click="toggle()">
              <v-tooltip top transition="fade-transition">
                <template v-slot:activator="{ on }">
                  <span v-on="on">
                    {{ components[comp_id].type }}
                  </span>
                </template>
                {{ components[comp_id].desc }}
              </v-tooltip>
            </td>
          </template>

          <template #item._field="{ item }">
            <v-tooltip top transition="fade-transition">
              <template v-slot:activator="{ on }">
                <span v-on="on">
                  {{ item._field }}
                </span>
              </template>
              {{ item.desc }}
            </v-tooltip>
          </template>

          <template #item.value="{ item }">
            <div v-if="item.value instanceof Array">
              <ul>
                <li
                  v-for="(value, index) in item.value"
                  :key="item.key + '[' + index + ']'"
                >
                  <router-link
                    v-if="item.type[0] === 'entity'"
                    :to="'/entity/' + value"
                  >
                    <entity-with-tooltip bottom :id="value" />
                  </router-link>
                  <span v-else>
                    {{ value }}
                  </span>
                </li>
              </ul>
            </div>
            <div v-else-if="item.value instanceof Object">
              TODO Object: {{ item.value }}
            </div>
            <div v-else>
              <router-link
                v-if="item.type === 'entity' && item.value"
                :to="'/entity/' + item.value"
              >
                <entity-with-tooltip bottom :id="item.value" />
              </router-link>
              <span v-else>
                {{ item.value }}
              </span>
            </div>
          </template>

          <template #item.actions="{ item }">
            <div style="white-space:nowrap">
              <v-tooltip top transition="fade-transition">
                <template v-slot:activator="{ on }">
                  <v-icon small v-on="on" @click="edit_field(item)"
                    >mdi-pencil-outline</v-icon
                  >
                </template>
                edit
              </v-tooltip>

              <v-tooltip top transition="fade-transition">
                <template v-slot:activator="{ on }">
                  <v-icon small v-on="on">mdi-rotate-left</v-icon>
                </template>
                set to default
              </v-tooltip>

              <v-tooltip top transition="fade-transition">
                <template v-slot:activator="{ on }">
                  <v-icon
                    small
                    v-on="on"
                    @click="set_field(item._comp_id, item._field, item.default)"
                  >
                    mdi-close
                  </v-icon>
                </template>
                clear
              </v-tooltip>
            </div>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>

    <v-dialog v-model="edit.active" max-width="500px">
      <v-card>
        <v-card-title>
          {{ edit.name }}
        </v-card-title>

        <v-card-subtitle>
          {{ edit.desc }}
        </v-card-subtitle>

        <v-card-text>
          <component-field-input
            v-model="edit.value"
            :type="edit.type"
            :options="edit.options"
            @keyup.enter="set_field(edit.comp_id, edit.field, edit.value)"
          />
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn text @click="edit.active = false">Cancel</v-btn>
          <v-btn
            class="primary"
            text
            @click="set_field(edit.comp_id, edit.field, edit.value)"
          >
            Save
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-snackbar top v-model="snack" :timeout="3000" :color="snack_color">
      {{ snack_text }}
      <v-btn text @click="snack = false">Close</v-btn>
    </v-snackbar>
  </div>
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
    headers: [
      { text: "field", value: "_field" },
      { text: "value", value: "value" },
      { text: "actions", value: "actions" }
    ],
    components: {},
    component_fields: [],
    edit: { active: false },
    entity: null,
    snack: false,
    snack_color: "info",
    snack_text: "",
    search: "",
    rules: {}
  }),
  computed: {
    base: function() {
      var metadata = this.get_component("metadata");
      return metadata ? metadata.fields.base.value : [];
    }
  },
  mounted: async function() {
    this.entity = await this.$morrow.get_entity(this.id);

    this.entity.components.forEach(cid => {
      this.$morrow.get_component(cid).then(comp => {
        this.components[comp.component] = comp;

        for (let name of Object.keys(comp.fields)) {
          let field = comp.fields[name];

          this.component_fields.push(
            this._.merge(field, {
              _comp_id: comp.component,
              _comp_name: comp.type,
              _key: comp.component + "." + name,
              _field: name
            })
          );
        }
      });
    });
  },
  methods: {
    show_snack(color, msg) {
      this.snack_color = color;
      this.snack_text = msg;
      this.snack = true;
    },
    edit_field(field) {
      this.edit.comp_id = field._comp_id;
      this.edit.field = field._field;
      this.edit.value = field.value;
      this.edit.name = field._comp_name + "." + field._field;
      this.edit.desc = field.desc;
      this.edit.type = field.type;
      this.edit.options = field.valid instanceof Array ? field.valid : null;
      this.edit.active = true;
    },

    set_field(comp_id, field, value) {
      this.$morrow
        .set_component_field(comp_id, field, value)
        .then(() => {
          this.show_snack("success", "Field updated");
          this.edit.active = false;
          this.components[comp_id].fields[field].value = value;
        })
        .catch(e => {
          this.show_snack("error", e.response.data);
        });
    },
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
