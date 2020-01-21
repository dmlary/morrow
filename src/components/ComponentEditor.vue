<template>
  <v-dialog v-model="dialog" width="640px">
    <template v-slot:activator="{ on: dialog }">
      <v-icon small v-on="dialog">mdi-pencil-outline</v-icon>
    </template>
    <v-card>
      <v-card-title align-bottom>
        <span class="mr-1">{{ component.name }}</span>
        <span v-if="component.unique" class="mx-1 body-2 secondary--text">
          unique
        </span>
        <span class="grey--text caption mx-1">({{ component.id }})</span>
      </v-card-title>
      <v-card-subtitle>
        <div class="pt-0">{{ component.desc }}</div>
      </v-card-subtitle>
      <v-card-text>
        <v-row
          v-for="(field, name) in component.fields"
          :key="'edit-' + component.id + '.' + name"
        >
          <v-col>
            <entity-autocomplete
              v-if="field.type == 'entity'"
              v-model="field.value"
              :label="name"
            />
            <v-text-field
              v-else
              dense
              :label="name"
              :hint="field.desc"
              v-model="field.value"
              clearable
            >
              <template v-slot:append>
                <v-tooltip top transition="fade-transition">
                  <template v-slot:activator="{ on: tooltip }">
                    <v-icon v-on="tooltip" @click="field.value = field.default"
                      >mdi-import</v-icon
                    >
                  </template>
                  <span>Reset to default: {{ field.default }}</span>
                </v-tooltip>
              </template>
            </v-text-field>
          </v-col>
        </v-row>
        <div style="white-space: pre">{{ component }}</div>
      </v-card-text>
      <v-divider />
      <v-card-actions>
        <v-spacer />
        <v-btn text @click="dialog = false">Cancel</v-btn>
        <v-btn text class="primary">Save</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  name: "component-editor",
  props: {
    component: {
      type: Object,
      required: true
    }
  },
  data: () => ({
    dialog: null
  })
};
</script>

<style></style>
