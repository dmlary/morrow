<template>
  <v-row class="component">
    <v-col cols="12" md="2">
      <v-tooltip bottom transition="fade-transition">
        <template v-slot:activator="{ on: tooltip }">
          <div v-on="tooltip" class="component-name">{{ component.name }}</div>
        </template>
        <div class="component-desc">{{ component.desc }}</div>
      </v-tooltip>
    </v-col>
    <v-col class="component-fields">
      <v-row
        wrap
        no-gutters
        v-for="(field, name) in component.fields"
        :key="component.id + name"
        :class="
          `${
            field.modified ? 'primary--text lighten-1' : 'grey--text darken-2'
          }`
        "
      >
        <v-col cols="12" md="2">
          <v-tooltip bottom transition="fade-transition">
            <template v-slot:activator="{ on: tooltip }">
              <div class="component-field-name" v-on="tooltip">{{ name }}</div>
            </template>
            <div class="component-field-desc">{{ field.desc }}</div>
          </v-tooltip>
        </v-col>
        <v-col v-if="field.value instanceof Array">
          <div
            v-for="(value, index) in field.value"
            :key="component.id + name + index"
          >
            <entity-with-tooltip
              v-if="field.type[0] === 'entity' && value"
              :id="value"
            />
            <div v-else>{{ value }}</div>
          </div>
        </v-col>
        <v-col v-else>
          <entity-with-tooltip
            v-if="field.type === 'entity' && field.value"
            :id="field.value"
          />
          <template v-else>{{ field.value }}</template>
        </v-col>
      </v-row>
    </v-col>
  </v-row>
</template>

<script>
export default {
  name: "component-row",
  props: {
    component: {
      type: Object,
      required: true
    }
  }
};
</script>

<style>
.component-desc {
  white-space: pre;
}
.component-field-desc {
  white-space: pre;
}
</style>
