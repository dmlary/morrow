<template>
  <v-row class="component">
    <v-col cols="12" md="2">
      <v-tooltip bottom transition="fade-transition">
        <template v-slot:activator="{ on: tooltip }">
          <div v-on="tooltip" class="component-name">
            {{ component.name }}
          </div>
        </template>
        <div class="component-desc">{{ component.desc }}</div>
      </v-tooltip>
      <component-editor :component="component" />
    </v-col>
    <v-col class="component-fields">
      <v-row
        wrap
        no-gutters
        v-for="(field, name) in component.fields"
        :key="component.id + '.' + name"
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
          <ol>
            <li
              v-for="(value, index) in field.value"
              :key="component.id + '.' + name + '[' + index + ']'"
            >
              <router-link
                v-if="field.type[0] === 'entity' && value"
                :to="'/entity/' + value"
              >
                <entity-with-tooltip bottom :id="value" />
              </router-link>
              <span v-else>{{ value }}</span>
            </li>
          </ol>
        </v-col>
        <v-col v-else-if="field.value instanceof Object">
          <v-simple-table dense>
            <template>
              <tbody>
                <template v-for="(value, name) in field.value">
                  <tr
                    no-gutters
                    :key="component.id + '.' + name + '[' + name + ']'"
                  >
                    <td>{{ name }}</td>
                    <td>{{ value }}</td>
                  </tr>
                </template>
              </tbody>
            </template>
          </v-simple-table>
        </v-col>
        <v-col v-else>
          <router-link
            v-if="field.type === 'entity' && field.value"
            :to="'/entity/' + field.value"
          >
            <entity-with-tooltip bottom :id="field.value" />
          </router-link>
          <span v-else>{{ field.value }}</span>
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
