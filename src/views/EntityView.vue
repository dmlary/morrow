<template>
  <div class="entity_view mx-5">
    <h1 class="subheading font-weight-thin">Entity Viewer</h1>
    <v-container>
      <v-card>
        <v-card-title class="pb-0">
          <v-row wrap>
            <v-col sm="12" md="8">
              <v-text-field
                v-model="search"
                label="Entity ID"
                append-icon="mdi-magnify"
                :rules="search_rules"
              />
            </v-col>
            <!-- <v-col sm="6" md="2">
              <v-text-field
                :value="items_per_page"
                label="Items per page"
                type="number"
                min="1"
                max="10000"
                @input="items_per_page = parseInt($event, 10)"
              />
            </v-col> -->
            <!-- <v-col sm="6" md="2" justify="bottom">
              <v-btn class="primary">New Entity</v-btn>
            </v-col> -->
          </v-row>
        </v-card-title>

        <v-data-table
          :headers="headers"
          :items="entities"
          :items-per-page.sync="items_per_page"
          :hide-default-header="true"
          :loading="loading"
          :footer-props="{
            'items-per-page-options': [10, 25, 50, 100, 250, 500, 1000]
          }"
        >
          <template v-slot:item="{ item }">
            <router-link :to="'entity/' + item.entity" tag="tr">
              <td>
                <entity-with-tooltip :id="item.entity" />
              </td>
            </router-link>
          </template>
        </v-data-table>
      </v-card>
    </v-container>
  </div>
</template>

<script>
// import json_entities from '@/json/test-entities.json'

export default {
  data: () => ({
    search_rules: [
      value => !!value || "Required",
      value => (value && value.length >= 3) || "Min 3 characters"
    ],
    headers: [
      { text: "Entity", align: "left", value: "entity" },
      {
        text: "Actions",
        align: "right",
        value: "action",
        sortable: false,
        filterable: false
      }
    ],
    items_per_page: 25,
    loading: false,
    search: "",
    entities: []
  }),
  watch: {
    search: function() {
      if (this.search.length < 3) {
        this.entities = [];
      } else {
        this.loading = true;
        this.debounced_fetch_entities();
      }
    }
  },
  created: function() {
    this.debounced_fetch_entities = this._.debounce(this.fetch_entities, 750);
  },
  methods: {
    fetch_entities() {
      if (this.search.length < 3) {
        this.entities = [];
        this.loading = false;
        return;
      }

      this.axios
        .get(process.env.VUE_APP_BACKEND_URL + "/entities", {
          params: { q: this.search }
        })
        .then(response => {
          this.entities = response.data.map(id => {
            return { entity: id };
          });
          this.loading = false;
        });
    },
    edit_entity(item) {
      this.entity = Object.assign({}, item);
      this.dialog = true;
    }
  }
};
</script>
